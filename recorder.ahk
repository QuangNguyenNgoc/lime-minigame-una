#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; Sol RNG Path Recorder
; F5: Start/Stop recording
; F6: Export to clipboard
; ============================================

; === State ===
global isRecording := false
global segments := []
global activeKeys := Map()
global currentCombo := ""
global comboStartTick := 0

; === Hotkeys ===

F5:: {
    global isRecording, segments, activeKeys, currentCombo, comboStartTick
    if isRecording {
        ; Stop recording — flush last segment
        if currentCombo != "" {
            duration := A_TickCount - comboStartTick
            if duration > 30
                segments.Push({ keys: currentCombo, ms: duration })
        }
        isRecording := false
        activeKeys := Map()
        currentCombo := ""
        count := segments.Length
        ToolTip("⏹ Stopped — " count " segments recorded`nPress F6 to export")
        SetTimer(() => ToolTip(), -4000)
    } else {
        ; Start recording
        segments := []
        activeKeys := Map()
        currentCombo := ""
        comboStartTick := A_TickCount
        isRecording := true
        ToolTip("🔴 Recording... (F5 to stop)")
        SetTimer(() => ToolTip(), -3000)
    }
}

F6:: {
    global segments
    if segments.Length = 0 {
        ToolTip("⚠ Nothing recorded")
        SetTimer(() => ToolTip(), -2000)
        return
    }

    ; Build output
    output := ""
    for seg in segments {
        output .= 'Walk("' seg.keys '", ' seg.ms ')`n'
    }

    ; Copy to clipboard
    A_Clipboard := output
    ToolTip("📋 Copied " segments.Length " segments to clipboard!`n`n" SubStr(output, 1, 500))
    SetTimer(() => ToolTip(), -6000)
}

; === Key tracking ===
; Track WASD keys. When the combination of held keys changes,
; save the previous combo as a segment and start a new one.

#HotIf isRecording

~*w:: => OnKeyDown("w")
~*a:: => OnKeyDown("a")
~*s:: => OnKeyDown("s")
~*d:: => OnKeyDown("d")

~*w Up:: => OnKeyUp("w")
~*a Up:: => OnKeyUp("a")
~*s Up:: => OnKeyUp("s")
~*d Up:: => OnKeyUp("d")

#HotIf

OnKeyDown(key) {
    global activeKeys, currentCombo, comboStartTick, segments

    if activeKeys.Has(key) && activeKeys[key]
        return  ; already held

    activeKeys[key] := true
    newCombo := BuildCombo()

    if newCombo != currentCombo {
        ; Save previous segment
        if currentCombo != "" {
            duration := A_TickCount - comboStartTick
            if duration > 30  ; ignore tiny glitches
                segments.Push({ keys: currentCombo, ms: duration })
        }
        currentCombo := newCombo
        comboStartTick := A_TickCount
    }
}

OnKeyUp(key) {
    global activeKeys, currentCombo, comboStartTick, segments

    activeKeys[key] := false
    newCombo := BuildCombo()

    if newCombo != currentCombo {
        ; Save previous segment
        if currentCombo != "" {
            duration := A_TickCount - comboStartTick
            if duration > 30
                segments.Push({ keys: currentCombo, ms: duration })
        }
        currentCombo := newCombo
        comboStartTick := A_TickCount
    }
}

/**
 * BuildCombo — xây chuỗi combo từ các key đang giữ.
 * Trả về dạng "w", "w+a", "a+s", v.v. Thứ tự cố định: w, a, s, d.
 */
BuildCombo() {
    global activeKeys
    parts := []
    for k in ["w", "a", "s", "d"] {
        if activeKeys.Has(k) && activeKeys[k]
            parts.Push(k)
    }
    return parts.Length > 0 ? JoinArray(parts, "+") : ""
}

/**
 * JoinArray — nối mảng thành chuỗi với separator.
 */
JoinArray(arr, sep) {
    result := ""
    for i, v in arr {
        if i > 1
            result .= sep
        result .= v
    }
    return result
}