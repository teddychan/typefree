import Foundation

// Typefree 自定义版（fork）新增：中文输出字形（简体 / 繁體）。
// 在流水线最后一步统一转换：识别原文、润色结果、「翻译成中文」都覆盖，跟用哪家服务商无关。
// 用系统自带的 ICU 转换（逐字对应）：「软件」→「軟件」，不会换成台湾用语「軟體」。
public enum ChineseScript: String, CaseIterable {
    case original = "auto"          // 跟随识别 / 润色结果，不转换（默认）
    case simplified = "hans"
    case traditional = "hant"

    public static let configKey = "chinese_output_script"

    public static func current(config: VoicePolishConfig = .shared) -> ChineseScript {
        config.string(forKey: configKey).flatMap(ChineseScript.init(rawValue:)) ?? .original
    }

    public var title: String {
        switch self {
        case .original: return "跟随识别结果"
        case .simplified: return "简体中文"
        case .traditional: return "繁體中文"
        }
    }

    /// 只动中文字；英文、数字、标点原样保留
    public func apply(to text: String) -> String {
        switch self {
        case .original: return text
        case .simplified: return text.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? text
        case .traditional: return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
        }
    }
}
