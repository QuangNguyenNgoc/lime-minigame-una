#Requires AutoHotkey v2.0

SendMode("Event")
CoordMode("Pixel", "Client")
CoordMode("Mouse", "Client")

global Config := {}

LoadConfig()

LoadConfig() {
    global Config
    iniPath := A_ScriptDir "\config.ini"

    if !FileExist(iniPath) {
        MsgBox("Không tìm thấy config.ini. Vui lòng tạo hoặc copy từ thư mục gốc.")
        ExitApp
    }

    ; Đọc [Radar]
    Config.TargetColor := IniRead(iniPath, "Radar", "TargetColor", "0x00FF00")
    Config.ColorVar := Integer(IniRead(iniPath, "Radar", "ColorVariation", "10"))
    Config.RadarX := Integer(IniRead(iniPath, "Radar", "ScanX", "400"))
    Config.RadarY := Integer(IniRead(iniPath, "Radar", "ScanY", "200"))
    Config.RadarW := Integer(IniRead(iniPath, "Radar", "ScanW", "800"))
    Config.RadarH := Integer(IniRead(iniPath, "Radar", "ScanH", "400"))
}

1:: {
    ; Tự động Focus vào game nếu cần (tuỳ chọn)
    ; WinActivate("Roblox")

    ; Bước 1: Lăn chuột vào Góc nhìn thứ nhất (First-person)
    ; Lăn 20 nấc để đảm bảo chạm giới hạn zoom-in tối đa
    Loop 20 {
        Send("{WheelUp}")
        Sleep(20)
    }
    Sleep(200) ; Chờ game xử lý góc nhìn xong

    ; Bước 2: Kéo chuột nhìn thẳng xuống đất
    ; Trong game 3D (Roblox), MouseMove thường bị block. Cần dùng DllCall cấp phần cứng.
    Click("Right Down")
    Sleep(100)
    Loop 20 {
        ; 1 = MOUSEEVENTF_MOVE (Gửi tín hiệu chuột ảo ở cấp độ Driver/OS)
        DllCall("mouse_event", "UInt", 1, "Int", 0, "Int", 20, "UInt", 0, "UPtr", 0)
        Sleep(15)
    }
    Click("Right Up")
    Sleep(200)

    ; Bước 3: Lăn chuột ngược ra vài nấc để có góc view gần
    ; Bạn có thể thay đổi số nấc lăn (Loop 3, 4, 5...) tuỳ ý
    Loop 4 {
        Send("{WheelDown}")
        Sleep(50)
    }

    ToolTip("[v] Đã căn chỉnh Camera hoàn tất!")
    SetTimer(() => ToolTip(), -2000)
}

2:: {
    global Config
    if (PixelSearch(&outX, &outY, Config.RadarX, Config.RadarY, Config.RadarX + Config.RadarW, Config.RadarY + Config.RadarH, Config.TargetColor, Config.ColorVar)
    ) {
        MsgBox("Đã tìm thấy màu xanh tại: " outX ", " outY)
    }
    else {
        MsgBox("Not found!")
    }
}