#SingleInstance, Force
#Persistent
If !A_IsAdmin
	Run *RunAs "%A_ScriptFullPath%"

; Default settings
global hardKillHotkey := "F3"
global silentKillHotkey := "F4"
global showNotifications := true

; Load settings from INI file
LoadSettings()
; Register initial hotkeys
RegisterHotkeys()

; Create tray menu
Menu, Tray, Add, Settings, ShowSettings
Menu, Tray, Default, Settings

; Ctrl+G to toggle settings window
^g::ShowSettings()

; Load settings from INI file
LoadSettings() {
    global
    iniFile := A_ScriptDir . "\HotkeySettings.ini"
    
    if FileExist(iniFile) {
        IniRead, hardKillHotkey, %iniFile%, Settings, HardKillHotkey, F3
        IniRead, silentKillHotkey, %iniFile%, Settings, SilentKillHotkey, F4
        IniRead, showNotifications, %iniFile%, Settings, ShowNotifications, 1
        showNotifications := showNotifications ? true : false
    }
}

; Save settings to INI file
SaveSettingsToIni() {
    global
    iniFile := A_ScriptDir . "\HotkeySettings.ini"
    
    ; Ensure we can write to the file
    try {
        IniWrite, %hardKillHotkey%, %iniFile%, Settings, HardKillHotkey
        IniWrite, %silentKillHotkey%, %iniFile%, Settings, SilentKillHotkey
        IniWrite, %showNotifications%, %iniFile%, Settings, ShowNotifications
    } catch {
        ; If can't write to script directory, try temp directory
        iniFile := A_Temp . "\HotkeySettings.ini"
        IniWrite, %hardKillHotkey%, %iniFile%, Settings, HardKillHotkey
        IniWrite, %silentKillHotkey%, %iniFile%, Settings, SilentKillHotkey
        IniWrite, %showNotifications%, %iniFile%, Settings, ShowNotifications
    }
}

; Settings GUI
ShowSettings() {
    global
    
    ; Destroy existing GUI if it exists
    Gui, Settings:Destroy
    
    ; Create dark mode GUI
    Gui, Settings:New, , Hotkey Settings
    
    ; Apply dark mode to window
    ApplyDarkMode()
    
    ; Set dark colors for controls
    Gui, Settings:Color, 2b2b2b, 3c3f41
    Gui, Settings:Font, cFFFFFF s9, Segoe UI
    
    Gui, Add, Text, , Hard Kill Hotkey (with confirmation):
    Gui, Add, Edit, vHardKillHotkey gHotkeyChanged w200, % hardKillHotkey
    
    Gui, Add, Text, , Silent Kill Hotkey:
    Gui, Add, Edit, vSilentKillHotkey gHotkeyChanged w200, % silentKillHotkey
    
    Gui, Add, Text, , Note: Use # for Win, ^ for Ctrl, + for Shift, ! for Alt`nExample: #r = Win+R, ^+t = Ctrl+Shift+T
    
    ; Checkbox for notifications
    Gui, Add, Checkbox, vShowNotifications Checked%showNotifications%, Show notification tips when killing windows
    
    ; Create buttons
    Gui, Add, Button, gSaveHotkeys Default xm HwndHBtnSave, Save
    Gui, Add, Button, x+10 gCancelHotkeys HwndHBtnCancel, Cancel
	
	; Apply dark mode to buttons
    DllCall("UxTheme\SetWindowTheme", "Ptr", hBtnSave, "Str", "DarkMode_Explorer", "Ptr", 0)
    DllCall("UxTheme\SetWindowTheme", "Ptr", hBtnCancel, "Str", "DarkMode_Explorer", "Ptr", 0)
	
    ; Apply dark mode
    ApplyControlDarkMode()
    
    Gui, Show
    return
    
    SettingsGuiClose:
    CancelHotkeys:
    Gui, Settings:Destroy
    return
    
    HotkeyChanged:
    return
    
    SaveHotkeys:
    Gui, Settings:Submit, NoHide
    
    ; Trim whitespace from hotkeys
    HardKillHotkey := Trim(HardKillHotkey)
    SilentKillHotkey := Trim(SilentKillHotkey)
    
    ; Validate hotkeys (not empty)
    if (HardKillHotkey = "") {
        MsgBox, 64, Error, Hard kill hotkey cannot be empty!
        return
    }
    if (SilentKillHotkey = "") {
        MsgBox, 64, Error, Silent kill hotkey cannot be empty!
        return
    }
    
    ; Unregister old hotkeys first
    UnregisterHotkeys()
    
    ; Update settings
    hardKillHotkey := HardKillHotkey
    silentKillHotkey := SilentKillHotkey
    showNotifications := ShowNotifications
    
    ; Register new hotkeys
    RegisterHotkeys()
    
    ; Save to INI file
    SaveSettingsToIni()
    
    Gui, Settings:Destroy
    
    if (showNotifications) {
        TrayTip, Hotkeys Updated, Hard Kill: %hardKillHotkey%`nSilent Kill: %silentKillHotkey%, 3
    }
    return
}

; Apply dark mode to the GUI window
ApplyDarkMode() {
    Gui, Settings:+LastFound
    hWnd := WinExist()
    
    if (A_OSVersion ~= "10\..*|11") {
        ; Try to set dark mode
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hWnd, "int", 20, "int*", 1, "int", 4)
        DllCall("uxtheme\SetWindowTheme", "ptr", hWnd, "wstr", "DarkMode_Explorer", "ptr", 0)
    }
}

; Apply dark mode to all controls
ApplyControlDarkMode() {
    ; Get the GUI's window handle
    Gui, Settings:+LastFound
    hWnd := WinExist()
    
    ; Apply dark theme to all edit controls (including hotkey fields)
    ControlGet, hWndEdit1, hWnd,, Edit1, Hotkey Settings
    if (hWndEdit1) {
        DllCall("uxtheme\SetWindowTheme", "ptr", hWndEdit1, "wstr", "DarkMode_Explorer", "ptr", 0)
        ; Set dark background and white text for edit control
        SendMessage, 0x0001, 0, 0xFFFFFF,, ahk_id %hWndEdit1%  ; WM_SETTEXT? Actually no - we need EM_SETBKGNDCOLOR
        ; Better approach: Use control's own coloring
        GuiControl, Settings:+Background2b2b2b, HardKillHotkey
        GuiControl, Settings:+Background2b2b2b, SilentKillHotkey
    }
    
    ControlGet, hWndEdit2, hWnd,, Edit2, Hotkey Settings
    if (hWndEdit2) {
        DllCall("uxtheme\SetWindowTheme", "ptr", hWndEdit2, "wstr", "DarkMode_Explorer", "ptr", 0)
        GuiControl, Settings:+Background2b2b2b, SilentKillHotkey
    }
      
    ; Apply to checkbox (usually Button3)
    ControlGet, hWndChk, hWnd,, Button3, Hotkey Settings
    if (hWndChk) {
        DllCall("uxtheme\SetWindowTheme", "ptr", hWndChk, "wstr", "DarkMode_Explorer", "ptr", 0)
    }
    
    ; Also try to set the edit control colors directly via GUI control options
    GuiControl, Settings:+cWhite, HardKillHotkey
    GuiControl, Settings:+cWhite, SilentKillHotkey
}

; Register hotkeys dynamically
RegisterHotkeys() {
    global
    try {
        Hotkey, % hardKillHotkey, HardKillLabel, On
        Hotkey, % silentKillHotkey, SilentKillLabel, On
    } catch e {
        MsgBox, Error registering hotkeys: %e%
    }
}

; Unregister hotkeys
UnregisterHotkeys() {
    global
    try {
        Hotkey, % hardKillHotkey, Off
        Hotkey, % silentKillHotkey, Off
    } catch {
        ; Ignore errors when unregistering
    }
}

; Hard kill hotkey label
HardKillLabel:
    WinGetClass, this_class, A
    
    ; Skip Rainmeter windows
    if (this_class = "RainmeterMeterWindow")
    {
        if (showNotifications)
            MsgBox, Cannot kill Rainmeter process.
        Return
    }
	
	if (this_class = "Progman")
		Return
	
	if (this_class = "Shell_TrayWnd")
		Return
    
    MsgBox, 4, Kill Active Window, Are you sure you want to kill this process?
    IfMsgBox No
        Return
    
    KillActiveWindow()
    Return

; Silent kill hotkey label
SilentKillLabel:
    WinGetClass, this_class, A
    
    ; Skip Rainmeter windows
    if (this_class = "RainmeterMeterWindow")
    {
        if (showNotifications)
            TrayTip, Kill Active Window, Cannot kill Rainmeter process., 2
        Return
    }
	
	if (this_class = "Progman")
		Return
		
	if (this_class = "Shell_TrayWnd")
		Return
		
    KillActiveWindow()
    Return

; Function to perform the kill operation
KillActiveWindow() {
    global showNotifications
    WinGet, PID, PID, A
    
    WinClose, A,, .5
    RunWait, taskkill /pid %PID%,, hide
    
    ; Show notification if enabled
    if (showNotifications)
        TrayTip, Kill Active Window, Process terminated., 1
}

ExitApp:
    ExitApp