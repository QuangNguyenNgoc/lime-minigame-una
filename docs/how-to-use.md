# Hướng dẫn sử dụng cho A Sơn đọc

## Mô tả

Công cụ tự động chan chết cụ Lime

1. `main.ahk`: file chạy chính.
2. `utils.ahk`: cung cấp các công cụ thử nghiệm
3. `recorder.ahk`: công cụ record lộ trình di chuyển

## Chi tiết cách sử dụng và cách sửa đổi code

Sẽ mô tả lần lượt hướng dẫn sử dụng ứng với từng file (chạy 3 file cùng lúc được!)

1. chạy file `utils.ahk`:

- bấm phím `1` để tự động căn chỉnh camera, su khi căn chỉnh xong sẽ được trạng thái cố định hướng di chuyển dựa theo các trục.
  Lưu ý: không bấm `shift lock`, hay vừa bấm chuột phải vừa di chuyển; việc này dẫn tới việc làm lệch đi hướng đi theo trục; sửa bằng cách bấm 1 và đợi căn chỉnh tiếp!

2. `main.ahk`: chạy thử để biết nó đang làm gì.

- Bấm phím `F1` (Fn+F1) để thực thi lộ trình chính. Hiện tại code bạn đang đi qua 7 chấm đỏ theo lộ trình. Xem code \*(chỉ chỉnh code trong hàm RunPath())\* bắt đầu từ đoạn:

```
    ; === START ===
    Sleep(2000)
    Walk("w", 5312)
    Walk("d", 1188)
    Sleep(281)
    Walk("Space", 188)
```

Là lộ trình đi khi vừa vào map xám. Nhìn sẽ có `Walk` sẽ di chuyển theo phím được gán và số sau đó là số milisecond được thực hiện. ! Dùng natro macro đủ nhiều để biết cách ghi ntn rồi!

- Bấm phím `F2` để tạm ngưng
- Bấm phím `F3` để dừng macro (hàng copy natro macro :>)

3. `recorder.ahk`: file chính để ghi lại path di chuyển y như đoạn code mẫu trên.

- bấm phím `F5`: _bắt đầu_ ghi lộ trình di chuyển, cứ bấm các phím di chuyển (nhớ cái trên nói là ko được di chuột khi shift hay chuột phải). - Sau khi ghi lộ trình xong, bấm `F5` để kết thúc quá trình ghi
- bấm `F6` để copy.

## Chi tiết cách bổ sung vào code

1. Cần hiểu rõ mục tiêu: cần đi qua các điểm màu đỏ (code đã có sẵn tự động lặt!) nhiều nhất hoặc tối ưu nhất. Thế nên kết quả đặt ra ở sau START sẽ là một lộ trình đi qua các điểm đó!
2. paste đoạn code ở `recorder.ahk` vào.
   -> Cần để ý các phím mình đã ghi vào code, có thể xóa sửa đoạn đó. Cố gắng sao để nó hoàn hảo là đc.
   Mẹo là từ điểm này đến điểm kia, nếu đi bị lỗi thì chỉnh code tính từ đoạn dó thôi.
   Ví dụ: Mình ghi được đoạn A->B->C, nhưng C->D lại đi lỗi, mình chỉ cần sửa C->D (dựa vào việc coi code và đọc log trong file log.txt!). Hoặc thấy đoạn B->C->D nào đó tối ưu hơn, thì sửa tính từ điểm bắt đầu B.

? Về log, khi chạy `main.ahk` sẽ có file `log.txt`, trong đó sẽ ghi "các thông tin mà mình cần". Dưới đây là ví dụ thêm `id` cho `Walk`:

```
    Walk("w", 5312, 1)
    Walk("d", 1188, 2)
```

-> Việc thêm vào giúp mình xác nhận là điểm nào do log sẽ in ra id như 1,2 đó

! Và nhớ, comment code thành từng khối mà đã bổ sung.

Cảm ơn đã đóng góp! Thanh kiu vi na miu
