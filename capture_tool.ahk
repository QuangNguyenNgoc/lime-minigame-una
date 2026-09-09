#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%\lib\Gdip_All.ahk"

; --- CẤU HÌNH VÙNG CHỤP (ROI) ---
global roiX := 210     ; Cách lề trái màn hình
global roiY := 110      ; Cách lề trên màn hình
global roiW := 1710    ; Chiều rộng ảnh
global roiH := 835     ; Chiều cao ảnh
global roiString := roiX "|" roiY "|" roiW "|" roiH
; --------------------------------

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

; --- TẠO KHUNG NGẮM (BORDER) ---
global borderGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20")
borderGui.BackColor := "White" ; Màu viền trắng

t := 3 ; Độ dày viền
iw := roiW - (2 * t)
ih := roiH - (2 * t)

; Tạo một khối màu Fuchsia ở giữa làm "ruột"
borderGui.Add("Text", "x" t " y" t " w" iw " h" ih " BackgroundFuchsia")

; Lệnh này sẽ làm "bốc hơi" toàn bộ màu Fuchsia thành rỗng ruột (xuyên thấu),
; Số 120 là độ trong suốt của phần viền trắng còn lại (thang đo 0-255)
WinSetTransColor("Fuchsia 120", borderGui.Hwnd)

borderGui.Show("NA x" roiX " y" roiY " w" roiW " h" roiH)

; Nhấn phím 3 để chụp 1 tấm ảnh
3:: {
    ; 1. Ẩn khung ngắm đi để không dính vào ảnh
    borderGui.Hide()
    Sleep(50) ; Chờ Windows render lại màn hình game cho sạch

    ; Tạo thư mục map_capture nếu chưa có
    folderPath := A_ScriptDir "\data\map_capture"
    if !DirExist(folderPath)
        DirCreate(folderPath)

    ; Đặt tên file theo mốc thời gian
    fileName := folderPath "\capture_" A_Now "_" A_MSec ".png"

    ; 2. Chụp và lưu ảnh
    pBitmap := Gdip_BitmapFromScreen(roiString)
    Gdip_SaveBitmapToFile(pBitmap, fileName)
    Gdip_DisposeImage(pBitmap) ; Giải phóng RAM

    ; 3. Hiện khung ngắm lại ngay lập tức
    borderGui.Show("NA")

    ToolTip("📸 Đã chụp: capture_" A_Now "_" A_MSec ".png", 0, 0)
    SetTimer(() => ToolTip(), -2000) ; Tắt tooltip sau 2s
}

; F4: Tắt công cụ
F4:: ExitApp