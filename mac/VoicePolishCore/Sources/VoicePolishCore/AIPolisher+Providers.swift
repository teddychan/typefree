import Foundation

// Typefree 自定义版（fork）新增：OpenAI / Gemini / Claude / 自定义网关。
// 单独成文件，上游 AIPolisher.swift 里只留几处调用，拉上游更新时少冲突。

extension AIPolisher {
    /// 自带 Key 的海外服务商（OpenAI / Gemini / Claude）：只用于润色和问 AI，识别仍走火山 / 百炼。
    /// OpenAI、Gemini 走各自官方的 OpenAI 兼容 chat/completions；Claude 走 Anthropic 原生 Messages API。
    /// 模型可在设置里改成任意 ID，留空回落 defaultModel（2026-10 各家文档里的快速档）。
    public struct BYOKProvider {
        public let id: String              // polish_provider 的取值
        public let keyConfigKey: String
        public let envKey: String
        public let modelConfigKey: String
        public let defaultModel: String
        public let consoleURL: String
        let url: URL
    }

    public static let byokProviders: [BYOKProvider] = [
        BYOKProvider(id: "openai", keyConfigKey: "openai_api_key", envKey: "OPENAI_API_KEY",
                     modelConfigKey: "openai_polish_model", defaultModel: "gpt-6-luna",
                     consoleURL: "https://platform.openai.com/api-keys",
                     url: URL(string: "https://api.openai.com/v1/chat/completions")!),
        BYOKProvider(id: "gemini", keyConfigKey: "gemini_api_key", envKey: "GEMINI_API_KEY",
                     modelConfigKey: "gemini_polish_model", defaultModel: "gemini-3.8-flash",
                     consoleURL: "https://aistudio.google.com/apikey",
                     url: URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!),
        BYOKProvider(id: "claude", keyConfigKey: "anthropic_api_key", envKey: "ANTHROPIC_API_KEY",
                     modelConfigKey: "claude_polish_model", defaultModel: "claude-haiku-5-5",
                     consoleURL: "https://console.anthropic.com/settings/keys",
                     url: URL(string: "https://api.anthropic.com/v1/messages")!),
    ]

    public static func byokProvider(_ id: String?) -> BYOKProvider? {
        byokProviders.first { $0.id == id }
    }

    /// 设置里填的模型；没填（或只填了空格）用默认模型。
    public static func configuredModel(for provider: BYOKProvider, config: VoicePolishConfig = .shared) -> String {
        let saved = config.string(forKey: provider.modelConfigKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return saved.isEmpty ? provider.defaultModel : saved
    }

    /// 自定义服务商（polish_provider = "custom"）：自填地址 + Key + 模型，接口格式二选一。
    /// 用于自建 / 公司内部的 OpenAI 或 Anthropic 兼容网关。Key 可空（有的网关不鉴权）；地址和模型必填。
    public enum Custom {
        public static let providerID = "custom"
        public static let baseURLKey = "custom_base_url"
        public static let apiKeyKey = "custom_api_key"
        public static let modelKey = "custom_polish_model"
        public static let formatKey = "custom_api_format"   // "openai"（默认）或 "anthropic"
        public static let anthropicFormat = "anthropic"
        /// 走 Anthropic 格式时请求层用的 provider 名（决定请求体、鉴权头和响应解析）
        static let anthropicProviderName = "custom-anthropic"

        /// 填的是 base URL（如 https://host/v1）就补上接口路径；已经填到 /chat/completions 或 /messages 就原样用。
        public static func endpoint(base: String, anthropic: Bool) -> URL? {
            endpoint(base: base, path: anthropic ? "/messages" : "/chat/completions")
        }

        /// 通用版：base URL 补上 path（语音识别的自定义网关用 /audio/transcriptions）
        public static func endpoint(base: String, path: String) -> URL? {
            var s = base.trimmingCharacters(in: .whitespacesAndNewlines)
            while s.hasSuffix("/") { s.removeLast() }
            guard !s.isEmpty, let url = URL(string: s), let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http", url.host?.isEmpty == false else { return nil }
            return s.hasSuffix(path) ? url : URL(string: s + path)
        }

        public static func isAnthropic(config: VoicePolishConfig = .shared) -> Bool {
            config.string(forKey: formatKey) == anthropicFormat
        }

        static func model(config: VoicePolishConfig) -> String {
            config.string(forKey: modelKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }

        /// 地址合法且填了模型 = 可用
        public static func isConfigured(config: VoicePolishConfig = .shared) -> Bool {
            endpoint(base: config.string(forKey: baseURLKey) ?? "", anthropic: isAnthropic(config: config)) != nil
                && !model(config: config).isEmpty
        }
    }

    /// 走 Anthropic Messages API 的请求（官方 Claude 或 Anthropic 格式的自定义网关）
    static func speaksAnthropic(_ provider: String) -> Bool {
        provider == "claude" || provider == Custom.anthropicProviderName
    }

    // MARK: - 请求 / 响应

    /// Claude 用 x-api-key + anthropic-version；其余（含 OpenAI / Gemini 兼容接口）用 Bearer。
    /// Anthropic 格式的自定义网关两种头都带：各家网关认的不一样（有的只认 Bearer）。自定义没填 Key 就不带鉴权头。
    static func authorize(_ request: inout URLRequest, provider: String, apiKey: String) {
        if speaksAnthropic(provider) {
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }
        if provider.hasPrefix(Custom.providerID) && apiKey.isEmpty { return }
        if speaksAnthropic(provider) {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        if provider != "claude" {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    /// OpenAI 风格的 messages 转成 Anthropic Messages API 请求体：system 角色提到顶层 system 字段。
    static func anthropicBody(model: String, messages: [[String: Any]], maxTokens: Int, stream: Bool) -> [String: Any] {
        let system = messages.filter { $0["role"] as? String == "system" }
            .compactMap { $0["content"] as? String }.joined(separator: "\n\n")
        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": messages.filter { $0["role"] as? String != "system" }
        ]
        if !system.isEmpty { body["system"] = system }
        if stream { body["stream"] = true }
        return body
    }

    /// 取出回答正文和 token 用量：OpenAI 兼容的 choices[0].message.content，或 Anthropic 的 content[].text。
    static func parseCompletion(_ json: [String: Any]) -> (String, Int, Int)? {
        let usage = json["usage"] as? [String: Any]
        if let content = ((json["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String {
            return (content.trimmingCharacters(in: .whitespacesAndNewlines),
                    usage?["prompt_tokens"] as? Int ?? 0, usage?["completion_tokens"] as? Int ?? 0)
        }
        if let blocks = json["content"] as? [[String: Any]] {
            let text = blocks.filter { $0["type"] as? String == "text" }
                .compactMap { $0["text"] as? String }.joined()
            return (text.trimmingCharacters(in: .whitespacesAndNewlines),
                    usage?["input_tokens"] as? Int ?? 0, usage?["output_tokens"] as? Int ?? 0)
        }
        return nil
    }

    /// Gemini 的 OpenAI 兼容接口出错时可能回 [{"error":…}]：取第一个元素，按普通错误对象处理。
    static func jsonDictionary(_ object: Any?) -> [String: Any]? {
        (object as? [String: Any]) ?? (object as? [[String: Any]])?.first
    }
}
