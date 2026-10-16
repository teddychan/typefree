#if os(macOS)
import Darwin
import Foundation

// Typefree 自定义版（fork）新增：本机运行的 Qwen3-ASR 语音识别（mlx-qwen3-asr，Apple 芯片）。
//
// 用户只需在「语音识别」里选「本地 Qwen3-ASR」，其余全自动：
// 1. 用 App 自带的 uv 建私有 Python 环境，装固定版本的 mlx-qwen3-asr[serve]（约 300 MB，只装一次）；
// 2. 起本地服务（127.0.0.1 随机空闲端口 + 随机 Key），首次启动时它自己从 Hugging Face 下载模型（约 4.7 GB，
//    存在标准缓存 ~/.cache/huggingface，已下载过就直接用）；
// 3. /health 通了才算就绪；App 退出或换服务商时停掉服务。
// 识别时发 16 kHz WAV：服务端用标准库直接读 WAV，不需要 ffmpeg。
public final class LocalASRServer {
    public static let shared = LocalASRServer()

    public static let modelID = CloudASRTranscriber.LLMASR.localModelID
    /// 固定版本：升级要改这里并重新测，免得上游包更新把服务弄坏
    static let packageSpec = "mlx-qwen3-asr[serve]==0.4.4"
    static let pythonVersion = "3.12"
    public static let approxModelDownloadGB = 4.7

    public static let stateDidChange = Notification.Name("LocalASRServerStateDidChange")

    /// 用户在设置里打开「启用本地模型」才下载 / 加载（默认关：选了这个服务商也不自动占几 GB 磁盘和内存）
    public static let enabledConfigKey = "local_asr_enabled"   // 与 CloudASRTranscriber.LLMASR.localEnabled 同一个键
    public static func isEnabled(config: VoicePolishConfig = .shared) -> Bool {
        config.bool(forKey: enabledConfigKey, defaultValue: false)
    }

    /// 打开 = 需要时下载并加载；关闭 = 卸载（停服务、释放内存），已下载的文件保留，再打开很快
    public func setEnabled(_ enabled: Bool, config: VoicePolishConfig = .shared) {
        config.save(bool: enabled, forKey: Self.enabledConfigKey)
        if enabled { start() } else { stop() }
    }

    public enum State: Equatable {
        case stopped
        case installing             // 建 Python 环境 + 装依赖
        case starting               // 服务已起，下载 / 加载模型中
        case ready(port: Int)
        case failed(String)
    }

    /// MLX 只支持 Apple 芯片
    public static var isSupported: Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    public var debugLog: ((String) -> Void)?

    private let queue = DispatchQueue(label: "local-asr-server")
    private var _state: State = .stopped
    private var wanted = false                 // 用户当前要不要它跑着（stop 之后迟到的回调据此作废）
    private var generation = 0                 // 每次 start/stop 递增，旧一轮的回调据此作废
    private var installProcess: Process?
    private var serverProcess: Process?
    private let token = LocalASRServer.randomToken()

    private init() {}

    public var state: State { queue.sync { _state } }

    /// 就绪时给识别用的地址 / Key / 模型；没就绪返回 nil
    func transcriptionSettings() -> CloudASRTranscriber.LLMASRSettings? {
        queue.sync {
            guard case .ready(let port) = _state,
                  let url = URL(string: "http://127.0.0.1:\(port)/v1/audio/transcriptions") else { return nil }
            return CloudASRTranscriber.LLMASRSettings(url: url, apiKey: token, model: Self.modelID)
        }
    }

    /// 没就绪时给用户看的一句话
    public var notReadyMessage: String {
        switch state {
        case .installing: return "本地模型正在安装（首次约几分钟），好了再说一次"
        case .starting: return "本地模型正在启动（首次需下载约 \(Self.approxModelDownloadGB) GB），好了再说一次"
        case .failed(let reason): return "本地模型启动失败：\(reason)"
        case .stopped, .ready:
            return Self.isEnabled() ? "本地模型还没启动，正在启动，稍后再试"
                                    : "本地模型未启用 · 在「设置 → 模型」打开「启用本地模型」"
        }
    }

    // MARK: - 启停

    /// 幂等：已在装 / 在起 / 已就绪就什么都不做；失败过则重来。
    public func start() {
        queue.async {
            self.wanted = true
            switch self._state {
            case .installing, .starting, .ready: return
            case .stopped, .failed: break
            }
            guard Self.isSupported else { self.setState(.failed("需要 Apple 芯片（M 系列）的 Mac")); return }
            self.generation += 1
            let gen = self.generation
            self.killOrphanFromPIDFile()
            if self.isInstalled() {
                self.launchServer(generation: gen)
            } else {
                self.install(generation: gen)
            }
        }
    }

    /// 停服务（App 退出、换识别服务商时调用）。同步等进程退出，最多约 3 秒。
    public func stop() {
        let processes: [Process] = queue.sync {
            wanted = false
            generation += 1
            let ps = [installProcess, serverProcess].compactMap { $0 }
            installProcess = nil
            serverProcess = nil
            setState(.stopped)
            return ps
        }
        for p in processes where p.isRunning {
            p.terminate()
            let deadline = Date().addingTimeInterval(3)
            while p.isRunning && Date() < deadline { usleep(50_000) }
            if p.isRunning { kill(p.processIdentifier, SIGKILL) }
        }
        try? FileManager.default.removeItem(at: paths.pidFile)
    }

    // MARK: - 安装

    struct Paths {
        let base: URL
        var venv: URL { base.appendingPathComponent("venv") }
        var python: URL { venv.appendingPathComponent("bin/python") }
        var serverBinary: URL { venv.appendingPathComponent("bin/mlx-qwen3-asr") }
        var installedMarker: URL { base.appendingPathComponent("installed.txt") }
        var pidFile: URL { base.appendingPathComponent("server.pid") }
        var log: URL { base.appendingPathComponent("server.log") }
    }

    /// ~/Library/Application Support/<App 名>/LocalASR（Debug 与正式版各装一份；模型缓存共用）
    let paths: Paths = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Typefree"
        return Paths(base: support.appendingPathComponent(appName).appendingPathComponent("LocalASR"))
    }()

    /// 装好的版本和要求的一致才算装好（改了 packageSpec 会自动重装）
    func isInstalled() -> Bool {
        let marker = (try? String(contentsOf: paths.installedMarker, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return marker == Self.packageSpec && FileManager.default.isExecutableFile(atPath: paths.serverBinary.path)
    }

    /// App 自带的 uv（Contents/Resources/LocalASR/uv）；没打包进来就退到常见安装位置
    static func uvExecutable() -> URL? {
        var candidates: [URL] = []
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("LocalASR/uv") { candidates.append(bundled) }
        let home = FileManager.default.homeDirectoryForCurrentUser
        candidates += [home.appendingPathComponent(".local/bin/uv"),
                       URL(fileURLWithPath: "/opt/homebrew/bin/uv"), URL(fileURLWithPath: "/usr/local/bin/uv")]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    /// uv 的两步命令：建环境（用 uv 自己管理的 Python，不碰系统 Python）、装包
    static func installCommands(paths: Paths) -> [[String]] {
        [["venv", "--python", pythonVersion, "--clear", paths.venv.path],
         ["pip", "install", "--python", paths.python.path, packageSpec]]
    }

    private func install(generation gen: Int) {
        setState(.installing)
        guard let uv = Self.uvExecutable() else {
            setState(.failed("缺少 uv（App 应自带；也可以 brew install uv）"))
            return
        }
        do {
            try FileManager.default.createDirectory(at: paths.base, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: paths.installedMarker)
        } catch {
            setState(.failed("建不了 \(paths.base.path)：\(error.localizedDescription)"))
            return
        }
        log("install start: \(Self.packageSpec) via \(uv.path)")
        runInstallStep(uv: uv, steps: Self.installCommands(paths: paths), generation: gen)
    }

    private func runInstallStep(uv: URL, steps: [[String]], generation gen: Int) {
        guard let args = steps.first else {
            try? Self.packageSpec.write(to: paths.installedMarker, atomically: true, encoding: .utf8)
            log("install done")
            launchServer(generation: gen)
            return
        }
        let p = Process()
        p.executableURL = uv
        p.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["UV_PYTHON_PREFERENCE"] = "only-managed"   // 不依赖用户机器上装没装 Python、装的哪个版本
        env["UV_NO_PROGRESS"] = "1"
        p.environment = env
        attachLog(to: p)
        p.terminationHandler = { [weak self] proc in
            self?.queue.async {
                guard let self, self.generation == gen, self.wanted else { return }
                self.installProcess = nil
                if proc.terminationStatus == 0 {
                    self.runInstallStep(uv: uv, steps: Array(steps.dropFirst()), generation: gen)
                } else {
                    self.setState(.failed("安装依赖失败（uv \(args.first ?? "") 退出码 \(proc.terminationStatus)），详见 \(self.paths.log.path)"))
                }
            }
        }
        do {
            try p.run()
            installProcess = p
        } catch {
            setState(.failed("启动 uv 失败：\(error.localizedDescription)"))
        }
    }

    // MARK: - 服务

    /// 看门狗：用 sh 包一层起服务。App 崩了 / 被强退时（来不及调 stop）服务 1 秒内跟着退出，不白占几 GB 内存。
    /// $1 = App 的 pid，其余是服务命令；sh 收到 TERM 时先停服务再退。
    static let watchdogScript = """
    p=$1; shift
    "$@" & c=$!
    trap 'kill $c 2>/dev/null; wait $c; exit 143' TERM INT HUP
    while kill -0 "$p" 2>/dev/null && kill -0 "$c" 2>/dev/null; do sleep 1; done
    kill -0 "$c" 2>/dev/null && kill "$c"
    wait "$c"
    """

    static func serverArguments(port: Int, token: String) -> [String] {
        ["serve", "--host", "127.0.0.1", "--port", String(port), "--model", modelID, "--api-key", token,
         // 默认每分钟 60 次：录音中每 2 秒提交一段，长段话分段识别时会撞上限
         "--rate-limit", "1000"]
    }

    private func launchServer(generation gen: Int) {
        guard let port = Self.freeLocalPort() else { setState(.failed("找不到可用的本地端口")); return }
        setState(.starting)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", Self.watchdogScript, "sh", String(getpid()), paths.serverBinary.path]
            + Self.serverArguments(port: port, token: token)
        var env = ProcessInfo.processInfo.environment
        env["HF_HUB_DISABLE_TELEMETRY"] = "1"
        env["PYTHONUNBUFFERED"] = "1"
        p.environment = env
        attachLog(to: p)
        p.terminationHandler = { [weak self] proc in
            self?.queue.async {
                guard let self, self.generation == gen, self.wanted else { return }
                self.serverProcess = nil
                try? FileManager.default.removeItem(at: self.paths.pidFile)
                self.setState(.failed("本地模型服务退出了（退出码 \(proc.terminationStatus)），详见 \(self.paths.log.path)"))
            }
        }
        do {
            try p.run()
        } catch {
            setState(.failed("启动本地模型服务失败：\(error.localizedDescription)"))
            return
        }
        serverProcess = p
        try? String(p.processIdentifier).write(to: paths.pidFile, atomically: true, encoding: .utf8)
        log("server start pid=\(p.processIdentifier) port=\(port) model=\(Self.modelID)")
        pollHealth(port: port, generation: gen)
    }

    /// 每秒问一次 /health。首次要下载 4.7 GB，不设总时限——进程还活着就一直等。
    private func pollHealth(port: Int, generation gen: Int) {
        guard let url = URL(string: "http://127.0.0.1:\(port)/health") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            guard let self else { return }
            self.queue.async {
                guard self.generation == gen, self.wanted, self.serverProcess?.isRunning == true else { return }
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    self.log("server ready on port \(port)")
                    self.setState(.ready(port: port))
                } else {
                    self.queue.asyncAfter(deadline: .now() + 1) { self.pollHealth(port: port, generation: gen) }
                }
            }
        }.resume()
    }

    /// 上次 App 崩了没来得及停的服务：按 pid 文件找到、确认是 mlx-qwen3-asr 再杀，免得白占几 GB 内存
    private func killOrphanFromPIDFile() {
        guard let raw = try? String(contentsOf: paths.pidFile, encoding: .utf8),
              let pid = pid_t(raw.trimmingCharacters(in: .whitespacesAndNewlines)), pid > 0 else { return }
        defer { try? FileManager.default.removeItem(at: paths.pidFile) }
        guard kill(pid, 0) == 0, Self.commandLine(of: pid)?.contains("mlx-qwen3-asr") == true else { return }
        log("killing orphan server pid=\(pid)")
        kill(pid, SIGTERM)
    }

    private static func commandLine(of pid: pid_t) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/ps")
        p.arguments = ["-p", String(pid), "-o", "command="]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return nil }
        p.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }

    /// 让系统分一个 127.0.0.1 上的空闲端口
    static func freeLocalPort() -> Int? {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }
        defer { close(fd) }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bound == 0 else { return nil }
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &len) }
        }
        guard named == 0 else { return nil }
        return Int(UInt16(bigEndian: addr.sin_port))
    }

    private static func randomToken() -> String {
        (0..<24).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
    }

    // MARK: - 状态 / 日志

    private func setState(_ new: State) {
        guard _state != new else { return }
        _state = new
        log("state → \(new)")
        DispatchQueue.main.async { NotificationCenter.default.post(name: Self.stateDidChange, object: self) }
    }

    private func log(_ message: String) {
        debugLog?("[LocalASR] \(message)")
    }

    /// 子进程的输出追加进 LocalASR/server.log（不进 App 日志：下载进度条会刷屏）
    private func attachLog(to process: Process) {
        try? FileManager.default.createDirectory(at: paths.base, withIntermediateDirectories: true)
        // 下载进度条会把日志刷大：超过 5 MB 就从头记
        let size = (try? FileManager.default.attributesOfItem(atPath: paths.log.path)[.size] as? Int) ?? 0
        if size > 5_000_000 { try? FileManager.default.removeItem(at: paths.log) }
        if !FileManager.default.fileExists(atPath: paths.log.path) {
            FileManager.default.createFile(atPath: paths.log.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: paths.log) else { return }
        handle.seekToEndOfFile()
        process.standardOutput = handle
        process.standardError = handle
    }
}
#endif
