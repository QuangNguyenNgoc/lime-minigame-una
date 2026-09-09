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
global Config := {}

; Nạp cấu hình ngay khi khởi động
LoadConfig()

; === Functions ===

LoadConfig() {
    global Config
    iniPath := A_ScriptDir "\config.ini"

    if !FileExist(iniPath) {
        MsgBox("Không tìm thấy config.ini. Vui lòng tạo hoặc copy từ thư mục gốc.")
        ExitApp
    }

    ; Đọc [Features]
    Config.Logging := Integer(IniRead(iniPath, "Features", "EnableLogging", "1"))
    Config.Capture := Integer(IniRead(iniPath, "Features", "EnableCapture", "1"))
    Config.Debug := Integer(IniRead(iniPath, "Features", "EnableDebug", "0"))

    ; Đọc [Radar]
    Config.GiveUpX := Integer(IniRead(iniPath, "Radar", "GiveUpX", "500"))
    Config.GiveUpY := Integer(IniRead(iniPath, "Radar", "GiveUpY", "500"))
    Config.TargetColor := IniRead(iniPath, "Radar", "TargetColor", "0x00FF00")
    Config.ColorVar := Integer(IniRead(iniPath, "Radar", "ColorVariation", "10"))
}

LogAction(msg) {
    global Config
    if (Config.Logging) {
        logLine := "[" A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "] " msg "`n"
        FileAppend(logLine, A_ScriptDir "\log.txt")
    }
}

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

/**
 * AlignCameraTopDown — Chỉnh camera về góc nhìn từ trên xuống (Góc nhìn thứ 1 -> Cúi xuống -> Lăn ra)
 */
AlignCameraTopDown() {
    global isRunning
    if !isRunning
        return

    ; Bước 1: Lăn chuột vào Góc nhìn thứ nhất (First-person)
    Loop 20 {
        if !isRunning
            return
        Send("{WheelUp}")
        Sleep(20)
    }
    Sleep(200)

    ; Bước 2: Kéo chuột nhìn thẳng xuống đất bằng DllCall
    Click("Right Down")
    Sleep(100)
    Loop 40 { ; Để 40 cho chắc chắn ép góc chạm đáy
        if !isRunning
            break
        DllCall("mouse_event", "UInt", 1, "Int", 0, "Int", 20, "UInt", 0, "UPtr", 0)
        Sleep(15)
    }
    Click("Right Up")
    Sleep(200)

    ; Bước 3: Lăn chuột ngược ra 4 nấc
    Loop 4 {
        if !isRunning
            return
        Send("{WheelDown}")
        Sleep(50)
    }

    LogAction("Setup: Đã căn chỉnh Camera Top-Down.")
}

; === Path Flow ===

/**
 * RunPath — flow chính.
 * Viết path của bạn ở đây. Tham khảo README.md để biết cách dùng.
 */
RunPath() {
    global isRunning

    ; === SETUP ===
    ; --- Reset character ---
    Send("{Escape}")       ; ESC
    Sleep(400)
    Send("{r}")
    Sleep(400)
    Send("{Enter}")
    Sleep(1000)

    ; --- Camera align ---
    MouseMove(47, 467, 3)
    Sleep(400)
    Click("Left")
    Sleep(400)
    MouseMove(382, 126, 3)
    Sleep(400)
    Click("Left")
    Sleep(400)
    AlignCameraTopDown()

    ; --- Go to Lime ---
    Walk("s+d", 2031)
    Walk("s", 2188)
    Walk("d", 1391)
    Sleep(100)

    ; --- Start minigame ---
    Send("{e}")
    Sleep(400)
    MouseMove(1000, 800, 3)
    Sleep(400)
    Click("Left")
    Sleep(400)
    MouseMove(1265, 940, 3)
    Sleep(400)
    Click("Left")
    Sleep(400)
    MouseMove(1000, 800, 3)
    Sleep(400)
    Click("Left")
    Sleep(400)
    MouseMove(737, 941, 3)
    Sleep(400)
    Click("Left")

    ; === START ===
    ; --- Go to align place ---
    Sleep(2000)
    Walk("d", 5532)
    Sleep(125)
    Walk("s", 437)
    Walk("a", 234)
    Sleep(172)
    Walk("w", 188)
    Sleep(219)
    Walk("s+Space", 157)
    Walk("s", 234)
    Sleep(203)
    Walk("d", 656)
    Sleep(1500)


    ; --- EXAMPLE: Spawn → Điểm A ---
    ; Walk("w", 4000)          ; thẳng
    ; Walk("w+a", 800)         ; chéo trái
    ; Walk("w", 400)           ; SLIDE: vào vách trái

    ; --- EXAMPLE: Collect tại điểm A ---
    ; Collect(1500)

    ; --- Kết thúc ---
    isRunning := false
    ToolTip("Path complete")
    SetTimer(() => ToolTip(), -3000)
}