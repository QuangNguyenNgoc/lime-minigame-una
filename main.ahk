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
    global isRunning, isPaused
    isRunning := false
    isPaused := false
    ; Release tất cả key để tránh bị kẹt
    Send("{w up}{a up}{s up}{d up}{e up}")
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
    global isPaused, isRunning
    keyList := StrSplit(keys, "+")

    ; Press keys
    for k in keyList
        Send("{" k " down}")

    ; Dùng A_TickCount để đo thời gian chính xác, không bị drift
    startTick := A_TickCount
    while (A_TickCount - startTick) < ms {
        if !isRunning {
            for k in keyList
                Send("{" k " up}")
            return
        }
        if isPaused {
            pauseTick := A_TickCount
            for k in keyList
                Send("{" k " up}")
            while isPaused && isRunning
                Sleep(50)
            if !isRunning
                return
            ; Bù thời gian pause vào startTick
            startTick += A_TickCount - pauseTick
            for k in keyList
                Send("{" k " down}")
        }
        Sleep(10)
    }

    ; Release keys
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
    global isPaused, isRunning

    ; Zoom out nhanh
    Loop 5 {
        if !isRunning
            return
        Send("{WheelDown}")
        Sleep(30)
    }
    Sleep(100)

    ; Spam E
    elapsed := 0
    while elapsed < ms {
        if !isRunning
            return
        while isPaused && isRunning
            Sleep(50)
        if !isRunning
            return
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

    ; --- Start minigame ---
    SendInput("e")
    Sleep(220)
    MouseMove(1000, 800, 3)
    Sleep(220)
    Click("Left")
    Sleep(220)
    MouseMove(1265, 940, 3)
    Sleep(220)
    Click("Left")
    Sleep(220)
    MouseMove(1000, 800, 3)
    Sleep(220)
    Click("Left")
    Sleep(220)
    MouseMove(737, 941, 3)
    Sleep(220)
    Click("Left")

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