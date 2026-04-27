#Requires AutoHotkey v2.0
#NoTrayIcon

; ══════════════════════════════════════
;  开机自启动：将自身写入注册表 Run 键
; ══════════════════════════════════════
RegWrite('"' A_AhkPath '" "' A_ScriptFullPath '"',
    "REG_SZ",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run",
    "TaskbarToggle")

; ══════════════════════════════════════
;  全局状态
; ══════════════════════════════════════
global isHidden := false
global timerActive := false

; ══════════════════════════════════════
;  热键：Alt+Z 切换
; ══════════════════════════════════════
!z:: {
    global isHidden, timerActive
    isHidden := !isHidden

    ApplyVisibility()

    if isHidden {
        ; 开启定时器，每 500ms 强制维持隐藏
        SetTimer(KeepHidden, 500)
        timerActive := true
    } else {
        ; 停止定时器
        SetTimer(KeepHidden, 0)
        timerActive := false
    }
}

; ══════════════════════════════════════
;  定时器回调：持续维持隐藏状态
; ══════════════════════════════════════
KeepHidden() {
    global isHidden
    if isHidden
        ApplyVisibility()
}

; ══════════════════════════════════════
;  核心函数：应用隐藏 / 显示
; ══════════════════════════════════════
ApplyVisibility() {
    global isHidden

    ; —— 主任务栏 ——
    hTaskbar := WinExist("ahk_class Shell_TrayWnd")
    if hTaskbar {
        isHidden ? WinHide(hTaskbar) : WinShow(hTaskbar)

        ; 同步 AppBar 状态，防止鼠标触边自动弹出
        ABD := Buffer(A_PtrSize = 8 ? 48 : 36, 0)
        NumPut("UInt", ABD.Size, ABD, 0)
        NumPut("Ptr",  hTaskbar, ABD, A_PtrSize = 8 ? 8 : 4)
        NumPut("Ptr",  isHidden ? 0x1 : 0x2, ABD, ABD.Size - A_PtrSize)
        DllCall("Shell32\SHAppBarMessage", "UInt", 0xA, "Ptr", ABD)
    }

    ; —— 副屏任务栏 ——
    for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd")
        isHidden ? WinHide(hwnd) : WinShow(hwnd)

    ; —— 桌面图标 ——
    hProgman := WinExist("ahk_class Progman")
    if !hProgman
        hProgman := WinExist("ahk_class WorkerW")

    if hProgman {
        hShellView := DllCall("user32\FindWindowEx",
            "Ptr", hProgman, "Ptr", 0,
            "Str", "SHELLDLL_DefView", "Ptr", 0, "Ptr")
        if hShellView
            PostMessage(0x111, 0x7402, 0, hShellView)
    }
}
