# I Hate Lime - Roblox Minigame Macro v1.1

![Version](https://img.shields.io/badge/version-1.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![AHK](https://img.shields.io/badge/AutoHotkey-v2.0-red)

A lightweight, multi-threaded AutoHotkey v2 macro for automating Roblox minigames with pixel-perfect radar detection and fail-safe looping.

## Usage
Requires **1920x1080** resolution, full-screen mode, and **VIP** passive speed.
1. Configure your target colors and UI coordinates in `config.ini`.
2. Run `main.ahk`.
3. Use the following hotkeys:
   - `F1` : **Start / Resume**
   - `F2` : **Pause**
   - `F3` : **Stop & Reload** (Clears all stuck keys)
   - `3` : **Debug Mode** (Simulates a Radar hit)

## Project Structure

- **`main.ahk`**: The core engine. Handles walking paths, asynchronous pixel scanning (Radar), and fail-safe timeline cuts (12s Spam E & Give Up).
- **`config.ini`**: Stores all user configurations (Radar bounds, UI coordinates, Hex colors). Edit this to adapt the macro to your screen.
- **`utils.ahk`**: A developer scratchpad used for isolating and testing specific functions (like Mouse moves or Pixel reads).
- **`capture_tool.ahk`**: A visual helper that draws a transparent border on your screen to preview the Radar's Region of Interest (ROI) before capturing.

##s Credits

Inspired by the community's leading Roblox macros:

- [FishSol Macro](https://github.com/ivelchampion249/FishSol-Macro)
- [Natro Macro](https://github.com/NatroTeam/NatroMacro)
