# Sol RNG Auto-Path Tool

# I Hate Lime - Roblox Minigame Macro v1.1

AHK v2.0 tool tự động di chuyển path trong Sol RNG.
![Version](https://img.shields.io/badge/version-1.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![AHK](https://img.shields.io/badge/AutoHotkey-v2.0-red)

## Files

A highly optimized, multi-threaded capable AutoHotkey v2 macro designed for farming minigames in Roblox. Built with pixel-perfect radar detection, fail-safe fallback routines, and infinite looping capabilities.

| File           | Mục đích                                             |
| -------------- | ---------------------------------------------------- |
| `main.ahk`     | Script chính — hotkeys, Walk(), Collect(), path flow |
| `recorder.ahk` | Record WASD → export Walk() calls                    |
| `recorder.ahk` | Record WASD + Space + Các phím Tap                   |

## ✨ Features

## Hotkeys

- **Asynchronous Radar Detection:** Scans for target pixels continuously without interrupting the character's movement pattern.
- **Fail-safe Auto Restart:** Fully autonomous 12-second collection routine. If the collection fails, the macro clicks "Give Up" and intelligently resets the character to restart the loop.
- **Top-Down Camera Alignment:** Automatically aligns the Roblox camera to a strict Top-Down view using raw hardware mouse inputs (`DllCall`), bypassing Roblox's simulated input blocks.
- **Infinite Looping:** Gracefully handles edge cases and loop completions to keep the macro running 24/7.
- **Customizable Configuration:** Edit bounds, UI coordinates, and colors via a simple `config.ini` file without touching the code.

### main.ahk

## 🚀 Installation & Prerequisites

| Phím | Chức năng            |
| ---- | -------------------- |
| `F1` | Start path           |
| `F2` | Pause / Resume       |
| `F3` | Stop (reload script) |

1. Download and install [AutoHotkey v2.0+](https://www.autohotkey.com/).
2. Clone or download this repository.
3. Ensure your Roblox client is configured for the optimal camera settings (standard zoom limits).

### recorder.ahk

## ⚙️ Configuration (`config.ini`)

| Phím | Chức năng                            |
| ---- | ------------------------------------ |
| `F5` | Start / Stop recording               |
| `F6` | Export recorded segments → clipboard |

Before running the macro, configure your screen coordinates and pixel colors in `config.ini`. Use AutoHotkey's built-in **Window Spy** tool to fetch these values.

## Cách dùng

````ini
[Features]
EnableLogging=1
EnableCapture=1
EnableDebug=0

### 1. Record path mới
[Radar]
; Coordinates of the "Give Up" / "Skip" UI button
GiveUpX=500
GiveUpY=500

1. Mở game, đứng tại vị trí bắt đầu
2. Chạy `recorder.ahk`
3. Chạy `recorder.ahk` (Đảm bảo không chạy cùng lúc với `main.ahk`)
4. Nhấn `F5` — bắt đầu record
5. Di chuyển bằng WASD trong game
6. Thực hiện các thao tác:
   - **Di chuyển & Nhảy**: Dùng `W, A, S, D` và `Space` (các phím này ghi nhận thời gian giữ phím).
   - **Bấm phím 1 lần (Tap)**: `E`, `Esc`, `Enter`, `Tab`, `R`, `F`, `Q`.
7. Nhấn `F5` — dừng record
8. Nhấn `F6` — copy output ra clipboard
9. Paste vào `RunPath()` trong `main.ahk`
; Target pixel color of the UI text (Hex format: 0xRRGGBB)
TargetColor=0x00FF00
ColorVariation=10

Output dạng:
Output mẫu từ Recorder:

```ahk
Walk("w", 2200)
Walk("w+a", 800)
Walk("d", 400)
Walk("w+Space", 800)     ; Vừa tiến vừa nhảy
Sleep(120)               ; Khoảng nghỉ
Send("{e}")              ; Bấm phím E
Walk("w", 1500)
; The bounding box for the Radar to scan.
; Keep this tight around the UI area to improve performance and avoid false positives.
ScanX=400
ScanY=200
ScanW=800
ScanH=400
````

### 2. Viết path thủ công

## 🎮 Usage

Dùng các thao tác sau trong `RunPath()`:
Run `main.ahk` to launch the macro. You can control the execution using the following hotkeys:

#### Di chuyển

- `F1` : **Start / Resume** the macro loop.
- `F2` : **Pause** the macro temporarily.
- `F3` : **Stop & Reload** (Emergency stop that clears all stuck keys).
- `3` : **Debug Mode** (Simulates a Radar hit to test the 12-second Spam E & Give Up routine).

```ahk
Walk("w", 2000)          ; Đi thẳng 2 giây
Walk("a", 500)           ; Sang trái 0.5 giây
Walk("w+a", 800)         ; Chéo trái 0.8 giây
Walk("w+d", 1200)        ; Chéo phải 1.2 giây
Walk("s", 300)           ; Lùi 0.3 giây
Walk("w+Space", 730)     ; Tiến và nhảy
```

## 💡 Acknowledgements & Credits

#### Wall slide (alignment)

This macro was inspired by the brilliant logic and architecture of several leading Roblox macros in the community:

- [FishSol Macro](https://github.com/ivelchampion249/FishSol-Macro)
- [Natro Macro](https://github.com/NatroTeam/NatroMacro)

```ahk
Walk("w+a", 800)         ; SLIDE: đẩy vào vách trái để căn hàng
Walk("w", 600)           ; SLIDE: đẩy vào tường phía trước
```

## 📄 License

> Slide là Walk bình thường, chỉ khác ý đồ: cố tình đi vào tường để nhân vật bị chặn và căn vị trí. Đặt duration dài hơn khoảng cách thực tế một chút để đảm bảo chạm tường.

#### Nhảy (Parkour) giữ đà tuyệt đối

Hàm `Walk()` sẽ tự động nhả phím và chờ `50ms` ở cuối mỗi lệnh để tránh loạn phím. Nếu bạn dùng nhiều hàm `Walk` nối tiếp nhau để nhảy (VD: `Walk("w", 50)` rồi `Walk("w+Space", 700)`), nhân vật sẽ bị khựng lại 50ms và mất đà.

Đối với những pha parkour phức tạp cần giữ đà 100%, bạn nên **tự viết các lệnh Send độc lập** thay vì dùng `Walk()`:

```ahk
Send("{w down}")         ; Bắt đầu chạy lấy đà
Sleep(50)
Send("{Space down}")     ; Bắt đầu nhảy (vẫn đang giữ W)
Sleep(730)
Send("{Space up}")       ; Nhả nhảy
Sleep(200)
Send("{w up}")           ; Tiếp đất an toàn mới nhả chạy
```

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
; --- Segment: Spawn → Điểm A ---        ; Đánh dấu đoạn path
; SLIDE: vào vách trái                   ; Wall slide alignment
; 📍 Landmark: cây lớn bên phải          ; Mốc quan sát
; ⚠️ Đoạn này dễ lệch, cần test kỹ      ; Cảnh báo
; ⚠️ Đoạn này dễ lệch, cần test kỹ       ; Cảnh báo
```

## Lưu ý

- **FPS**: Lock 60 FPS trong Roblox Settings. FPS dao động (59.1–60.5) là lý do cần alignment points.
- **Engine Roblox & Phím Nhảy**: Roblox chạy ở tốc độ ~60 tick/giây (mỗi tick ~16.6ms). Các thao tác gõ phím quá nhanh (như `Send("{Space}")`) sẽ bị engine game bỏ qua. **Luôn sử dụng `Walk("Space", thời_gian)` hoặc `Send("{Space down}") ... Send("{Space up}")`** để game nhận đủ tín hiệu.
- **Camera align**: Luôn align camera trước khi chạy path. Code align đặt đầu `RunPath()`.
- **timeBeginPeriod**: Script tự gọi khi khởi động, tự cleanup khi thoát. Sleep chính xác ±1ms.
- **Recorder**: Chạy `recorder.ahk` riêng biệt, không chạy cùng lúc với `main.ahk`.
  This project is licensed under the MIT License - see the LICENSE file for details.
