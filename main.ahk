#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; Sol RNG Auto-Path Tool
; Hotkeys: F1 Start | F2 Pause/Resume | F3 Stop
; ============================================

; === Timing precision ===
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit((*) => DllCall("winmm\timeEndPeriod", "UInt", 1))

; === Mouse & Send mode ===
SendMode("Event")

; === State ===
global isRunning := false
global isPaused := false

; === Hotkeys ===

F1:: {
    global isRunning, isPaused
    if isRunning
        return
    isRunning := true
    isPaused := false
    ToolTip("▶ Running")
    SetTimer(() => ToolTip(), -2000)
    RunPath()
}

F2:: {
    global isPaused
    if !isRunning
        return
    isPaused := !isPaused
    ToolTip(isPaused ? "⏸ Paused" : "▶ Resumed")
    SetTimer(() => ToolTip(), -2000)
}

F3:: {
    ToolTip("⏹ Stopped")
    SetTimer(() => ToolTip(), -1000)
    Reload
}

; === Helpers ===

/**
 * Walk — giữ key combo trong ms milliseconds rồi release.
 * @param keys  Chuỗi phím, ví dụ: "w", "w+a", "a+s"
 * @param ms    Thời gian giữ (milliseconds)
 */
Walk(keys, ms) {
    global isPaused
    while isPaused
        Sleep(50)

    keyList := StrSplit(keys, "+")
    for k in keyList
        Send("{" k " down}")
    Sleep(ms)
    for k in keyList
        Send("{" k " up}")
    Sleep(50)  ; micro-gap giữa các segment
}

/**
 * Collect — zoom out + spam E.
 * Scroll xuống để phóng nhỏ view, đồng thời spam E mỗi 200ms.
 * @param ms  Tổng thời gian collect (milliseconds), mặc định 1500
 */
Collect(ms := 1500) {
    global isPaused
    while isPaused
        Sleep(50)

    ; Zoom out nhanh
    Loop 5 {
        Send("{WheelDown}")
        Sleep(30)
    }
    Sleep(100)

    ; Spam E
    elapsed := 0
    while elapsed < ms {
        Send("{e}")
        Sleep(200)
        elapsed += 200
    }
}

; === Path Flow ===

/**
 * RunPath — flow chính.
 * Viết path của bạn ở đây. Tham khảo README.md để biết cách dùng.
 */
RunPath() {
    global isRunning

    ; --- Camera align ---
    MouseMove(47, 467, 3)
    Sleep(220)
    Click("Left")
    Sleep(220)
    MouseMove(382, 126, 3)
    Sleep(220)
    Click("Left")
    Sleep(220)

    ; --- Go to Lime ---
    Walk("s+d", 3610)
    Walk("s", 1312)
    Walk("d", 484)

    ; --- EXAMPLE: Spawn → Điểm A ---
    ; Walk("w", 2200)          ; thẳng
    ; Walk("w+a", 800)         ; chéo trái
    ; Walk("w", 600)           ; SLIDE: vào vách trái

    ; --- EXAMPLE: Collect tại điểm A ---
    ; Collect(1500)

    ; --- Kết thúc ---
    isRunning := false
    ToolTip("Path complete")
    SetTimer(() => ToolTip(), -3000)
}