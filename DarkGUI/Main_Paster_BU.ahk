#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

#Include !CreateImageButton.ahk
#Include !WinDarkUI.ahk
#Include !DarkStyleMsgBox.ahk
#Include !GuiEnhancerKit.ahk


#DllLoad "Gdiplus.dll"

program_version := 2.0
code_version := 1
HotKeyStatus := true
CurrentPage := "P01"
Font := "Segoe UI"
global bind := "!v"
global to_tray := 0
status := 0
FontSize := 9

try {
    global bind := RegRead("HKEY_CURRENT_USER\Software\Agzes\Paster", "bind")
}
try {
    global to_tray := RegRead("HKEY_CURRENT_USER\Software\Agzes\Paster", "to_tray")
}

SetWindowColor(hwnd, titleText?, titleBackground?, border?)
{
    static DWMWA_BORDER_COLOR := 34
    static DWMWA_CAPTION_COLOR := 35
    static DWMWA_TEXT_COLOR := 36
    if (VerCompare(A_OSVersion, "10.0.22200") < 0)
        return ; MsgBox("This is supported starting with Windows 11 Build 22000.", "OS Version Not Supported.")
    if (border ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, border)
    if (titleBackground ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, titleBackground)
    if (titleText ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, titleText)
    DwmSetWindowAttribute(hwnd?, dwAttribute?, pvAttribute?) => DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", dwAttribute, "Ptr*", &pvAttribute, "UInt", 4)
}
UseGDIP() {
    Static GdipObject := 0
    If !IsObject(GdipObject) {
        GdipToken := 0
        SI := Buffer(24, 0)
        NumPut("UInt", 1, SI)
        If DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", &GdipToken, "Ptr", SI, "Ptr", 0, "UInt") {
            MsgBox("GDI+ could not be started!`n`nThe program will exit!", A_ThisFunc, 262160)
            ExitApp
        }
        GdipObject := { __Delete: UseGdipShutDown }
    }
    UseGdipShutDown(*) {
        DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", GdipToken)
    }
}
UseGDIP()

SaveBindCfg(*) {
    RegWrite(bind, "REG_SZ", "HKEY_CURRENT_USER\Software\Agzes\Paster", "bind")
    Hotkey(bind, start_write_non_ui)
}


ButtonStyles := Map()

ButtonStyles["dark"] := [[0xFF171717, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF262626, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF2F2F2F, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF626262, 0xFF474747, 0xFFFFFFFF, 3, 0xFF474747, 1]]

ButtonStyles["fake_for_group"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF262626, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF171717, 0xFF474747, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["reset"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFFFF4444, 0xFFCC0000, 0xFFFFFFFF, 3, 0xFFCC0000, 2],
    [0xFFFF6666, 0xFFFF0000, 0xFFFFFFFF, 3, 0xFFFF0000, 2],
    [0xFF1b1b1b, 0xFF474747, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["secondary"] := [[0xFF234125, 0xFF1B3019, 0xFFFFFFFF, 3, 0xFF1B3019, 1],
    [0xFF1B3019, 0xFF152512, 0xFFFFFFFF, 3, 0xFF152512, 1],
    [0xFF2D5230, 0xFF234125, 0xFFFFFFFF, 3, 0xFF234125, 1],
    [0xFF386A3C, 0xFF2D5230, 0xFFFFFFFF, 3, 0xFF2D5230, 1]]

MainUI := GuiExt("", "V.0.1.1 \ Paster \ by Agzes")
MainUI.SetFont("cWhite s" FontSize, Font)
MainUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

STB1 := MainUI.AddButton("x6 y6 w490 h338 0x100 Disabled", "")
CreateImageButton(STB1, 0, ButtonStyles["fake_for_group"]*)

STB2 := MainUI.AddButton("x+6 y6 w132 h338 0x100 Disabled", "")
CreateImageButton(STB2, 0, ButtonStyles["fake_for_group"]*)

INPUT := MainUI.AddEdit("x6 y6 w507 h338", "")
INPUT.SetRounded(7)

Clear(*) {
    INPUT.Value := ""
}
ClearButton := MainUI.AddButton("x508 y12 w120 h30", "clear")
ClearButton.OnEvent("Click", Clear)
CreateImageButton(ClearButton, 0, ButtonStyles["reset"]*)

CounterText := MainUI.AddText("x508 y45 w120 +Center", "0 / 0")
UpdateCounter(*) {
    text := INPUT.Value
    chars := StrLen(text)
    lines := StrSplit(text, "`n").Length
    CounterText.Value := chars " / " lines
}

INPUT.OnEvent("Change", UpdateCounter)

STB06 := MainUI.AddButton("x508 y75 w120 h36 0x100 Disabled", "")
CreateImageButton(STB06, 0, ButtonStyles["fake_for_group"]*)

SGW := SysGet(SM_CXMENUCHECK := 71)
SGH := SysGet(SM_CYMENUCHECK := 72)
CTTValue := MainUI.AddCheckBox("x512 y78 h" SGH " w" SGW)
CTTValue.Value := to_tray
CTTLabel := MainUI.AddText("x527 y78 0x200 h" SGH, " Close To Tray")

SGW1 := SysGet(SM_CXMENUCHECK := 71)
SGH1 := SysGet(SM_CYMENUCHECK := 72)
TFCValue := MainUI.AddCheckBox(" x512 y93 h" SGH1 " w" SGW1)
TFCLabel := MainUI.AddText("x527 y93 0x200 h" SGH1, " Text From Copy")

STB05 := MainUI.AddButton("x508 y115 w120 h77 0x100 Disabled", "") 
CreateImageButton(STB05, 0, ButtonStyles["fake_for_group"]*)

SpeedText := MainUI.AddText("x510 y124 w116 +Center", "Speed: 100ms") 
SpeedSlider := MainUI.AddSlider("x512 y140 w112 h25 Range0-500 TickInterval25 ToolTip+", 100) 
SpeedSlider.SetRounded(7)

SGW := SysGet(SM_CXMENUCHECK := 71)
SGH := SysGet(SM_CYMENUCHECK := 72)
SmartValue := MainUI.AddCheckBox(" x525 y168 h" SGH " w" SGW)
SmartLabel := MainUI.AddText(" x539 y168 0x200 h" SGH, " Smart Mode")


UpdateSpeed(*) {
    global writeSpeed := SpeedSlider.Value
    SpeedText.Value := "Speed: " writeSpeed "ms"
}
SpeedSlider.OnEvent("Change", UpdateSpeed)


STB04 := MainUI.AddButton("x508 y196 w120 h53 0x100 Disabled", "")
CreateImageButton(STB04, 0, ButtonStyles["fake_for_group"]*)

DelayText := MainUI.AddText("x510 y201 w116 +Center", "delay for start (sec)")
MainUI.SetFont("cWhite s" 10, Font)
BG := MainUI.AddButton("x512 y220 w112 h25 Disabled")
CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)
DelayInput := MainUI.AddEdit("x512 y220 w112 h25", "5")
DelayInput.SetRounded(7)
MainUI.SetFont("cWhite s" FontSize, Font)


WaitForBind(Options := "T5")
{
    global ih := InputHook(Options)
    if !InStr(Options, "V")
        ih.VisibleNonText := false
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ih.Wait()
    return StrReplace(StrReplace(ih.EndMods . ih.EndKey, "<", ""), ">", "")
}
BindHotkey(BtnObj) {
    global CurrentBindsRecords
    BtnObj.Text := Chr(0xE15B)
    CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
    CurrentBindsRecords := BtnObj.Hwnd
    tbind := WaitForBind()
    if tbind != "" {
        global bind
        Hotkey(bind, "off")
        bind := tbind
        BindInput.Text := BindToHotkey(tbind)
        SaveBindCfg()
    }
    BtnObj.Text := Chr(0xE104)
    CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
    CurrentBindsRecords := ""
}
BindHotkeyButton(BtnObj, *) {
    BindHotkey(BtnObj)
}
BindHotkeyInput(CtrlElement, *) {
    global bind
    Hotkey(bind, "off")
    bind := HotkeyToBind(CtrlElement.Text)
    SaveBindCfg()
}
HotkeyToBind(keys) {
    return StrReplace(StrReplace(StrReplace(StrReplace(keys, "Win + ", "#"), "Ctrl + ", "^"), "Alt + ", "!"), "Shift + ", "+")
}
BindToHotkey(keys) {
    return StrReplace(StrReplace(StrReplace(StrReplace(keys, "+", "Shift + "), "^", "Ctrl + "), "!", "Alt + "), "#", "Win + ")
}
ShowCode(Element, *) {
    Element.Text := BindToHotkey(Element.Text)
}
HideCode(Element, *) {
    Element.Text := HotkeyToBind(Element.Text)
}


STB03 := MainUI.AddButton("x508 y253 w120 h53 0x100 Disabled", "")
CreateImageButton(STB03, 0, ButtonStyles["fake_for_group"]*)

JustText := MainUI.AddText("x510 y258 w116 +Center", "hotkey to start")

BindButton := MainUI.AddButton("x512 y277 w25 h25", Chr(0xE104))
BindButton.OnEvent("Click", BindHotkeyButton)
CreateImageButton(BindButton, 0, ButtonStyles["fake_for_group"]*)

BG := MainUI.AddButton("x539 y277 w85 h25 Disabled")
CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)

MainUI.SetFont("cWhite s" 10, Font)
BindInput := MainUI.AddEdit("x539 y277 w85 h25 ", "")
BindInput.OnEvent("Change", BindHotkeyInput)
BindInput.OnEvent("Focus", HideCode)
BindInput.OnEvent("LoseFocus", ShowCode)
BindInput.SetRounded(7)
BindInput.Value := BindToHotkey(bind)
MainUI.SetFont("cWhite s" FontSize, Font)

StartButton := MainUI.AddButton("x508 y308 w120 h30", "START")
StartButton.OnEvent("Click", start_write_from_ui)
CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)

SetWindowAttribute(MainUI)
SetWindowTheme(MainUI)
SetWindowColor(MainUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
MainUI.Show("h350 w640")


start_write_from_ui(*) {
    global status
    if status == 1 {
        global status := 0
        ToolTip("")
        StartButton.Text := "START"
        CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)
        return
    }
    status := 1
    StartButton.Text := "STARTING IN " DelayInput.Text " SEC"
    CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)
    StartButton.OnEvent("Click", start_write_from_ui)
    start_write(true)

}
start_write_non_ui(*) {
    global status 
    status := 1
    start_write(false)
}


TypeText(text, normalDelay, shortDelay, smart) {
    RandDelay(delay) {
        if !smart
            return delay
        randomOffset := Random(-70, 70)
        newDelay := delay + randomOffset
        return (newDelay < 1) ? 1 : newDelay
    }

    StrRepeat(str, count) {
        newStr := ""
        while (count > 0) {
            newStr .= str
            count--
        }
        return newStr
    }

    splitted := StrSplit(text, "")
    totalCount := StrLen(text)
    barLength := 20

    for i, c in splitted {
        if status != 1
            break

        progressRatio := i / totalCount
        filledCount := Round(progressRatio * barLength)
        progressBar := "|" . StrRepeat("=", filledCount) . StrRepeat("-", barLength - filledCount) . "|"
        ToolTip("Progress: " i " / " totalCount "`n" progressBar)

        if (c = " " || c = "`n") {
            Sleep RandDelay(shortDelay)
            if (c = "`n") {
                Send "{Enter}"
                continue
            }
            Send c
        } else if (c = "`r") {
            continue
        } else {
            Sleep RandDelay(normalDelay)
            Send c
        }
    }

    
    ToolTip("")
    global status := 0
    StartButton.Text := "START"
    CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)
}

stop_this(*) {
    global status := 0
    ToolTip("")
    StartButton.Text := "START"
    CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)
}

start_write(ui?, *) {
    if TFCValue.Value
        INPUT.Value := A_Clipboard

    if ui {
        if bind != "^s" {
            ToolTip("Click Ctrl+S for stop")
            Hotkey("^s", stop_this)
            global t_b := "^s"
        } else {
            ToolTip("Click Ctrl+Alt+S for stop")
            Hotkey("!^s", stop_this)
            global t_b := "!^s"
        }
        SetTimer(() => ToolTip(""), DelayInput.Text * 1000)
        SetTimer(() => next_write(ui), DelayInput.Text * 1000)
    } else {
        next_write(false)
    }
        

}
  
next_write(ui?, *) {
    if ui 
        Hotkey(t_b, "off")

    if status == 0 {
        return
    }

    text := INPUT.Value
    if !text {
        global status := 0
        StartButton.Text := "START"
        CreateImageButton(StartButton, 0, ButtonStyles["secondary"]*)
        MsgBox("Error: Input is empty", "Paster - Error", 0x10)
        return
    }
    StartButton.Text := "PROCESS..."
    CreateImageButton(StartButton, 0, ButtonStyles["reset"]*)
    TypeText(text, SpeedSlider.Value, Floor(SpeedSlider.Value / 2), SmartValue.Value)
}

CloseEvent(*) {
    if CTTValue.Value {
        MainUI.Hide()
        MsgBox("To close the program, right-click on the tray icon and click `"Exit`". `nTo open UI, just run app again.", "v.0.1.1 \ Paster \ by Agzes")
    } else {
        ExitApp()
    }
}


MainUI.OnEvent('Close', (*) => CloseEvent())

Hotkey(bind, start_write_non_ui)

