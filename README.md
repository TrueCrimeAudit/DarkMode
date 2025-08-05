# AutoHotkey v2 Dark Mode GUI - WinAPI Custom Drawing Implementation

This project implements dark mode GUIs in AutoHotkey v2 using Windows API custom drawing techniques. The core approach relies on intercepting `WM_NOTIFY` messages with `NM_CUSTOMDRAW` to override default control rendering.

## Current Implementation Status

**Working**: Basic dark theming for most controls  
**In Development**: `___Darkest.ahk` - Latest version with comprehensive control showcase  
**Issues**: Inconsistent custom drawing, missing slider bar coloring

## WinAPI Custom Drawing Architecture

### Core Drawing Process

The dark mode implementation hooks into Windows' custom draw cycle:

1. **Message Interception**: `WM_NOTIFY` messages are captured via `OnMessage()`
2. **Custom Draw Stages**: Different `CDDS_*` stages handle various drawing phases
3. **Device Context Manipulation**: Direct GDI calls modify colors and brushes
4. **Return Codes**: `CDRF_*` values control Windows' default drawing behavior

### Color Management

```autohotkey
static Dark := Map(
    "Background", 0x202020,    ; Main window background
    "Controls", 0x303030,      ; Control backgrounds  
    "Font", 0xE0E0E0,         ; Text color
    "Border", 0x404040,       ; Control borders
    "Highlight", 0x404040     ; Selection/hover states
)
```

### Custom Draw Message Handling

The `_Dark` class processes `NMCUSTOMDRAW` structures:

```autohotkey
; Extract drawing stage and device context
dwDrawStage := NumGet(lParam, A_PtrSize * 3, "UInt")
hdc := NumGet(lParam, A_PtrSize * 3 + 4, "UPtr")

; Apply custom colors based on stage
switch dwDrawStage {
    case 0x00000001: ; CDDS_PREPAINT
        ; Set background and text colors
        DllCall("gdi32\SetBkColor", "Ptr", hdc, "UInt", this.Dark["Controls"])
        DllCall("gdi32\SetTextColor", "Ptr", hdc, "UInt", this.Dark["Font"])
        return 0x00000020 ; CDRF_NOTIFYITEMDRAW
}
```

## File Structure

- `___Darkest.ahk` - **Latest implementation** (needs debugging help)
- `_Dark2.ahk` - Core dark mode engine with WinAPI hooks
- `_Dark.ahk` - Original implementation
- `DarkGUI/` - Supporting utilities and examples

## Known Issues (Help Needed)

### 1. Inconsistent Custom Drawing

**Problem**: Controls sometimes render with:
- Missing borders on some controls
- Inconsistent background colors between similar controls
- Random fallback to default Windows styling

**Suspected Causes**:
- Race conditions in message handling
- Incomplete `CDDS_*` stage coverage
- Missing `CDRF_*` return codes for certain control types

### 2. Slider Bar Coloring

**Problem**: Slider track/bar remains default blue instead of dark theme colors.

**Current Approach**:
```autohotkey
; This isn't working consistently
case 0x00000001: ; CDDS_PREPAINT for slider
    DllCall("gdi32\SetBkColor", "Ptr", hdc, "UInt", this.Dark["Controls"])
    ; Need proper slider-specific drawing code here
```

**Need**: Proper slider custom draw implementation that colors the progress bar.

### 3. Control-Specific Drawing Issues

Different control types need different custom draw handling:
- **Buttons**: Border rendering inconsistent
- **Edit controls**: Background sometimes reverts to white
- **ListViews**: Header styling incomplete
- **TreeViews**: Expand/collapse icons not themed

## Technical Details

### Message Flow

1. Control sends `WM_NOTIFY` with `NM_CUSTOMDRAW`
2. `OnMessage()` handler receives notification
3. `NMCUSTOMDRAW` structure parsed for drawing info
4. Custom colors applied via GDI calls
5. Return code tells Windows how to proceed

### Device Context Operations

```autohotkey
; Common GDI operations used
DllCall("gdi32\SetBkColor", "Ptr", hdc, "UInt", backgroundColor)
DllCall("gdi32\SetTextColor", "Ptr", hdc, "UInt", textColor)
DllCall("gdi32\FillRect", "Ptr", hdc, "Ptr", rectPtr, "Ptr", brushHandle)
```

### Brush Management

```autohotkey
; Create brushes for different elements
static backgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", Dark["Background"])
static controlBrush := DllCall("gdi32\CreateSolidBrush", "UInt", Dark["Controls"])
```

## Testing the Latest Version

Run `___Darkest.ahk` to see the current state. You'll notice:
- Some controls render perfectly
- Others have missing borders or wrong colors
- Slider progress bar stays default blue
- Inconsistent behavior between runs

## What I Need Help With

1. **Debugging the custom draw message handling** - Why do some controls randomly fail to apply dark styling?

2. **Slider progress bar coloring** - How to properly intercept and color the slider's progress portion?

3. **Consistent border rendering** - Some controls lose their borders entirely.

4. **Control-specific custom draw stages** - Different controls may need different `CDDS_*` stage handling.

If you have experience with Windows custom draw or AutoHotkey WinAPI integration, any insights would be appreciated. The goal is reliable, consistent dark mode rendering across all control types.

## Requirements

- AutoHotkey v2.1-alpha.16+
- Windows 10/11 (for best API support)
- Understanding of WinAPI custom drawing (if contributing fixes)