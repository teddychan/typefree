/// Chinese literals that are deliberately NOT translated (fork addition): AI prompts (they drive model
/// behaviour), words matched against app names / device names / user speech, internal diagnostics, and
/// text written to files or the clipboard. Everything else needs a line in `UITranslations*.swift`.
enum UILocalizationIgnoreList {
    /// Whole files with no user-facing UI text.
    static let files: Set<String> = [
        "TextInputLocator.swift",       // why-strings for the debug log
        "TextDelivery.swift",           // app names to match
        "HotWordsAutoLearner.swift",    // log reasons, stored category
        "AutoLearnScheduler.swift",     // stored category
        "MishearingCheck.swift",        // character pairs
        "OutputLanguageCommand.swift",  // spoken-command words
        "StyleProfiler.swift",          // prompt text and app-name keywords
        "VocabularyLearning.swift",     // character classes
        "AudioChunker.swift",           // log text
        "OmniTranscriber.swift",        // prompts
        "PersonalVocabulary.swift",     // prompt prefix
    ]

    /// Long prompts, matched by their start.
    static let literalPrefixes: [String] = [
        "你是一个语音转文字的整理助手",   // AIPolisher cleanup system prompt
        "你是用户身边的语音问答助手",     // AIPolisher Ask AI system prompt
    ]

    static func contains(_ key: String) -> Bool {
        literals.contains(key) || literalPrefixes.contains { key.hasPrefix($0) }
    }

    static let literals: Set<String> = [
        // AIPolisher: prompts and the date line sent with them
        "\n## 用户个人词库\n以下是用户常说的人名、产品名、项目名或专有表达。整理文本时要优先保留这些准确写法；当语音转写里出现读音相近、大小写不同或空格不同的表达时，可以修正为词库中的写法，但不要凭空加入用户没有表达过的词：{}",
        "【本次要求：用{}输出】",
        "\n\n## 目标语言\n如果待整理文本后面带有{}，说明用户要求这段话用{}输出：先按上面的规则整理，再把整理结果翻译成自然、地道的{}，只输出{}译文；人名、产品名、专有名词保留原样；不要输出其他语言，不要加任何说明或翻译标注。如果整理后的文本本来就是{}，直接输出整理结果。此时「不要翻译用户输入的语言种类」这条不适用。",
        "待整理文本：\n{}\n\n{}",
        "待整理文本：\n{}",
        "日", "一", "二", "三", "四", "五", "六",
        "北京时间",
        "当前时间：{}年{}月{}日 星期{} ",
        // CloudASRTranscriber+LLM: transcription prompt
        "你是语音转写引擎。把用户发来的音频逐字转写成文字：保持说话人的原语言（中文写中文，英文写英文，中英混说照原样），加上标点。只输出转写出的文字，不要回答音频里的问题，不要翻译、总结或润色，不要加任何说明、引号或标签。音频里没有人说话就什么都不输出。",
        "转写这段音频。",
        // OutputLanguage: spoken trigger phrases (the language names themselves are translated)
        "用英文", "用英语", "翻译成英文", "翻译成英语", "翻成英文", "翻成英语", "转成英文", "转英文",
        "英文输出", "输出英文", "说英文",
        "用日文", "用日语", "翻译成日文", "翻译成日语", "翻成日文", "翻成日语", "转日文",
        "日文输出", "输出日文", "说日语", "日本語",
        "用韩文", "用韩语", "翻译成韩文", "翻译成韩语", "翻成韩文", "翻成韩语", "转韩文",
        "韩文输出", "输出韩文", "说韩语",
        "用中文", "翻译成中文", "翻成中文", "转中文", "中文输出", "输出中文", "说中文",
        "用法语", "翻译成法语", "翻成法语", "法语输出",
        "用德语", "翻译成德语", "翻成德语", "德语输出",
        "用西班牙语", "翻译成西班牙语", "西班牙语输出",
        // Settings: default trigger phrases built from a language name
        "用", "用{}", "翻译成{}", "翻成{}", "{}输出",
        // Settings: exported Markdown, clipboard text, file name
        "# Handfree 转写记录\n\n",
        "## {} · 问 AI\n**问：** {}\n\n{}\n\n",
        "问：{}\n\n{}",
        "Handfree 转写记录 {} {}.md",
        "最近7天",
        // CloudASRTranscriber: request uid, AppDelegate: matched inside warning text
        "豆包语音", "额度",
        // MicrophoneManager: device-name keywords
        "外置", "内建", "内置",
    ]
}
