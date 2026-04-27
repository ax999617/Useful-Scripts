#Requires AutoHotkey v2.0
#NoTrayIcon

!z:: {
    static isHidden := false
    isHidden := !isHidden

    ; ══════════════════════════════════════
    ;  1. 隐藏 / 显示任务栏
    ; ══════════════════════════════════════
    hTaskbar := WinExist("ahk_class Shell_TrayWnd")
    if hTaskbar {
        ; 直接操作窗口可见性
        isHidden ? WinHide(hTaskbar) : WinShow(hTaskbar)

        ; 同步通知系统 AppBar 状态（防止鼠标移到底部时自动弹出）
        ; APPBARDATA 结构：64位=48字节，32位=36字节
        ABD := Buffer(A_PtrSize = 8 ? 48 : 36, 0)
        NumPut("UInt", ABD.Size, ABD, 0)                          ; cbSize
        NumPut("Ptr",  hTaskbar, ABD, A_PtrSize = 8 ? 8 : 4)     ; hWnd（注意64位有4字节对齐填充）
        NumPut("Ptr",  isHidden ? 0x1 : 0x2,                      ; lParam: ABS_AUTOHIDE=1, ABS_ALWAYSONTOP=2
               ABD, ABD.Size - A_PtrSize)                         ; 修正：64位偏移40，32位偏移32
        DllCall("Shell32\SHAppBarMessage", "UInt", 0xA, "Ptr", ABD)  ; ABM_SETSTATE = 0xA
    }

    ; 副屏任务栏（可能有多个）
    for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd")
        isHidden ? WinHide(hwnd) : WinShow(hwnd)

    ; ══════════════════════════════════════
    ;  2. 隐藏 / 显示桌面图标
    ; ══════════════════════════════════════
    ; 修正：|| 返回布尔值，必须分两步取句柄
    hProgman := WinExist("ahk_class Progman")
    if !hProgman
        hProgman := WinExist("ahk_class WorkerW")

    if hProgman {
        hShellView := DllCall("user32\FindWindowEx",
            "Ptr", hProgman, "Ptr", 0,
            "Str", "SHELLDLL_DefView", "Ptr", 0, "Ptr")
        if hShellView
            PostMessage(0x111, 0x7402, 0, hShellView)  ; WM_COMMAND, SHVIEW_HIDEICONS
    }
}