---
title: "Visual Alignment (Pixel/Image Checkpoint)"
date: 2026-09-08
---

# Visual Alignment (Pixel/Image Checkpoint)

## Bối cảnh & Vấn đề

Trong quá trình xây dựng Auto-Path cho Sol RNG bằng AHK, có sai số tích luỹ khi di chuyển thời gian dài (do FPS dao động, server tickrate). Cần một phương pháp để sửa lỗi hoặc xác nhận vị trí nhân vật mà không phụ thuộc hoàn toàn vào việc đi vào góc tường (Wall-slide).

## Giải pháp đã thảo luận

Sử dụng kỹ thuật **Visual Alignment** (giống Natro Macro) làm **Điểm Neo Xác Nhận (Checkpoint)** thay vì dùng để tính toán và tự nắn đường đi liên tục:

- Dùng `PixelSearch` hoặc `ImageSearch` để xác nhận nhân vật đã tới một điểm mốc (landmark) cố định trên bản đồ chưa (VD: màu mái nhà, bảng hiệu).
- **Quy trình (Go / No-Go):** Đi một đoạn xa -> Chạy lệnh check màu/ảnh.
  - Nếu trùng khớp: Xác nhận đã đến đích, tiếp tục path.
  - Nếu sai lệch: Dừng lại, kích hoạt fallback (VD: đi lùi lại hoặc tìm góc tường gần nhất để nắn vật lý - Wall-slide).

## Lưu ý

- Không nên dùng Visual Alignment để tính toán độ lệch (offset) và nắn chuột/phím theo thời gian thực (micro-adjust) vì phép tính chuyển đổi từ pixel 2D sang quãng đường 3D rất phức tạp.
- Cần cẩn thận với chu kỳ ngày/đêm và bóng râm (shadows) trong Roblox vì chúng làm thay đổi mã màu. Nên dùng `ImageSearch` với tham số variation `*n` hoặc chọn các vật thể phát sáng (neon) để check.
- **Wall-slide** vẫn là phương pháp nắn vật lý tuyệt đối (Zero-error) hiệu quả nhất. Visual Alignment nên đóng vai trò là lớp kiểm tra phụ trợ.
