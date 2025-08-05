# AutoHotkey v2 Dark Mode GUI Library

A comprehensive dark mode GUI library for AutoHotkey v2 that provides modern, visually appealing dark-themed controls and interfaces.

## 🌟 Features

- **Complete Dark Mode Implementation** - Full dark theme support for all GUI controls
- **Modern UI Components** - Sleek, professional-looking dark controls
- **Easy Integration** - Simple API for adding dark mode to existing GUIs
- **Comprehensive Control Support** - Buttons, text fields, dropdowns, lists, and more
- **Custom Drawing** - Advanced custom-drawn controls with proper dark styling
- **Windows 10/11 Compatible** - Native dark mode integration where supported

## 📁 Project Structure

### Core Files

| File | Description |
|------|-------------|
| `___Darkest.ahk` | **Comprehensive showcase** - Complete demo of all dark mode controls |
| `_Dark2.ahk` | **Core dark mode engine** - Main dark mode implementation class |
| `_Dark.ahk` | **Legacy dark mode** - Original dark mode implementation |
| `__Darkest.ahk` | **Alternative showcase** - Additional demo implementation |

### DarkGUI Directory

| File | Purpose |
|------|---------|
| `Main.ahk` | Primary GUI application with dark mode integration |
| `DarkClass.ahk` | Windows theme management and dark mode utilities |
| `Example2.ahk` | Secondary example implementation |
| `!WinDarkUI.ahk` | Windows dark UI integration |
| `!GuiEnhancerKit.ahk` | GUI enhancement utilities |
| `!CreateImageButton.ahk` | Custom image button creation |
| `!DarkStyleMsgBox.ahk` | Dark-themed message boxes |
| `!ScroolBar.ahk` | Custom dark scrollbar implementation |
| `ColorButton.ahk` | Color-customizable button controls |
| `Const_Theme.ahk` | Theme constants and color definitions |

### Test & Development Files

| File | Purpose |
|------|---------|
| `Attempt_500.ahk` | Development/testing script |
| `Draft.ahk` | Draft implementation |
| `dark_mode_test.ahk` | Basic dark mode testing |

## 🚀 Quick Start

### Basic Usage

```autohotkey
#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

; Include the dark mode library
#Include _Dark2.ahk

; Create your GUI
myGui := Gui("+Resize", "My Dark App")

; Initialize dark mode
darkMode := _Dark(myGui)

; Add dark controls
darkMode.AddDarkButton("x10 y10 w100 h30", "Click Me")
darkMode.AddDarkEdit("x10 y50 w200 h25", "Type here...")
darkMode.AddDarkText("x10 y85 w200 h20", "Dark mode text")

; Show the GUI
myGui.Show()
```

### Running the Showcase

To see all available dark mode controls in action:

```bash
# Run the comprehensive showcase
AutoHotkey.exe ___Darkest.ahk
```

## 🎨 Available Controls

The library supports dark mode versions of all standard AutoHotkey controls:

### Input Controls
- **Text Fields** - Single and multi-line edit controls
- **Buttons** - Standard, default, and custom image buttons
- **Checkboxes** - Dark-themed checkbox controls
- **Radio Buttons** - Grouped radio button controls

### Selection Controls
- **Dropdown Lists** - ComboBox and DropDownList controls
- **List Boxes** - Single and multi-select list controls
- **Tree Views** - Hierarchical tree controls
- **List Views** - Detailed list/grid controls

### Display Controls
- **Text Labels** - Static text with dark styling
- **Progress Bars** - Animated progress indicators
- **Sliders** - Horizontal and vertical sliders
- **Status Bars** - Application status displays

### Advanced Controls
- **Custom Message Boxes** - Dark-themed dialog boxes
- **Image Buttons** - Buttons with custom graphics
- **Enhanced Scrollbars** - Custom dark scrollbar styling

## 🛠️ API Reference

### Core Dark Mode Class

```autohotkey
; Initialize dark mode for a GUI
darkMode := _Dark(guiObject)

; Add dark controls
button := darkMode.AddDarkButton(options, text)
edit := darkMode.AddDarkEdit(options, text)
text := darkMode.AddDarkText(options, text)
checkbox := darkMode.AddDarkCheckBox(options, text)
radio := darkMode.AddDarkRadio(options, text, group, parent)
combo := darkMode.AddDarkComboBox(options, items)
listbox := darkMode.AddDarkListBox(options, items)
slider := darkMode.AddDarkSlider(options, value)
progress := darkMode.AddDarkProgress(options, value)
treeview := darkMode.AddDarkTreeView(options)
listview := darkMode.AddListView(options, columns)
```

### Theme Management

```autohotkey
; Set application-wide dark mode
WindowsTheme.SetAppMode(true)

; Apply dark mode to specific window
WindowsTheme.SetWindowAttribute(guiObject, true)
```

## 🎯 Examples

### Simple Dark GUI

```autohotkey
#Include _Dark2.ahk

SimpleApp()

class SimpleApp {
    __New() {
        this.gui := Gui("+Resize", "Simple Dark App")
        this.darkMode := _Dark(this.gui)
        
        this.darkMode.AddDarkText("x20 y20 w200 h25", "Welcome to Dark Mode!")
        this.darkMode.AddDarkEdit("x20 y50 w200 h25", "Enter text here...")
        this.darkMode.AddDarkButton("x20 y85 w100 h30", "Submit")
        
        this.gui.Show("w250 h150")
    }
}
```

### Advanced Control Showcase

See `___Darkest.ahk` for a complete example featuring:
- Multiple input controls
- Selection and dropdown controls  
- Data display controls (ListView, TreeView)
- Progress indicators and sliders
- Custom styling and theming

## 🔧 Requirements

- **AutoHotkey v2.1-alpha.16** or newer
- **Windows 10/11** (recommended for best dark mode support)
- **GDI+ support** (included with Windows)

## 🎨 Customization

### Color Themes

The library uses a configurable color scheme:

```autohotkey
; Default dark theme colors
static Dark := Map(
    "Background", 0x202020,    ; Dark gray background
    "Controls", 0x303030,      ; Slightly lighter control background
    "Font", 0xE0E0E0,         ; Light gray text
    "Border", 0x404040         ; Border color
)
```

### Custom Styling

You can customize the appearance by modifying the color constants in `Const_Theme.ahk` or by extending the `_Dark` class with your own styling methods.

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is open source. Please check individual files for specific licensing information.

## 🙏 Acknowledgments

- AutoHotkey community for ongoing support and development
- Contributors to the various dark mode implementations
- Windows API documentation and examples

---

**Note**: This library is designed for AutoHotkey v2. For AutoHotkey v1 compatibility, please use the legacy versions or consider upgrading your scripts to v2.