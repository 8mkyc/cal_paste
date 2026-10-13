#Requires AutoHotkey v2.0
#SingleInstance Force
; ══════════════════════════════════════════════
;  cal_paste (财务快贴) · 按键可配置版
;  ──────────────────────────────────────
;  【维护速览 · 给技术用户 / AI agent】
;  · 完整契约/验收清单/已知坑: 见同目录 AGENTS.md,改前必读
;  · 改按键: 不用改本文件,改 config.ini 的 [hotkeys] 段,
;    托盘右键 → 重新加载配置 即生效
;  · 加新功能: 四步 —— ① gDefs 加一行(键名+默认键)
;    ② gNames 加一行(中文名,用于气泡和报错提示)
;    ③ DoAction 加一个 case ④ 照抄 ToWan 写功能函数,
;    并在 WriteDefaultConfig 模板里加同名行
;  · 剪贴板契约(所有功能必须遵守): 开头
;    saved := ClipboardAll() 存原状,每条退出路径(含出错)
;    都要 A_Clipboard := saved 还原 —— 用户剪贴板永不丢失
;  · 复制等待: 统一 ClipWait(0.6) —— 慢软件(SAP/老网页)
;    0.3s 常复制不完,会误判"没选中"而贴错数
;  · GrabNum: 提取文本里第一个数字,自动忽略半角/全角
;    千分位逗号和货币符号; FmtNum: 整数不带小数点,小数抹尾零
;
;  默认按键(全部可在 config.ini 改):
;   CapsLock+A  加法粘贴(没选中=直接粘贴变量)
;   CapsLock+C  设变量
;   CapsLock+S  变量正负切换
;   CapsLock+M  乘法粘贴 / CapsLock+D  除法粘贴
;   CapsLock+W  元→万元 / CapsLock+Y  万元→元
;   CapsLock+K  ÷1000粘贴
;   CapsLock+X  累加(只记不贴) / CapsLock+Z  贴合计并清零
;
;  变量和累加器保存在 config.ini,重启不丢
;  详细用法见同目录 使用说明.txt
; ══════════════════════════════════════════════

global iniFile := A_ScriptDir "\config.ini"
if !FileExist(iniFile)
    WriteDefaultConfig()

global delta := IniRead(iniFile, "main", "delta", 3000) + 0
global accum := IniRead(iniFile, "main", "accum", 0) + 0

; ── 读取按键配置 ──
global prefName := Trim(IniRead(iniFile, "hotkeys", "prefix", "CapsLock"))
global prefix := PrefixToAHK(prefName, &prefixOK)

global gDefs := Map(
    "add",       IniRead(iniFile, "hotkeys", "add", "A"),
    "set_var",   IniRead(iniFile, "hotkeys", "set_var", "C"),
    "sign_flip", IniRead(iniFile, "hotkeys", "sign_flip", "S"),
    "multiply",  IniRead(iniFile, "hotkeys", "multiply", "M"),
    "divide",    IniRead(iniFile, "hotkeys", "divide", "D"),
    "to_wan",    IniRead(iniFile, "hotkeys", "to_wan", "W"),
    "to_yuan",   IniRead(iniFile, "hotkeys", "to_yuan", "Y"),
    "to_kilo",   IniRead(iniFile, "hotkeys", "to_kilo", "K"),
    "accum_add",   IniRead(iniFile, "hotkeys", "accum_add", "X"),
    "accum_paste", IniRead(iniFile, "hotkeys", "accum_paste", "Z"),
)
global gNames := Map(
    "add", "加法粘贴", "set_var", "设变量", "sign_flip", "正负切换",
    "multiply", "乘法粘贴", "divide", "除法粘贴",
    "to_wan", "元→万元", "to_yuan", "万元→元", "to_kilo", "÷1000粘贴",
    "accum_add", "累加", "accum_paste", "贴合计清零"
)

; ── 注册热键 ──
global gUsed := Map()
nLoaded := 0
for name, key in gDefs {
    hk := BuildHotkey(prefix, key, &badKey)
    if (hk = "") {
        if (badKey)
            MsgBox("【" gNames[name] "】的按键写法不对: [" key "]`n`n可用值: a~z、0~9、F1~F12,或留空关闭该功能", "cal_paste 配置提示", "48")
        continue
    }
    if gUsed.Has(hk) {
        MsgBox("按键冲突:【" gNames[gUsed[hk]] "】和【" gNames[name] "】都用了 [" hk "]`n`n【" gNames[name] "】不会生效,请打开 config.ini 修改", "cal_paste 配置提示", "48")
        continue
    }
    try Hotkey(hk, MakeHandler(name))
    catch Error as e {
        MsgBox("热键 " hk " 注册失败:`n" e.Message, "cal_paste", "16")
        continue
    }
    gUsed[hk] := name
    nLoaded++
}

; CapsLock 做前缀时,保留单按 CapsLock = 原大小写切换
; 不能用 Send("{CapsLock}") 重放——物理+模拟两次事件会被外部软件误判为双击;
; SetCapsLockState 直接改状态,不产生按键事件
if InStr(prefix, "CapsLock")
    Hotkey("CapsLock", (*) => SetCapsLockState(GetKeyState("CapsLock", "T") ? "Off" : "On"))

; ── 托盘菜单 ──
A_TrayMenu.Delete()
A_TrayMenu.Add("打开按键配置 (config.ini)", (*) => Run('notepad.exe "' iniFile '"'))
A_TrayMenu.Add("重新加载配置", (*) => Reload())
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())
A_TrayMenu.Default := "打开按键配置 (config.ini)"

if (nLoaded > 0) {
    if !prefixOK
        Notify("⚠️ prefix 写法不认识,已按 CapsLock 处理")
    Notify("✅ cal_paste 已启动: " nLoaded " 个热键,前缀 " prefName)
} else
    MsgBox("一个热键都没注册,请检查 config.ini 的 [hotkeys] 段", "cal_paste", "48")

; ══════════════ 配置处理 ══════════════

; 前缀名 → AHK 热键前缀
PrefixToAHK(p, &ok) {
    ok := true
    t := StrReplace(StrUpper(p), " ", "")
    t := StrReplace(t, "+", "")
    switch t {
        case "CAPSLOCK", "CAPS":    return "CapsLock & "
        case "CTRLALT":             return "^!"
        case "CTRLSHIFT":           return "^+"
        case "ALTSHIFT":            return "!+"
        case "CTRLALTSHIFT":        return "^!+"
    }
    ok := false
    return "CapsLock & "
}

; 功能键值 → 完整热键串;空=关闭,非法=badKey
BuildHotkey(prefix, key, &badKey) {
    badKey := false
    key := Trim(key)
    if (key = "")
        return ""
    if RegExMatch(key, "i)^F(?:1[0-2]|[1-9])$")
        return StrUpper(key)
    if RegExMatch(key, "i)^[a-z0-9]$")
        return prefix StrUpper(key)
    badKey := true
    return ""
}

MakeHandler(name) {
    return (*) => DoAction(name)
}

DoAction(name) {
    switch name {
        case "add":       AddPaste()
        case "set_var":   SetVar()
        case "sign_flip": SignFlip()
        case "multiply":  MultiplyPaste()
        case "divide":    DividePaste()
        case "to_wan":    ToWan()
        case "to_yuan":   ToYuan()
        case "to_kilo":   ToKilo()
        case "accum_add": AccumAdd()
        case "accum_paste": AccumPaste()
    }
}

; 首次运行生成带注释的配置模板
WriteDefaultConfig() {
    txt := "[main]`r`n"
    txt .= "delta=3000`r`n"
    txt .= "`r`n"
    txt .= "[hotkeys]`r`n"
    txt .= "; ═══════ 按键配置 ═══════`r`n"
    txt .= "; 改等号右边的字母/数字,保存后托盘右键→重新加载配置 即可生效`r`n"
    txt .= "; prefix = 前缀,可选: CapsLock / CtrlAlt / CtrlShift / AltShift / CtrlAltShift`r`n"
    txt .= "; 某个功能不想要 → 等号右边留空`r`n"
    txt .= "; 也可填 F1~F12 当独立热键(不受前缀影响)`r`n"
    txt .= "; 两个功能不能填同一个键,冲突的那个不生效`r`n"
    txt .= "prefix=CapsLock`r`n"
    txt .= "add=A`r`n"
    txt .= "set_var=C`r`n"
    txt .= "sign_flip=S`r`n"
    txt .= "multiply=M`r`n"
    txt .= "divide=D`r`n"
    txt .= "to_wan=W`r`n"
    txt .= "to_yuan=Y`r`n"
    txt .= "to_kilo=K`r`n"
    txt .= "accum_add=X`r`n"
    txt .= "accum_paste=Z`r`n"
    FileAppend(txt, iniFile, "UTF-16")
}

; ══════════════ 七个功能 ══════════════

; ── 加法粘贴(自带复制;无选中=直接粘贴变量) ──
AddPaste() {
    global delta
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    n := ClipWait(0.6) ? GrabNum(A_Clipboard) : ""
    if (n = "") {
        A_Clipboard := FmtNum(delta)
        Sleep 80
        Send "^v"
        Sleep 300
        A_Clipboard := saved
        Notify("📌 无选中,直接粘贴变量 " . FmtNum(delta))
        return
    }
    res := n + delta
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . (delta < 0 ? " − " : " + ") . FmtNum(Abs(delta)) . " = " . FmtNum(res) . "   ✅已粘贴")
}

; ── 选中数字 → 设为变量 ──
SetVar() {
    global delta
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.6) {
        A_Clipboard := saved
        return Notify("⚠️ 没复制到内容——先选中一个数字再按")
    }
    n := GrabNum(A_Clipboard)
    A_Clipboard := saved
    if (n = "")
        return Notify("⚠️ 选中的内容里没有数字")
    delta := n
    IniWrite(delta, iniFile, "main", "delta")
    Notify("📌 变量已设为 " . FmtNum(delta))
}

; ── 变量正负切换 ──
SignFlip() {
    global delta
    delta := -delta
    IniWrite(delta, iniFile, "main", "delta")
    Notify("📌 变量切换为 " . FmtNum(delta))
}

; ── 剪贴板数字 ÷10000 后粘贴(元→万元) ──
ToWan() {
    saved := ClipboardAll()
    n := GrabNum(A_Clipboard)
    if (n = "")
        return Notify("⚠️ 剪贴板里没有数字——先 Ctrl+C 复制要换算的金额")
    res := n / 10000
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . " 元 → " . FmtNum(res) . " 万元   ✅已粘贴")
}

; ── 剪贴板数字 ×10000 后粘贴(万元→元) ──
ToYuan() {
    saved := ClipboardAll()
    n := GrabNum(A_Clipboard)
    if (n = "")
        return Notify("⚠️ 剪贴板里没有数字——先 Ctrl+C 复制万元金额")
    res := n * 10000
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . " 万元 → " . FmtNum(res) . " 元   ✅已粘贴")
}

; ── 剪贴板数字 ÷1000 后粘贴(元→千元、毫米→米等同套路) ──
ToKilo() {
    saved := ClipboardAll()
    n := GrabNum(A_Clipboard)
    if (n = "")
        return Notify("⚠️ 剪贴板里没有数字——先 Ctrl+C 复制要换算的数")
    res := n / 1000
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . " ÷ 1000 = " . FmtNum(res) . "   ✅已粘贴")
}

; ── 累加:选中数字记入累计(不粘贴),气泡实时报合计 ──
AccumAdd() {
    global accum
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.6) {
        A_Clipboard := saved
        return Notify("⚠️ 没复制到内容——先选中一个数字再按")
    }
    n := GrabNum(A_Clipboard)
    A_Clipboard := saved
    if (n = "")
        return Notify("⚠️ 选中的内容里没有数字")
    accum += n
    IniWrite(accum, iniFile, "main", "accum")
    Notify("📌 已累加 " . FmtNum(n) . ",当前合计 " . FmtNum(accum))
}

; ── 贴合计:粘贴累计总和,同时累加器清零 ──
AccumPaste() {
    global accum
    if (accum = 0)
        return Notify("⚠️ 累加器是 0——先用累加键收集数字")
    saved := ClipboardAll()
    A_Clipboard := FmtNum(accum)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    accum := 0
    IniWrite(accum, iniFile, "main", "accum")
    Notify("📌 合计已粘贴,累加器已清零")
}

; ── 选中数 × 变量(税率等) ──
MultiplyPaste() {
    global delta
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.6) {
        A_Clipboard := saved
        return Notify("⚠️ 没复制到内容——先选中一个数字再按")
    }
    n := GrabNum(A_Clipboard)
    if (n = "") {
        A_Clipboard := saved
        return Notify("⚠️ 选中的内容里没有数字")
    }
    res := n * delta
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . " × " . FmtNum(delta) . " = " . FmtNum(res) . "   ✅已粘贴")
}

; ── 选中数 ÷ 变量 ──
DividePaste() {
    global delta
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.6) {
        A_Clipboard := saved
        return Notify("⚠️ 没复制到内容——先选中一个数字再按")
    }
    n := GrabNum(A_Clipboard)
    if (n = "") {
        A_Clipboard := saved
        return Notify("⚠️ 选中的内容里没有数字")
    }
    if (delta = 0)
        return Notify("⚠️ 变量是 0,不能做除法——先设个非零数")
    res := n / delta
    A_Clipboard := FmtNum(res)
    Sleep 80
    Send "^v"
    Sleep 300
    A_Clipboard := saved
    Notify(FmtNum(n) . " ÷ " . FmtNum(delta) . " = " . FmtNum(res) . "   ✅已粘贴")
}

; ══════════════ 工具函数 ══════════════

; 从文本里提取第一个数字(自动忽略千分位逗号、货币符号、文字)
GrabNum(s) {
    s := StrReplace(s, ",")
    s := StrReplace(s, "，")
    if RegExMatch(s, "-?\d+(?:\.\d+)?", &m)
        return m[0] + 0
    return ""
}

; 数字转文本:整数不带小数点,小数去掉末尾多余的 0
FmtNum(n) {
    if (n = Floor(n))
        return Format("{:d}", Integer(n))
    s := Format("{:.6f}", n)
    s := RTrim(s, "0")
    s := RTrim(s, ".")
    return (s = "-0") ? "0" : s
}

; 鼠标光标旁提示,1.8 秒后自动消失
Notify(msg) {
    ToolTip(msg, , , 1)
    SetTimer(() => ToolTip(, , , 1), -1800)
}
