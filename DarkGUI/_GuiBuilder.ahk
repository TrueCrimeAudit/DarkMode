#Requires AutoHotkey v2.1-alpha.17
#SingleInstance Force

GuiApp()

class GuiApp {
  __New() {
    this.designer := GuiDesigner()
    this.SetupGui()
  }

  SetupGui() {
    this.designer.OnEvent("Close", (*) => ExitApp())
    this.designer.OnEvent("Escape", (*) => ExitApp())

    this.designer.AddText("lblName", "Enter your name:")
      .Position(20, 20)
      .Font("", 12)
      .Build()

    this.designer.AddEdit("editName", "")
      .Position(20, 45)
      .Size(200, 25)
      .Var("UserName")
      .Build()

    this.designer.AddButton("btnSubmit", "Submit")
      .Position(20, 80)
      .Size(100, 30)
      .Default()
      .OnEvent("Click", this.ButtonClicked.Bind(this))
      .Build()

    this.designer.AddButton("btnCancel", "Cancel")
      .Position(130, 80)
      .Size(100, 30)
      .OnEvent("Click", (*) => this.designer.Hide())
      .Build()

    this.designer.Build()
  }

  ButtonClicked(*) {
    name := this.designer.Get("editName").Value
    MsgBox("Hello, " name "!")
  }
}

class GuiDesigner {
  __New() {
    this.gui := Gui()
    this.controls := Map()
    this.formatBuilder := GuiFormatBuilder()
  }

  AddControl(controlType, name, text := "", options := "") {
    builder := ControlChainBuilder(this, controlType, name, text, options)
    return builder
  }

  AddText(name, text := "", options := "") {
    return this.AddControl("Text", name, text, options)
  }

  AddButton(name, text := "", options := "") {
    return this.AddControl("Button", name, text, options)
  }

  AddEdit(name, text := "", options := "") {
    return this.AddControl("Edit", name, text, options)
  }

  AddListBox(name, items := [], options := "") {
    return this.AddControl("ListBox", name, items, options)
  }

  AddDropDownList(name, items := [], options := "") {
    return this.AddControl("DropDownList", name, items, options)
  }

  AddCheckbox(name, text := "", options := "") {
    return this.AddControl("Checkbox", name, text, options)
  }

  AddRadio(name, text := "", options := "") {
    return this.AddControl("Radio", name, text, options)
  }

  AddGroupBox(name, text := "", options := "") {
    return this.AddControl("GroupBox", name, text, options)
  }

  AddPicture(name, filename := "", options := "") {
    return this.AddControl("Picture", name, filename, options)
  }

  Format(x := "", y := "", w := "", h := "", options := "") {
    this.formatBuilder.Reset()
    if IsSet(x) && x !== ""
      this.formatBuilder.Position(x, y)
    if IsSet(w) && w !== ""
      this.formatBuilder.Size(w, h)
    if IsSet(options) && options !== ""
      this.formatBuilder.ExtraParams(options)
    return this.formatBuilder
  }

  Build() {
    this.gui.Show()
    return this
  }

  Hide() {
    this.gui.Hide()
    return this
  }

  OnEvent(eventName, callback) {
    this.gui.OnEvent(eventName, callback)
    return this
  }

  Get(name) {
    return this.controls.Has(name) ? this.controls[name] : ""
  }
}

class ControlChainBuilder {
  __New(designer, type, name, text := "", options := "") {
    this.designer := designer
    this.type := type
    this.name := name
    this.text := text
    this.options := options
    this._position := Map("x", "", "y", "")
    this.dimensions := Map("w", "", "h", "")
    this.events := []
    this.styles := []
    this.extraOptions := []
  }

  Position(x, y) {
    this._position["x"] := x
    this._position["y"] := y
    return this
  }

  Size(w, h) {
    this.dimensions["w"] := w
    this.dimensions["h"] := h
    return this
  }

  Pos(x, y) {
    return this.Position(x, y)
  }

  Default() {
    this.styles.Push("Default")
    return this
  }

  Center() {
    this.styles.Push("Center")
    return this
  }

  ReadOnly() {
    this.styles.Push("ReadOnly")
    return this
  }

  Password() {
    this.styles.Push("Password")
    return this
  }

  Multi() {
    this.styles.Push("Multi")
    return this
  }

  Hidden() {
    this.styles.Push("Hidden")
    return this
  }

  Background(color) {
    this.styles.Push("Background" color)
    return this
  }

  Color(color) {
    this.styles.Push("c" color)
    return this
  }

  Font(name, size := "", options := "") {
    fontOpt := "" size " " name
    if options
      fontOpt .= " " options
    this.styles.Push(fontOpt)
    return this
  }

  OnEvent(eventName, callback) {
    this.events.Push([eventName, callback])
    return this
  }

  Var(varName) {
    this.extraOptions.Push("v" varName)
    return this
  }

  WantReturn() {
    this.extraOptions.Push("WantReturn")
    return this
  }

  WantTab() {
    this.extraOptions.Push("WantTab")
    return this
  }

  Choose(n) {
    this.extraOptions.Push("Choose" n)
    return this
  }

  Build() {
    format := ""

    ; Build position if specified
    if this._position["x"] !== "" && this._position["y"] !== ""
      format .= "x" this._position["x"] " y" this._position["y"] " "

    ; Build dimensions if specified
    if this.dimensions["w"] !== ""
      format .= "w" this.dimensions["w"] " "
    if this.dimensions["h"] !== ""
      format .= "h" this.dimensions["h"] " "

    ; Add styles
    for _, style in this.styles
      format .= style " "

    ; Add extra options
    for _, option in this.extraOptions
      format .= option " "

    ; Add base options
    if this.options
      format .= this.options " "

    ; Clean up format string
    format := Trim(format)

    ; Create the control
    ctrl := ""
    switch this.type {
      case "Text":
        ctrl := this.designer.gui.AddText(format, this.text)
      case "Button":
        ctrl := this.designer.gui.AddButton(format, this.text)
      case "Edit":
        ctrl := this.designer.gui.AddEdit(format, this.text)
      case "ListBox":
        ctrl := this.designer.gui.AddListBox(format, this.text)
      case "DropDownList":
        ctrl := this.designer.gui.AddDropDownList(format, this.text)
      case "Checkbox":
        ctrl := this.designer.gui.AddCheckbox(format, this.text)
      case "Radio":
        ctrl := this.designer.gui.AddRadio(format, this.text)
      case "GroupBox":
        ctrl := this.designer.gui.AddGroupBox(format, this.text)
      case "Picture":
        ctrl := this.designer.gui.AddPicture(format, this.text)
    }

    ; Add events
    for _, event in this.events
      ctrl.OnEvent(event[1], event[2])

    ; Store control reference
    this.designer.controls[this.name] := ctrl

    return this.designer
  }
}

class GuiFormatBuilder {
  __New() {
    this._x := ""
    this._y := ""
    this._w := ""
    this._h := ""
    this._extraParams := ""
  }

  Position(x, y) {
    this._x := x
    this._y := y
    return this
  }

  Size(w, h) {
    this._w := w
    this._h := h
    return this
  }

  ExtraParams(value) {
    this._extraParams := value
    return this
  }

  Build() {
    params := ""
    if this._x !== "" && this._y !== ""
      params .= "x" this._x " y" this._y " "
    if this._w !== ""
      params .= "w" this._w " "
    if this._h !== ""
      params .= "h" this._h " "
    if this._extraParams
      params .= this._extraParams " "
    return Trim(params)
  }

  Reset() {
    this._x := ""
    this._y := ""
    this._w := ""
    this._h := ""
    this._extraParams := ""
    return this
  }
}

class CommandManager {
  __New() {
    this.commands := Map()
  }

  Register(name, callback) {
    this.commands[name] := callback
    return this
  }

  Execute(name, params*) {
    if (this.commands.Has(name))
      return this.commands[name](params*)
    return false
  }
}

GuiFormat(x, y, w, h, extraParams := "") {
  return GuiFormatBuilder().Position(x, y).Size(w, h).ExtraParams(extraParams).Build()
}