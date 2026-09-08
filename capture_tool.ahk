#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%\lib\Gdip_All.ahk"

; Khởi tạo GDI+
global pToken := Gdip_Startup()
if !pToken {
    MsgBox("Lỗi: Không thể khởi tạo GDI+. Kiểm tra thư viện Gdip_All.ahk")
    ExitApp
}
OnExit(CleanUp)

CleanUp(ExitReason, ExitCode) {
    Gdip_Shutdown(pToken)
}
; 227, 67 (điểm bắt đầu, X, Y)
; 227, 927
; 1919,927

; Nhấn phím 3 để chụp 1 tấm ảnh
3:: {
    ; --- CẤU HÌNH VÙNG CHỤP (ROI) ---
    ; Dùng công cụ "Window Spy" của AHK
    roiX := 227     ; Cách lề trái màn hình
    roiY := 67     ; Cách lề trên màn hình
    roiW := 1692    ; Chiều rộng ảnh muốn chụp
    roiH := 860     ; Chiều cao ảnh muốn chụp
    roiString := roiX "|" roiY "|" roiW "|" roiH
    ; --------------------------------

    ; Tạo thư mục map_capture nếu chưa có
    folderPath := A_ScriptDir "\data\map_capture"
    if !DirExist(folderPath)
        DirCreate(folderPath)

    ; Đặt tên file theo mốc thời gian để không bị trùng
    fileName := folderPath "\capture_" A_Now "_" A_MSec ".png"

    ; Chụp và lưu ảnh
    pBitmap := Gdip_BitmapFromScreen(roiString)
    Gdip_SaveBitmapToFile(pBitmap, fileName)
    Gdip_DisposeImage(pBitmap) ; Giải phóng RAM lập tức

    ToolTip("Đã chụp: capture_" A_Now "_" A_MSec ".png", 0, 0)
    SetTimer(() => ToolTip(), -2000) ; Tắt tooltip sau 2s
}

; F4: Tắt công cụ
F4:: ExitApp