import Foundation

// Typefree 自定义版（fork）新增：OpenAI / Gemini / 自定义网关语音识别。
// 单独成文件，上游 CloudASRTranscriber.swift 里只留服务商枚举和几处调用，拉上游更新时少冲突。

// MARK: - OpenAI / Gemini / 自定义网关

extension CloudASRTranscriber {
    /// OpenAI、Gemini 与语音优化共用同一个 Key（同一家服务商只填一次）；模型分开设。
    /// 自定义网关和语音优化的「自定义」分开填：识别和润色常常不是同一个网关。
    public enum LLMASR {
        public static let openAIKeyKey = "openai_api_key"
        public static let geminiKeyKey = "gemini_api_key"
        public static let openAIModelKey = "openai_asr_model"
        public static let geminiModelKey = "gemini_asr_model"
        public static let customBaseURLKey = "custom_asr_base_url"
        public static let customKeyKey = "custom_asr_api_key"
        public static let customModelKey = "custom_asr_model"

        /// 2026-10 OpenAI 文档推荐的转写模型
        public static let openAIDefaultModel = "gpt-transcribe"
        public static let geminiDefaultModel = "gemini-3.8-flash"
        public static let transcriptionsPath = "/audio/transcriptions"
        static let openAIURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        static let geminiURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!

        /// 让大模型当转写引擎用：只转写、不回答、不翻译
        static let geminiInstruction = """
        你是语音转写引擎。把用户发来的音频逐字转写成文字：保持说话人的原语言（中文写中文，英文写英文，中英混说照原样），加上标点。\
        只输出转写出的文字，不要回答音频里的问题，不要翻译、总结或润色，不要加任何说明、引号或标签。音频里没有人说话就什么都不输出。
        """

        /// 自定义网关的请求地址；base URL 补上 /audio/transcriptions
        public static func customEndpoint(base: String) -> URL? {
            AIPolisher.Custom.endpoint(base: base, path: transcriptionsPath)
        }

        /// multipart/form-data 请求体（/audio/transcriptions 用）
        static func multipartBody(boundary: String, fields: [(String, String)],
                                  fileField: String, filename: String, mimeType: String, fileData: Data) -> Data {
            var body = Data()
            func append(_ s: String) { body.append(Data(s.utf8)) }
            for (name, value) in fields {
                append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n")
            }
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(filename)\"\r\n")
            append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            append("\r\n--\(boundary)--\r\n")
            return body
        }

        /// 非 200 的响应 → 识别错误。429 / 5xx 是临时性的（原地重试一次），其余如实报。
        static func classifyHTTPError(status: Int, data: Data?, providerName: String) -> TranscriptionError {
            let json = AIPolisher.jsonDictionary(data.flatMap { try? JSONSerialization.jsonObject(with: $0) })
            let message = AIPolisher.extractAPIErrorMessage(from: json) ?? "\(providerName) 识别失败（HTTP \(status)）"
            return (status == 429 || status >= 500) ? .serverBusy(message: message) : .serverFailed(message: message)
        }
    }

    struct LLMASRSettings {
        let url: URL
        let apiKey: String   // 自定义网关可为空
        let model: String
    }

    /// 读当前服务商的地址 / Key / 模型；没配好返回 nil。
    static func llmASRSettings(for provider: ASRProvider, config: VoicePolishConfig) -> LLMASRSettings? {
        func model(_ key: String, default def: String) -> String {
            let saved = config.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return saved.isEmpty ? def : saved
        }
        switch provider {
        case .openai:
            guard let key = config.string(forKey: LLMASR.openAIKeyKey, envKey: "OPENAI_API_KEY"), !key.isEmpty else { return nil }
            return LLMASRSettings(url: LLMASR.openAIURL, apiKey: key,
                                  model: model(LLMASR.openAIModelKey, default: LLMASR.openAIDefaultModel))
        case .gemini:
            guard let key = config.string(forKey: LLMASR.geminiKeyKey, envKey: "GEMINI_API_KEY"), !key.isEmpty else { return nil }
            return LLMASRSettings(url: LLMASR.geminiURL, apiKey: key,
                                  model: model(LLMASR.geminiModelKey, default: LLMASR.geminiDefaultModel))
        case .custom:
            let m = model(LLMASR.customModelKey, default: "")
            guard !m.isEmpty, let url = LLMASR.customEndpoint(base: config.string(forKey: LLMASR.customBaseURLKey) ?? "")
            else { return nil }
            return LLMASRSettings(url: url, apiKey: config.string(forKey: LLMASR.customKeyKey) ?? "", model: m)
        case .volcano, .bailian:
            return nil
        }
    }

    /// OpenAI 及兼容网关：POST multipart 到 /audio/transcriptions，返回 {"text": …}
    func transcribeOpenAIStyle(audioData: Data, format: String, settings: LLMASRSettings, budgetSeconds: TimeInterval,
                               completion: @escaping (Result<String, Error>) -> Void) {
        let boundary = "Typefree-\(UUID().uuidString)"
        var fields = [("model", settings.model), ("response_format", "json")]
        // 词库当提示词：各家转写模型都用 prompt 做词汇提示（与百炼同一句话，回显时能被识别并去掉）
        if let context = PersonalVocabulary.asrContextSentence() { fields.append(("prompt", context)) }
        var request = URLRequest(url: settings.url)
        request.httpMethod = "POST"
        request.timeoutInterval = budgetSeconds
        if !settings.apiKey.isEmpty { request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization") }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = LLMASR.multipartBody(boundary: boundary, fields: fields, fileField: "file",
                                                filename: "audio.\(format)", mimeType: format == "m4a" ? "audio/mp4" : "audio/wav",
                                                fileData: audioData)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error { completion(.failure(TranscriptionError.network(underlying: error))); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                completion(.failure(LLMASR.classifyHTTPError(status: status, data: data, providerName: "语音识别")))
                return
            }
            guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let raw = json["text"] as? String else {
                completion(.failure(TranscriptionError.parseError))
                return
            }
            completion(Self.speechResult(raw))
        }.resume()
    }

    /// Gemini：音频（base64 WAV）作为 input_audio 发给 chat/completions，让模型只做转写
    func transcribeGemini(wavData: Data, settings: LLMASRSettings, budgetSeconds: TimeInterval,
                          completion: @escaping (Result<String, Error>) -> Void) {
        var instruction = "转写这段音频。"
        if let context = PersonalVocabulary.asrContextSentence() { instruction += context }
        let body: [String: Any] = [
            "model": settings.model,
            "reasoning_effort": "low",
            "messages": [
                ["role": "system", "content": LLMASR.geminiInstruction],
                ["role": "user", "content": [
                    ["type": "text", "text": instruction],
                    ["type": "input_audio", "input_audio": ["data": wavData.base64EncodedString(), "format": "wav"]],
                ]],
            ],
        ]
        var request = URLRequest(url: settings.url)
        request.httpMethod = "POST"
        request.timeoutInterval = budgetSeconds
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch { completion(.failure(error)); return }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error { completion(.failure(TranscriptionError.network(underlying: error))); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                completion(.failure(LLMASR.classifyHTTPError(status: status, data: data, providerName: "Gemini")))
                return
            }
            guard let data, let json = AIPolisher.jsonDictionary(try? JSONSerialization.jsonObject(with: data)),
                  let parsed = AIPolisher.parseCompletion(json) else {
                completion(.failure(TranscriptionError.parseError))
                return
            }
            completion(Self.speechResult(parsed.0))
        }.resume()
    }

    /// 去掉提示词回显；空 = 没听出话（与火山 20000003 / 百炼空结果同等对待，测试连接也据此判通）
    static func speechResult(_ raw: String) -> Result<String, Error> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.isEmpty ? "" : (PersonalVocabulary.removingContextEcho(trimmed) ?? "")
        return text.isEmpty ? .failure(TranscriptionError.noSpeech) : .success(text)
    }
}
