# Sol RNG Auto-Path Tool

AHK v2.0 tool tự động di chuyển path trong Sol RNG.

## Files

| File           | Mục đích                                             |
| -------------- | ---------------------------------------------------- |
| `main.ahk`     | Script chính — hotkeys, Walk(), Collect(), path flow |
| `recorder.ahk` | Record WASD → export Walk() calls                    |

## Hotkeys

### main.ahk

| Phím | Chức năng            |
| ---- | -------------------- |
| `F1` | Start path           |
| `F2` | Pause / Resume       |
| `F3` | Stop (reload script) |

### recorder.ahk

| Phím | Chức năng                            |
| ---- | ------------------------------------ |
| `F5` | Start / Stop recording               |
| `F6` | Export recorded segments → clipboard |

## Cách dùng

### 1. Record path mới

1. Mở game, đứng tại vị trí bắt đầu
2. Chạy `recorder.ahk`
3. Nhấn `F5` — bắt đầu record
4. Di chuyển bằng WASD trong game
5. Nhấn `F5` — dừng record
6. Nhấn `F6` — copy output ra clipboard
7. Paste vào `RunPath()` trong `main.ahk`

Output dạng:

```ahk
Walk("w", 2200)
Walk("w+a", 800)
Walk("d", 400)
Walk("w", 1500)
```

### 2. Viết path thủ công

Dùng các thao tác sau trong `RunPath()`:

#### Di chuyển

```ahk
Walk("w", 2000)          ; Đi thẳng 2 giây
Walk("a", 500)           ; Sang trái 0.5 giây
Walk("w+a", 800)         ; Chéo trái 0.8 giây
Walk("w+d", 1200)        ; Chéo phải 1.2 giây
Walk("s", 300)           ; Lùi 0.3 giây
```

#### Wall slide (alignment)

```ahk
Walk("w+a", 800)         ; SLIDE: đẩy vào vách trái để căn hàng
Walk("w", 600)           ; SLIDE: đẩy vào tường phía trước
```

> Slide là Walk bình thường, chỉ khác ý đồ: cố tình đi vào tường để nhân vật bị chặn và căn vị trí. Đặt duration dài hơn khoảng cách thực tế một chút để đảm bảo chạm tường.

#### Click UI

```ahk
MouseMove(47, 467, 3)     ; Di chuột đến vị trí (speed 3)
Sleep(220)
Click("Left")             ; Click
Sleep(220)
```

#### Collect (zoom out + spam E)

```ahk
Collect(1500)             ; Zoom out + spam E trong 1.5 giây
Collect()                 ; Mặc định 1.5 giây
Collect(2000)             ; Lâu hơn cho điểm khó
```

#### Chờ

```ahk
Sleep(3000)               ; Chờ 3 giây (load, animation, v.v.)
```

### 3. Comment convention

```ahk
; --- Segment: Spawn → Điểm A ---       ; Đánh dấu đoạn path
; SLIDE: vào vách trái                   ; Wall slide alignment
; 📍 Landmark: cây lớn bên phải          ; Mốc quan sát
; ⚠️ Đoạn này dễ lệch, cần test kỹ      ; Cảnh báo
```

## Lưu ý

- **FPS**: Lock 60 FPS trong Roblox Settings. FPS dao động (59.1–60.5) là lý do cần alignment points.
- **Camera align**: Luôn align camera trước khi chạy path. Code align đặt đầu `RunPath()`.
- **timeBeginPeriod**: Script tự gọi khi khởi động, tự cleanup khi thoát. Sleep chính xác ±1ms.
- **Recorder**: Chạy `recorder.ahk` riêng biệt, không chạy cùng lúc với `main.ahk`.
