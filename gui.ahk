; gui.ahk
#Requires AutoHotkey v2.0

global MainGui := Gui("", "I Hate Lime Macro v1.1")
MainGui.OnEvent("Close", (*) => ExitApp())

; Left side - Control Buttons
MainGui.Add("Button", "x10 y10 w100 h35", "▶ Start (F1)").OnEvent("Click", StartMacro)
MainGui.Add("Button", "x10 y50 w100 h35", "⏸ Pause (F2)").OnEvent("Click", PauseMacro)
MainGui.Add("Button", "x10 y90 w100 h35", "⏹ Stop (F3)").OnEvent("Click", StopMacro)

; Right side - Debug Log
MainGui.Add("Text", "x120 y10 w300 h15", "Live Debug Log:")
global GuiLogBox := MainGui.Add("Edit", "x120 y25 w300 h100 ReadOnly -Wrap")

MainGui.Show("NoActivate w430 h135")

; Helper to safely append to GUI log and scroll to bottom
GuiLog(msg) {
    global GuiLogBox
    try {
        GuiLogBox.Value .= msg "`r`n"
        ; 0x0115 = WM_VSCROLL, 7 = SB_BOTTOM
        SendMessage(0x0115, 7, 0, GuiLogBox.Hwnd)
    }
}