// UI translation table (fork addition), one entry per line, tab-separated:
//
//     <upstream Simplified Chinese source>	<English (US)>	<繁體中文（台灣）>
//
// `{}` marks an interpolated value (`"已识别 \(n) 个字"` → `已识别 {} 个字`); use `{1}` `{2}`… in a
// translation to reorder values. `\n` is a line break. Lines starting with `#` are comments.
// After pulling upstream, `swift test --filter UILocalizationCoverageTests` lists new strings
// that need a line here (or in `UILocalizationIgnoreList` when they are not UI text).
// Traditional Chinese uses Taiwan vocabulary (設定, 軟體, 預設, 影片, 資訊, 網路, 檔案, 程式, 帳號…).

extension UITranslationTable {
    static let sections: [String] = [common, settings, app, core, guide]
}
