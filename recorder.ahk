#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; Sol RNG Path Recorder
; F5: Start/Stop recording
; F6: Export to clipboard
;
; Track: WASD (held combo → Walk), các phím khác (tap → Send)
; ============================================

; === State ===
global isRecording := false
global segments := []
global activeKeys := Map()
global currentCombo := ""
global comboStartTick := 0

; Phím tap: tên AHK → tên trong Send("{...}")
global tapKeyNames := Map(
    "e", "e",
    "Escape", "Escape",
    "Enter", "Enter",
    "Tab", "Tab",
    "r", "r",
    "f", "f",
    "q", "q"
)

; === Hotkeys ===

F5:: {
    global isRecording, segments, activeKeys, currentCombo, comboStartTick
    if isRecording {
        ; Stop recording — flush last segment
        FlushWalkSegment()
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
        if seg.type = "walk"
            output .= 'Walk("' seg.keys '", ' seg.ms ')`n'
        else if seg.type = "tap"
            output .= 'Send("{' seg.key '}")`n'
        else if seg.type = "sleep"
            output .= 'Sleep(' seg.ms ')`n'
    }

    ; Copy to clipboard
    A_Clipboard := output
    ToolTip("📋 Copied " segments.Length " segments!`n`n" SubStr(output, 1, 500))
    SetTimer(() => ToolTip(), -6000)
}

; === Key tracking ===

#HotIf isRecording

; --- WASD + Space (held combo → Walk) ---
~*w:: OnKeyDown("w")
~*a:: OnKeyDown("a")
~*s:: OnKeyDown("s")
~*d:: OnKeyDown("d")
~*Space:: OnKeyDown("Space")

~*w Up:: OnKeyUp("w")
~*a Up:: OnKeyUp("a")
~*s Up:: OnKeyUp("s")
~*d Up:: OnKeyUp("d")
~*Space Up:: OnKeyUp("Space")

; --- Tap keys (press → Send) ---
~*e:: OnTapKey("e")
~*Escape:: OnTapKey("Escape")
~*Enter:: OnTapKey("Enter")
~*Tab:: OnTapKey("Tab")
~*r:: OnTapKey("r")
~*f:: OnTapKey("f")
~*q:: OnTapKey("q")

#HotIf

; === WASD logic (giữ key → Walk) ===

OnKeyDown(key) {
    global activeKeys, currentCombo, comboStartTick, segments

    if activeKeys.Has(key) && activeKeys[key]
        return

    activeKeys[key] := true
    newCombo := BuildCombo()

    if newCombo != currentCombo {
        FlushWalkSegment()
        currentCombo := newCombo
        comboStartTick := A_TickCount
    }
}

OnKeyUp(key) {
    global activeKeys, currentCombo, comboStartTick, segments

    activeKeys[key] := false
    newCombo := BuildCombo()

    if newCombo != currentCombo {
        FlushWalkSegment()
        currentCombo := newCombo
        comboStartTick := A_TickCount
    }
}

; === Tap key logic (bấm 1 lần → Send) ===

OnTapKey(key) {
    global segments, tapKeyNames, currentCombo, comboStartTick

    ; Flush walk segment hiện tại (nếu đang đi)
    FlushWalkSegment()
    comboStartTick := A_TickCount

    ; Ghi tap
    sendName := tapKeyNames.Has(key) ? tapKeyNames[key] : key
    segments.Push({ type: "tap", key: sendName })
    ; Thêm sleep nhỏ sau tap (thời gian thực sẽ được ghi khi segment tiếp theo bắt đầu)
}

; === Shared helpers ===

/**
 * FlushWalkSegment — lưu walk segment hiện tại (nếu có).
 */
FlushWalkSegment() {
    global currentCombo, comboStartTick, segments
    if currentCombo != "" {
        duration := A_TickCount - comboStartTick
        if duration > 30
            segments.Push({ type: "walk", keys: currentCombo, ms: duration })
    }
    ; Nếu không có walk nhưng có khoảng trống (idle), ghi Sleep
    else {
        duration := A_TickCount - comboStartTick
        if duration > 100
            segments.Push({ type: "sleep", ms: duration })
    }
}

BuildCombo() {
    global activeKeys
    parts := []
    for k in ["w", "a", "s", "d", "Space"] {
        if activeKeys.Has(k) && activeKeys[k]
            parts.Push(k)
    }
    return parts.Length > 0 ? JoinArray(parts, "+") : ""
}

JoinArray(arr, sep) {
    result := ""
    for i, v in arr {
        if i > 1
            result .= sep
        result .= v
    }
    return result
}