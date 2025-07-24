#Requires AutoHotkey v2.0
#SingleInstance Force

StructFromPtr(StructClass, Address) => StructClass(Address)

class NMCUSTOMDRAWINFO
{
    static Call(ptr)
    {
        RECT(left := 0, top := 0, right := 0, bottom := 0)
        {
            static ofst := Map("left", 0, "top", 4, "right", 8, "bottom", 12)
            buf := Buffer(16)
            NumPut("int", left, "int", top, "int", right, "int", bottom, buf)
            for k, v in ofst
                buf.DefineProp(k, {Get: NumGet.Bind(, v, "int"), Set: IntPut.Bind(v)})
            return buf
            IntPut(ofst, _, v) => NumPut("int", v, _, ofst)
        }

        return Map(
            "hdr", Map(
                "hwndFrom", NumGet(ptr, 0, "uptr"),
                "idFrom", NumGet(ptr, 8, "uptr"),
                "code", NumGet(ptr, 16, "int")
            ),
            "dwDrawStage", NumGet(ptr, 24, "uint"),
            "hdc", NumGet(ptr, 32, "uptr"),
            "rc", RECT(
                NumGet(ptr, 40, "uint"),
                NumGet(ptr, 44, "uint"),
                NumGet(ptr, 48, "int"),
                NumGet(ptr, 52, "int")
            ),
            "dwItemSpec", NumGet(ptr, 56, "uptr"),
            "uItemState", NumGet(ptr, 64, "int"),
            "lItemlParam", NumGet(ptr, 72, "iptr")
        )
    }
}

; Change from extending classes to using utility functions
class GuiUtils
{
    static HookMessage(guiObj, msg, callback, addRemove?)
    {
        _callback(wParam, lParam, uMsg, hWnd)
        {
            if (uMsg = msg && hWnd = guiObj.hwnd)
                return callback(guiObj, wParam, lParam, uMsg)
        }

        OnMessage(msg, _callback, addRemove?)
        guiObj.OnEvent("Close", g => OnMessage(msg, _callback, 0))
    }
}

class BtnUtils
{
    static SetBackColor(myBtn, btnBgColor, colorBehindBtn?, roundedCorner?)
    {
        static BS_FLAT          := 0x8000
        static BS_BITMAP        := 0x0080
        static IS_WIN11         := (VerCompare(A_OSVersion, "10.0.22200") >= 0)
        static WM_CTLCOLORBTN   := 0x0135
        static NM_CUSTOMDRAW    := -12
        static WM_DESTROY       := 0x0002
        static WS_EX_COMPOSITED := 0x02000000
        static WS_CLIPSIBLINGS  := 0x04000000

        rcRgn := ""
        clr := IsNumber(btnBgColor) ? btnBgColor : BtnUtils.ColorHex(btnBgColor)
        isDark := BtnUtils.IsColorDark(clr)
        hoverColor := BtnUtils.RgbToBgr(BtnUtils.BrightenColor(clr, isDark ? 15 : -15))
        pushedColor := BtnUtils.RgbToBgr(BtnUtils.BrightenColor(clr, isDark ? -10 : 10))
        clr := BtnUtils.RgbToBgr(clr)
        btnBkColr := (colorBehindBtn ?? 0) && BtnUtils.RgbToBgr(BtnUtils.ColorHex(myBtn.Gui.BackColor))
        hbrush := btnBkColr ? BtnUtils.CreateSolidBrush(btnBkColr) : BtnUtils.GetStockObject(5)

        myBtn.Gui.Opt("+" WS_CLIPSIBLINGS)
        GuiUtils.HookMessage(myBtn.Gui, WM_CTLCOLORBTN, ON_WM_CTLCOLORBTN)

        if btnBkColr
            myBtn.Gui.OnEvent("Close", (*) => BtnUtils.DeleteObject(hbrush))

        myBtn.Opt("+" (WS_CLIPSIBLINGS | BS_FLAT | BS_BITMAP))
        BtnUtils.SetWindowTheme(myBtn.hwnd, isDark ? "DarkMode_Explorer" : "Explorer")
        myBtn.OnNotify(NM_CUSTOMDRAW, ON_NM_CUSTOMDRAW)
        myBtn.Redraw()

        ON_WM_CTLCOLORBTN(GuiObj, wParam, lParam, Msg)
        {
            Critical(-1)

            if btnBkColr {
                BtnUtils.SelectObject(wParam, hbrush)
                BtnUtils.SetBkMode(wParam, 0)
                BtnUtils.SetBkColor(wParam, btnBkColr)
            }

            return hbrush 
        }

        ON_NM_CUSTOMDRAW(gCtrl, lParam)
        {
            static CDDS_PREPAINT        := 0x1
            static CDDS_PREERASE        := 0x3
            static CDIS_HOT             := 0x40
            static CDRF_NOTIFYPOSTPAINT := 0x10
            static CDRF_SKIPPOSTPAINT   := 0x100
            static CDRF_SKIPDEFAULT     := 0x4
            static CDRF_NOTIFYPOSTERASE := 0x40
            static CDRF_DODEFAULT       := 0x0
            static DC_BRUSH             := BtnUtils.GetStockObject(18)
            static DC_PEN               := BtnUtils.GetStockObject(19)
            
            Critical(-1)

            lpnmCD := StructFromPtr(NMCUSTOMDRAWINFO, lParam)

            if (lpnmCD["hdr"]["code"] != NM_CUSTOMDRAW || lpnmCD["hdr"]["hwndFrom"] != gCtrl.hwnd)
                return
            
            switch lpnmCD["dwDrawStage"] {
            case CDDS_PREERASE:
                {
                    if (roundedCorner ?? IS_WIN11) {
                        rcRgn := BtnUtils.CreateRoundRectRgn(lpnmCD["rc"].left, lpnmCD["rc"].top, lpnmCD["rc"].right, lpnmCD["rc"].bottom, roundedCorner ?? 9, roundedCorner ?? 9)
                        BtnUtils.SetWindowRgn(gCtrl.hwnd, rcRgn, 1)
                    }

                    BtnUtils.SetBkMode(lpnmCD["hdc"], 0)
                    return CDRF_NOTIFYPOSTERASE 
                }
            case CDDS_PREPAINT: 
                {
                    brushColor := (!(lpnmCD["uItemState"] & CDIS_HOT) ? clr : (GetKeyState("LButton", "P")) ? pushedColor : hoverColor)

                    BtnUtils.SelectObject(lpnmCD["hdc"], DC_BRUSH)
                    BtnUtils.SetDCBrushColor(lpnmCD["hdc"], brushColor)
                    
                    BtnUtils.SelectObject(lpnmCD["hdc"], DC_PEN)
                    BtnUtils.SetDCPenColor(lpnmCD["hdc"], gCtrl.Focused ? 0x1C1C1C : brushColor)

                    if gCtrl.Focused 
                        BtnUtils.DrawFocusRect(lpnmCD["hdc"], lpnmCD["rc"])

                    rounded := !!(rcRgn ?? 0)

                    BtnUtils.RoundRect(lpnmCD["hdc"], lpnmCD["rc"].left, lpnmCD["rc"].top, lpnmCD["rc"].right - rounded, lpnmCD["rc"].bottom - rounded, roundedCorner ?? 9, roundedCorner ?? 9)

                    if rounded {
                        BtnUtils.DeleteObject(rcRgn)
                        rcRgn := ""
                    }

                    return CDRF_NOTIFYPOSTPAINT 
                }
            }
            
            return CDRF_DODEFAULT
        }
    }

    static RgbToBgr(color) => (IsInteger(color) ? ((color >> 16) & 0xFF) | (color & 0x00FF00) | ((color & 0xFF) << 16) : Integer(RegExReplace(String(color), "Si)c?(?:0x)?(?<R>\w{2})(?<G>\w{2})(?<B>\w{2})", "0x${B}${G}${R}")))

    static CreateRoundRectRgn(nLeftRect, nTopRect, nRightRect, nBottomRect, nWidthEllipse, nHeightEllipse) => DllCall('Gdi32\CreateRoundRectRgn', 'int', nLeftRect, 'int', nTopRect, 'int', nRightRect, 'int', nBottomRect, 'int', nWidthEllipse, 'int', nHeightEllipse, 'ptr')

    static CreateSolidBrush(crColor) => DllCall('Gdi32\CreateSolidBrush', 'uint', crColor, 'ptr')

    static ColorHex(clr) => Number((!InStr(clr, "0x") ? "0x" : "") clr)

    static DrawFocusRect(hDC, lprc) => DllCall("User32\DrawFocusRect", "ptr", hDC, "ptr", lprc, "int")

    static GetStockObject(fnObject) => DllCall('Gdi32\GetStockObject', 'int', fnObject, 'ptr')

    static SetDCPenColor(hdc, crColor) => DllCall('Gdi32\SetDCPenColor', 'ptr', hdc, 'uint', crColor, 'uint')

    static SetDCBrushColor(hdc, crColor) => DllCall('Gdi32\SetDCBrushColor', 'ptr', hdc, 'uint', crColor, 'uint')

    static SetWindowRgn(hWnd, hRgn, bRedraw) => DllCall("User32\SetWindowRgn", "ptr", hWnd, "ptr", hRgn, "int", bRedraw, "int")

    static DeleteObject(hObject) => DllCall('Gdi32\DeleteObject', 'ptr', hObject, 'int')

    static FillRect(hDC, lprc, hbr) => DllCall("User32\FillRect", "ptr", hDC, "ptr", lprc, "ptr", hbr, "int")

    static IsColorDark(clr) => 
        ( (clr >> 16 & 0xFF) / 255 * 0.2126 
        + (clr >>  8 & 0xFF) / 255 * 0.7152 
        + (clr       & 0xFF) / 255 * 0.0722 < 0.5 )

    static RGB(R := 255, G := 255, B := 255) => ((R << 16) | (G << 8) | B)
    
    static BrightenColor(clr, perc := 5) => ((p := perc / 100 + 1), BtnUtils.RGB(Round(Min(255, (clr >> 16 & 0xFF) * p)), Round(Min(255, (clr >> 8 & 0xFF) * p)), Round(Min(255, (clr & 0xFF) * p))))

    static RoundRect(hdc, nLeftRect, nTopRect, nRightRect, nBottomRect, nWidth, nHeight) => DllCall('Gdi32\RoundRect', 'ptr', hdc, 'int', nLeftRect, 'int', nTopRect, 'int', nRightRect, 'int', nBottomRect, 'int', nWidth, 'int', nHeight, 'int')
    
    static SetTextColor(hdc, color) => DllCall("SetTextColor", "Ptr", hdc, "UInt", color)
    
    static SetWindowTheme(hwnd, appName, subIdList?) => DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "ptr", StrPtr(appName), "ptr", subIdList ?? 0)
    
    static SelectObject(hdc, hgdiobj) => DllCall('Gdi32\SelectObject', 'ptr', hdc, 'ptr', hgdiobj, 'ptr')
            
    static SetBkColor(hdc, crColor) => DllCall('Gdi32\SetBkColor', 'ptr', hdc, 'uint', crColor, 'uint')
    
    static SetBkMode(hdc, iBkMode) => DllCall('Gdi32\SetBkMode', 'ptr', hdc, 'int', iBkMode, 'int')
}

greetings(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(500)
    SendInput("Здравствуйте, чем я могу вам помочь? {ENTER}")
    Return
}

billboard(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(100)
    SendInput("/mee берёт валик весящий на куртке, окунывает валик в ведро с клеем, обмазывает билборд клеем, приклеивает объявление на билборд.{ENTER}")
    Sleep(300)
    SendInput("{t}")
    Sleep(100)
    SendInput("/billboard ")
    Return
}

lecture(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(100)
    SendInput("Для начала я проведу вам небольшую лекцию о запрещенных продажах {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(100)
    SendInput("Начнем {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(3000)
    SendInput("Продажа и покупка наркотиков запрещенна. Это по правилу 2.1 {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(3000)
    SendInput("/n Правильное оформление: Куплю зелёный чай(4). Куплю лечебные леденцы/сахарные конфеты(5) {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(6000)
    SendInput("Редактировать объявления о купле/продаже оружия запрещенно по правилу 2.2 {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(6000)
    SendInput("/n Правильное оформление: Куплю водный пистолет/деревянный макет пистолета/игрушечный пистолет/книгу о `"Название оружия`"  Продам строительную кувалду/лопату.  Куплю кухонный нож. Исключение: запрещено подававать объявления о донат-оружии {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(20000)
    SendInput("Редактировать объявления о купле/продаже cкинов запрещенно!. Правило 2.2.1 {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(6000)
    SendInput("/n Правильное оформление: Продам гравюру(6) на игрушечный `"Desert Eagle`"   Продам чехол(6) для кухонного ножа `"Тесак`" {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(6000)
    SendInput("Редактировать объявления о купле/продаже патронов запрещенно. Это - 2.3 {ENTER}")
    Sleep(100)
    SendInput("{t}")
    Sleep(6000)
    SendInput("/n Правильное оформление: Продам резиновые/пенопластовые/игрушечные/силиконовые/патроны {ENTER}")
    Return
}

back(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(850)
    SendInput("/mee взяв свои документы из рук человека напротив, кладёт их обратно в сумку, закрывает сумку.{ENTER}")
    Return
}

ad_edit(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(100)
    SendInput("/ad edit{ENTER}")
    Return
}

stahirovka(GuiObject?, eventInfo?) {
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(1000)
    SendInput("Рабочее время у нас с 9:00-19:00, обеденный перерыв 11:00-11:30.  Воскресенье выходной день.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("В рабочее время сотрудники должны находиться в радиоцентре.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("Обязательно соблюдение субординации, уважайте своих коллег.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("Старший состав должен помогать новичкам фракции и следить за составом в целом.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("Запрещено выпрашивать повышение и давать взятки.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("Стажировка окончена.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("/n F2 или же своё приложение для скриншота экрана{ENTER}")
    Return
}

lecua(GuiObject?, eventInfo?){
    hide_ui()
    ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
    SendInput("{t}")
    Sleep(1000)
    SendInput("С должности Редактор - вы имеете право редактировать объявления, писать статьи.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("С должности Журналист - вы обязаны брать интервью у граждан города, собирать информацию для её распространения.{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("С должности Репортёр - вы обязаны отправляться на место события и сообщать информацию старшему составу, делать репортажи{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("С должности Ведущий - вы обязаны проводить эфиры, следить за младшим составом, вы доверенный человек Директору{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("С должности Гл.Редактор - вы обязаны следить за редакцией объявлений, составом, вам доступно всё что и должностням ниже, вы правая рука Директора. {ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("Вы прослушали лекцию!{ENTER}")
    Sleep(1000)
    SendInput("{t}")
    Sleep(1000)
    SendInput("/n F2 или же своё приложение для скриншота экрана{ENTER}")
    Return
}

DirCreate(A_Temp . "\ahk-news")
cfg_file := A_Temp . "\ahk-news\config.cfg"
temp_file := A_Temp . "\ahk-news\tempp.cfg"

if !FileExist(temp_file){
    try {
        FileAppend("", temp_file, "utf-8")
    } catch Error as err {
        MsgBox("Error creating temp file: " . err.Message)
    }
}

temp_data := ""
cfg_data := ""

if FileExist(temp_file){
    try {
        temp_data := FileRead(temp_file)
    } catch Error as err {
        MsgBox("Error reading temp file: " . err.Message)
    }
}

if FileExist(cfg_file){
    try {
        cfg_data := FileRead(cfg_file)
    } catch Error as err {
        MsgBox("Error reading config file: " . err.Message)
    }
}

restart_ui(GuiObject?, eventInfo?)
{   
    try {
        FileAppend("restart", temp_file, "utf-8")
        Reload()
    } catch Error as e {
        MsgBox("Error restarting: " . e.Message)
    }
}

open_rp_termin(GuiObject?, eventInfo?)
{   
    Main.Hide()
    rp_termin.Show("AutoSize")
}

hide_ui()
{   
    If WinExist("AHK | RP Термины") or WinExist("AHK | Основное")
    {    
        Main.Hide()
        rp_termin.Hide()
        Sleep(100)
        MouseClick("Left")
        Sleep(100)
        ErrorLevel := SendMessage(0x50, , 0x4190419, , "A")
        Sleep(100)
        SendInput("{Esc}")
    } else {
        Sleep(1000)
    }
}

; Initialize GUI objects
Main := Gui()
Main.Title := "AHK | Основное"
Main.Opt("+AlwaysOnTop")
Main.BackColor := 0x1C1C1C
Main.Add("Text", "cWhite", "AHK | СМИ                                  By Agzes")

aq := Main.AddButton("w200 h20", "NumPad2 | Приветствие")
BtnUtils.SetBackColor(aq, 0x4e4e4e, 0x1C1C1C)
aq.OnEvent("Click", greetings)

a0 := Main.AddButton("w200 h20", 'NumPad3 | "/ad edit" ')
BtnUtils.SetBackColor(a0, 0x4e4e4e, 0x1C1C1C)
a0.OnEvent("Click", ad_edit)

az := Main.AddButton("w200 h20", "NumPad4 | Забрать документы")
BtnUtils.SetBackColor(az, 0x4e4e4e, 0x1C1C1C)
az.OnEvent("Click", back)

ab := Main.AddButton("w200 h20", "Объявление на билборд")
BtnUtils.SetBackColor(ab, 0x4e4e4e, 0x1C1C1C)
ab.OnEvent("Click", billboard)

a5 := Main.AddButton("w200 h20", "Лекция о запрещенных продажах")
BtnUtils.SetBackColor(a5, 0x4e4e4e, 0x1C1C1C)
a5.OnEvent("Click", lecture)

sta := Main.AddButton("w200 h20", "Стажировка")
BtnUtils.SetBackColor(sta, 0x4e4e4e, 0x1C1C1C)
sta.OnEvent("Click", stahirovka)

lec := Main.AddButton("w200 h20", "Лекция")
BtnUtils.SetBackColor(lec, 0x4e4e4e, 0x1C1C1C)
lec.OnEvent("Click", lecua) 

rpt := Main.AddButton("w200 h20", 'РП ТЕРМИНЫ')
BtnUtils.SetBackColor(rpt, 0x4e4e4e, 0x1C1C1C)
rpt.OnEvent("Click", open_rp_termin)

rp_termin := Gui()
rp_termin.Opt("+AlwaysOnTop")
rp_termin.Title := "AHK | RP Термины"
rp_termin.BackColor := 0x1C1C1C

rp_termin.AddText("cWhite","
(Ltrim join`r`n
OOC  ( НонРП чат ) - это все, что касается реального 
мира. (пишется /n текст)
IC ( Игровой/рп чат ) - это все, что касается 
виртуального мира, то есть игры. (пишется в обычный чат)

ДМ - Убийство без причины.
СК- Спавн килл, т.е. убийство при появлении.
ТК- "Team Kill" - Убийство своих.
РП- "Role Play"- Игра по ролям где каждый 
должен соблюдать свою роль.
МГ- "Meta Gaming" - Использование информации 
из реального мира в игровой
ПГ- "Power Gaming" - Изображение из себя героя. 
(Например когда у тебя нет оружия и ты идешь на 
человека у которого оно есть , или например драка 
5 против одного.)
РК- Возвращение на место где тебя убили.
ЗЗ- "Зеленая Зона". Общественные места-площадь у 
мэрии, вокзалы, больницы и т.п. (В этой зоне запрещено 
стрелять, наносить вред)
БЮ - Багаюз. Использование багов сервера или плагина 
в личных целях, прохождениях преград
FearRP - боязнь смерти. Вы должны отыгрывать боязнь смерти.
ДБ (Damage Bikes) - наносить урон с машин. 
LeaveRP - выйти с сервера во время любой РП ситуации.
FunRP - неадекватные отыгровки
Non Role Play ( NonRp/НонРП ) - действие, которое персонаж 
не смог бы совершить в реальной жизни.

НПРА-Нарушения Правил Рейда Авианосца
НППГ-Нарушения Правил Посещения Гетто
НПО - Нарушение правил ограбления
НПОБ-нарушение правил ограбления банка
НППС-Нарушения правил поведения суда
НПКСК - Нарушения правила капта убийства при появлении 
ЦК - Убийство своего РП перса
УБП - угроза безопасности проекта
НПП - Нарушения правил похищений.
НПК - Нарушение правил каптов/криминала
НПМ - Нарушение правил митингов
НПРПК - Нарушение правил РП килла
НПРГ - Нарушение правил рейда гетто
НПСЗ - Нарушение правил судебного заседания
НПФ - Нарушения правила ферм
НПР - нарушения правил регионов
НПН - Нарушение правил никнеймов
НПС - Нарушение правил скинов
НПЧ - Нарушения правил чата
НПИП -Нарушение правил игрового процесса
НПКЧ - Нарушение правил комендантского часа
НППР - Нарушение правил перестрой районов
НПРПИ - Нарушение правил рп имён
НПЭ - Нарушение правил эмоций
НППСС - нарушение правил поведения со стримерами
НПСЗ - Нарушения правил снятия звёзд
НПБ - Нарушение правил бизнеса
НПНГ - Нарушение правил нахождения в гетто
НПЗГ - Нарушение правил захвата гетто
)")

close_notify(GuiObject?, eventInfo?)
{
    notify.Hide()
}

notify := Gui()
notify.Opt("+AlwaysOnTop")
notify.Title := "AHK | Статус"
notify.BackColor := 0x1C1C1C 

if temp_data == "restart" {
    notify.AddText("cWhite","AHK | СМИ | Программа была перезапущена")
}
else {
    notify.AddText("cWhite","AHK | СМИ | Программа запущена и свёрнута в трей")
}

if !FileExist(cfg_file){
    notify.AddText("cWhite","
    (Ltrim join`r`n
AHK | СМИ | Список изменений:
made with love by Agzes! [WertyKnack]
    )")
    try {
        FileAppend("non_first_start", cfg_file, "utf-8")
    } catch Error as err {
        MsgBox("Error creating config file: " . err.Message)
    }
}

notifya := notify.AddButton("w290 h20", "OK")
BtnUtils.SetBackColor(notifya, 0x4e4e4e, 0x1C1C1C)
notifya.OnEvent("Click", close_notify)
notify.Show("AutoSize")

try {
    FileDelete(temp_file)
} catch Error as err {
    MsgBox("Error deleting temp file: " . err.Message)
}

; Hotkey definitions
Numpad0::Reload()
Numpad1::Main.Show("AutoSize")
Numpad2::greetings()
Numpad4::back()
Numpad3::ad_edit()
!q::greetings()
!b::back()
!e::ad_edit()
F10::Reload()
F4::Main.Show("AutoSize")