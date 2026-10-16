#if os(macOS)
import AppKit
import ObjectiveC

/// Applies `UILocalizer` to AppKit text as it is set (fork addition), so upstream's thousands of
/// `label("…")` / `VPButton(title: "…")` / `NSMenuItem(title: "…")` call sites need no edits.
///
/// Hooks the setters AppKit text goes through: label text (not editable fields: they hold user input),
/// placeholders, button and menu-item titles (plain and attributed), tooltips, window titles, alert
/// texts and segment labels. Call `install()` once, before any UI is built.
/// Text drawn by hand (SwiftUI `Text`, `CATextLayer`, `NSString.draw`, web pages) calls `.uiLocalized`.
public enum AppKitUILocalization {
    private static var installed = false

    public static func install() {
        guard !installed else { return }
        installed = true
        swizzle(NSTextField.self, #selector(setter: NSTextField.stringValue), #selector(NSTextField.l10n_setStringValue(_:)))
        swizzle(NSTextField.self, #selector(setter: NSTextField.attributedStringValue), #selector(NSTextField.l10n_setAttributedStringValue(_:)))
        swizzle(NSTextField.self, #selector(setter: NSTextField.placeholderString), #selector(NSTextField.l10n_setPlaceholderString(_:)))
        swizzle(NSButton.self, #selector(setter: NSButton.title), #selector(NSButton.l10n_setTitle(_:)))
        swizzle(NSButton.self, #selector(setter: NSButton.attributedTitle), #selector(NSButton.l10n_setAttributedTitle(_:)))
        swizzle(NSMenuItem.self, #selector(setter: NSMenuItem.title), #selector(NSMenuItem.l10n_setTitle(_:)))
        swizzle(NSMenuItem.self, #selector(setter: NSMenuItem.attributedTitle), #selector(NSMenuItem.l10n_setAttributedTitle(_:)))
        swizzle(NSMenu.self, #selector(NSMenu.insertItem(_:at:)), #selector(NSMenu.l10n_insertItem(_:at:)))
        swizzle(NSMenu.self, #selector(setter: NSMenu.title), #selector(NSMenu.l10n_setTitle(_:)))
        swizzle(NSMenuItem.self, #selector(setter: NSMenuItem.submenu), #selector(NSMenuItem.l10n_setSubmenu(_:)))
        swizzle(NSView.self, #selector(setter: NSView.toolTip), #selector(NSView.l10n_setToolTip(_:)))
        swizzle(NSWindow.self, #selector(setter: NSWindow.title), #selector(NSWindow.l10n_setTitle(_:)))
        swizzle(NSAlert.self, #selector(setter: NSAlert.messageText), #selector(NSAlert.l10n_setMessageText(_:)))
        swizzle(NSAlert.self, #selector(setter: NSAlert.informativeText), #selector(NSAlert.l10n_setInformativeText(_:)))
        swizzle(NSSegmentedControl.self, #selector(NSSegmentedControl.setLabel(_:forSegment:)), #selector(NSSegmentedControl.l10n_setLabel(_:forSegment:)))
        swizzle(NSSavePanel.self, #selector(setter: NSSavePanel.message), #selector(NSSavePanel.l10n_setMessage(_:)))
        swizzle(DateFormatter.self, #selector(DateFormatter.string(from:)), #selector(DateFormatter.l10n_string(from:)))
        NotificationCenter.default.addObserver(forName: UILanguage.didChangeNotification, object: nil, queue: nil) { _ in
            refreshMenusAndWindowTitles()
        }
    }

    /// Menus and window titles that already exist (the status-bar menu, the main menu) are re-translated
    /// in place when the language changes; views are rebuilt by their owners (Settings reloads its pages).
    static func refreshMenusAndWindowTitles() {
        for menu in trackedMenus.allObjects {
            if let source = objc_getAssociatedObject(menu, &sourceKey) as? String {
                menu.l10n_setTitle(source.uiLocalized)
            }
            for item in menu.items {
                if let source = objc_getAssociatedObject(item, &sourceKey) as? NSAttributedString {
                    item.l10n_setAttributedTitle(localize(source))
                } else if let source = objc_getAssociatedObject(item, &sourceKey) as? String {
                    item.l10n_setTitle(source.uiLocalized)
                }
            }
        }
        for window in NSApp?.windows ?? [] {
            if let source = objc_getAssociatedObject(window, &sourceKey) as? String {
                window.l10n_setTitle(source.uiLocalized)
            }
        }
    }

    static let trackedMenus = NSHashTable<NSMenu>.weakObjects()
    static var sourceKey: UInt8 = 0

    static func remember(_ source: Any, on object: AnyObject) {
        objc_setAssociatedObject(object, &sourceKey, source, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Translates each attribute run on its own (runs are usually separate source literals, e.g. a bold
    /// prefix plus body text), or the whole string when it is one known string.
    static func localize(_ attributed: NSAttributedString) -> NSAttributedString {
        guard UILocalizer.language != .simplifiedChinese, UILocalizer.containsHan(attributed.string) else { return attributed }
        let whole = attributed.string
        let wholeTranslated = UILocalizer.localize(whole)
        if wholeTranslated != whole, attributed.length > 0 {
            var runCount = 0
            attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { _, _, _ in runCount += 1 }
            if runCount == 1 {
                return NSAttributedString(string: wholeTranslated, attributes: attributed.attributes(at: 0, effectiveRange: nil))
            }
        }
        let out = NSMutableAttributedString(attributedString: attributed)
        var changed = false
        // Back to front, so earlier ranges stay valid as lengths change.
        var ranges: [NSRange] = []
        attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { _, range, _ in ranges.append(range) }
        for range in ranges.reversed() {
            let piece = (whole as NSString).substring(with: range)
            let translated = UILocalizer.localize(piece)
            if translated != piece {
                out.replaceCharacters(in: range, with: translated)
                changed = true
            }
        }
        if !changed, wholeTranslated != whole, attributed.length > 0 {
            return NSAttributedString(string: wholeTranslated, attributes: attributed.attributes(at: 0, effectiveRange: nil))
        }
        return changed ? out : attributed
    }

    private static func swizzle(_ cls: AnyClass, _ original: Selector, _ replacement: Selector) {
        guard let orig = class_getInstanceMethod(cls, original),
              let repl = class_getInstanceMethod(cls, replacement) else {
            assertionFailure("UILocalization: cannot hook \(cls).\(original)")
            return
        }
        // Add to this class first, so an inherited implementation (e.g. NSControl's) isn't swapped for everyone.
        if class_addMethod(cls, original, method_getImplementation(repl), method_getTypeEncoding(repl)) {
            class_replaceMethod(cls, replacement, method_getImplementation(orig), method_getTypeEncoding(orig))
        } else {
            method_exchangeImplementations(orig, repl)
        }
    }
}

// After swizzling, each `l10n_…` call below runs the original AppKit setter.

extension NSTextField {
    @objc func l10n_setStringValue(_ value: String) {
        l10n_setStringValue(isEditable ? value : value.uiLocalized)
    }
    @objc func l10n_setAttributedStringValue(_ value: NSAttributedString) {
        l10n_setAttributedStringValue(isEditable ? value : AppKitUILocalization.localize(value))
    }
    @objc func l10n_setPlaceholderString(_ value: String?) {
        l10n_setPlaceholderString(value?.uiLocalized)
    }
}

extension NSButton {
    @objc func l10n_setTitle(_ value: String) { l10n_setTitle(value.uiLocalized) }
    @objc func l10n_setAttributedTitle(_ value: NSAttributedString) {
        l10n_setAttributedTitle(AppKitUILocalization.localize(value))
    }
}

extension NSMenuItem {
    @objc func l10n_setSubmenu(_ submenu: NSMenu?) {
        submenu?.l10n_translateTitleOnce()
        l10n_setSubmenu(submenu)
    }

    @objc func l10n_setTitle(_ value: String) {
        AppKitUILocalization.remember(value, on: self)
        l10n_setTitle(value.uiLocalized)
    }
    @objc func l10n_setAttributedTitle(_ value: NSAttributedString?) {
        if let value { AppKitUILocalization.remember(value, on: self) }
        l10n_setAttributedTitle(value.map(AppKitUILocalization.localize))
    }
}

extension NSMenu {
    /// A submenu's title is what the menu bar shows for it ("Edit").
    @objc func l10n_setTitle(_ value: String) {
        AppKitUILocalization.remember(value, on: self)
        AppKitUILocalization.trackedMenus.add(self)
        l10n_setTitle(value.uiLocalized)
    }

    /// `NSMenu(title:)` sets the title without the setter; translate it when the menu is attached.
    func l10n_translateTitleOnce() {
        guard objc_getAssociatedObject(self, &AppKitUILocalization.sourceKey) == nil else { return }
        AppKitUILocalization.remember(title, on: self)
        AppKitUILocalization.trackedMenus.add(self)
        l10n_setTitle(title.uiLocalized)
    }

    /// `NSMenuItem(title:…)` and `addItem(withTitle:…)` set the title without the setter; catch them here.
    @objc func l10n_insertItem(_ item: NSMenuItem, at index: Int) {
        if item.attributedTitle == nil, objc_getAssociatedObject(item, &AppKitUILocalization.sourceKey) == nil {
            AppKitUILocalization.remember(item.title, on: item)
            item.l10n_setTitle(item.title.uiLocalized)   // original setter: keep the Chinese source remembered
        }
        AppKitUILocalization.trackedMenus.add(self)
        l10n_insertItem(item, at: index)
    }
}

extension NSView {
    @objc func l10n_setToolTip(_ value: String?) { l10n_setToolTip(value?.uiLocalized) }
}

extension NSWindow {
    @objc func l10n_setTitle(_ value: String) {
        AppKitUILocalization.remember(value, on: self)
        l10n_setTitle(value.uiLocalized)
    }
}

extension NSSavePanel {
    @objc func l10n_setMessage(_ value: String) { l10n_setMessage(value.uiLocalized) }
}

extension DateFormatter {
    /// Formats like "M月d日 HH:mm" have table entries ("MMM d, HH:mm"); format with the translated pattern
    /// and a matching locale. Patterns without Chinese (parsing, ISO dates) are untouched.
    @objc func l10n_string(from date: Date) -> String {
        let lang = UILocalizer.language
        guard lang != .simplifiedChinese, let format = dateFormat, UILocalizer.containsHan(format),
              let translated = UILocalizer.translation(of: format, in: lang), translated != format,
              let copy = self.copy() as? DateFormatter else {
            return l10n_string(from: date)
        }
        copy.dateFormat = translated
        copy.locale = Locale(identifier: lang == .english ? "en_US" : "zh_TW")
        return copy.l10n_string(from: date)
    }
}

extension NSAlert {
    @objc func l10n_setMessageText(_ value: String) { l10n_setMessageText(value.uiLocalized) }
    @objc func l10n_setInformativeText(_ value: String) { l10n_setInformativeText(value.uiLocalized) }
}

extension NSSegmentedControl {
    @objc func l10n_setLabel(_ label: String, forSegment segment: Int) {
        l10n_setLabel(label.uiLocalized, forSegment: segment)
    }
}
#endif
