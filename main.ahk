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
    ; Release tất cả key để tránh bị kẹt
    Send("{w up}{a up}{s up}{d up}{e up}")
    ToolTip("⏹ Stopped")
    SetTimer(() => ToolTip(), -1000)
    Reload
}

; === Debug Hotkeys ===

; 3:: {
;     global isRunning, spamETimerActive
;     ; Chỉ cho phép test khi đang chạy Walk (isRunning) và chưa bật Spam (để tránh lặp)
;     if (isRunning && !spamETimerActive) {
;         LogAction("[DEBUG] Nhấn phím 3: Ép buộc kích hoạt Spam Mode 12s!")
;         ToolTip("⚠️ FORCE SPAM MODE 12s!")
;         SetTimer(() => ToolTip(), -2000)
;         StartSpamMode()
;     }
; }

; === Helpers ===

/**
 * Walk — giữ key combo trong ms milliseconds rồi release.
 * @param keys    Chuỗi phím, ví dụ: "w", "w+a", "a+s"
 * @param ms      Thời gian giữ (milliseconds)
 * @param stepId  (Tuỳ chọn) Đánh dấu ID của luống để Ghi log
 */
Walk(keys, ms, stepId := 0) {
    global isPaused, isRunning, Config, spamETimerActive
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

        ; Xử lý Tạm Dừng (Pause)
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
        ; Chỉ bật quét nếu Radar được cho phép và chưa vào mode SpamE
        ; Only scan if Radar is enabled and not in SpamE mode
        if (enableRadar && !spamETimerActive && CheckRadar()) {
            LogAction("Radar [XANH] - Phát hiện tại Step " stepId ". Bật chế độ Spam E 12s.")
            LogAction("Radar: HIT at Step " stepId " (Spam 12s)")

            if (Config.Capture) {
                ; TODO: Chụp ảnh lưu lại (sẽ tích hợp Gdip sau)
                ; TODO: Capture image (Gdip integration later)
            }

            ; Bật Timer Spam E đa luồng ảo (nhân vật vẫn tiếp tục đi theo pattern)
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
    ; Bật luồng gõ phím E mỗi 100ms
    SetTimer(TickSpamE, 100)

    ; Đặt đồng hồ đếm ngược 12 giây (12000ms). Số âm nghĩa là chỉ chạy 1 lần.
    SetTimer(StopSpamAndGiveUp, -12000)
}

/**
 * Hàm được SetTimer gọi liên tục mỗi 100ms
 */
TickSpamE() {
    global isRunning, spamETimerActive
    if (!isRunning || !spamETimerActive) {
        SetTimer(TickSpamE, 0) ; Tắt timer nếu bị huỷ
        return
    }
    Send("{e}")
}

/**
 * Hết 12s, tắt Spam E và nhấn nút Give Up mù
 * Sau đó NGẮT TOÀN BỘ lộ trình và quay lại Loop đầu (Reset character)
 */
StopSpamAndGiveUp() {
    global spamETimerActive, Config, isRunning
    if (!isRunning)
        return

    spamETimerActive := false
    SetTimer(TickSpamE, 0) ; Tắt timer gõ phím E
    SetTimer(TickSpamE, 0) ; Stop E spam timer

    ; Bấm mù vào toạ độ nút Give Up
    ; Blind click the Give Up button
    MouseMove(Config.GiveUpX, Config.GiveUpY, 0)
    Sleep(50)
    Click()
    Sleep(50)

    LogAction("Đã hết 12s Spam E. Nhấn Give Up. Cắt chu trình để quay lại từ đầu.")
    LogAction("Spam 12s Ended: Give Up & Restart")

    ; Cắt hoàn toàn các Walk() đang chạy dở
    ; Cut all running Walk() paths
    isRunning := false

    ; Đợi 1 giây cho an toàn rồi tự động gọi RunPath() lại từ đầu
    ; Wait 1s for safety then auto restart RunPath()
    SetTimer(AutoRestartMacro, -1000)
}

AutoRestartMacro() {
    global isRunning
    isRunning := true
    LogAction("Tự động Restart RunPath()...")
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
    Loop 8 {
        if !isRunning
            return
        Send("{WheelDown}")
        Sleep(50)
    }

    LogAction("Setup: Đã căn chỉnh Camera Top-Down.")
    LogAction("Setup: Camera aligned")
}

; === Path Flow ===

/**
 * RunPath — flow chính.
 * Viết path của bạn ở đây. Tham khảo README.md để biết cách dùng.
 */
RunPath() {
    global isRunning, enableRadar, spamETimerActive

    ; Khởi tạo cờ an toàn cho mỗi Loop mới
    enableRadar := false
    spamETimerActive := false

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

    Sleep(1515)


    ; --- KẾT THÚC ---
    isRunning := false
    ToolTip("Path complete")
    SetTimer(() => ToolTip(), -3000)
}