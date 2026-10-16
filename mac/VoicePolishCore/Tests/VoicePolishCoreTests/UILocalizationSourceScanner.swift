import Foundation

/// Finds the Chinese string literals in Swift source (fork addition, for `UILocalizationCoverageTests`).
/// Interpolations become `{}`, the same key form `UITranslations*.swift` uses; format specifiers inside
/// `String(format:)` become `{}` too. Literals inside log calls (`debugLog`, `NSLog`, `log`, `print`…)
/// and comments are skipped: logs stay Chinese on purpose.
struct UILocalizationSourceScanner {
    struct Literal: Hashable {
        let key: String
        let file: String
        let line: Int
    }

    static let logCalls: Set<String> = ["debugLog", "NSLog", "log", "print", "os_log", "fputs", "logLine", "appendLog"]

    private let s: [Unicode.Scalar]
    private let file: String
    private var i = 0
    private var line = 1
    private var literals: [Literal] = []

    static func scan(source: String, file: String) -> [Literal] {
        var scanner = UILocalizationSourceScanner(s: Array(source.unicodeScalars), file: file)
        scanner.scanCode(stack: [], untilClosingParen: false)
        return scanner.literals
    }

    private init(s: [Unicode.Scalar], file: String) {
        self.s = s
        self.file = file
    }

    private func peek(_ offset: Int = 0) -> Unicode.Scalar? {
        i + offset < s.count ? s[i + offset] : nil
    }

    private mutating func advance() {
        if s[i] == "\n" { line += 1 }
        i += 1
    }

    private static func isIdent(_ c: Unicode.Scalar) -> Bool {
        CharacterSet.alphanumerics.contains(c) || c == "_" || c == "." || c == "?" || c == "!"
    }

    /// Scans code; inside an interpolation stops after the `)` that closes it.
    private mutating func scanCode(stack: [String], untilClosingParen: Bool) {
        var stack = stack
        var depth = 0
        var ident = ""
        while let c = peek() {
            if c == "/", peek(1) == "/" {
                while let d = peek(), d != "\n" { _ = d; advance() }
                continue
            }
            if c == "/", peek(1) == "*" {
                skipBlockComment()
                continue
            }
            if c == "#", peek(1) == "\"" || peek(1) == "#" {
                skipRawString()
                ident = ""
                continue
            }
            if c == "\"" {
                parseString(stack: stack)
                ident = ""
                continue
            }
            if c == "(" {
                let name = ident.split(whereSeparator: { $0 == "." || $0 == "?" || $0 == "!" }).last.map(String.init) ?? ""
                stack.append(name)
                depth += 1
                ident = ""
                advance()
                continue
            }
            if c == ")" {
                if untilClosingParen && depth == 0 {
                    advance()
                    return
                }
                depth -= 1
                if !stack.isEmpty { stack.removeLast() }
                ident = ""
                advance()
                continue
            }
            if Self.isIdent(c) {
                ident.unicodeScalars.append(c)
            } else if c != " " {
                ident = ""
            }
            advance()
        }
    }

    private mutating func skipBlockComment() {
        var nest = 0
        while let c = peek() {
            if c == "/", peek(1) == "*" { nest += 1; advance(); advance(); continue }
            if c == "*", peek(1) == "/" {
                nest -= 1; advance(); advance()
                if nest == 0 { return }
                continue
            }
            advance()
        }
    }

    /// Raw strings (`#"…"#`) are only used for regexes here; skip them.
    private mutating func skipRawString() {
        var hashes = 0
        while peek() == "#" { hashes += 1; advance() }
        guard peek() == "\"" else { return }
        let multi = peek(1) == "\"" && peek(2) == "\""
        advance()
        if multi { advance(); advance() }
        while let c = peek() {
            if c == "\"" {
                var ok = true
                if multi { ok = peek(1) == "\"" && peek(2) == "\"" }
                let quoteLen = multi ? 3 : 1
                if ok {
                    var h = 0
                    while peek(quoteLen + h) == "#" { h += 1 }
                    if h >= hashes {
                        for _ in 0..<(quoteLen + hashes) { advance() }
                        return
                    }
                }
            }
            advance()
        }
    }

    private static let placeholder: Unicode.Scalar = "\u{E000}"

    private mutating func parseString(stack: [String]) {
        let startLine = line
        let multi = peek(1) == "\"" && peek(2) == "\""
        advance()
        if multi { advance(); advance() }
        var raw = String.UnicodeScalarView()
        while let c = peek() {
            if c == "\\" {
                if peek(1) == "(" {
                    advance(); advance()
                    raw.append(Self.placeholder)
                    scanCode(stack: stack, untilClosingParen: true)
                    continue
                }
                raw.append(c); advance()
                if let d = peek() { raw.append(d); advance() }
                continue
            }
            if c == "\"" {
                if !multi { advance(); break }
                if peek(1) == "\"" && peek(2) == "\"" { advance(); advance(); advance(); break }
            }
            if !multi && c == "\n" { break }   // unterminated; give up on this one
            raw.append(c)
            advance()
        }
        var text = String(raw)
        if multi { text = Self.dedentMultiline(text) }
        text = Self.unescape(text)
        let inFormat = stack.contains("String") || stack.contains("localizedStringWithFormat")
        if inFormat {
            text = text.replacingOccurrences(of: #"%(\d+\$)?[-+ 0#]*\d*(\.\d+)?(ll|l|h)?[@dDuUxXoOfeEgGcCsS]"#,
                                             with: "\u{E000}", options: .regularExpression)
        }
        text = text.replacingOccurrences(of: "\u{E000}", with: "{}")
        guard UILocalizationSourceScanner.containsHan(text) else { return }
        if stack.contains(where: { Self.logCalls.contains($0) }) { return }
        literals.append(Literal(key: text, file: file, line: startLine))
    }

    static func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value) }
    }

    /// Swift multi-line rules: drop the first and last line breaks, strip the closing delimiter's indentation,
    /// join lines ending in `\`.
    private static func dedentMultiline(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        guard lines.count >= 2 else { return text }
        let last = lines.removeLast()
        let indent = last.prefix { $0 == " " || $0 == "\t" }
        lines.removeFirst()   // content of the `"""` line itself is empty
        var out = ""
        for (n, l) in lines.enumerated() {
            var l = l.hasPrefix(indent) ? String(l.dropFirst(indent.count)) : l
            let isLast = n == lines.count - 1
            if l.hasSuffix("\\") && !l.hasSuffix("\\\\") {
                l.removeLast()
                out += l
            } else {
                out += l + (isLast ? "" : "\n")
            }
        }
        return out
    }

    private static func unescape(_ text: String) -> String {
        guard text.contains("\\") else { return text }
        var out = String.UnicodeScalarView()
        var it = Array(text.unicodeScalars)[...]
        while let c = it.popFirst() {
            guard c == "\\", let n = it.popFirst() else { out.append(c); continue }
            switch n {
            case "n": out.append("\n")
            case "t": out.append("\t")
            case "r": out.append("\r")
            case "0": out.append("\0")
            case "u":
                // \u{XXXX}
                if it.first == "{" {
                    it.removeFirst()
                    var hex = ""
                    while let h = it.popFirst(), h != "}" { hex.unicodeScalars.append(h) }
                    if let v = UInt32(hex, radix: 16), let sc = Unicode.Scalar(v) { out.append(sc) }
                }
            default: out.append(n)   // \" \\ \'
            }
        }
        return String(out)
    }
}
