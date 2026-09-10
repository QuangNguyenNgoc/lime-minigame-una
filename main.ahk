#Requires AutoHotkey v2.0
#SingleInstance Force

; === Timing precision ===
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit((*) => DllCall("winmm\timeEndPeriod", "UInt", 1))

; === Mouse, Pixel & Send mode ===
SendMode("Event")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")

; === State ===
global isRunning := false
global isPaused := false
global enableRadar := false
global spamETimerActive := false
global Config := {}

; Nạp cấu hình ngay khi khởi động
LoadConfig()

; === Functions ===

LoadConfig() {
    global Config
    iniPath := A_ScriptDir "\config.ini"

    if !FileExist(iniPath) {
        MsgBox("config.ini not found.")
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
    Config.RadarX := Integer(IniRead(iniPath, "Radar", "ScanX", "400"))
    Config.RadarY := Integer(IniRead(iniPath, "Radar", "ScanY", "200"))
    Config.RadarW := Integer(IniRead(iniPath, "Radar", "ScanW", "800"))
    Config.RadarH := Integer(IniRead(iniPath, "Radar", "ScanH", "400"))
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
    ; Release keys
    Send("{w up}{a up}{s up}{d up}{e up}")
    ReleaseAllKeys()
    ToolTip("⏹ Stopped")
    SetTimer(() => ToolTip(), -1000)
    Reload
}

; === Debug Hotkeys ===

3:: {
    global isRunning, spamETimerActive
    if (isRunning && !spamETimerActive) {
        LogAction("[DEBUG] 3: Force spam mode 12s!")
        ToolTip("FORCE SPAM MODE 12s!")
        SetTimer(() => ToolTip(), -2000)
        StartSpamMode()
    }
}

; === Helpers ===

/**
 * anti ghosting keyboard
 */
ReleaseAllKeys() {
    Send("{w up}{a up}{s up}{d up}{e up}{Space up}")
}

/**
 * Walk — giữ key combo trong ms milliseconds rồi release.
 * @param keys    Chuỗi phím, ví dụ: "w", "w+a", "a+s"
 * @param ms      Thời gian giữ (milliseconds)
 * @param stepId  (Tuỳ chọn) Đánh dấu ID của luống để Ghi log
 */
Walk(keys, ms, stepId := 0) {
    global isPaused, isRunning, Config, spamETimerActive

    if (!isRunning)
        return

    keyList := StrSplit(keys, "+")

    ; Press keys
    for k in keyList
        Send("{" k " down}")

    startTick := A_TickCount
    while (A_TickCount - startTick) < ms {
        if !isRunning {
            for k in keyList
                Send("{" k " up}")
            return
        }

        ; Pause
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

        ; === RADAR CHUNK ===
        ; Only scan if Radar is enabled and not in SpamE mode
        if (enableRadar && !spamETimerActive && CheckRadar()) {
            LogAction("Radar [XANH] detect")
            LogAction("Radar: HIT at Step " stepId " (Spam 12s)")
            ToolTip("Detect color!")

            if (Config.Capture) {
                ; TODO: Chụp ảnh lưu lại (sẽ tích hợp Gdip sau)
                ; TODO: Capture image (Gdip integration later)
            }

            ; Start virtual multi-threaded Spam E timer (character continues pattern)
            StartSpamMode()
        }
        ; ===================

        Sleep(10)
    }

    ; Release keys
    for k in keyList
        Send("{" k " up}")
    Sleep(50)  ; micro-gap giữa các segment

    if (stepId > 0)
        LogAction("Step " stepId ": none")
    if (stepId > 0) {
        LogAction("Step " stepId ": PASS")
        ToolTip("Step " stepId ": PASS")
    }
}

; === RADAR & MULTITASKING LOGIC ===

global spamETimerActive := false

/**
 * CheckRadar - Quét tìm Pixel trong vùng giới hạn (Bounding Box)
 */
CheckRadar() {
    global Config
    found := PixelSearch(&outX, &outY, Config.RadarX, Config.RadarY, Config.RadarX + Config.RadarW, Config.RadarY + Config.RadarH, Config.TargetColor, Config.ColorVar)
    return found
}

/**
 * Kích hoạt chế độ Vừa Đi Vừa Nhặt (Spam E)
 */
StartSpamMode() {
    global spamETimerActive
    if (spamETimerActive)
        return

    spamETimerActive := true
    SetTimer(TickSpamE, 100)

    SetTimer(StopSpamAndGiveUp, -12000)
}

/**
 * Hàm được SetTimer gọi liên tục mỗi 100ms
 */
TickSpamE() {
    global isRunning, spamETimerActive
    if (!isRunning || !spamETimerActive) {
        SetTimer(TickSpamE, 0) ; stop
        return
    }
    Send("{e}")
}

/**
 * endloop
 */
StopSpamAndGiveUp() {
    global spamETimerActive, Config, isRunning
    if (!isRunning)
        return

    spamETimerActive := false
    SetTimer(TickSpamE, 0)

    ; Blind click the Give Up button
    MouseMove(Config.GiveUpX, Config.GiveUpY, 3)
    Sleep(500)
    Click()
    Sleep(500)

    LogAction("Spam 12s Ended: Give Up & Restart")

    ; Cut all running Walk() paths
    isRunning := false
    ReleaseAllKeys()

    ; Wait 1s for safety then auto restart RunPath()
    SetTimer(AutoRestartMacro, -1000)
}

AutoRestartMacro() {
    global isRunning
    isRunning := true
    LogAction("Restarting RunPath...")
    RunPath()
}

/**
 * AlignCameraTopDown — Chỉnh camera về góc nhìn từ trên xuống (Góc nhìn thứ 1 -> Cúi xuống -> Lăn ra)
 */
AlignCameraTopDown() {
    global isRunning
    if !isRunning
        return

    ; Bước 1: Lăn chuột vào Góc nhìn thứ nhất
    Loop 20 {
        if !isRunning
            return
        Send("{WheelUp}")
        Sleep(20)
    }
    Sleep(200)

    ; Bước 2: Kéo chuột nhìn thẳng xuống đất
    Click("Right Down")
    Sleep(100)
    Loop 40 {
        if !isRunning
            break
        DllCall("mouse_event", "UInt", 1, "Int", 0, "Int", 20, "UInt", 0, "UPtr", 0)
        Sleep(15)
    }
    Click("Right Up")
    Sleep(200)

    ; Bước 3: Lăn chuột ngược ra
    Loop 8 {
        if !isRunning
            return
        Send("{WheelDown}")
        Sleep(50)
    }

    LogAction("Setup: Camera aligned")
}

; === Path Flow ===

RunPath() {
    global isRunning, enableRadar, spamETimerActive

    enableRadar := false
    spamETimerActive := false
    ReleaseAllKeys() ; safe release

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
    enableRadar := true

    ; --- Go to align place ---
    Sleep(2000)
    Walk("w", 5312)
    Walk("d", 1188)
    Sleep(281)
    Walk("Space", 188)
    Sleep(109)
    Walk("d", 172)
    Sleep(672)
    Walk("Space", 140)
    Walk("d", 625)
    Sleep(766)
    Walk("s", 281, 1)
    Sleep(453)
    Walk("d", 1438)
    Walk("s", 579)
    Walk("a", 625)
    Walk("w", 516, 2)
    Walk("d", 4860)
    Walk("d+Space", 125)
    Walk("d", 1828, 3)
    Walk("s", 719)
    Sleep(110)
    Walk("w", 218)
    Sleep(250)
    Walk("s", 47)
    Walk("s+Space", 125, 4)
    Walk("s", 2250)
    Walk("a", 1890)
    Walk("w", 855)
    Walk("d", 609)
    Walk("s", 546)
    Walk("a", 525)
    Walk("w", 1400)
    Walk("d", 360)
    Walk("s", 547, 5)

    Walk("a", 547)
    Walk("s", 625)
    Walk("a", 608)
    Walk("s", 1969)
    Walk("a", 1281)
    Walk("w", 1218)
    Walk("d", 516)
    Walk("s", 2594, 6)

    Walk("a", 359)
    Walk("s", 1094)
    Walk("d", 641)
    Walk("a", 438)
    Walk("s", 4469)

    Walk("w", 250)
    Walk("a", 1156)
    Walk("w", 797)
    Walk("s", 1094)
    Walk("d", 1562)
    Walk("w", 1985)
    Walk("d", 1140)
    Walk("s", 1364)
    Walk("a", 224)
    Walk("w", 2070, 7)

    Walk("s", 187)
    Walk("w+Space", 200)
    Walk("w", 577)
    Walk("d", 2672)
    Walk("s", 1109)
    Walk("a", 1000, 8)

    Walk("s", 3125)
    Walk("d", 2266)
    Walk("w", 219)
    Walk("d", 1547)
    Walk("w", 3234)
    Walk("s", 1828)
    Walk("d", 453)
    Walk("s", 485)
    Walk("a", 900)
    Walk("s", 2547, 9)

    Walk("a", 1594)
    Walk("d", 187)
    Walk("w", 125)
    Walk("a+Space", 156)
    Walk("a", 891)
    Walk("w", 468)
    Walk("d", 500)
    Walk("s", 1531)
    Walk("a", 2250)
    Walk("w", 437)
    Walk("d", 672)
    Walk("s", 1172, 10)

    Walk("w", 266)
    Walk("s+Space", 172)
    Walk("s", 1376)
    Walk("a", 1281)
    Walk("s", 859)
    Walk("a", 1500)
    Walk("w", 875)
    Walk("d", 2266)
    Walk("s", 1859)
    Walk("a", 390)
    Walk("s", 859, 11)

    Walk("d", 641)
    Walk("a", 859)
    Walk("s", 1859)
    Walk("w", 203)
    Walk("a", 890)
    Walk("d", 265)
    Walk("a", 47)
    Walk("a+Space", 156)
    Walk("a", 297, 12)

    Walk("s", 782)
    Walk("w", 156)
    Walk("s+Space", 172)
    Walk("s", 1047)
    Walk("d", 3406, 13)

    Walk("a", 187)
    Walk("d", 31)
    Walk("d+Space", 188)
    Walk("d", 1718)
    Walk("d", 422)
    Walk("d+Space", 219)
    Walk("d", 2781)
    Walk("s+d", 141)
    Walk("s", 453)
    Walk("a+s", 47)
    Walk("a", 2812)
    Walk("w", 765)
    Walk("d", 2625)
    Walk("w+d", 125)
    Walk("w", 781)
    Walk("w+a", 47)
    Walk("a", 1875, 14)

    Walk("Space", 47)
    Walk("w+Space", 141)
    Walk("w", 1031)
    Walk("a", 610)
    Walk("s", 547)
    Walk("w", 1734)
    Walk("a", 1109)
    Walk("s", 609)
    Walk("d", 4110)
    Walk("a", 875)
    Walk("w", 1250)
    Walk("a", 516)
    Walk("s", 2859, 15)

    Walk("w", 172)
    Walk("s", 31)
    Walk("s+Space", 156)
    Walk("s", 1469)
    Walk("s+Space", 172)
    Walk("s", 609)
    Walk("a", 1625)
    Walk("s", 562)
    Walk("d", 484, 16)

    Walk("s", 1032)
    Walk("w", 813)
    Walk("a", 1016)
    Walk("s", 688, 17)

    Walk("a", 1640)
    Walk("a", 1172)
    Walk("s", 1204)
    Walk("d", 796)
    Walk("w", 3250, 18)

    Walk("a", 4094)
    Walk("s", 719)
    Walk("d", 1063)
    Walk("w", 735)
    Walk("a", 1735, 19)

    Walk("s", 1047)
    Walk("w", 3569)
    Walk("s", 93)
    Walk("a", 1047)
    Walk("s", 829)
    Walk("w", 843)
    Walk("a", 700)
    Walk("s", 1015, 20)

    Walk("w", 2953)
    Walk("a", 797)
    Walk("s", 250)
    Walk("s+Space", 156)
    Walk("s", 375)
    Walk("a", 453)
    Walk("d", 938)
    Walk("s", 421)
    Walk("d", 500)
    Walk("a", 1859)
    Walk("s", 960, 21)

    Walk("w", 625)
    Walk("a", 1750)
    Walk("w", 1219)
    Walk("a", 344)
    Walk("w", 547)
    Walk("a", 594)
    Walk("w", 1016)
    Walk("a", 30)
    Walk("s", 1812)
    Walk("d", 1781, 22)

    Walk("a", 1212)
    Walk("a+Space", 157)
    Walk("a", 2125)
    Walk("a+Space", 125)
    Walk("a", 1421)
    Walk("a+Space", 157)
    Walk("a", 1406)
    Walk("w", 1080, 23)

    Sleep(1515)


    ; --- KẾT THÚC ---

    ; Trường hợp 1: Phát hiện vật thể ở những bước cuối cùng
    if (spamETimerActive) {
        LogAction("End of path reached. Waiting for 12s Spam to finish...")
        while (spamETimerActive && isRunning) {
            Sleep(100)
        }
        return ; StopSpamAndGiveUp sẽ làm việc tiếp
    }

    ; Trường hợp 2: Đi hết đường mà không thấy gì cả -> Tự động đi lại từ đầu
    isRunning := false
    ReleaseAllKeys()
    LogAction("Path complete (Nothing found). Auto-restarting loop...")
    ToolTip("Restarting Loop...")
    SetTimer(AutoRestartMacro, -2000)
}