#Requires AutoHotkey v2.0

SendMode("Event")

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