#Requires AutoHotkey v2.0

SendMode("Event")

1:: {
    Click("Right Down")       ; Holds down the right mouse button
    Sleep(100)
    Loop 40 {
        MouseMove(0, 3, 0, "R") ; Move down 3 pixels instantly per step
        Sleep(15)               ; Pause 15 milliseconds between steps (approx. 60Hz)
    }
    Click("Right Up")         ; Releases the right mouse button
}