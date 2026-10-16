// Translations: see UITranslations.swift for the format.
// The 3.0 "What's New" guide page (mac/Resources/WhatsNewGuide.html), translated as text before loading:
// keys are its script string literals, text nodes and attribute values (see UILocalizer+HTML.swift).
// The voice-translation demo keeps its spoken Chinese (the commands are Chinese speech).
// `html:` keys override a shared key for this page only.
extension UITranslationTable {
    static let guide = #"""
Handfree 新功能	What's New in Handfree	Handfree 新功能
新功能	What's New	新功能
html:开始说话	Start speaking	開始說話
项目群	Project Team	專案群組
明天的会几点开？	What time is tomorrow's meeting?	明天的會幾點開？
发消息…	Message…	傳訊息…
用 RAG 搭建企业知识库的五个步骤	Five Steps to Build a Company Knowledge Base with RAG	用 RAG 建立企業知識庫的五個步驟
RAG 是现在最常用的知识库做法：把文档切成小段存起来，提问时先找出最相关的几段，再交给大模型组织回答。	RAG is the most common way to build a knowledge base today: split documents into small chunks and store them; when a question comes in, find the most relevant chunks and have a large language model compose the answer.	RAG 是現在最常用的知識庫做法：把文件切成小段存起來，提問時先找出最相關的幾段，再交給大型模型組織回答。
试一试	Try It	試試看
· 在下面的框里按住鼠标，说一句话	· Hold the mouse in the box below and say something	· 在下面的框裡按住滑鼠，說一句話
这些功能已默认开启，想关闭或调整，去「设置 → 探索」。	These features are on by default. To turn them off or adjust them, go to “Settings → Explore”.	這些功能已預設開啟，想關閉或調整，請到「設定 → 探索」。
上一个	Previous	上一個
下一个	Next	下一個
手势动画演示	Gesture animation demo	手勢動畫示範
演示动作	Demo actions	示範動作
在这里按住鼠标，说一句话	Hold the mouse here and say something	在這裡按住滑鼠，說一句話
第 1 页	Page 1	第 1 頁
第 2 页	Page 2	第 2 頁
第 3 页	Page 3	第 3 頁
按住说话	Hold to Talk	按住說話
在输入框上<b>按住鼠标左键</b>说话，<b>松开</b>就输入。	<b>Hold the left mouse button</b> on a text field and speak; <b>release</b> to type it in.	在輸入框上<b>按住滑鼠左鍵</b>說話，<b>放開</b>就輸入。
在输入框上按住鼠标，约半秒	Hold the mouse on a text field for about half a second	在輸入框上按住滑鼠，約半秒
松开	Release	放開
整理好的文字自动输入	The cleaned-up text is typed in for you	整理好的文字自動輸入
明天下午三点开会，记得带上电脑。	Meeting at 3 p.m. tomorrow, remember to bring your laptop.	明天下午三點開會，記得帶上電腦。
向下拖：锁定	Drag Down: Lock	向下拖：鎖定
说到一半想松手：<b>向下拖一点</b>，亮绿光后松手接着说，说完点 ✓。	Want to let go mid-sentence? <b>Drag down a little</b>; when it glows green, release and keep talking, then click ✓ when you're done.	說到一半想放手：<b>向下拖一點</b>，亮綠光後放手繼續說，說完點 ✓。
按住，开始说话	Hold and start talking	按住，開始說話
说到一半想松手：向下拖一点	Want to let go mid-sentence? Drag down a little	說到一半想放手：向下拖一點
亮绿光 = 已锁定，松手接着说	Green glow = locked; release and keep talking	亮綠光 = 已鎖定，放手繼續說
说完，点 ✓	When you're done, click ✓	說完，點 ✓
会议纪要我整理好了，下午发到群里。	I've finished the meeting notes and will post them to the group this afternoon.	會議紀錄我整理好了，下午發到群組裡。
拖远：取消	Drag Away: Cancel	拖遠：取消
不想要这句：<b>往外拖远</b>，亮红光后松开。点错了 9 秒内可撤销。	Don't want it? <b>Drag far away</b> and release when it glows red. Changed your mind? Undo within 9 seconds.	不想要這句：<b>往外拖遠</b>，亮紅光後放開。點錯了 9 秒內可以復原。
不想要了：往外拖远	Don't want it? Drag far away	不想要了：往外拖遠
亮红光了，松开	It's glowing red: release	亮紅光了，放開
已取消，点错了 9 秒内可撤销	Canceled. Changed your mind? Undo within 9 seconds	已取消，點錯了 9 秒內可以復原
RAG 就是「检索增强生成」：先从资料里找出和问题相关的内容，再交给大模型组织成回答。回答有依据，资料更新了也不用重新训练模型。	RAG means “retrieval-augmented generation”: first find the material relevant to the question, then have a large language model turn it into an answer. Answers are grounded in sources, and updating the material doesn't require retraining the model.	RAG 就是「檢索增強生成」：先從資料裡找出和問題相關的內容，再交給大型模型組織成回答。回答有依據，資料更新了也不用重新訓練模型。
微调是把知识训练进模型本身，成本高、更新慢；RAG 不改模型，换掉资料就能更新，更适合经常变化的内容。	Fine-tuning trains knowledge into the model itself, which is costly and slow to update; RAG leaves the model alone and updates by swapping the material, so it suits content that changes often.	微調是把知識訓練進模型本身，成本高、更新慢；RAG 不改模型，換掉資料就能更新，更適合經常變化的內容。
按住提问	Hold to Ask	按住提問
看到不懂的，在<b>空白处按住鼠标</b>说出问题，回答出现在<b>右上角</b>。不用切窗口，也不用先复制什么。	See something you don't understand? <b>Hold the mouse on empty space</b> and ask; the answer appears in the <b>top-right corner</b>. No switching windows, no copying first.	看到不懂的，在<b>空白處按住滑鼠</b>說出問題，回答出現在<b>右上角</b>。不用切換視窗，也不用先複製什麼。
找一块空白处，按住鼠标约半秒	Find an empty spot and hold the mouse for about half a second	找一塊空白處，按住滑鼠約半秒
亮蓝光，说出问题	It glows blue: ask your question	亮藍光，說出問題
回答出现在屏幕右上角	The answer appears in the top-right corner of the screen	回答出現在螢幕右上角
RAG 是什么意思？	What does RAG mean?	RAG 是什麼意思？
按住面板：追问	Hold the Panel: Follow Up	按住面板：追問
<b>按住回答面板</b>继续说，AI 接着这个话题回答。点图钉可以把回答固定住。	<b>Hold the answer panel</b> and keep talking; AI continues on the same topic. Click the pin to keep the answer on screen.	<b>按住回答面板</b>繼續說，AI 接著這個話題回答。點圖釘可以把回答固定住。
想接着问：按住回答面板	Want to follow up? Hold the answer panel	想接著問：按住回答面板
说出下一个问题	Ask the next question	說出下一個問題
接在同一个话题下回答	The answer continues the same topic	接在同一個話題下回答
它和微调有什么区别？	How is it different from fine-tuning?	它和微調有什麼區別？
点外面：收起	Click Outside: Collapse	點外面：收起
看完了，<b>点面板外面</b>任意地方，它会缩成一行，几秒后自动消失。想留住它，点右上角的<b>图钉</b>。	Done reading? <b>Click anywhere outside the panel</b>; it shrinks to one line and disappears after a few seconds. To keep it, click the <b>pin</b> in the top-right corner.	看完了，<b>點面板外面</b>任意地方，它會縮成一行，幾秒後自動消失。想留住它，點右上角的<b>圖釘</b>。
看完了：点面板外面任意地方	Done reading? Click anywhere outside the panel	看完了：點面板外面任意地方
缩成一行，几秒后自动消失	It shrinks to one line and disappears after a few seconds	縮成一行，幾秒後自動消失
想留住它：点右上角的图钉	To keep it, click the pin in the top-right corner	想留住它：點右上角的圖釘
用英文	用英文	用英文
说完正文，结尾加一句<b>「用英文」</b>，这句就直接输入成英文。放在开头也行；用快捷键说话也一样。	After what you want to say, add <b>“用英文”</b> (“in English”) at the end, and that sentence is typed in English. It works at the start too, and with the keyboard shortcut as well.	說完正文，結尾加一句<b>「用英文」</b>，這句就直接輸入成英文。放在開頭也行；用快速鍵說話也一樣。
明天下午三点开会，记得带上电脑，	明天下午三点开会，记得带上电脑，	明天下午三點開會，記得帶上電腦，
按住鼠标，说完正文，结尾加一句「用英文」	Hold the mouse, say your text, then add “用英文” at the end	按住滑鼠，說完正文，結尾加一句「用英文」
已按口令「用英文」输出英文	Output in English per voice command “用英文”	已依指令「用英文」輸出英文
用韩文	用韩文	用韓文
还支持韩文、中文；法语、德语、西班牙语可以在设置里打开。也可以固定一种输出语言，不用每次说口令。	Korean and Chinese work too; French, German and Spanish can be turned on in Settings. You can also set one fixed output language instead of saying a command each time.	還支援韓文、中文；法語、德語、西班牙語可以在設定裡開啟。也可以固定一種輸出語言，不用每次說指令。
谢谢你今天帮忙，	谢谢你今天帮忙，	謝謝你今天幫忙，
说完正文，结尾加一句「用韩文」	Say your text, then add “用韩文” at the end	說完正文，結尾加一句「用韓文」
已按口令「用韩文」输出韩文	Output in Korean per voice command “用韩文”	已依指令「用韓文」輸出韓文
这句直接输入成对应的语言	The sentence is typed in that language	這句直接輸入成對應的語言
在输入框上<b>按住鼠标左键</b>说话，<b>松开</b>就输入。想松手：<b>向下拖</b>锁定；不想要：<b>拖远</b>再松开。	<b>Hold the left mouse button</b> on a text field and speak; <b>release</b> to type it in. To let go: <b>drag down</b> to lock. Don't want it: <b>drag away</b>, then release.	在輸入框上<b>按住滑鼠左鍵</b>說話，<b>放開</b>就輸入。想放手：<b>向下拖</b>鎖定；不想要：<b>拖遠</b>再放開。
在<b>空白处按住鼠标</b>，说出问题，回答出现在<b>右上角</b>。<b>按住回答面板</b>可以接着问。	<b>Hold the mouse on empty space</b> and ask a question; the answer appears in the <b>top-right corner</b>. <b>Hold the answer panel</b> to follow up.	在<b>空白處按住滑鼠</b>，說出問題，回答出現在<b>右上角</b>。<b>按住回答面板</b>可以接著問。
说完正文，<b>结尾</b>加一句口令，比如「用英文」，这句话就直接输入成那种语言。放开头也行。	After what you want to say, add a command <b>at the end</b>, like “用英文” (“in English”), and that sentence is typed in that language. It works at the start too.	說完正文，<b>結尾</b>加一句指令，比如「用英文」，這句話就直接輸入成那種語言。放開頭也行。
"""#
}
