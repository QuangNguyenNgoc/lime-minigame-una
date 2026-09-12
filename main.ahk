#Requires AutoHotkey v2.0
#SingleInstance Force

/*
================================================================================
I Hate Lime - Roblox Minigame Macro v1.1
================================================================================
Author: QuangNguyenNgoc
License: MIT License

Credits & Inspirations:
- FishSol Macro: https://github.com/ivelchampion249/FishSol-Macro
- Natro Macro: https://github.com/NatroTeam/NatroMacro

Description:
A highly optimized, multi-threaded capable AutoHotkey v2 macro for farming
minigames in Roblox. Features pixel-perfect radar detection, fail-safe
fallback routines, and infinite looping.
================================================================================
*/

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
global verifyMinigameActive := false
global verifyFailStartTick := 0
global spamETimerActive := false
global currentZone := "Spawn"
global loopStartTime := ""
global currentLoopCount := 0
global lastStepId := 0
global Config := {}

; Load configuration on startup
LoadConfig()

; === GUI ===
#Include gui.ahk

; === Functions ===

LoadConfig() {
    global Config
    iniPath := A_ScriptDir "\config.ini"

    if !FileExist(iniPath) {
        MsgBox("config.ini not found.")
        ExitApp
    }

    ; Read [Features]
    Config.Logging := Integer(IniRead(iniPath, "Features", "EnableLogging", "1"))
    Config.Capture := Integer(IniRead(iniPath, "Features", "EnableCapture", "1"))
    Config.Debug := Integer(IniRead(iniPath, "Features", "EnableDebug", "0"))

    ; Read [Radar]
    Config.GiveUpX := Integer(IniRead(iniPath, "Radar", "GiveUpX", "500"))
    Config.GiveUpY := Integer(IniRead(iniPath, "Radar", "GiveUpY", "500"))
    Config.GiveUpColor := IniRead(iniPath, "Radar", "GiveUpColor", "0xFF0000")
    Config.TargetColor := IniRead(iniPath, "Radar", "TargetColor", "0x00FF00")
    Config.ColorVar := Integer(IniRead(iniPath, "Radar", "ColorVariation", "10"))
    Config.RadarX := Integer(IniRead(iniPath, "Radar", "ScanX", "400"))
    Config.RadarY := Integer(IniRead(iniPath, "Radar", "ScanY", "200"))
    Config.RadarW := Integer(IniRead(iniPath, "Radar", "ScanW", "800"))
    Config.RadarH := Integer(IniRead(iniPath, "Radar", "ScanH", "400"))
}

LogAction(msg) {
    logLine := "[" A_Hour ":" A_Min ":" A_Sec "] " msg
    try {
        GuiLog(logLine)
    }
}

LogTransaction(result) {
    global Config, loopStartTime, currentLoopCount, currentZone, lastStepId
    endTime := FormatTime(, "HH:mm:ss")

    transLine := "[" loopStartTime " -> " endTime "] Loop " currentLoopCount " | Zone: " currentZone " (Step " lastStepId ") | Result: " result

    try {
        GuiLog("=========================================")
        GuiLog(transLine)
        GuiLog("=========================================")
    }

    if (Config.Logging) {
        FileAppend(transLine "`n", A_ScriptDir "\log.txt")
    }
}

; === Hotkeys ===

StartMacro(*) {
    global isRunning, isPaused, MainGui
    if isRunning
        return

    ; Auto Focus Roblox
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    } else if WinExist("Roblox") {
        WinActivate("Roblox")
    }

    ; Thu nhỏ GUI để không vướng màn hình
    WinMinimize(MainGui)

    isRunning := true
    isPaused := false
    ToolTip("▶ Running")
    SetTimer(() => ToolTip(), -2000)
    RunPath()
}

PauseMacro(*) {
    global isPaused, isRunning, MainGui
    if !isRunning
        return
    isPaused := !isPaused

    ; Hiện lại GUI khi tạm dừng
    if (isPaused)
        WinRestore(MainGui)

    ToolTip(isPaused ? "⏸ Paused" : "▶ Resumed")
    SetTimer(() => ToolTip(), -2000)
}

StopMacro(*) {
    global isRunning, isPaused, currentLoopCount

    ; Nếu đang chạy dở 1 vòng lặp mà bị ngắt, ghi lại Log Transaction
    if (isRunning && currentLoopCount > 0) {
        LogTransaction("STOPPED (User Aborted)")
    }

    isRunning := false
    isPaused := false
    ReleaseAllKeys()
    ToolTip("⛔ Stopped")
    SetTimer(() => ToolTip(), -1000)
    Reload
}

F1:: StartMacro()
F2:: PauseMacro()
F3:: StopMacro()

; === Helpers ===

/**
 * anti ghosting keyboard
 */
ReleaseAllKeys() {
    Send("{w up}{a up}{s up}{d up}{e up}{Space up}")
}

/**
 * Walk - Hold key combo for ms milliseconds then release.
 * @param keys    Key string, e.g., "w", "w+a", "a+s"
 * @param ms      Hold duration (milliseconds)
 * @param stepId  (Optional) ID of the path step for logging
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
            ; Compensate startTick for paused duration
            startTick += A_TickCount - pauseTick
            for k in keyList
                Send("{" k " down}")
        }

        ; === CONTINUOUS SAFETY CHECK ===
        if (verifyMinigameActive && !VerifyMinigameState()) {
            if (spamETimerActive) {
                LogAction("Minigame ended early (Item collected!). Aborting 12s timer & Restarting...")
                spamETimerActive := false
                SetTimer(TickSpamE, 0)
                SetTimer(StopSpamAndGiveUp, 0) ; Kill the 12s timer
            } else {
                LogAction("CRITICAL: Minigame lost (Disconnected/Crashed). Aborting...")
            }
            isRunning := false
            for k in keyList
                Send("{" k " up}")
            ReleaseAllKeys()
            SetTimer(AutoRestartMacro, -1000)
            return
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
    Sleep(50)  ; Micro-gap between walk segments

    if (stepId > 0) {
        lastStepId := stepId
        LogAction("Step " stepId ": none")
    }
    if (stepId > 0) {
        LogAction("Step " stepId ": PASS")
        ToolTip("Step " stepId ": PASS")
    }
}

; === RADAR & MULTITASKING LOGIC ===

global spamETimerActive := false
global currentZone := "Spawn"
global loopStartTime := ""
global currentLoopCount := 0
global lastStepId := 0

/**
 * CheckRadar - Scan for Pixel within the Bounding Box
 */
CheckRadar() {
    global Config
    found := PixelSearch(&outX, &outY, Config.RadarX, Config.RadarY, Config.RadarX + Config.RadarW, Config.RadarY + Config.RadarH, Config.TargetColor, Config.ColorVar)
    return found
}

/**
 * Activate Spam E mode while walking
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
 * Timer callback called every 100ms to spam E
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
    LogTransaction("FOUND (Caught Item)")

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
    MouseMove(Config.GiveUpX, Config.GiveUpY, 3)
    Sleep(500)
    Click()
    Sleep(500)
    RunPath()
}

/**
 * AlignCameraTopDown - Align camera to top-down view (First-person -> Look down -> Zoom out)
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


/**
 * VerifyMinigameState - Checks if the Give Up button (Red color) is present on screen.
 */
VerifyMinigameState() {
    global Config
    ; Mở rộng vùng tìm kiếm (200x100) quanh toạ độ GiveUpX/Y để đảm bảo bắt trúng toàn bộ nút
    startX := Config.GiveUpX - 50
    startY := Config.GiveUpY - 15
    endX := Config.GiveUpX + 50
    endY := Config.GiveUpY + 15

    ; Variation 70 để bắt mọi tone màu đỏ của nút Give Up (kể cả khi viền nhạt/sáng)
    found := PixelSearch(&outX, &outY, startX, startY, endX, endY, Config.GiveUpColor, 70)
    return found
}

; === Path Flow ===

RunPath() {
    global isRunning, enableRadar, spamETimerActive, verifyMinigameActive
    global currentLoopCount, loopStartTime, currentZone, lastStepId, GuiLogBox, verifyFailStartTick

    currentLoopCount++
    loopStartTime := FormatTime(, "HH:mm:ss")
    currentZone := "Spawn"
    lastStepId := 0
    try {
        GuiLogBox.Value := "" ; Clear GUI log
    }

    enableRadar := false
    spamETimerActive := false
    verifyMinigameActive := false
    verifyFailStartTick := 0
    ReleaseAllKeys() ; safe release

    ; === ĐẢM BẢO GAME LUÔN FOCUS KHI TỰ ĐỘNG RESTART ===
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    } else if WinExist("Roblox") {
        WinActivate("Roblox")
    }
    Sleep(500)

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

    ; --- Wait for Minigame (Polling check up to 5 seconds) ---
    LogAction("Waiting for minigame to load...")
    minigameLoaded := false
    Loop 50 { ; Chờ tối đa 5 giây (50 * 100ms)
        if (!isRunning)
            return
        if VerifyMinigameState() {
            minigameLoaded := true
            break
        }
        Sleep(100)
    }

    if (!minigameLoaded) {
        LogAction("Safety Check: 'Give Up' button not found. Teleport failed! Restarting...")
        LogTransaction("FAILED TO JOIN MINIGAME")
        isRunning := false
        ReleaseAllKeys()
        SetTimer(AutoRestartMacro, -1000)
        return
    }
    LogAction("Safety Check: Minigame verified.")
    verifyMinigameActive := true

    ; Bù lại khoảng dừng 2 giây gốc để đồng bộ nhịp độ rơi xuống/camera của path di chuyển
    Sleep(2000)

    currentZone := "near the donation board"
    Walk("w", 5297)
    Walk("d", 1187)
    Walk("a", 250)
    Walk("d+Space", 156)
    Walk("d", 578)
    Walk("a", 156)
    Walk("d+Space", 125)
    Walk("d", 600)
    Walk("s", 281, 1)

    Walk("d", 1230)
    Walk("s", 579)
    Walk("a", 625)
    Walk("w", 625, 2)

    currentZone := "near parkour"
    Walk("d", 6000)
    Walk("a", 200)
    Walk("d", 50)
    Walk("d+Space", 224)
    Walk("d", 1828, 3)
    Walk("s", 719)
    Walk("w", 218)
    Walk("s", 47)
    Walk("s+Space", 125, 4)

    currentZone := "tree near leardboard"
    Walk("s", 2250)
    Walk("a", 1890)
    Walk("w", 855)
    Walk("d", 609)
    Walk("s", 759)
    Walk("a", 2891)

    Walk("w", 640)
    Walk("d", 1860)
    Walk("w", 955)
    Walk("d", 1438)
    Walk("s", 688)
    Walk("a", 593)
    Walk("s", 766)
    Walk("a", 609)
    Walk("s", 1985)

    Walk("d", 328)
    Walk("a", 609)
    Walk("s", 516)
    Walk("d", 359)
    Walk("a", 282)
    Walk("s", 516)
    Walk("d", 281)
    Walk("a", 282)
    Walk("s", 422)
    Walk("d", 219)
    Walk("s", 1140)

    Walk("a", 453)
    Walk("s", 391)
    Walk("d", 485)
    Walk("s", 4000)

    currentZone := "at roll leadboard"
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

    Walk("d", 450)
    Walk("w", 1625)
    Walk("s", 578)
    Walk("d", 547)
    Walk("w", 641)
    Walk("s", 1625)

    Walk("d", 2300)
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

    currentZone := "two tree near quest board"
    ; 1 spot near need to detect
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
    Walk("a+Space", 156)
    Walk("a", 297, 12)

    currentZone := "go up place"
    Walk("s", 782)
    Walk("w", 187)
    Walk("s+Space", 172)
    Walk("s", 900)
    Walk("d", 3406, 13)

    currentZone := "french"
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

    currentZone := "go out french"
    Walk("s", 1032)
    Walk("w", 813)
    Walk("a", 1016, 17)

    Walk("s", 688)
    Walk("a", 2750)
    Walk("s", 1204)
    Walk("d", 796)
    Walk("w", 1000)
    Walk("a", 1359)
    Walk("s", 2484)
    Walk("a", 1765)
    Walk("w", 813)
    Walk("d", 2900)
    Walk("a", 1100)

    Walk("w", 4687)
    Walk("d", 359)
    Walk("w", 344, 18)

    currentZone := "hut"
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

    currentZone := "high grown near cave"
    Walk("w", 31)
    Walk("s+Space", 141)
    Walk("s", 1266)
    Walk("a", 3969)
    Walk("d", 235)
    Walk("a", 47)
    Walk("a+Space", 187)
    Walk("a", 4656)

    Walk("w", 47)
    Walk("w+Space", 141)
    Walk("w", 1375)

    Walk("s", 234)
    Walk("d", 1797)
    Walk("a", 125)
    Walk("d", 78)
    Walk("d+Space", 141)
    Walk("d", 547)
    Walk("a", 657)
    Walk("a+Space", 94)
    Walk("a", 1328)
    Walk("d", 172)
    Walk("a", 62)
    Walk("a+Space", 125)
    Walk("a", 1047)
    Walk("w", 547)

    Walk("d", 522)
    Walk("w", 484)
    Walk("a", 469)
    Walk("w", 1500)
    Walk("d", 922)
    Walk("s", 1375)
    Walk("d", 172)
    Walk("w", 922)
    Walk("d", 295)
    Walk("s", 2200, 24)

    Walk("d", 4297)
    Walk("w", 423)
    Walk("a", 1890)
    Walk("w", 2187)
    Walk("d", 735)
    Walk("s", 547)
    Walk("a", 531)
    Walk("d", 2515)
    Walk("s", 812)
    Walk("d", 1234)
    Walk("w", 500)
    Walk("a", 750)
    Walk("s", 625, 25)

    Walk("w", 766)
    Walk("d", 2609)
    Walk("s", 719)
    Walk("d", 953)
    Walk("s", 671)
    Walk("d", 734)
    Walk("w", 718)
    Walk("d", 593)
    Walk("s", 687)

    Walk("a+s", 94)
    Walk("a", 47)
    Walk("w", 156)
    Walk("w+Space", 172)
    Walk("w", 1203)
    Walk("s", 1516)
    Walk("d", 297)
    Walk("w+d", 63)
    Walk("w", 500)
    Walk("w+a", 47)
    Walk("a", 265)
    Walk("w", 469)
    Walk("d", 469)
    Walk("a+d", 31)
    Walk("a", 1063, 26)

    Walk("d", 360)
    Walk("a", 47)
    Walk("a+Space", 265)
    Walk("a", 579, 27)

    Walk("a", 6125)
    Walk("d", 141)
    Walk("w", 3187)
    Walk("s", 594)
    Walk("d", 1469)
    Walk("s", 1422)
    Walk("w", 922)
    Walk("a", 1766)
    Walk("s", 500, 28)

    Walk("d", 266)
    Walk("a", 47)
    Walk("a+Space", 156)
    Walk("a", 2203)
    Walk("w", 2240)
    Walk("s", 172)
    Walk("w+Space", 140)
    Walk("w", 891)
    Walk("d", 281)
    Walk("w", 484)
    Walk("w+a", 32)
    Walk("a", 546)
    Walk("s", 610, 29)

    Walk("w", 359)
    Walk("d", 3109)
    Walk("w", 610)
    Walk("a", 609)
    Walk("s", 625)
    Walk("a", 2906, 30)

    Walk("w", 2578)
    Walk("d", 1625)
    Walk("s", 550)
    Walk("a", 1990, 31)

    Walk("w", 2625)
    Walk("d", 969)
    Walk("s", 593)
    Walk("a", 1313, 32)

    Walk("w", 3219)
    Walk("s", 547)
    Walk("d", 1219)
    Walk("a", 328)
    Walk("d", 109)
    Walk("d+Space", 172)
    Walk("d", 2250)
    Walk("s", 3078)
    Walk("d", 1609)
    Walk("a", 1844)
    Walk("w", 3422, 33)

    Walk("d", 3079)
    Walk("a", 203)
    Walk("d+Space", 141)
    Walk("d", 703)
    Walk("w", 562)
    Walk("s", 437)
    Walk("w", 484)
    Walk("s", 484)
    Walk("w", 562, 34)

    Walk("a", 782)
    Walk("d", 266)
    Walk("a+Space", 157)
    Walk("a", 1296)
    Walk("s", 906)
    Walk("w", 265)
    Walk("s", 78)
    Walk("s+Space", 156)
    Walk("s", 1469)
    Walk("w", 469)
    Walk("d", 406)
    Walk("a", 391)
    Walk("s", 406)
    Walk("s", 547)
    Walk("w", 671)
    Walk("d", 375)
    Walk("w", 610)
    Walk("a", 281)
    Walk("s", 266, 35)

    Sleep(2000)


    ; --- END ---

    ; Case 1: Target detected at the very end of the path
    if (spamETimerActive) {
        LogAction("End of path reached. Waiting for 12s Spam to finish...")
        while (spamETimerActive && isRunning) {
            Sleep(100)
        }
        return ; StopSpamAndGiveUp sẽ làm việc tiếp
    }

    ; Case 2: Walked entire path without detecting anything -> Auto restart
    if (isRunning) {
        isRunning := false
        ReleaseAllKeys()
        LogAction("Path complete (Nothing found). Auto-restarting loop...")
        LogTransaction("NOT FOUND")
        ToolTip("Restarting Loop...")
        SetTimer(AutoRestartMacro, -2000)
    }
}