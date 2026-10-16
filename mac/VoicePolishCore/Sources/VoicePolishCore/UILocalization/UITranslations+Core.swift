// Translations: see UITranslations.swift for the format.
extension UITranslationTable {
    static let core = #"""
# AIPolisher.swift
保存全部数据	Keep All Data	儲存全部資料
保存一个月	Keep for 1 Month	儲存一個月
保存一周	Keep for 1 Week	儲存一週
保存 24 小时	Keep for 24 Hours	儲存 24 小時
不保存数据	Don't Keep Data	不儲存資料
不自动删除历史记录	History is never deleted automatically	不自動刪除歷史紀錄
自动删除 30 天前的记录	Automatically deletes records older than 30 days	自動刪除 30 天前的紀錄
自动删除 7 天前的记录	Automatically deletes records older than 7 days	自動刪除 7 天前的紀錄
自动删除 24 小时前的记录	Automatically deletes records older than 24 hours	自動刪除 24 小時前的紀錄
录音结束后不保留任何本地历史	No local history is kept after recording ends	錄音結束後不保留任何本機歷史
润色模型均不可用（额度用完）	All cleanup models are unavailable (quota used up)	潤飾模型皆無法使用（額度用完）
试用已结束 · 开通会员，或填自己的 Key	Trial ended · Get Membership, or enter your own key	試用已結束 · 開通會員，或填入自己的 Key
会员润色失败（{}）	Member cleanup failed ({})	會員潤飾失敗（{}）
试用润色失败（{}）	Trial cleanup failed ({})	試用潤飾失敗（{}）
今天	today	今天
现在	now	現在
目前	currently	目前
最近	recently	最近
最新	latest	最新
新闻	news	新聞
价格	price	價格
股价	stock price	股價
汇率	exchange rate	匯率
天气	weather	天氣
几号	what date	幾號
星期	day of the week	星期
多少钱	how much	多少錢
发布	release	發布
更新	update	更新
今年	this year	今年
这周	this week	這週
昨天	yesterday	昨天
明天	tomorrow	明天
上市	launch	上市
问答请求失败（{}）	Ask AI request failed ({})	問答請求失敗（{}）
问答模型均不可用（额度用完）	All Ask AI models are unavailable (quota used up)	問答模型皆無法使用（額度用完）
键盘	Keyboard	鍵盤
未配置润色模型的 API key	No API key configured for the cleanup model	未設定潤飾模型的 API key
润色服务未返回数据	Cleanup service returned no data	潤飾服務未回傳資料
润色返回无法解析	Couldn't parse the cleanup response	無法解析潤飾回傳內容
模型未开通或无权限：{}	Model not enabled or access denied: {}	模型未開通或無權限：{}
欠费	overdue	欠費
余额	balance	餘額
API Key 无效，请检查是否复制完整{}	Invalid API Key. Make sure you copied all of it{}	API Key 無效，請檢查是否完整複製{}
账号欠费或免费额度已用完，请到服务商控制台检查{}	Account payment overdue or free quota used up. Check your provider's console{}	帳號欠費或免費額度已用完，請到服務商控制台檢查{}
请求太频繁或额度超限，稍后再试{}	Too many requests or quota exceeded. Try again later{}	請求太頻繁或額度超限，請稍後再試{}
# ActivityRhythm.swift
周日	Sun	週日
周一	Mon	週一
周二	Tue	週二
周三	Wed	週三
周四	Thu	週四
周五	Fri	週五
周六	Sat	週六
# ChineseScript.swift
跟随识别结果	Match Recognized Text	跟隨辨識結果
简体中文	Simplified Chinese	簡體中文
繁體中文	Traditional Chinese	繁體中文
# CloudASRTranscriber+LLM.swift
{} 识别失败（HTTP {}）	{} recognition failed (HTTP {})	{} 辨識失敗（HTTP {}）
# CloudASRTranscriber.swift
火山引擎	Volcengine	火山引擎
百炼	Bailian	百鍊
本地 Qwen3-ASR	Local Qwen3-ASR	本機 Qwen3-ASR
未配置云端语音识别凭证	Cloud speech recognition credentials not configured	未設定雲端語音辨識憑證
音频编码失败	Audio encoding failed	音訊編碼失敗
云端识别未返回数据	Cloud recognition returned no data	雲端辨識未回傳資料
云端识别返回无法解析	Couldn't parse the cloud recognition response	無法解析雲端辨識回傳內容
网络错误：{}	Network error: {}	網路錯誤：{}
识别超时	Recognition timed out	辨識逾時
读不到钥匙串里的 Key · 重启 Handfree 再试，系统询问时点「允许」	Can't read the key from Keychain · Restart Handfree and try again; click “Allow” when macOS asks	讀不到鑰匙圈裡的 Key · 重新啟動 Handfree 再試，系統詢問時點「允許」
语音识别选的「{}」还没填 Key · 在「设置 → 模型」填上，或改选已填 Key 的「{}」	Speech recognition is set to “{}”, which has no key yet · Add one in “Settings → Model”, or switch to “{}”, which has a key	語音辨識選的「{}」還沒填 Key · 在「設定 → 模型」填上，或改選已填 Key 的「{}」
本地模型还没启用 · 在「设置 → 模型」打开「启用本地模型」	Local model isn't enabled yet · Turn on “Enable Local Model” in “Settings → Model”	本機模型尚未啟用 · 在「設定 → 模型」開啟「啟用本機模型」
请配置火山引擎的 bigasr_api_key，或阿里百炼的 dashscope_api_key	Configure Volcengine's bigasr_api_key or Alibaba Bailian's dashscope_api_key	請設定火山引擎的 bigasr_api_key，或阿里百鍊的 dashscope_api_key
百炼识别最长支持 5 分钟，这段约 {} 分钟太长了。请在「模型」里改用火山 2.0，或把录音分短一些。	Bailian recognition supports up to 5 minutes; this recording is about {} minutes, which is too long. Switch to Volcengine 2.0 in “Model”, or record shorter clips.	百鍊辨識最長支援 5 分鐘，這段約 {} 分鐘太長了。請在「模型」裡改用火山引擎 2.0，或把錄音分短一些。
会员识别失败（{}）	Member recognition failed ({})	會員辨識失敗（{}）
试用识别失败（{}）	Trial recognition failed ({})	試用辨識失敗（{}）
识别完成但未返回文本	Recognition finished but returned no text	辨識完成但未回傳文字
百炼识别失败	Bailian recognition failed	百鍊辨識失敗
云端识别失败	Cloud recognition failed	雲端辨識失敗
{}（服务器繁忙）	{} (server busy)	{}（伺服器忙碌）
火山账号未开通此识别版本，请到控制台开通并领免费额度（45000030）	Your Volcengine account hasn't enabled this recognition version. Enable it and claim the free quota in the console (45000030)	火山引擎帳號未開通此辨識版本，請到控制台開通並領取免費額度（45000030）
火山 API Key 无效，请检查是否复制完整（45000010）	Invalid Volcengine API Key. Make sure you copied all of it (45000010)	火山引擎 API Key 無效，請檢查是否完整複製（45000010）
{}（状态码 {}）	{} (status code {})	{}（狀態碼 {}）
# CueSound.swift
四度双音	Two-Note Fourth	四度雙音
五度双音	Two-Note Fifth	五度雙音
三度双音	Two-Note Third	三度雙音
单音	Single Note	單音
# FeedbackService.swift
地址错误	Invalid URL	網址錯誤
提交失败（{}）	Submission failed ({})	提交失敗（{}）
# InputStats.swift
{}年{}月	{2}/{1}	{1}年{2}月
# LicenseManager.swift
激活校验失败	Activation verification failed	啟用驗證失敗
返回解析失败	Couldn't parse the response	回傳內容解析失敗
激活失败，请稍后重试	Activation failed. Try again later	啟用失敗，請稍後重試
# LocalASRServer.swift
本地模型正在安装（首次约几分钟），好了再说一次	Local model is installing (a few minutes the first time). Speak again when it's ready	本機模型正在安裝（首次約需幾分鐘），好了再說一次
本地模型正在启动（首次需下载约 {} GB），好了再说一次	Local model is starting (first run downloads about {} GB). Speak again when it's ready	本機模型正在啟動（首次需下載約 {} GB），好了再說一次
本地模型启动失败：{}	Local model failed to start: {}	本機模型啟動失敗：{}
本地模型还没启动，正在启动，稍后再试	Local model isn't running yet and is starting now. Try again shortly	本機模型尚未啟動，正在啟動，請稍後再試
本地模型未启用 · 在「设置 → 模型」打开「启用本地模型」	Local model isn't enabled · Turn on “Enable Local Model” in “Settings → Model”	本機模型未啟用 · 在「設定 → 模型」開啟「啟用本機模型」
需要 Apple 芯片（M 系列）的 Mac	Requires a Mac with Apple silicon (M-series)	需要搭載 Apple 晶片（M 系列）的 Mac
缺少 uv（App 应自带；也可以 brew install uv）	uv is missing (it should be bundled with the app; you can also run brew install uv)	缺少 uv（App 應內建；也可以 brew install uv）
建不了 {}：{}	Couldn't create {}: {}	無法建立 {}：{}
安装依赖失败（uv {} 退出码 {}），详见 {}	Failed to install dependencies (uv {} exited with code {}). See {}	安裝相依套件失敗（uv {} 結束代碼 {}），詳見 {}
启动 uv 失败：{}	Failed to launch uv: {}	啟動 uv 失敗：{}
找不到可用的本地端口	No available local port found	找不到可用的本機連接埠
本地模型服务退出了（退出码 {}），详见 {}	Local model service exited (exit code {}). See {}	本機模型服務已結束（結束代碼 {}），詳見 {}
启动本地模型服务失败：{}	Failed to start local model service: {}	啟動本機模型服務失敗：{}
# OutputLanguage.swift
英文	English	英文
日文	Japanese	日文
韩文	Korean	韓文
中文	Chinese	中文
法语	French	法語
德语	German	德語
西班牙语	Spanish	西班牙語
# ProcessingMode.swift
全云端：云端识别直出	Cloud Only: Direct Cloud Recognition	全雲端：雲端辨識直出
全模态：Qwen Omni 一步直出	Omni: Qwen Omni in One Step	全模態：Qwen Omni 一步直出
云端识别中...	Recognizing in the cloud...	雲端辨識中...
全模态处理中...	Processing with Omni...	全模態處理中...
结果整理中...	Tidying up the result...	結果整理中...
整理中...	Tidying up...	整理中...
# SimpleAudioRecorder.swift
麦克风权限被拒绝	Microphone access denied	麥克風權限遭拒
音频会话: {}	Audio session: {}	音訊工作階段: {}
AudioQueue创建失败: {}	Failed to create AudioQueue: {}	AudioQueue 建立失敗: {}
Buffer分配失败: {}	Failed to allocate buffer: {}	Buffer 配置失敗: {}
Buffer入队失败: {}	Failed to enqueue buffer: {}	Buffer 排入佇列失敗: {}
AudioQueue启动失败: {}	Failed to start AudioQueue: {}	AudioQueue 啟動失敗: {}
# SupportChat.swift
使用问题	Usage Issue	使用問題
功能建议	Feature Request	功能建議
附件太大了	Attachment is too large	附件太大了
这台设备已被停用反馈	Feedback has been disabled for this device	這台裝置已被停用意見回饋
这个工单已结束，有新问题请提交新工单	This ticket is closed. For a new issue, please submit a new ticket	這個工單已結束，有新問題請提交新工單
发送失败：{}	Failed to send: {}	傳送失敗：{}
服务器返回格式不对	Server returned an unexpected format	伺服器回傳格式不正確
网络不通	No network connection	網路不通
服务器返回 {}	Server returned {}	伺服器回傳 {}
# VoicePolishConfig.swift
之前已改用备用位置	Previously switched to the fallback location	先前已改用備用位置
{} 不是文件夹	{} is not a folder	{} 不是資料夾
写不进 {}：{}	Can't write to {}: {}	無法寫入 {}：{}
# VoicePolishPipeline.swift
全模态识别失败	Omni recognition failed	全模態辨識失敗
{} · 录音已存进历史，可点「···」→「重试」	{} · Recording saved to History; click “···” → “Retry”	{} · 錄音已存入歷史紀錄，可點「···」→「重試」
润色未配置，已输出原文 · 在「设置 → 模型」填润色 Key，或开通会员	Cleanup isn't set up, so the original text was output · Enter a cleanup key in “Settings → Model”, or Get Membership	潤飾未設定，已輸出原文 · 在「設定 → 模型」填入潤飾 Key，或開通會員
（这段录音识别失败，点右侧「···」→「重试」可重新识别）	(Recognition failed for this recording. Click “···” → “Retry” on the right to recognize it again)	（這段錄音辨識失敗，點右側「···」→「重試」可重新辨識）
"""#
}
