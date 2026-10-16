// Translations: see UITranslations.swift for the format.
extension UITranslationTable {
    static let app = #"""
# AnswerPanel.swift
固定面板	Pin Panel	固定面板
正在听…	Listening…	正在聽…
问 AI · 第 {} 轮	Ask AI · Round {}	問 AI · 第 {} 輪
问 AI	Ask AI	問 AI
已固定：下次说话时不会自动收起	Pinned: won't auto-hide the next time you speak	已固定：下次說話時不會自動收起
长按任意位置继续提问	Press and hold anywhere to ask a follow-up	長按任意位置繼續提問
识别中	Recognizing	辨識中
没听到问题	Didn't catch a question	沒聽到問題
已取消	Canceled	已取消
已复制	Copied	已複製
复制	Copy	複製
正在思考…	Thinking…	正在思考…
# HotkeyManager.swift
右 Command	Right Command	右 Command
⌘ Space 通常会被系统输入法或 Spotlight 占用，建议换一个组合。	⌘ Space is usually taken by the system input method or Spotlight. Try a different combination.	⌘ Space 通常會被系統輸入法或 Spotlight 佔用，建議換一個組合。
⌘ Tab 通常会被系统用于切换 App，建议换一个组合。	⌘ Tab is usually used by the system to switch apps. Try a different combination.	⌘ Tab 通常會被系統用來切換 App，建議換一個組合。
单独使用 ⌘ 加字母，可能和常用 App 菜单快捷键冲突。	⌘ plus a single letter may conflict with common app menu shortcuts.	單獨使用 ⌘ 加字母，可能和常用 App 選單快速鍵衝突。
# MicrophoneManager.swift
跟随系统默认（{}）	System Default ({})	跟隨系統預設（{}）
未知设备	Unknown Device	未知裝置
# OverlayWindow.swift
已锁定	Locked	已鎖定
已加入词库「{}」	Added “{}” to Vocabulary	已加入詞庫「{}」
学习「{}」？	Learn “{}”?	學習「{}」？
撤销取消	Undo Cancel	復原取消
取消本次录音	Cancel This Recording	取消本次錄音
完成并转写	Finish and Transcribe	完成並轉錄
# RhythmStripView.swift
{} · {} 字 · {} 次	{} · {} chars · {} sessions	{} · {} 字 · {} 次
{} · 没有使用	{} · Not used	{} · 沒有使用
{}月{}日	{1}/{2}	{1}月{2}日
本周	This Week	本週
{} 周前	{} wk ago	{} 週前
# StatusBarController.swift
开始/停止录音	Start/Stop Recording	開始／停止錄音
打开 Typefree	Open Typefree	打開 Typefree
个人词库…	Vocabulary…	個人詞庫…
复制最后一句	Copy Last Sentence	複製最後一句
{}（推荐）	{} (Recommended)	{}（推薦）
长按/单击	Hold/Tap	長按／單擊
快捷键：{} {} 录音	Shortcut: {} {} to record	快速鍵：{} {} 錄音
# WhatsNewGuideView.swift
跳过	Skip	略過
跳过引导（Esc）	Skip Guide (Esc)	略過引導（Esc）
# AudioRecorder.swift
音频会话激活失败: {}	Failed to activate audio session: {}	音訊工作階段啟用失敗：{}
没有检测到麦克风输入	No microphone input detected	沒有偵測到麥克風輸入
# AppDelegate.swift
Typefree 更新	Typefree Update	Typefree 更新
稍后	Later	稍後
正在安装并重启…	Installing and Restarting…	正在安裝並重新啟動…
有可用更新	Update Available	有可用的更新
关闭	Close	關閉
{} 已在后台下载好，重启即可完成更新。	{} has been downloaded in the background. Restart to finish updating.	{} 已在背景下載完成，重新啟動即可完成更新。
看看改了什么	See What's New	看看更新了什麼
重启更新	Restart to Update	重新啟動以更新
更新检查遇到问题	Update Check Problem	檢查更新時發生問題
发现新版本	New Version Available	發現新版本
错误信息	Error Details	錯誤資訊
更新内容	What's New	更新內容
已是最新版本	You're Up to Date	已是最新版本
当前没有可安装的新版本。	There's no new version to install right now.	目前沒有可安裝的新版本。
更新状态	Update Status	更新狀態
Typefree 会每天自动检查一次；有新版本时会先在后台下载好，再提醒你安装。	Typefree checks for updates once a day. When a new version is available, it downloads it in the background first, then reminds you to install.	Typefree 每天會自動檢查一次；有新版本時會先在背景下載好，再提醒你安裝。
好	OK	好
更新检查失败	Update Check Failed	檢查更新失敗
新版本	New Version	新版本
下载完成，正在安装并重启…	Download complete. Installing and restarting…	下載完成，正在安裝並重新啟動…
下载完成，正在准备安装…	Download complete. Preparing to install…	下載完成，正在準備安裝…
版本 {} 已准备好，可以安装并重启。	Version {} is ready to install and restart.	版本 {} 已準備好，可以安裝並重新啟動。
正在下载更新 {}%…	Downloading update {}%…	正在下載更新 {}%…
正在开始下载…	Starting download…	正在開始下載…
安装并重启	Install and Restart	安裝並重新啟動
Typefree 新版本	New Typefree Version	Typefree 新版本
正在下载更新 {}%，下载完成后会自动安装并重启。	Downloading update {}%. It will install and restart automatically when done.	正在下載更新 {}%，下載完成後會自動安裝並重新啟動。
正在下载更新，下载完成后会自动安装并重启。	Downloading update. It will install and restart automatically when done.	正在下載更新，下載完成後會自動安裝並重新啟動。
发现版本 {}。	Version {} is available.	發現版本 {}。
重新检查	Check Again	重新檢查
查看详情	View Details	查看詳情
放到后台	Run in Background	放到背景
立即更新	Update Now	立即更新
版本 {}	Version {}	版本 {}
版本 {}（{}）	Version {} ({})	版本 {}（{}）
本地开发版	Local Dev Build	本機開發版
当前版本 {}	Current version {}	目前版本 {}
这次更新包含体验改进和问题修复。	This update includes improvements and bug fixes.	這次更新包含體驗改進和問題修正。
完整更新内容：{}	Full release notes: {}	完整更新內容：{}
后半段没识别出来 · 整段录音在历史里，可点「···」→「重试」	The second half wasn't recognized · The full recording is in History; click “···” → “Retry”	後半段沒有辨識出來 · 整段錄音在歷史紀錄裡，可點「···」→「重試」
未知	Unknown	未知
已按口令「{}」输出{}	Output in {2} per voice command “{1}”	已依語音指令「{}」輸出{}
录音启动失败: {}	Couldn't start recording: {}	錄音啟動失敗：{}
网络太慢，这段没识别出来 · 录音已存进历史，可点「···」→「重试」	Network too slow; this part wasn't recognized · The recording is saved in History; click “···” → “Retry”	網路太慢，這段沒有辨識出來 · 錄音已存進歷史紀錄，可點「···」→「重試」
网络太慢，这段没识别出来，请再说一次	Network too slow; this part wasn't recognized. Please say it again	網路太慢，這段沒有辨識出來，請再說一次
回答失败：{}	Answer failed: {}	回答失敗：{}
识别失败	Recognition Failed	辨識失敗
历史记录的加密密钥已丢失	History Encryption Key Lost	歷史紀錄的加密金鑰已遺失
钥匙串里找不到之前用来加密历史记录的密钥（通常是钥匙串被重置或迁移过）。\n\n之前的历史记录无法再读取；从现在起的新记录会用新密钥正常保存。	The key previously used to encrypt your history can't be found in the Keychain (usually because the Keychain was reset or migrated).\n\nYour earlier history can no longer be read; new entries from now on will be saved normally with a new key.	鑰匙圈裡找不到之前用來加密歷史紀錄的金鑰（通常是鑰匙圈被重設或移轉過）。\n\n之前的歷史紀錄無法再讀取；從現在起的新紀錄會用新金鑰正常儲存。
知道了	Got It	知道了
\n(已复制到剪贴板；授予辅助功能权限后可自动粘贴)	\n(Copied to clipboard; grant Accessibility permission to paste automatically)	\n（已複製到剪貼簿；授予輔助使用權限後可自動貼上）
\n(窗口已切换，已复制到剪贴板)	\n(Window switched; copied to clipboard)	\n（視窗已切換，已複製到剪貼簿）
隐藏 Typefree	Hide Typefree	隱藏 Typefree
退出 Typefree	Quit Typefree	結束 Typefree
编辑	Edit	編輯
撤销	Undo	還原
重做	Redo	重做
剪切	Cut	剪下
拷贝	Copy	拷貝
粘贴	Paste	貼上
全选	Select All	全選
试用额度已用完（7 天共 {} 字）· 开通会员，或填自己的 Key 不限量	Trial quota used up ({} chars over 7 days) · Get Membership, or add your own key for unlimited use	試用額度已用完（7 天共 {} 字）· 開通會員，或填入自己的 Key 不限量
今日试用额度已用完（剩 {} 天）· 开通会员或填自己的 Key 不限量	Today's trial quota is used up ({} days left) · Get Membership or add your own key for unlimited use	今日試用額度已用完（剩 {} 天）· 開通會員或填入自己的 Key 不限量
试用已结束 · 开通会员，或在「设置 → 模型」填自己的 Key	Trial has ended · Get Membership, or add your own key in “Settings → Model”	試用已結束 · 開通會員，或在「設定 → 模型」填入自己的 Key
请先在「设置 → 模型」里填入 API Key	Please add an API Key in “Settings → Model” first	請先在「設定 → 模型」裡填入 API Key
正在准备免费试用，请稍候…	Preparing your free trial, please wait…	正在準備免費試用，請稍候…
会员已到期 · 续费，或在「设置 → 模型」填自己的 Key	Membership expired · Renew, or add your own key in “Settings → Model”	會員已到期 · 續訂，或在「設定 → 模型」填入自己的 Key
无法连接激活服务，请检查网络后再试	Can't reach the activation service. Check your network and try again	無法連線到啟用服務，請檢查網路後再試
正在验证会员状态，请稍候…	Verifying membership status, please wait…	正在驗證會員狀態，請稍候…
请先在「设置 → 模型」里填入 API key	Please add an API key in “Settings → Model” first	請先在「設定 → 模型」裡填入 API key
请授予辅助功能权限以启用快捷键	Grant Accessibility permission to enable shortcuts	請授予輔助使用權限以啟用快速鍵
辅助功能已开启，现在可以用快捷键录音了	Accessibility is on. You can now record with the shortcut	輔助使用已開啟，現在可以用快速鍵錄音了
移近锁定	Move closer to lock	移近以鎖定
还没有可复制的内容	Nothing to copy yet	還沒有可複製的內容
已复制最后一句 · 按 ⌘V 粘贴	Copied the last sentence · Press ⌘V to paste	已複製最後一句 · 按 ⌘V 貼上
没有可纠正的内容	Nothing to correct	沒有可修正的內容
纠正上次结果	Correct Last Result	修正上次結果
Typefree 输出了：\n{}\n\n请在下方修改为正确的文字：	Typefree typed:\n{}\n\nEdit it below to the correct text:	Typefree 輸出了：\n{}\n\n請在下方修改為正確的文字：
学习	Learn	學習
取消	Cancel	取消
没有需要加进词库的新词	No new words to add to Vocabulary	沒有需要加進詞庫的新詞
文字可能没粘上 · 已复制，按 ⌘V 粘贴	The text may not have pasted · Copied; press ⌘V to paste	文字可能沒有貼上 · 已複製，按 ⌘V 貼上
刚才的位置不能输入文字 · 已复制，按 ⌘V 粘贴	Can't type text at the previous position · Copied; press ⌘V to paste	剛才的位置無法輸入文字 · 已複製，按 ⌘V 貼上
窗口已切换 · 已复制，按 ⌘V 粘贴	Window switched · Copied; press ⌘V to paste	視窗已切換 · 已複製，按 ⌘V 貼上
 · 开通会员或填自己的 Key 不限量	 · Get Membership or add your own key for unlimited use	 · 開通會員或填入自己的 Key 不限量
已输出未润色文字（润色失败：{}）{}	Typed text without cleanup (cleanup failed: {}){}	已輸出未潤飾的文字（潤飾失敗：{}）{}
← 上一步	← Back	← 上一步
下一步 →	Next →	下一步 →
欢迎使用 Typefree	Welcome to Typefree	歡迎使用 Typefree
按住快捷键说话，松手就贴上整理好的文字。简单几步就能开始。	Hold the shortcut and speak; release to paste the cleaned-up text. Just a few steps to get started.	按住快速鍵說話，放開就貼上整理好的文字。簡單幾步就能開始。
开始设置	Start Setup	開始設定
开启辅助功能	Turn On Accessibility	開啟輔助使用
用于监听快捷键、把文字贴到光标处。	Used to listen for the shortcut and paste text at the cursor.	用於監聽快速鍵、把文字貼到游標處。
打开辅助功能设置	Open Accessibility Settings	打開輔助使用設定
✓ 已授权	✓ Authorized	✓ 已授權
等待授权…	Waiting for permission…	等待授權…
开启麦克风	Turn On Microphone	開啟麥克風
用来录下你的声音，再转成文字。	Used to record your voice and turn it into text.	用來錄下你的聲音，再轉成文字。
去系统设置开启	Enable in System Settings	到系統設定開啟
已拒绝 · 点上面到系统设置开启	Denied · Click above to enable in System Settings	已拒絕 · 點上方到系統設定開啟
还差一步	One More Step	還差一步
全部就绪	All Set	全部就緒
这个版本不含试用通道。先到「设置 → 模型」填入自己的 API Key，然后按住 {} 说话。	This version has no trial access. Add your own API Key in “Settings → Model” first, then hold {} and speak.	這個版本不含試用管道。請先到「設定 → 模型」填入自己的 API Key，然後按住 {} 說話。
按住 {} 说话，松手就贴上整理好的文字。	Hold {} and speak; release to paste the cleaned-up text.	按住 {} 說話，放開就貼上整理好的文字。
开始使用	Get Started	開始使用
# SupportChatView.swift
TYPEFREE / 反馈	TYPEFREE / FEEDBACK	TYPEFREE / 意見回饋
遇到问题或有建议，提交一个工单。开发者的回复会出现在对应工单里。	Have a problem or a suggestion? Submit a ticket. The developer's replies will appear in that ticket.	遇到問題或有建議，提交一個工單。開發者的回覆會出現在對應的工單裡。
提交工单	Submit Ticket	提交工單
全部 {}	All {}	全部 {}
处理中 {}	Open {}	處理中 {}
已结束 {}	Closed {}	已結束 {}
没有处理中的工单。	No open tickets.	沒有處理中的工單。
还没有已结束的工单。	No closed tickets yet.	還沒有已結束的工單。
正在读取工单…	Loading tickets…	正在讀取工單…
还没有工单。遇到问题或有建议，点右上角「提交工单」。	No tickets yet. Have a problem or a suggestion? Click “Submit Ticket” in the top-right corner.	還沒有工單。遇到問題或有建議，點右上角的「提交工單」。
{} 条消息	{} messages	{} 則訊息
处理中	Open	處理中
已结束	Closed	已結束
工单 #{} {}，{}	Ticket #{} {}, {}	工單 #{} {}，{}
说清楚在哪个软件里、怎么操作时出的问题，处理起来最快。	Describe which app you were in and what you were doing when the problem occurred — that's the fastest way to get it fixed.	說清楚在哪個軟體裡、怎麼操作時出的問題，處理起來最快。
比如：在微信里按住鼠标说话，胶囊出来了但松手后没有出字…	E.g., In WeChat, I held the mouse and spoke; the capsule appeared, but no text came out after I released…	例如：在微信裡按住滑鼠說話，膠囊出來了，但放開後沒有出字…
提交	Submit	提交
类型	Type	類型
描述	Description	描述
附件（可选）	Attachments (Optional)	附件（選填）
先描述一下遇到的问题	Describe the problem first	請先描述一下遇到的問題
提交中…	Submitting…	提交中…
工单已提交，附件没发成功：{}，可以在这里重新附上	Ticket submitted, but the attachment failed to send: {}. You can attach it again here	工單已提交，但附件沒有傳送成功：{}，可以在這裡重新附上
工单	Ticket	工單
{} 提交	Submitted {}	{} 提交
{} 结束	Closed {}	{} 結束
开发者已结束这个工单{}	The developer closed this ticket{}	開發者已結束這個工單{}
补充说明，或回复开发者…	Add details, or reply to the developer…	補充說明，或回覆開發者…
发送	Send	傳送
这个工单已结束，不能再回复。还有问题可以提交新工单。	This ticket is closed and can't be replied to. If you still have an issue, submit a new ticket.	這個工單已結束，無法再回覆。還有問題可以提交新工單。
提交新工单	Submit New Ticket	提交新工單
写点内容或附上截图再发	Write something or attach a screenshot before sending	寫點內容或附上截圖再傳送
发送中…	Sending…	傳送中…
已发送	Sent	已傳送
🖼 截图	🖼 Screenshot	🖼 截圖
🎙 附带了最后一次录音	🎙 Last recording attached	🎙 附帶了最後一次錄音
 · 开发者	 · Developer	 · 開發者
添加截图	Add Screenshot	加入截圖
附上最后的转录	Attach Last Transcript	附上最後的轉錄
把最近一次识别的文字和录音一起发给开发者，方便查识别问题	Send your most recent recognized text and recording to the developer to help diagnose recognition issues	把最近一次辨識的文字和錄音一起傳給開發者，方便查辨識問題
也可以把截图拖进来或直接粘贴。	You can also drag a screenshot here or paste it directly.	也可以把截圖拖進來或直接貼上。
截图 · {}×{}	Screenshot · {}×{}	截圖 · {}×{}
最后的转录：{}	Last transcript: {}	最後的轉錄：{}
选一张截图（PNG / JPG）	Choose a Screenshot (PNG / JPG)	選擇一張截圖（PNG / JPG）
这张图读不出来	Can't read this image	這張圖片無法讀取
‹ 全部工单	‹ All Tickets	‹ 全部工單
今天 	Today 	今天 
M月d日	MMM d	M月d日
点击查看大图	Click to view full size	點擊查看大圖
"""#
}
