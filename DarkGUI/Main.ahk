#Requires AutoHotkey v2.1-alpha.14
#SingleInstance Force
#Warn All, Off

#Include !CreateImageButton.ahk
#Include !WinDarkUI.ahk
#Include !GuiEnhancerKit.ahk
#Include !ScroolBar.ahk
#Include !DarkStyleMsgBox.ahk

#DllLoad "Gdiplus.dll"

R_G_Binds := ""

Esc:: ExitApp

global logs := []
LogAdd(Text) {
    logs.Push(Text)
}

Username := "User"
Name := "DB"
Role := "Doctor"

global settings := SettingsManager()

global Settings := settings.Settings

; Add this at the start of your script
global G_Binds_Name := [
    "Menu", "Bind", "Options", "Information", "Reload",
    "Welcome", "Pass tablet", "Sell honey", "Bruise", "Ammonia",
    "Injection", "Med. Card", "Extract from ward 6", "Med. Exam", "Professional suitability",
    "Knife/Bullet", "Stretcher/Dropper", "Defibrillator", "Twist + soothing injection", "Calming injection",
    "Plastic surgery", "Blood test", "Treat wound", "Bullet removal", "Closed fracture",
    "Open fracture", "X-ray", "Dislocation", "CPR", "ECG",
    "Lecture", "Charter 1", "Charter 3", "Charter 3 terms", "Charter 4",
    "Oath 1", "Oath 2", "Orders", "Practice 1", "Practice 2",
    "PMP Dislocation", "PMP Closed", "PMP Open", "PMP Bullet", "PMP Knife"
]

SaveSettingsForUSERDATA(Element, *) {
    try {
        settings.Settings["Name"] := SSP_P1_NAME.Text
        settings.Settings["Role"] := SSP_P1_ROLE.Text
        settings.Settings["UserName"] := SSP_P1_USERNAME.Text
        settings.Save()
        MsgBox("Data saved successfully!`nRestart to apply")
    } catch Error as e {
        MsgBox("Error while saving!")
    }
}

class IniConfig {
    __New(iniPath) {
        this.path := iniPath
        this.Settings := IniConfig.Section(iniPath, "Settings")
        this.UserData := IniConfig.Section(iniPath, "UserData")
        this.Binds := IniConfig.Section(iniPath, "Binds")
    }

    class Section {
        __New(iniPath, sectionName) {
            this.DefineProp("path", { get: (*) => iniPath })
            this.DefineProp("name", { get: (*) => sectionName })
        }

        Get(key, default := "") => IniRead(this.path, this.name, key, default)
        Set(key, value) => IniWrite(value, this.path, this.name, key)

        ReadAll() {
            section := IniRead(this.path, this.name)
            result := Map()
            for k, v in StrSplit(section, "`n")
                result[StrSplit(v, "=")[1]] := StrSplit(v, "=")[2]
            return result
        }
    }
}

class SettingsManager {
    Settings := Map()
    Binds := []

    __New(iniPath := "settings.ini") {
        this.path := iniPath
        this.Settings := Map(
            "program_version", 2.0,
            "code_version", 1,
            "HotKeyStatus", true,
            "CurrentPage", "SBT01",
            "Font", "Segoe UI",
            "FontSize", 11,
            "UserName", "User",
            "ScrollActive", false,
            "Role", "",
            "Name", "",
            "FocusMethod", 1,
            "BeforeEsc", 1,
            "BeforeCheck", 0,
            "BeforeLimit", 0,
            "ShowStatus", 1,
            "UpdateCheck", 1
        )

        this.LoadBinds()
        this.LoadSettings()
    }

    LoadSettings() {
        for field in this.Settings
            try this.Settings[field] := IniRead(this.path, "Settings", field, this.Settings[field])
        this.LoadUserData()
    }

    LoadUserData() {
        userDataFields := ["UserName", "Role", "Name", "FocusMethod", "BeforeEsc",
            "BeforeCheck", "BeforeLimit", "ShowStatus", "UpdateCheck"]
        for field in userDataFields
            try this.Settings[field] := IniRead(this.path, "UserData", field, this.Settings[field])
    }

    LoadBinds() {
        try {
            this.Binds := []
            Loop 45 {
                if key := IniRead(this.path, "Binds", A_Index, "")
                    this.Binds.Push(key)
            }
        }
    }

    Save() {
        userDataFields := ["UserName", "Role", "Name", "FocusMethod", "BeforeEsc",
            "BeforeCheck", "BeforeLimit", "ShowStatus", "UpdateCheck"]

        for key, value in this.Settings {
            section := userDataFields.Has(key) ? "UserData" : "Settings"
            IniWrite(value, this.path, section, key)
        }
    }

    SaveBind(index, value) {
        if (index >= 1 && index <= 45) {
            IniWrite(value, this.path, "Binds", index)
            this.Binds[index] := value
        }
    }
}

global FocusMethod := Settings["FocusMethod"]
global BeforeEsc := Settings["BeforeEsc"]
global BeforeCheck := Settings["BeforeCheck"]
global BeforeLimit := Settings["BeforeLimit"]
global ShowStatus := Settings["ShowStatus"]
global UpdateCheck := Settings["UpdateCheck"]
global UserName := Settings["UserName"]
global Role := Settings["Role"]
global Name := Settings["Name"]

config := IniConfig("settings.ini")
Settings := config.Settings.ReadAll()
for k, v in config.UserData.ReadAll()
    Settings[k] := v

global KeyBinds := Map()
global Settings := Map()

LoadConfig() {
    global Settings := Map(
        "program_version", 2.0,
        "code_version", 1,
        "HotKeyStatus", true,
        "CurrentPage", "SBT01",
        "Font", "Segoe UI",
        "FontSize", 11,
        "UserName", "User",
        "ScrollActive", false,
        "Role", "",
        "Name", "",
        "FocusMethod", 1,
        "BeforeEsc", 1,
        "BeforeCheck", 0,
        "BeforeLimit", 0,
        "ShowStatus", 1,
        "UpdateCheck", 1
    )
    userDataFields := ["UserName", "Role", "Name", "FocusMethod", "BeforeEsc", "BeforeCheck", "BeforeLimit", "ShowStatus", "UpdateCheck"]
    for field in Settings {
        try Settings[field] := IniRead("settings.ini", "Settings", field)
    }
    for field in userDataFields {
        try Settings[field] := IniRead("settings.ini", "UserData", field)
    }
}

LoadConfig()

try {
    LogAdd("[info] getting config files `"Binds`"")
    bindsArr := []
    Loop 45 {
        key := IniRead("settings.ini", "Binds", A_Index)
        bindsArr.Push(key)
    }
    global G_Binds := bindsArr
}

try {
    global UserName := IniRead("settings.ini", "UserData", "UserName")
    global Role := IniRead("settings.ini", "UserData", "Role")
    global Name := IniRead("settings.ini", "UserData", "Name")
    global FocusMethod := IniRead("settings.ini", "UserData", "FocusMethod")
    global BeforeEsc := IniRead("settings.ini", "UserData", "BeforeEsc")
    global BeforeCheck := IniRead("settings.ini", "UserData", "BeforeCheck")
    global BeforeLimit := IniRead("settings.ini", "UserData", "BeforeLimit")
    global ShowStatus := IniRead("settings.ini", "UserData", "ShowStatus")
    global UpdateCheck := IniRead("settings.ini", "UserData", "UpdateCheck")
}

SetWindowColor(hwnd, titleText?, titleBackground?, border?)
{
    static DWMWA_BORDER_COLOR := 34
    static DWMWA_CAPTION_COLOR := 35
    static DWMWA_TEXT_COLOR := 36
    if (VerCompare(A_OSVersion, "10.0.22200") < 0)
        return
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

GetPageData(Page) {
    if Page == "SBT01" {
        return MainPage
    } else if Page == "SBT02" {
        return BindsPage
    } else if Page == "SBT03" {
        return SettingsPage
    } else if Page == "SBT04" {
        return OtherPage
    }
}

SettingsTabSelect(BtnCtrl, *) {
    global CurrentPage
    global ScrollActive
    OldPageData := GetPageData(CurrentPage)
    OldCurrentPage := CurrentPage
    CurrentPageData := GetPageData(BtnCtrl.Name)
    CurrentPage := BtnCtrl.Name
    for key in OldPageData {
        key.Opt("Hidden")
    }
    for key in CurrentPageData {
        key.Opt("-Hidden")
    }
    if OldCurrentPage == "SBT02" {
        SendMessage(0x115, 6, 0, , SettingsUI.Hwnd)
        STB.Opt("-Hidden")
        STB1.Opt("Hidden")
        RemoveScrollBar(SettingsUI)
        ScrollActive := false
        for item in BindItems {
            t := GuiCtrlFromHwnd(item)
            t.Opt("Hidden")
        }
    }
    if CurrentPage == "SBT02" {
        STB1.Opt("-Hidden")
        STB.Opt("Hidden")
        ShowScrollBar(SettingsUI)
        ScrollActive := true
        for item in BindItems {
            t := GuiCtrlFromHwnd(item)
            t.Opt("-Hidden")
        }
    }
    LogSent("[info] [tab-sys]: " OldCurrentPage " -> " CurrentPage "")
}

ButtonStyles := Map()

ButtonStyles["dark"] := [[0xFF171717, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF262626, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF2F2F2F, 0xFF1A1A1A, 0xFFFFFFFF, 3, 0xFF1A1A1A, 1],
    [0xFF626262, 0xFF474747, 0xFFFFFFFF, 3, 0xFF474747, 1]]

ButtonStyles["tab"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF262626, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF626262, 0xFF474747, 0xFFFFFFFF, 3, 0xFF474747, 2]]

ButtonStyles["fake_for_group"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF262626, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF171717, 0xFF474747, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["fake_for_hotkey"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF262626, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFF1b1b1b, 0xFF474747, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["binds"] := [[0xFF191919, 0xFF181818, 0xFFBEBEBE, 5, 0xFF191919, 2],
    [0xFF262626, 0xFF181818, 0xFFBEBEBE, 5, 0xFF191919, 2],
    [0xFF2F2F2F, 0xFF181818, 0xFFBEBEBE, 5, 0xFF191919, 2],
    [0xFF626262, 0xFF474747, 0xFFBEBEBE, 5, 0xFF191919, 2]]

ButtonStyles["reset"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
    [0xFFFF4444, 0xFFCC0000, 0xFFFFFFFF, 3, 0xFFCC0000, 2],
    [0xFFFF6666, 0xFFFF0000, 0xFFFFFFFF, 3, 0xFFFF0000, 2],
    [0xFF1b1b1b, 0xFF474747, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["to_settings"] := [[0xFF171717, 0xFF1A1A1A, 0xFFFFFFFF, 0, 0xFF1A1A1A, 1],
    [0xFF262626, 0xFF1A1A1A, 0xFFFFFFFF, 0, 0xFF1A1A1A, 1],
    [0xFF2F2F2F, 0xFF1A1A1A, 0xFFFFFFFF, 0, 0xFF1A1A1A, 1],
    [0xFF626262, 0xFF474747, 0xFFFFFFFF, 0, 0xFF474747, 1]]

ButtonStyles["secondary"] := [[0xFF6C757D, 0xFF5A6268, 0xFFFFFFFF, 3, 0xFF5A6268, 1],
    [0xFF5A6268, 0xFF4E555B, 0xFFFFFFFF, 3, 0xFF4E555B, 1],
    [0xFF808B96, 0xFF6C757D, 0xFFFFFFFF, 3, 0xFF6C757D, 1],
    [0xFFA0ACB8, 0xFF808B96, 0xFFFFFFFF, 3, 0xFF808B96, 1]]

UseGDIP()
LogAdd("[status] GDIP")

FontSize := Settings["FontSize"]
Font := Settings["Font"]
SettingsUI := GuiExt("", "AHK | Hospital v2 ")
SettingsUI.SetFont("cWhite s" FontSize, Font)
SettingsUI.BackColor := 0x171717
SettingsUI.OnEvent('Size', UpdateScrollBars.Bind(SettingsUI))
CreateImageButton("SetDefGuiColor", 0x171717)

SBT01 := SettingsUI.AddButton("xm+3 y+6 w180 h36 0x100 vSBT01 x6", "  " Chr(0xE10F) "   Home")
SBT01.OnEvent("Click", SettingsTabSelect)
CreateImageButton(SBT01, 0, ButtonStyles["tab"]*)

SBT02 := SettingsUI.AddButton("xm+3 y+4 w180 h36 0x100 vSBT02 x6", "  " Chr(0xE138) "   Bind")
SBT02.OnEvent("Click", SettingsTabSelect)
CreateImageButton(SBT02, 0, ButtonStyles["tab"]*)

SBT03 := SettingsUI.AddButton("xm+3 y+4 w180 h36 0x100 vSBT03 x6", "  " Chr(0xE115) "   Options")
SBT03.OnEvent("Click", SettingsTabSelect)
CreateImageButton(SBT03, 0, ButtonStyles["tab"]*)

SBT04 := SettingsUI.AddButton("xm+3 y308 w180 h36 0x100 vSBT04 x6", "  " Chr(0xE10C) "   Information")
SBT04.OnEvent("Click", SettingsTabSelect)
CreateImageButton(SBT04, 0, ButtonStyles["tab"]*)

GitHubOpen(Element, *) {
    Run("https://github.com/Agzes/AHK-FOR-RPM")
}

SBTB02 := SettingsUI.AddButton("xm+3 y268 w56 h36 0x100 Center vSBTB02 x6", Chr(0xE1CF)) ; github
SBTB02.OnEvent("Click", GitHubOpen)
CreateImageButton(SBTB02, 0, ButtonStyles["tab"]*)
ReloadFromUI(Element, *) {
    Reload()
}
SBTB03 := SettingsUI.AddButton("xm+3 y268 w56 h36 0x100 Center vSBTB03 x+6", Chr(0xE117)) ; reload
SBTB03.OnEvent("Click", ReloadFromUI)
CreateImageButton(SBTB03, 0, ButtonStyles["tab"]*)

SBTB04 := SettingsUI.AddButton("xm+3 y268 w56 h36 0x100 Center vSBTB04 x+6", Chr(0xE103)) ; pause/play
CreateImageButton(SBTB04, 0, ButtonStyles["tab"]*)

AddFixedElement(SBT01)
AddFixedElement(SBT02)
AddFixedElement(SBT03)
AddFixedElement(SBT04)
AddFixedElement(SBTB02)
AddFixedElement(SBTB03)
AddFixedElement(SBTB04)


STB := SettingsUI.AddButton("x192 y6 w442 h338 0x100 vSTB Disabled", "")
CreateImageButton(STB, 0, ButtonStyles["fake_for_group"]*)

STB1 := SettingsUI.AddButton("x192 y6 w431 h1349 0x100 vSTB1 Disabled Hidden", "")
CreateImageButton(STB1, 0, ButtonStyles["fake_for_group"]*)


SettingsUI.SetFont("cWhite s" 13, Font)
SMP_GREETINGS := SettingsUI.AddText("x194 y44 w438 h30 +Center", "Hello, " UserName "!")

SettingsUI.SetFont("cGray s" 8, Font)
SMP_VERSION := SettingsUI.AddText("x338 y325", "AHK-FOR-RPM: v2.0" ' I ' "RP: v2.0.0")
SettingsUI.SetFont("cWhite s" FontSize - 1, Font)

LogAdder() {
    for i in logs {
        SMP_LOGS.add("", i)
    }
}

SMP_LOGS := SettingsUI.AddListView("x198 y104 w452 h240", [""])
SMP_LOGS.SetRounded(3)
SMP_LOGS.add("", "")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "                                      AHK_FOR_RPM V2")
SMP_LOGS.add("", "                                             by Agzes")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "                                 ⬇️ scroll for logs⬇️")
SMP_LOGS.add("", "")
SMP_LOGS.add("", "")
LogAdder()

WaitForBind(Options := "T5")
{
    LogSent("[info] [bind-sys] I'm waiting for the connection...")
    global ih := InputHook(Options)
    if !InStr(Options, "V")
        ih.VisibleNonText := false
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ih.Wait()
    LogSent("[info] [bind-sys] combination obtained: " StrReplace(StrReplace(ih.EndMods . ih.EndKey, "<", ""), ">", ""))
    return StrReplace(StrReplace(ih.EndMods . ih.EndKey, "<", ""), ">", "")
}

LogSent(Text) {
    SMP_LOGS.add("", Text)
}

SaveBindCfg() {
    index := 1
    for i in BindHwnd {
        el := GuiCtrlFromHwnd(i)
        IniWrite(HotkeyToBind(el.Text), "settings.ini", "Binds", index)
        index++
    }
}

CurrentBindsRecords := ""
BindHotkey(BtnObj) {
    global CurrentBindsRecords
    BtnObj.Text := Chr(0xE15B)
    CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_hotkey"]*)
    CurrentBindsRecords := BtnObj.Hwnd
    tbind := WaitForBind()
    if tbind != "" {
        tt := StrReplace(BtnObj.Name, "EBIND_", "")
        G_Binds[tt] := tbind
        ttt := BindHwnd[tt]
        ttt := GuiCtrlFromHwnd(ttt)
        ttt.Text := BindToHotkey(tbind)
        SaveBindCfg()
    }
    BtnObj.Text := Chr(0xE104)
    CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_hotkey"]*)
    CurrentBindsRecords := ""
}

BindHotkeyButton(BtnObj, *) {
    global CurrentBindsRecords
    if CurrentBindsRecords == "" {
        BindHotkey(BtnObj)
    } else {
        MsgBox("You are already entering something...`nWait 5 seconds...", "Information")
    }
}

BindHotkeyInput(CtrlElement, *) {
    tt := StrReplace(CtrlElement.Name, "BIND_", "")
    G_Binds[tt] := HotkeyToBind(CtrlElement.Text)
    SaveBindCfg()
}

ImportBinds(Element, *) {
    LogSent("[info] [bind-sys] [import] > start")
    PathToFile := FileSelect("", "Hospital_cfg.txt", "Importing a configuration file", "AHK_FOR_RPM Config file (*.txt*)")
    if !FileExist(PathToFile)
        MsgBox("Configuration file not found!")
    else {
        CfgDatas := FileRead(PathToFile, "UTF-8")
        global G_Binds := StrSplit(CfgDatas, A_Space)
        temp := 0
        for i in G_Binds {
            if i != "" {
                temp += 1
                temp1 := GuiCtrlFromHwnd(BindHwnd[temp])
                temp1.Text := BindToHotkey(i)
            }
        }
        LogSent("[info] [bind-sys] [import] > imported")
    }
}
ResetBinds(Element, *) {
    global G_Binds := R_G_Binds
    temp := 0
    for i in G_Binds {
        temp += 1
        temp1 := GuiCtrlFromHwnd(BindHwnd[temp])
        temp1.Text := BindToHotkey(i)
    }
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

LogSent("[info] Loading the bind configurator")

SBP_LABEL := SettingsUI.AddText("Hidden x194 y13 w420 h20 +Center", Chr(0xE138) " Binds Configurator")

SettingsUI.SetFont("cWhite s" FontSize - 1, Font)
temp_for_bind_init := 0
BindItems := []
BindHwnd := []
for bind in G_Binds {
    temp_for_bind_init += 1
    t := SettingsUI.AddButton("Hidden x198 y+3 w25 h25 vEBIND_" temp_for_bind_init " ", Chr(0xE104))
    t.OnEvent("Click", BindHotkeyButton)
    CreateImageButton(t, 0, ButtonStyles["fake_for_hotkey"]*)
    BindItems.Push(t.Hwnd)
    t := SettingsUI.AddButton("Hidden x226 y" t.Y " w116 h25 Disabled")
    CreateImageButton(t, 0, ButtonStyles["fake_for_hotkey"]*)
    BindItems.Push(t.Hwnd)
    t := SettingsUI.AddEdit("Hidden x226 y" t.Y " w116 h25 vBIND_" temp_for_bind_init " ", "")
    BindHwnd.Push(t.Hwnd)
    BindItems.Push(t.Hwnd)
    t.OnEvent("Change", BindHotkeyInput)
    t.OnEvent("Focus", HideCode)
    t.OnEvent("LoseFocus", ShowCode)
    t.SetRounded(7)
    t.Value := BindToHotkey(bind)
    t := SettingsUI.AddButton("Hidden Left w272 h25 x345 Disabled y" t.Y " vTBIND_" temp_for_bind_init " ", "  " G_Binds_Name[temp_for_bind_init])
    CreateImageButton(t, 0, ButtonStyles["fake_for_hotkey"]*)
    BindItems.Push(t.Hwnd)
}

SBP_Import := SettingsUI.AddButton("Hidden x198 h30 w155 y+10 ", Chr(0xE118) "  Import")
CreateImageButton(SBP_Import, 0, ButtonStyles["fake_for_hotkey"]*)
SBP_Import.OnEvent("Click", ImportBinds)

SBP_Export := SettingsUI.AddButton("Hidden x359 h30 w155 y" SBP_Import.Y, Chr(0xE11C) "  Export")

SBP_Reset := SettingsUI.AddButton("Hidden x520 h30 w97 y" SBP_Import.Y, Chr(0xE149) " Сброс")
CreateImageButton(SBP_Reset, 0, ButtonStyles["reset"]*)
SBP_Reset.OnEvent("Click", ResetBinds)

LogSent("[info] Launch ScrollBar")
OnMessage(WM_VSCROLL, OnScroll)

SSP_LABEL := SettingsUI.AddText("Hidden x194 y13 w437 h20 +Center", Chr(0xE115) " Options/Settings")

SSP_PANEL_1 := SettingsUI.AddButton("Hidden x198 y+5 w213 h200 0x100 Disabled", "")
CreateImageButton(SSP_PANEL_1, 0, ButtonStyles["fake_for_group"]*)

SSP_PANEL_2 := SettingsUI.AddButton("Hidden x415 y" SSP_PANEL_1.Y " w213 h200 0x100 Disabled", "")
CreateImageButton(SSP_PANEL_2, 0, ButtonStyles["fake_for_group"]*)

SSP_PANEL_3 := SettingsUI.AddButton("Hidden x198 y+3 w430 h97 0x100 Disabled", "")
CreateImageButton(SSP_PANEL_3, 0, ButtonStyles["fake_for_group"]*)

SSP_P1_USERNAME_LABEL := SettingsUI.AddText("Hidden x203 y50", Chr(0xE13D) " NickName ↴")
SSP_P1_USERNAME_BG := SettingsUI.AddButton("Hidden x203 y70 Disabled w203 h25", "")
CreateImageButton(SSP_P1_USERNAME_BG, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P1_USERNAME := SettingsUI.AddEdit("Hidden x203 y70 w203", UserName)
SSP_P1_USERNAME.SetRounded(3)

SSP_P1_NAME_LABEL := SettingsUI.AddText("Hidden x203 y97", Chr(0xE136) "RP First Name Last Name ↴")
SSP_P1_NAME_BG := SettingsUI.AddButton("Hidden x203 y117 Disabled w203 h25", "")
CreateImageButton(SSP_P1_NAME_BG, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P1_NAME := SettingsUI.AddEdit("Hidden x203 y117 w203", Name)
SSP_P1_NAME.SetRounded(3)

SSP_P1_ROLE_LABEL := SettingsUI.AddText("Hidden x203 y144", Chr(0xE181) " Position ↴")
SSP_P1_ROLE_BG := SettingsUI.AddButton("Hidden x203 y164 Disabled w203 h25", "")
CreateImageButton(SSP_P1_ROLE_BG, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P1_ROLE := SettingsUI.AddEdit("Hidden x203 y164 w203", Role)
SSP_P1_ROLE.SetRounded(3)

SSP_P1_SAVEBUTTON := SettingsUI.AddButton("Hidden x203 y200 w203 h33 Center", Chr(0xe222) " Save")
SSP_P1_SAVEBUTTON.OnEvent("click", SaveSettingsForUSERDATA)
CreateImageButton(SSP_P1_SAVEBUTTON, 0, ButtonStyles["fake_for_hotkey"]*)


UiMethodList := ["WinActivate [`"Minecarft`"] (" Chr(0xE113) ")", "WinActivate [`"javaw.exe`"] (" Chr(0xE113) ")", "MouseClick (Old)"]
SSP_P2_UIMETHOD_LABEL := SettingsUI.AddText("Hidden x420 y50", Chr(0xE12A) " Game Focus Method ↴")
SSP_P2_UIMETHOD_BG := SettingsUI.AddButton("Hidden x420 y70 Disabled w203 h25 Left", "  ᐁ I " UiMethodList[FocusMethod])
CreateImageButton(SSP_P2_UIMETHOD_BG, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_UIMETHOD := SettingsUI.AddDropDownList("Hidden x420 y70 w203 +0x4000000", UiMethodList)
SSP_P2_UIMETHOD.OnEvent("Change", DropDownListWorker)
SSP_P2_UIMETHOD.Text := UiMethodList[FocusMethod]

ShowInformationESC(Element, *) {
    MsgBox "Press ESC`n`nUsed to prevent`n the start of playback on the game menu`n`nDefault -> ON"
}
ShowInformationCHECK(Element, *) {
    MsgBox "Check the open game`n`nBefore starting playback`n checks whether the game is running`n`nDefault -> OFF"
}
ShowInformationLIMIT(Element, *) {
    MsgBox "Limit hotkey`n`nLimits the maximum number of simultaneous hotkey`n enable if hotkey is launched twice`n`nDefault -> OFF"
}
ShowInformationSTATUS(Element, *) {
    MsgBox "Show status`n`nShows the status of wagering progress`n the progress of wagering is shown at the top of the screen`n`nDefault -> ON"
}

ShowInformationUPDATE(Element, *) {
    MsgBox "Auto-check for updates`n`nAutomatically checks for notifications`n checks for updates at startup`n`nDefault -> ON"
}


DropDownListWorker(Element, *) {
    SSP_P2_UIMETHOD_BG.Text := "  ᐁ I " UiMethodList[Element.Value]
    CreateImageButton(SSP_P2_UIMETHOD_BG, 0, ButtonStyles["fake_for_hotkey"]*)
    SaveSettingsForDATA(Element)
}

SaveSettingsForDATA(Element, *) {
    try {
        IniWrite(SSP_P2_UIMETHOD.Value, "settings.ini", "UserData", "FocusMethod")
        IniWrite(SSP_P2_ESCNEED.Value, "settings.ini", "UserData", "BeforeEsc")
        IniWrite(SSP_P2_CHECKNEED.Value, "settings.ini", "UserData", "BeforeCheck")
        IniWrite(SSP_P2_LIMIT.Value, "settings.ini", "UserData", "BeforeLimit")
        IniWrite(SSP_P2_STATUS.Value, "settings.ini", "UserData", "ShowStatus")
        IniWrite(SSP_P2_UPDATE.Value, "settings.ini", "UserData", "UpdateCheck")
        MsgBox("Data saved successfully!`nRestart to apply")
    } catch Error as e {
        MsgBox("Error while saving!")
    }
}

SSP_P2_BEFORERP_LABEL := SettingsUI.AddText("Hidden x420 y97", Chr(0xE102) "Before wagering ↴")

SGW := SysGet(SM_CXMENUCHECK := 71)
SGH := SysGet(SM_CYMENUCHECK := 72)
SSP_P2_ESCNEED := SettingsUI.AddCheckBox("Hidden x420 y117 Checked h" SGH " w" SGW)
SSP_P2_ESCNEED_TEXT := SettingsUI.AddText("Hidden x434 y115 0x200 h" SGH, " Press ESC")
SSP_P2_ESCNEED_HELP := SettingsUI.AddButton("Hidden x600 y117 h17 w17", "?")
SSP_P2_ESCNEED_HELP.OnEvent("Click", ShowInformationESC)
CreateImageButton(SSP_P2_ESCNEED_HELP, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_ESCNEED.OnEvent("Click", SaveSettingsForDATA)
SSP_P2_ESCNEED.Value := BeforeEsc

SGW2 := SysGet(SM_CXMENUCHECK := 71)
SGH2 := SysGet(SM_CYMENUCHECK := 72)
SSP_P2_CHECKNEED := SettingsUI.AddCheckBox("Hidden x420 y137 h" SGH2 " w" SGW2)
SSP_P2_CHECKNEED_TEXT := SettingsUI.AddText("Hidden x434 y135 0x200 h" SGH2, "Check open game")
SSP_P2_CHECKNEED_HELP := SettingsUI.AddButton("Hidden x600 y137 h17 w17", "?")
SSP_P2_CHECKNEED_HELP.OnEvent("Click", ShowInformationCHECK)
CreateImageButton(SSP_P2_CHECKNEED_HELP, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_CHECKNEED.OnEvent("Click", SaveSettingsForDATA)
SSP_P2_CHECKNEED.Value := BeforeCheck

SGW3 := SysGet(SM_CXMENUCHECK := 71)
SGH3 := SysGet(SM_CYMENUCHECK := 72)
SSP_P2_LIMIT := SettingsUI.AddCheckBox("Hidden x420 y157 h" SGH3 " w" SGW3)
SSP_P2_LIMIT_TEXT := SettingsUI.AddText("Hidden x434 y155 0x200 h" SGH3, " Limit hotkey")
SSP_P2_LIMIT_HELP := SettingsUI.AddButton("Hidden x600 y157 h17 w17", "?")
SSP_P2_LIMIT_HELP.OnEvent("Click", ShowInformationLIMIT)
CreateImageButton(SSP_P2_LIMIT_HELP, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_LIMIT.OnEvent("Click", SaveSettingsForDATA)
SSP_P2_LIMIT.Value := BeforeLimit

SSP_P2_OTHER := SettingsUI.AddText("Hidden x420 y177", Chr(0xE14C) "Other ↴")

SGW4 := SysGet(SM_CXMENUCHECK := 71)
SGH4 := SysGet(SM_CYMENUCHECK := 72)
SSP_P2_STATUS := SettingsUI.AddCheckBox("Hidden x420 y197 Checked h" SGH4 " w" SGW4)
SSP_P2_STATUS_TEXT := SettingsUI.AddText("Hidden x434 y195 0x200 h" SGH4, " Show rp status")
SSP_P2_STATUS_HELP := SettingsUI.AddButton("Hidden x600 y197 h17 w17", "?")
SSP_P2_STATUS_HELP.OnEvent("Click", ShowInformationSTATUS)
CreateImageButton(SSP_P2_STATUS_HELP, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_STATUS.OnEvent("Click", SaveSettingsForDATA)
SSP_P2_STATUS.Value := ShowStatus

SGW5 := SysGet(SM_CXMENUCHECK := 71)
SGH5 := SysGet(SM_CYMENUCHECK := 72)
SSP_P2_UPDATE := SettingsUI.AddCheckBox("Hidden x420 y217 Checked h" SGH4 " w" SGW4)
SSP_P2_UPDATE_TEXT := SettingsUI.AddText("Hidden x434 y215 0x200 h" SGH4, "Auto-check for updates")
SSP_P2_UPDATE_HELP := SettingsUI.AddButton("Hidden x600 y217 h17 w17", "?")
SSP_P2_UPDATE_HELP.OnEvent("Click", ShowInformationUPDATE)
CreateImageButton(SSP_P2_UPDATE_HELP, 0, ButtonStyles["fake_for_hotkey"]*)
SSP_P2_UPDATE.OnEvent("Click", SaveSettingsForDATA)
SSP_P2_UPDATE.Value := UpdateCheck

SettingsUI.SetFont("cWhite s" FontSize + 3, Font)
SSP_P3_STATS := SettingsUI.AddText("Hidden x287 y266", Chr(0xE10C) "")
SettingsUI.SetFont("cWhite s" FontSize - 3, Font)
SSP_P3_DESC := SettingsUI.AddText("Hidden x231 y290 w130 Center", "\(ᵔ•ᵔ)/")
SettingsUI.SetFont("cWhite s" FontSize - 1, Font)
SSP_P3_BUTTON := SettingsUI.AddButton("Hidden x430 y275", "Check for updates")
CreateImageButton(SSP_P3_BUTTON, 0, ButtonStyles["fake_for_hotkey"]*)


ToDev(Element, *) {
    Run("https://e-z.bio/agzes")
}

ToMessage(Element, *) {
    Run("https://discord.com/users/695827097024856124")
}
ToGitHub(Element, *) {
    Run("https://github.com/Agzes/AHK-FOR-RPM")
}

SettingsUI.SetFont("cWhite s" FontSize + 8, Font)
SOP_LABEL := SettingsUI.AddText("Hidden x203 y114 w200 h30 ", "AHK-FOR-RPM")
SettingsUI.SetFont("cWhite s" FontSize - 1, Font)
SOP_LABEL2 := SettingsUI.AddText("Hidden x203 y144 w200 h30 ", "V2 by Agzes")


SOP_DEV := SettingsUI.AddButton("Hidden x198 h30 w155 y308 ", Chr(0xE13D) "  Developer")
CreateImageButton(SOP_DEV, 0, ButtonStyles["fake_for_hotkey"]*)
SOP_DEV.OnEvent("Click", ToDev)

SOP_CONTACT := SettingsUI.AddButton("Hidden x359 h30 w155 y308 ", Chr(0xE136) "  Contact")
CreateImageButton(SOP_CONTACT, 0, ButtonStyles["fake_for_hotkey"]*)
SOP_CONTACT.OnEvent("Click", ToMessage)

SOP_GITHUB := SettingsUI.AddButton("Hidden x520 h30 w107 y308 ", Chr(0xE136) "  GitHub")
CreateImageButton(SOP_GITHUB, 0, ButtonStyles["fake_for_hotkey"]*)
SOP_GITHUB.OnEvent("Click", ToGitHub)

LogSent("[status] Interface initialized")

isScrollBarActive() {
    if WinActive(SettingsUI) {
        if ScrollActive {
            return true
        }
    }
    return false
}

LogSent("[info] running additional interface scripts")
A_HotkeyInterval := 2000
A_MaxHotkeysPerInterval := 50
#HotIf isScrollBarActive()
WheelUp::
WheelDown:: {
    Loop 10 {
        SendMessage WM_VSCROLL, A_ThisHotkey ~= 'Up' ? SB_LINEUP : SB_LINEDOWN, , , SettingsUI
    }
}

LogSent("[info] configuring interface data")
MainPage := [SMP_GREETINGS, SMP_VERSION, SMP_LOGS]
BindsPage := [SBP_LABEL, SBP_Import, SBP_Export, SBP_Reset]
SettingsPage := [SSP_LABEL, SSP_PANEL_1, SSP_PANEL_2, SSP_PANEL_3, SSP_P1_NAME, SSP_P1_NAME_BG, SSP_P1_NAME_LABEL, SSP_P1_ROLE, SSP_P1_ROLE_BG, SSP_P1_ROLE_LABEL, SSP_P1_SAVEBUTTON, SSP_P1_USERNAME, SSP_P1_USERNAME_BG, SSP_P1_USERNAME_LABEL, SSP_P2_BEFORERP_LABEL, SSP_P2_CHECKNEED, SSP_P2_CHECKNEED_HELP, SSP_P2_CHECKNEED_TEXT, SSP_P2_ESCNEED, SSP_P2_ESCNEED_HELP, SSP_P2_CHECKNEED_TEXT, SSP_P2_LIMIT, SSP_P2_LIMIT_HELP, SSP_P2_LIMIT_TEXT, SSP_P2_STATUS, SSP_P2_STATUS_HELP, SSP_P2_STATUS_TEXT, SSP_P2_UIMETHOD, SSP_P2_UIMETHOD_BG, SSP_P2_UIMETHOD_LABEL, SSP_P2_UPDATE, SSP_P2_UPDATE_HELP, SSP_P2_UPDATE_TEXT, SSP_P3_BUTTON, SSP_P3_DESC, SSP_P3_STATS, SSP_P2_ESCNEED_TEXT, SSP_P2_OTHER]
OtherPage := [SOP_CONTACT, SOP_DEV, SOP_GITHUB, SOP_LABEL, SOP_LABEL2]

LogSent("[info] applying attributes and theme to window")
SetWindowAttribute(SettingsUI)
SetWindowTheme(SettingsUI)
SetWindowColor(SettingsUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
LogSent("[info] showing the interface")
SettingsUI.Show("h350 w640")
RemoveScrollBar(SettingsUI)

; STATUS BAR
global SBMaximum := 0
global SBMaximumForOne := 0
global CurrentProgress := 0

StatusUI := GuiExt("+AlwaysOnTop -Caption", "AHK | Status")
StatusUI.BackColor := "0"
WinSetTransColor(0, StatusUI.Hwnd)
ProgressBar := StatusUI.AddProgress("w300 h32 x0 y0 Background171717 c636363")
ProgressBar.Value := 0
ProgressBar.SetRounded(6)

ShowStatusBar(Element?, *) {
    StatusUI.Show("w300 h32 NA")
    Sleep(100)
    screenWidth := A_ScreenWidth
    x := (screenWidth - StatusUI.W) / 2
    StatusUI.Move(x, 2)
}

SetMStatusBar(MaxSteps?, *) {
    global SBMaximum := MaxSteps
    global SBMaximumForOne := 100 / MaxSteps
    global CurrentProgress := 0
    ProgressBar.Value := 0
}

SetNStatusBar(Step?, *) {
    global CurrentProgress
    if !SBMaximum
        return

    targetProgress := SBMaximumForOne * Step

    loop {
        if CurrentProgress < targetProgress {
            global CurrentProgress += 1
        } else if CurrentProgress > targetProgress {
            break
        } else {
            break
        }

        ProgressBar.Value := CurrentProgress
        Sleep(5)
    }
}

HideStatusBar(Element?, *) {
    StatusUI.Hide()
    global SBMaximum := 0
    global SBMaximumForOne := 0
    global CurrentProgress := 0
    ProgressBar.Value := 0
}

; {RP ELEMENTS}

hide_ui(Element?, *) {
    temp := false
    if WinExist("AHK | Hospital v2") {
        temp := true
    }
    MainBindUI.Hide()
    EducBindUI.Hide()
    RareBindUI.Hide()
    PMPBindUI.Hide()
    MenuUI.Hide()
    Sleep(100)
    if FocusMethod = 1 {
        if WinExist("Minecraft") {
            WinShow("Minecraft")
            WinActivate("Minecraft")
        }
    } else if FocusMethod = 2 {
        if WinExist("ahk_exe javaw.exe") {
            WinShow("ahk_exe javaw.exe")
            WinActivate("ahk_exe javaw.exe")
        }
    } else {
        MouseClick("Left")
    }
    Sleep(100)
    if BeforeEsc and !temp {
        SendInput("{Esc}")
    }
}
greetings(Element?, *)
{
    hide_ui()
    if BeforeCheck {
        if !WinActive("ahk_exe javaw.exe") and !WinActive("Minecraft") {
            return 0
        }
    }
    SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(100)
    SendInput("Hello, how can I help you? {ENTER}")
    Return
}

MainBindUI := GuiExt("", "AHK | Hospital v2 ")
MainBindUI.SetFont("cWhite s" FontSize - 1, Font)
MainBindUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

MainBindUI.AddText("w250 x5 +Center", "\^o^/")

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Welcome")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Pass tablet")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Sell honey")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Bruise")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Ammonia")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Injection")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Med. Card")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Extract from ward 6")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Med. Exam")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := MainBindUI.AddButton("w250 h30 y+5 x5", "Professional suitability")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)


SetWindowAttribute(MainBindUI)
SetWindowColor(MainBindUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
mainbindsy := t.y + 35
; MainBindUI.Show("w260 h" mainbindsy)


RareBindUI := GuiExt("", "AHK | Hospital v2 ")
RareBindUI.SetFont("cWhite s" FontSize - 1, Font)
RareBindUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

t := RareBindUI.AddButton("w123 h30 y+5 x5", "Knife")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y" t.Y " x133", "Bullet")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y+5 x5", "Stretcher")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y" t.Y " x133", "Dropper")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Defibrillator")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Twist + soothing injection")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Calming injection")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Plastic surgery")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Taking blood for analysis (in a test tube)")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Treat and stitch the wound")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Bullet removal operation")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Closed fracture")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w250 h30 y+5 x5", "Open fracture")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y+5 x5", "X-ray")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y" t.Y " x133", "Dislocation")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y+5 x5", "CPR")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := RareBindUI.AddButton("w123 h30 y" t.Y " x133", "ECG")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)


SetWindowAttribute(RareBindUI)
SetWindowColor(RareBindUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
rarebindy := t.y + 35
; RareBindUI.Show("w260 h" rarebindy)


EducBindUI := GuiExt("", "AHK | Hospital v2 ")
EducBindUI.SetFont("cWhite s" FontSize - 1, Font)
EducBindUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

EducBindUI.AddText("w250 x5 +Center", "\(ᵔ•ᵔ)/")

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Lecture to intern")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Charter [1/4] | `"Are you ready?`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Charter [3/4] | `"3 charters`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Charter [3/4] | `"3 terms`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Charter [4/4] | `"You passed.`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Oath [1/2] | `"Are you ready?`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Oath [2/2] | `"You gave...`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Orders | 3 orders (auto)")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Practice [1/2] | Roleplaying")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := EducBindUI.AddButton("w250 h30 y+5 x5", "Practice [2/2] | `"You passed`"")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

SetWindowAttribute(EducBindUI)
SetWindowColor(EducBindUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
educbindy := t.y + 35
; EducBindUI.Show("w260 h" educbindy)


open_settings_ui(Element?, *) {
    SettingsUI.Show("h350 w640")
}
open_pmp_window(Element?, *) {
    pmpbindy := t.Y + 35
    PMPBindUI.Show("w260 h" pmpbindy)
}

MenuUI := GuiExt("", "AHK | Hospital v2 ")
MenuUI.SetFont("cWhite s" FontSize - 1, Font)
MenuUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

MenuUI.AddText("w250 x5 +Center", "(. ❛ ᴗ ❛.)")

t := MenuUI.AddButton("w250 h30 y+5 x5", "open menu")
CreateImageButton(t, 0, ButtonStyles["fake_for_hotkey"]*)
t.OnEvent("Click", open_settings_ui)

t := MenuUI.AddButton("w250 h30 y+5 x5", "pmp")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", open_pmp_window)

menu_restart := MenuUI.AddButton("w250 h30 y+5 x5", Chr(0xE117))
CreateImageButton(menu_restart, 0, ButtonStyles["binds"]*)
menu_restart.OnEvent("Click", ReloadFromUI)

menu_stopstart := MenuUI.AddButton("w250 h30 y+5 x5", Chr(0xE103))
CreateImageButton(menu_stopstart, 0, ButtonStyles["binds"]*)

SetWindowAttribute(MenuUI)
SetWindowColor(MenuUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
mainbindy := menu_stopstart.Y + 35
; MenuUI.Show("w260 h" mainbindy)


PMPBindUI := GuiExt("", "AHK | Hospital v2 ")
PMPBindUI.SetFont("cWhite s" FontSize - 1, Font)
PMPBindUI.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

PMPBindUI.AddText("w250 x5 +Center", "pmp")

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Dislocation")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Closed fracture")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Open fracture")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Bullet wound")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Knife with knife")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Knife without knife")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Bleeding: Arterial")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Concussion: check")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Heart attack")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Heart attack (shirt, belt)")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

t := PMPBindUI.AddButton("w250 h30 y+5 x5", "Epilepsy")
CreateImageButton(t, 0, ButtonStyles["binds"]*)
t.OnEvent("Click", greetings)

SetWindowAttribute(PMPBindUI)
SetWindowColor(PMPBindUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
pmpbindy := t.Y + 35
; PMPBindUI.Show("w260 h" pmpbindy)


MainBindUIopen(Element?, *) {
    MainBindUI.Show("w260 h" mainbindsy)
}
EducBindUIopen(Element?, *) {
    EducBindUI.Show("w260 h" educbindy)
}
RareBindUIopen(Element?, *) {
    RareBindUI.Show("w260 h" rarebindy)
}
MenuUIopen(Element?, *) {
    MenuUI.Show("w260 h" mainbindy)
}

SetHotKey(key, function) {
    if key != "" {
        HotKey(key, function)
    }
}

funcs := [MainBindUIopen, EducBindUIopen, RareBindUIopen, MenuUIopen, ReloadFromUI]
Loop 5
    SetHotKey(G_Binds[A_Index], funcs[A_Index])

Loop 38
    SetHotKey(G_Binds[A_Index + 6], greetings)

if BeforeLimit {
    A_HotkeyInterval := 1000
    A_MaxHotkeysPerInterval := 1
}