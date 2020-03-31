;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.3.14.2                                                             ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  Timboli                                                                     ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:  Floating Dropbox for use with downloaded game files from GOG       ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FUNCTIONS
; AddFileToList(), GetFileSize(), ImitationConsoleGUI($start)
; WM_DROPFILES_FUNC($hWnd, $msgID, $wParam, $lParam)

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ScrollBarsConstants.au3>
#include <EditConstants.au3>
#include <ColorConstants.au3>
#include <ButtonConstants.au3>
#include <Misc.au3>
#include <GuiListBox.au3>
#include <GuiEdit.au3>
#include <File.au3>
#include <Date.au3>
#include <Array.au3>

_Singleton("gog-downloads-timboli")

Global $Button_list, $Button_log, $Button_opts, $Button_start, $Input_size, $Label_drop
Global $List_menu, $Log_menu, $Clear_item, $Wipe_item

Global $7zip, $array, $atts, $boxcol, $cnt, $dir, $DropboxGUI, $drv, $fext, $fnam, $folder, $inifle
Global $innoextract, $left, $listfle, $logfle, $notepad, $path, $size, $srcfle, $start, $style, $target
Global $text, $textcol, $top, $tot, $zipcheck

Global $gaDropFiles[1], $hWnd, $lParam, $msgID, $wParam
; NOTE - If using older AutoIt, then $WM_DROPFILES = 0x233 may need to be declared.

$7zip = @ScriptDir & "\7-Zip\7za.exe"
$folder = @ScriptDir & "\7-Zip"
$inifle = @ScriptDir & "\Settings.ini"
$innoextract = @ScriptDir & "\innoextract.exe"
$logfle = @ScriptDir & "\Log.txt"
$listfle = @ScriptDir & "\Files.txt"
$notepad = @WindowsDir & "\Notepad.exe "
$target = @LF & "Drag && Drop" & @LF & "Downloaded" & @LF & "Game Files" & @LF & "HERE"

If Not FileExists($folder) Then DirCreate($folder)

If Not FileExists($logfle) Then _FileCreate($logfle)

$left = IniRead($inifle, "Program Window", "left", -1)
$top = IniRead($inifle, "Program Window", "top", -1)
$style = $WS_CAPTION + $WS_POPUP + $WS_CLIPSIBLINGS + $WS_SYSMENU
$DropboxGUI = GUICreate("GOGFile Checker", 165, 110, $left, $top, $style, $WS_EX_TOPMOST + $WS_EX_ACCEPTFILES)
;
; CONTROLS
$Label_drop = GUICtrlCreateLabel($target, 1, 1, 161, 80, $SS_CENTER)
GUICtrlSetFont($Label_drop, 9, 600, 0, "Small Fonts")
GUICtrlSetState($Label_drop, $GUI_DROPACCEPTED)
GUICtrlSetTip($Label_drop, "Drag & Drop downloaded game files here!")
;
$Button_start = GUICtrlCreateButton("Start", 2, 84, 38, 22)
GUICtrlSetFont($Button_start, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_start, "Start Processing!")
;
$Button_list = GUICtrlCreateButton("List", 42, 84, 33, 22)
GUICtrlSetFont($Button_list, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_list, "View the File List!")
;
$Button_log = GUICtrlCreateButton("Log", 77, 84, 32, 22)
GUICtrlSetFont($Button_log, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_log, "View the Log file!")
;
$Button_opts = GUICtrlCreateButton("Options", 111, 84, 51, 22)
GUICtrlSetFont($Button_opts, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_opts, "Console Options!")
;
; CONTEXT MENU
$List_menu = GUICtrlCreateContextMenu($Button_list)
$Clear_item = GUICtrlCreateMenuItem("Clear The List", $List_menu)
;
$Log_menu = GUICtrlCreateContextMenu($Button_log)
$Wipe_item = GUICtrlCreateMenuItem("Clear The Log", $Log_menu)
;
; SETTINGS
$boxcol = $COLOR_YELLOW
$textcol = $COLOR_RED
GUICtrlSetBkColor($Label_drop, $boxcol)
GUICtrlSetColor($Label_drop, $textcol)

GUIRegisterMsg($WM_DROPFILES, "WM_DROPFILES_FUNC")

GUISetState(@SW_SHOW)
While True
	$msg = GUIGetMsg()
	Select
		Case $msg = $GUI_EVENT_CLOSE
			; Exit or Close dropbox
			$winpos = WinGetPos($DropboxGUI, "")
			$left = $winpos[0]
			If $left < 0 Then
				$left = 2
			ElseIf $left > @DesktopWidth - $winpos[2] Then
				$left = @DesktopWidth - $winpos[2]
			EndIf
			IniWrite($inifle, "Program Window", "left", $left)
			$top = $winpos[1]
			If $top < 0 Then
				$top = 2
			ElseIf $top > @DesktopHeight - $winpos[3] Then
				$top = @DesktopHeight - $winpos[3]
			EndIf
			IniWrite($inifle, "Program Window", "top", $top)
			;
			GUIDelete($DropboxGUI)
			ExitLoop
		Case $msg = $GUI_EVENT_DROPPED
			;MsgBox(262208, "Drop Result", @GUI_DragFile & " was dropped on " & @GUI_DropId, 0, $DropboxGUI)
			$cnt = UBound($gaDropFiles)
			If $cnt = 1 Then
				$srcfle = @GUI_DragFile
				$atts = FileGetAttrib($srcfle)
				If StringInStr($atts, "D") > 0 Then
					MsgBox(262192, "Drop Error", "Folders are not supported!", 0, $DropboxGUI)
				Else
					AddFileToList()
				EndIf
			Else
				For $g = 0 To $cnt - 1
					$srcfle = $gaDropFiles[$g]
					$atts = FileGetAttrib($srcfle)
					If StringInStr($atts, "D") > 0 Then
						MsgBox(262192, "Drop Error", "Folders are not supported!", 2, $DropboxGUI)
					Else
						AddFileToList()
					EndIf
				Next
			EndIf
		Case $msg = $Button_start
			; Start Processing
			If FileExists($innoextract) Then
				If FileExists($7zip) Then
					$zipcheck = 1
				Else
					$zipcheck = ""
					MsgBox(262192, "Program Error", "7-Zip (7za.exe) is Required for ZIP files and is missing!", 0, $DropboxGUI)
				EndIf
				If FileExists($listfle) Then
					$tot = _FileCountLines($listfle)
					If $tot > 0 Then
						_FileReadToArray($listfle, $array)
						If @error Then
							MsgBox(262192, "File Error", "File List could not be read!", 0, $DropboxGUI)
						Else
							GUISetState(@SW_HIDE, $DropboxGUI)
							ImitationConsoleGUI(1)
							GUISetState(@SW_SHOW, $DropboxGUI)
						EndIf
					Else
						MsgBox(262192, "File Error", "File List is empty!", 0, $DropboxGUI)
					EndIf
				Else
					MsgBox(262192, "File Error", "File List does not exist!", 0, $DropboxGUI)
				EndIf
			Else
				MsgBox(262192, "Program Error", "Required 'innoextract.exe' is missing!", 0, $DropboxGUI)
			EndIf
		Case $msg = $Button_opts
			; Console Options
			GUISetState(@SW_HIDE, $DropboxGUI)
			ImitationConsoleGUI(0)
			GUISetState(@SW_SHOW, $DropboxGUI)
		Case $msg = $Button_log
			; View the Log file
			If FileExists($logfle) Then Run($notepad & $logfle)
		Case $msg = $Button_list
			; View the File List
			If FileExists($listfle) Then Run($notepad & $listfle)
		Case $msg = $Wipe_item
			; Clear The Log
			_FileCreate($logfle)
		Case $msg = $Clear_item
			; Clear The List
			_FileCreate($listfle)
		Case Else
	EndSelect
WEnd

Exit


Func ImitationConsoleGUI($start)
	Local $Button_info, $Button_ontop, $Checkbox_beep, $Checkbox_during, $Checkbox_exit, $Checkbox_kill
	Local $Checkbox_results, $Checkbox_save, $Checkbox_send, $Checkbox_show, $Checkbox_shutdown, $Checkbox_stop
	Local $Edit_console, $Group_console, $Group_done, $Group_job, $Group_jobs
	Local $Input_job, $Input_jobs,$Input_path, $Input_title
	Local $Label_job, $Label_path, $Label_size, $Label_state, $Label_status, $Label_title
	Local $List_done, $List_jobs
	;
	Local $a, $beep, $cancel, $close, $ConsoleGUI, $create, $duration, $err, $exit, $frequency, $height, $ind
	Local $j, $job, $line, $ontop, $o, $out, $output, $passed, $pid, $resfile, $resfold, $results, $ret, $save
	Local $send, $show, $shutdown, $shutoptions, $shutwarn, $width
	;
	$shutdown = IniRead($inifle, "After Downloads", "shutdown", "")
	If $shutdown = "" Then
		$shutdown = "none"
		IniWrite($inifle, "After Downloads", "shutdown", $shutdown)
	EndIf
	If $shutdown <> "none" Then
		$shutwarn = " - SHUTDOWN ENABLED"
	Else
		$shutwarn = ""
	EndIf
	;
	$height = 570
	$width = 710
	$ConsoleGUI = GuiCreate("GOGDownload Checker Console" & $shutwarn, $width, $height, @DesktopWidth - $width - 28, 30, $WS_OVERLAPPED + _
									$WS_MINIMIZEBOX + $WS_SYSMENU + $WS_CAPTION + $WS_VISIBLE + $WS_CLIPSIBLINGS, $WS_EX_TOPMOST)
	GUISetBkColor(0x969696)
	; CONTROLS
	$Group_job = GUICtrlCreateGroup("Job Processing", 10, 10, 690, 75)
	$Label_job = GUICtrlCreateLabel("Job", 20, 30, 30, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_job, $Color_Black)
	GUICtrlSetColor($Label_job, $Color_White)
	$Input_job = GUICtrlCreateInput("0", 50, 30, 30, 20, $ES_NUMBER + $ES_CENTER)
	GUICtrlSetBkColor($Input_job, 0xD0C0C0)
	GUICtrlCreateLabel("of", 80, 30, 20, 20, $SS_CENTER + $SS_CENTERIMAGE)
	GUICtrlSetTip($Input_job, "Number of Current File being Tested!")
	$Input_jobs = GUICtrlCreateInput("", 100, 30, 40, 20, $ES_NUMBER + $ES_CENTER)
	GUICtrlSetBkColor($Input_jobs, 0xD0C0C0)
	GUICtrlSetTip($Input_jobs, "Number of Files to be Tested!")
	;
	$Label_title = GUICtrlCreateLabel("File Title", 150, 30, 60, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN + $SS_NOTIFY)
	GUICtrlSetBkColor($Label_title, $Color_Green)
	GUICtrlSetColor($Label_title, $Color_White)
	$Input_title = GUICtrlCreateInput("", 210, 30, 380, 20)
	GUICtrlSetBkColor($Input_title, 0xD7FFD7)
	GUICtrlSetTip($Input_title, "Current File being Tested!")
	$Label_size = GUICtrlCreateLabel("Size", 595, 30, 35, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN + $SS_NOTIFY)
	GUICtrlSetBkColor($Label_size, $Color_Green)
	GUICtrlSetColor($Label_size, $Color_White)
	$Input_size = GUICtrlCreateInput("", 630, 30, 60, 20)
	GUICtrlSetBkColor($Input_size, 0xD7FFD7)
	GUICtrlSetTip($Input_size, "Size of File being Tested!")
	;
	$Label_path = GUICtrlCreateLabel("Path", 20, 55, 30, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_path, $Color_Blue)
	GUICtrlSetColor($Label_path, $Color_White)
	$Input_path = GUICtrlCreateInput("", 50, 55, 640, 20)
	GUICtrlSetBkColor($Input_path, 0xCAE4FF)
	GUICtrlSetTip($Input_path, "Path of Current File being Tested!")
	;
	$Group_jobs = GUICtrlCreateGroup("Jobs To Do", 10, 95, 690, 95)
	$List_jobs = GUICtrlCreateList("", 20, 115, 670, 65, $WS_BORDER + $WS_VSCROLL)
	GUICtrlSetBkColor($List_jobs, 0xFFCEE7)
	GUICtrlSetTip($List_jobs, "Files waiting to be tested!")
	;
	$Group_done = GUICtrlCreateGroup("Jobs Done", 10, 200, 690, 95)
	$List_done = GUICtrlCreateList("", 20, 220, 670, 65, $WS_BORDER + $WS_VSCROLL)
	GUICtrlSetBkColor($List_done, 0xFFFFB7)
	GUICtrlSetTip($List_done, "Files that have completed testing!")
	;
	$Group_console = GUICtrlCreateGroup("DOS CMD Console Ouput", 10, 305, 690, 180)
	$Edit_console = GUICtrlCreateEdit("", 20, 325, 670, 145, $ES_MULTILINE + $ES_WANTRETURN + $ES_READONLY + $WS_VSCROLL)
	;$Edit_console = _GUICtrlEdit_Create($ConsoleGUI, "", 20, 325, 670, 145, $ES_MULTILINE + $ES_WANTRETURN + $ES_READONLY + $WS_VSCROLL)
	GUICtrlSetBkColor($Edit_console, $Color_Black)
	GUICtrlSetColor($Edit_console, $Color_White)
	GUICtrlSetTip($Edit_console, "Process data from InnoExtract testing!")
	;
	$Checkbox_exit = GUICtrlCreateCheckbox("Exit On Jobs Finished", 10, 500, 120, 20)
	GUICtrlSetTip($Checkbox_exit, "Close the Console after all Jobs are Finished!")
	$Checkbox_stop = GUICtrlCreateCheckbox("Stop After Current Job", 10, 520, 120, 20)
	GUICtrlSetTip($Checkbox_stop, "Stop After Current Job or Process!")
	;
	$Label_status = GUICtrlCreateLabel("Status", 140, 503, 50, 30, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_status, $Color_Black)
	GUICtrlSetColor($Label_status, $Color_White)
	$Label_state = GUICtrlCreateLabel("", 190, 503, 140, 30, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetColor($Label_state, $Color_Black)
	GUICtrlSetTip($Label_state, "Current state of Processing!")
	;
	$Checkbox_during = GUICtrlCreateCheckbox("Stop During", 340, 500, 75, 20)
	GUICtrlSetTip($Checkbox_during, "Stop during Current Job or Process!")
	$Checkbox_kill = GUICtrlCreateCheckbox("Kill not Close", 340, 520, 80, 20)
	GUICtrlSetTip($Checkbox_kill, "Kill the InnoExtract process, not close!")
	;
	$Label_shutdown = GUICtrlCreateLabel("Shutdown", 430, 507, 70, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_shutdown, $Color_Black)
	GUICtrlSetColor($Label_shutdown, $Color_White)
	$Combo_shutdown = GUICtrlCreateCombo("", 500, 507, 75, 21)
	GUICtrlSetTip($Combo_shutdown, "Shutdown Options!")
	;
	$Button_ontop = GUICtrlCreateCheckbox("ON Top", 585, 503, 60, 30, $BS_PUSHLIKE)
	GUICtrlSetFont($Button_ontop, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_ontop, "Toggle the window On Top setting!")
	;
	$Button_info = GUICtrlCreateButton("INFO", 655, 503, 45, 30)
	GUICtrlSetFont($Button_info, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Checkbox_show = GUICtrlCreateCheckbox("Show a 'Finished' dialog", 10, 540, 130, 20)
	GUICtrlSetTip($Checkbox_show, "Show a 'Finished' dialog after all Jobs are Finished!")
	;
	$Checkbox_beep = GUICtrlCreateCheckbox("Beep on finish", 150, 540, 85, 20)
	GUICtrlSetTip($Checkbox_beep, "Beep after all Jobs are Finished!")
	;
	$Checkbox_save = GUICtrlCreateCheckbox("Enable creation of 'Results.txt' files", 245, 540, 180, 20)
	GUICtrlSetTip($Checkbox_save, "Enable creation of the 'Results.txt' files!")
	;
	$Checkbox_create = GUICtrlCreateCheckbox("Create a 'Results' folder", 435, 540, 130, 20)
	GUICtrlSetTip($Checkbox_create, "Create a folder for 'Results.txt' files!")
	;
	$Checkbox_send = GUICtrlCreateCheckbox("Send to 'Results' folder", 575, 540, 125, 20)
	GUICtrlSetTip($Checkbox_send, "Send 'Results.txt' files to the 'Results' folder!")
	;
	; SETTINGS
	$close = ""
	$shutoptions = "none|Shutdown|Hibernate|Standby|Powerdown|Logoff"
	If $start = 1 Then
		If $shutdown <> "none" Then
			$ans = MsgBox(262195, "Shutdown Alert", _
				"A shutdown option is currently enabled." & @LF & @LF & _
				"YES = Continue." & @LF & _
				"NO = Disable shutdown." & @LF & _
				"CANCEL = Abort checking.", 0, $ConsoleGUI)
			If $ans = 7 Then
				$shutdown = "none"
				IniWrite($inifle, "After Downloads", "shutdown", $shutdown)
			ElseIf $ans = 2 Then
				$close = 1
			EndIf
		EndIf
		;
		If $close = "" Then
			GUICtrlSetData($Input_jobs, $tot)
			;
			For $a = 1 To $array[0]
				$path = $array[$a]
				If $path <> "" Then
					GUICtrlSetData($List_jobs, $path)
				EndIf
			Next
		EndIf
	Else
		GUICtrlSetBkColor($Label_state, $Color_White)
		GUICtrlSetData($Label_state, "SETUP MODE")
		GUICtrlSetState($Checkbox_stop, $GUI_DISABLE)
		GUICtrlSetState($Checkbox_during, $GUI_DISABLE)
		;GUICtrlSetState($Checkbox_kill, $GUI_DISABLE)
	EndIf
	If $close = "" Then
		GUICtrlSetData($Combo_shutdown, $shutoptions, $shutdown)
		;
		$exit = IniRead($inifle, "On Jobs Finished", "auto_exit", "")
		If $exit = "" Then
			$exit = 4
			IniWrite($inifle, "On Jobs Finished", "auto_exit", $exit)
		EndIf
		GUICtrlSetState($Checkbox_exit, $exit)
		;
		$ontop = IniRead($inifle, "Console", "ontop", "")
		If $ontop = "" Then
			$ontop = 1
			IniWrite($inifle, "Console", "ontop", $ontop)
		EndIf
		GUICtrlSetState($Button_ontop, $ontop)
		If $ontop = 4 Then WinSetOnTop($ConsoleGUI, "", 0)
		;
		$kill = IniRead($inifle, "Taskkill For Cancel", "use", "")
		If $kill = "" Then
			$kill = 1
			IniWrite($inifle, "Taskkill For Cancel", "use", $kill)
		EndIf
		GUICtrlSetState($Checkbox_kill, $kill)
		;
		$show = IniRead($inifle, "On Jobs Finished", "dialog", "")
		If $show = "" Then
			$show = 4
			IniWrite($inifle, "On Jobs Finished", "dialog", $show)
		EndIf
		GUICtrlSetState($Checkbox_show, $show)
		;
		$beep = IniRead($inifle, "On Jobs Finished", "beep", "")
		If $beep = "" Then
			$beep = 4
			IniWrite($inifle, "On Jobs Finished", "beep", $beep)
		EndIf
		GUICtrlSetState($Checkbox_beep, $beep)
		$frequency = IniRead($inifle, "Beep", "frequency", "")
		If $frequency = "" Then
			$frequency = 1200
			IniWrite($inifle, "Beep", "frequency", $frequency)
		EndIf
		$duration = IniRead($inifle, "Beep", "duration", "")
		If $duration = "" Then
			$duration = 1500
			IniWrite($inifle, "Beep", "duration", $duration)
		EndIf
		;
		$save = IniRead($inifle, "Testing Results", "save", "")
		If $save = "" Then
			$save = 1
			IniWrite($inifle, "Testing Results", "save", $save)
		EndIf
		GUICtrlSetState($Checkbox_save, $save)
		;
		$create = IniRead($inifle, "Results Folder", "create", "")
		If $create = "" Then
			$create = 1
			IniWrite($inifle, "Results Folder", "create", $create)
		EndIf
		GUICtrlSetState($Checkbox_create, $create)
		;
		$send = IniRead($inifle, "Results Files", "send", "")
		If $send = "" Then
			$send = 4
			IniWrite($inifle, "Results Files", "send", $send)
		EndIf
		GUICtrlSetState($Checkbox_send, $send)
		;
		If $save = 4 Then
			GUICtrlSetState($Checkbox_create, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
		EndIf
		If $create = 4 Then
			GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
		EndIf
	EndIf


	GuiSetState()
	While 1
		$msg = GuiGetMsg()
		Select
		Case $msg = $GUI_EVENT_CLOSE Or $close = 1
			; Close, Quit or Exit the Console
			GUIDelete($ConsoleGUI)
			ExitLoop
		Case $msg = $Button_ontop
			; Toggle the window On Top setting
			If GUICtrlRead($Button_ontop) = $GUI_CHECKED Then
				WinSetOnTop($ConsoleGUI, "", 1)
				$ontop = 1
			Else
				WinSetOnTop($ConsoleGUI, "", 0)
				$ontop = 4
			EndIf
			IniWrite($inifle, "Console", "ontop", $ontop)
			GUICtrlSetState($Button_ontop, $ontop)
		Case $msg = $Button_info
			; Program Information
			MsgBox(262208, "Program Information", _
				"This program tests the integrity of game files downloaded from" & @LF & _
				"the GOG store. EXE (with BIN) files and ZIP files are supported." & @LF & @LF & _
				"The program uses InnoExtract to do the testing, which is freely" & @LF & _
				"available online. The 'innoextract.exe' file needs to exist in the" & @LF & _
				"same folder (directory) as this program." & @LF & @LF & _
				"The program also requires '7-Zip' to do the testing of ZIP files," & @LF & _
				"which is freely available online. The '7za.exe' file needs to exist" & @LF & _
				"in a '7-Zip' content folder, in the same folder as this program." & @LF & @LF & _
				"When the Console window and testing process are running, a" & @LF & _
				"few of the options on the Console window will either be once" & @LF & _
				"off selection only (setting not saved) or unavailable for use. It" & @LF & _
				"is better to set some options before clicking Start for testing." & @LF & @LF & _
				"When you start the program, you are presented with a floating" & @LF & _
				"dropbox, to which you can drag & drop your game files on. As" & @LF & _
				"each is dropped it is added to a list as a path for that file. When" & @LF & _
				"the START button is clicked, the Console window opens, and" & @LF & _
				"the list of files is processed, testing the integrity of each one." & @LF & _
				"NOTE - Multiple drag & drop is supported (Thanks to Lazycat)." & @LF & @LF & _
				"When an EXE file is tested, all companion BIN files are tested as" & @LF & _
				"well. For each main file, a '%name% - Results file' is created. It" & @LF & _
				"contains the same data as shown in the DOS Console window." & @LF & @LF & _
				"A 'Log.txt' file is also written to with a simple result for each file" & @LF & _
				"tested. If you truly wish to disable the creation of the 'Results.txt'" & @LF & _
				"files, just modify an entry in 'Settings.ini' (save=1 to save=4)." & @LF & @LF & _
				"Both the LIST and LOG buttons on the dropbox, have right-click" & @LF & _
				"'Clear' options, for easy wiping ... or just edit them manually." & @LF & @LF & _
				"The 'Kill not Close' option, uses 'taskkill.exe' to close '7za.exe' or" & @LF & _
				"'innoextract.exe' if you stop during testing. It should hopefully" & @LF & _
				"not be required to close them, and perhaps best avoided." & @LF & @LF & _
				"During testing, some options can take a while to be responded" & @LF & _
				"to (i.e. 'Stop During' and 'ON Top')." & @LF & @LF & _
				"© March 2020 - Created by Timboli. (v1.1 update)", 0, $ConsoleGUI)
		Case $msg = $Checkbox_show
			; Show a 'Finished' dialog after all Jobs are Finished
			If GUICtrlRead($Checkbox_show) = $GUI_CHECKED Then
				$show = 1
			Else
				$show = 4
			EndIf
			IniWrite($inifle, "On Jobs Finished", "dialog", $show)
		Case $msg = $Checkbox_send
			; Send 'Results.txt' files to the 'Results' folder
			If GUICtrlRead($Checkbox_send) = $GUI_CHECKED Then
				$send = 1
			Else
				$send = 4
			EndIf
			IniWrite($inifle, "Results Files", "send", $send)
		Case $msg = $Checkbox_save
			; Enable creation of the 'Results.txt' files
			If GUICtrlRead($Checkbox_save) = $GUI_CHECKED Then
				$save = 1
				GUICtrlSetState($Checkbox_create, $GUI_ENABLE)
				If $create = 1 Then GUICtrlSetState($Checkbox_send, $GUI_ENABLE)
			Else
				$save = 4
				GUICtrlSetState($Checkbox_create, $GUI_DISABLE)
				If $create = 1 Then GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
			EndIf
			IniWrite($inifle, "Testing Results", "save", $save)
		Case $msg = $Checkbox_kill
			; Kill the InnoExtract process, not close
			If GUICtrlRead($Checkbox_kill) = $GUI_CHECKED Then
				$kill = 1
			Else
				$kill = 4
			EndIf
			IniWrite($inifle, "Taskkill For Cancel", "use", $kill)
		Case $msg = $Checkbox_exit
			; Exit On Jobs Finished
			If GUICtrlRead($Checkbox_exit) = $GUI_CHECKED Then
				$exit = 1
			Else
				$exit = 4
			EndIf
			IniWrite($inifle, "On Jobs Finished", "auto_exit", $exit)
		Case $msg = $Checkbox_create
			; Create a folder for 'Results.txt' files
			If GUICtrlRead($Checkbox_create) = $GUI_CHECKED Then
				$create = 1
				GUICtrlSetState($Checkbox_send, $GUI_ENABLE)
			Else
				$create = 4
				GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
			EndIf
			IniWrite($inifle, "Results Folder", "create", $create)
		Case $msg = $Checkbox_beep
			; Beep after all Jobs are Finished
			If GUICtrlRead($Checkbox_beep) = $GUI_CHECKED Then
				$beep = 1
				$frequency = InputBox("Beep Frequency", "Set the frequency to use." & @LF & "(number from 37 to 32767)", $frequency, "", 200, 140, Default, Default, 0, $ConsoleGUI)
				If @error Or $frequency = "" Then
					$frequency = 1200
				ElseIf $frequency < 37 Or $frequency > 32767 Then
					$frequency = 1200
				EndIf
				IniWrite($inifle, "Beep", "frequency", $frequency)
				$duration = InputBox("Beep Duration", "Set the duration to use. 1000 = 1 second." & @LF & "(length of the beep in milliseconds)", $duration, "", 250, 140, Default, Default, 0, $ConsoleGUI)
				If @error Or $duration = "" Then
					$duration = 1500
				ElseIf $duration < 30 Then
					$duration = 30
				ElseIf $duration > 10000 Then
					$duration = 10000
				EndIf
				IniWrite($inifle, "Beep", "duration", $duration)
				Beep($frequency, $duration)
			Else
				$beep = 4
			EndIf
			IniWrite($inifle, "On Jobs Finished", "beep", $beep)
		Case $msg = $Combo_shutdown
			; Shutdown Process
			$shutdown = GUICtrlRead($Combo_shutdown)
			IniWrite($inifle, "After Downloads", "shutdown", $shutdown)
			If $shutdown = "none" Then
				WinSetTitle($ConsoleGUI, "", "GOGDownload Checker Console")
			Else
				WinSetTitle($ConsoleGUI, "", "GOGDownload Checker Console - SHUTDOWN ENABLED")
			EndIf
		Case Else
			If $start = 1 Then
				GUICtrlSetState($Button_info, $GUI_DISABLE)
				Local $limit, $reached
				$limit = _GUICtrlEdit_GetLimitText($Edit_console)
				IniWrite($inifle, "Edit Control Text", "limit", $limit)
				IniWrite($inifle, "Testing", "started", _Now())
				$job = 0
				For $j = 1 To $array[0]
					$path = $array[$j]
					If $path <> "" Then
						If FileExists($path) Then
							_FileWriteLog($logfle, "Checking = " & $path)
							$job = $job + 1
							GUICtrlSetData($Input_job, $job)
							GUICtrlSetData($Input_path, $path)
							_GUICtrlListBox_SetCurSel($List_jobs, 0)
							GUICtrlSetData($Label_state, "WORKING")
							GUICtrlSetBkColor($Label_state, 0xFFFF00) ; Yellow
							_PathSplit($path, $drv, $dir, $fnam, $fext)
							GUICtrlSetData($Input_title, $fnam & $fext)
							;
							$resfile = $drv & $dir & $fnam & " - Results.txt"
							;If $create = 1 Then
							If GUICtrlRead($Checkbox_create) = $GUI_CHECKED Then
								$resfold = $drv & $dir & "Results"
								DirCreate($resfold)
								;If $send = 1 Then
								If GUICtrlRead($Checkbox_send) = $GUI_CHECKED Then
									If FileExists($resfold) Then $resfile = $resfold & "\" & $fnam & " - Results.txt"
								EndIf
							EndIf
							;
							GUICtrlSetData($Edit_console, "")
							;Sleep(2000)
							;
							$cancel = ""
							$err = ""
							$result = ""
							$results = ""
							$text = ""
							$zip = ""
							FileChangeDir(@ScriptDir)
							If $fext = ".exe" Then
								GetFileSize()
								;$ret = Run(@ComSpec & ' /k innoextract.exe --test --gog -p on "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
								;$ret = Run(@ComSpec & ' /k innoextract.exe --test --gog "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
								$ret = Run('innoextract.exe --test --gog "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
								$pid = $ret
								$line = 0
								While 1
									$out = StdoutRead($ret)
									If @error Then
										; Exit the loop if the process closes or StdoutRead returns an error.
										; NOTE - If process closes without error, then two Exitloops should occur, without getting an error $val.
										While 1
											$out = StderrRead($ret)
											If @error Then
												; Exit the loop if the process closes or StderrRead returns an error.
												ExitLoop
											EndIf
											;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
											$err = 1
											_GUICtrlEdit_AppendText($Edit_console, @CRLF & $out)
											_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
										WEnd
										If $out <> "" Then $results &= $out
										ExitLoop
									Else
										If $out <> "" Then
											$output = StringSplit($out, @CR, 1)
											For $o = 1 To $output[0]
												$out = $output[$o]
												$out = StringStripWS($out, 7)
												If $out <> "" Then
													$out = $out & @CRLF
													_GUICtrlEdit_AppendText($Edit_console, $out)
													_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
													If $out = "Done." & @CRLF Then
														If $out <> "" Then $results &= $out
														;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
														ExitLoop
													ElseIf StringInStr($out, "Done") > 0 Then
														If StringInStr($out, " error.") > 0 Or StringInStr($out, " error ") > 0 Then
															If $out <> "" Then $results &= $out
															$err = 2
															;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
															ExitLoop
														EndIf
													EndIf
													$results &= $out
													$line = $line + 1
													If $line = 25 Then
														$text = $results & "###### SEE THE '" & $fnam & " - Results.txt' FILE FOR FULL DETAIL ######" & @CRLF
														_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
													ElseIf $line = 50 Then
														GUICtrlSetData($Edit_console, $text)
														$line = 26
														_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
													EndIf
												EndIf
											Next
											$reached = _GUICtrlEdit_GetTextLen($Edit_console)
											IniWrite($inifle, "Edit Control Text", "count", $reached)
										EndIf
									EndIf
									If GUICtrlRead($Checkbox_during) = $GUI_CHECKED Then
										$cancel = 1
										GUICtrlSetState($Checkbox_during, $GUI_UNCHECKED)
										$ans = MsgBox(33 + 262144 + 256, "Stop Query", _
										   "Do you really want to cancel processing" & @LF & _
										   "right NOW, before the current job has" & @LF & _
										   "fully completed?" & @LF & @LF & _
										   "OK = STOP NOW." & @LF & _
										   "CANCEL = Let current job finish first.", 0, $ConsoleGUI)
										If $ans = 1 Then
											; Quit or Exit testing
											If GUICtrlRead($Checkbox_kill) = $GUI_CHECKED Then
												Run(@SystemDir & '\taskkill.exe /IM "' & $pid & '" /T /F', @SystemDir, @SW_HIDE)
											Else
												ProcessClose($pid)
											EndIf
											$cancel = 1
											ExitLoop
										ElseIf $ans = 2 Then
											; Leave until current job finished
											GUICtrlSetState($Checkbox_stop, $GUI_CHECKED)
										EndIf
									EndIf
								Wend
							ElseIf $fext = ".sh" Then
								GetFileSize()
								If $zipcheck = 1 Then
									$zip = 1
									FileChangeDir(@ScriptDir & "\7-Zip")
									$ret = Run('7za.exe t -tzip "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
									$pid = $ret
									$line = 0
									While 1
										$out = StdoutRead($ret)
										If @error Then
											; Exit the loop if the process closes or StdoutRead returns an error.
											; NOTE - If process closes without error, then two Exitloops should occur, without getting an error $val.
											While 1
												$out = StderrRead($ret)
												If @error Then
													; Exit the loop if the process closes or StderrRead returns an error.
													ExitLoop
												EndIf
												;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
												$err = 1
												_GUICtrlEdit_AppendText($Edit_console, @CRLF & $out)
												_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
											WEnd
											If $out <> "" Then $results &= $out
											ExitLoop
										Else
											If $out <> "" Then
												$output = StringSplit($out, @CR, 1)
												For $o = 1 To $output[0]
													$out = $output[$o]
													$out = StringStripWS($out, 7)
													If $out <> "" Then
														$out = $out & @CRLF
														_GUICtrlEdit_AppendText($Edit_console, $out)
														_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
														If StringInStr($out, "Everything is Ok") > 0 Then
															$result = "good"
															;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
														EndIf
														$results &= $out
														$line = $line + 1
														If $line = 25 Then
															$text = $results & "###### SEE THE '" & $fnam & " - Results.txt' FILE FOR FULL DETAIL ######" & @CRLF
															_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
														ElseIf $line = 50 Then
															GUICtrlSetData($Edit_console, $text)
															$line = 26
															_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
														EndIf
													EndIf
												Next
											EndIf
										EndIf
										If GUICtrlRead($Checkbox_during) = $GUI_CHECKED Then
											$cancel = 1
											GUICtrlSetState($Checkbox_during, $GUI_UNCHECKED)
											$ans = MsgBox(33 + 262144 + 256, "Stop Query", _
											   "Do you really want to cancel processing" & @LF & _
											   "right NOW, before the current job has" & @LF & _
											   "fully completed?" & @LF & @LF & _
											   "OK = STOP NOW." & @LF & _
											   "CANCEL = Let current job finish first.", 0, $ConsoleGUI)
											If $ans = 1 Then
												; Quit or Exit testing
												If GUICtrlRead($Checkbox_kill) = $GUI_CHECKED Then
													Run(@SystemDir & '\taskkill.exe /IM "' & $pid & '" /T /F', @SystemDir, @SW_HIDE)
												Else
													ProcessClose($pid)
												EndIf
												$cancel = 1
												ExitLoop
											ElseIf $ans = 2 Then
												; Leave until current job finished
												GUICtrlSetState($Checkbox_stop, $GUI_CHECKED)
											EndIf
										EndIf
									Wend
									If $result = "good" Then
										Sleep(2000)
										FileChangeDir(@ScriptDir & "\7-Zip")
										$ret = Run('7za.exe l -tzip "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
										$pid = $ret
										$line = 0
										While 1
											$out = StdoutRead($ret)
											If @error Then
												; Exit the loop if the process closes or StdoutRead returns an error.
												; NOTE - If process closes without error, then two Exitloops should occur, without getting an error $val.
												While 1
													$out = StderrRead($ret)
													If @error Then
														; Exit the loop if the process closes or StderrRead returns an error.
														ExitLoop
													EndIf
													;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
													$err = 1
													_GUICtrlEdit_AppendText($Edit_console, @CRLF & $out)
													_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
												WEnd
												If $out <> "" Then $results &= $out
												ExitLoop
											Else
												If $out <> "" Then
													$output = StringSplit($out, @CR, 1)
													For $o = 1 To $output[0]
														$out = $output[$o]
														$out = StringStripWS($out, 7)
														If $out <> "" Then
															$out = $out & @CRLF
															_GUICtrlEdit_AppendText($Edit_console, $out)
															_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
															$results &= $out
															$line = $line + 1
															If $line = 25 Then
																$text = $results & "###### SEE THE '" & $fnam & " - Results.txt' FILE FOR FULL DETAIL ######" & @CRLF
																_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
															ElseIf $line = 50 Then
																GUICtrlSetData($Edit_console, $text)
																$line = 26
																_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
															EndIf
														EndIf
													Next
													$reached = _GUICtrlEdit_GetTextLen($Edit_console)
													IniWrite($inifle, "Edit Control Text", "count", $reached)
												EndIf
											EndIf
											If GUICtrlRead($Checkbox_during) = $GUI_CHECKED Then
												$cancel = 1
												GUICtrlSetState($Checkbox_during, $GUI_UNCHECKED)
												$ans = MsgBox(33 + 262144 + 256, "Stop Query", _
												   "Do you really want to cancel processing" & @LF & _
												   "right NOW, before the current job has" & @LF & _
												   "fully completed?" & @LF & @LF & _
												   "OK = STOP NOW." & @LF & _
												   "CANCEL = Let current job finish first.", 0, $ConsoleGUI)
												If $ans = 1 Then
													; Quit or Exit testing
													If GUICtrlRead($Checkbox_kill) = $GUI_CHECKED Then
														Run(@SystemDir & '\taskkill.exe /IM "' & $pid & '" /T /F', @SystemDir, @SW_HIDE)
													Else
														ProcessClose($pid)
													EndIf
													$cancel = 1
													ExitLoop
												ElseIf $ans = 2 Then
													; Leave until current job finished
													GUICtrlSetState($Checkbox_stop, $GUI_CHECKED)
												EndIf
											EndIf
										Wend
									EndIf
								Else
									$err = 3
								EndIf
							ElseIf $fext = ".zip" Or $fext = ".7z" Or $fext = ".rar" Then
								GetFileSize()
								If $zipcheck = 1 Then
									$zip = 1
									FileChangeDir(@ScriptDir & "\7-Zip")
									$ret = Run('7za.exe t "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
									$pid = $ret
									$line = 0
									While 1
										$out = StdoutRead($ret)
										If @error Then
											; Exit the loop if the process closes or StdoutRead returns an error.
											; NOTE - If process closes without error, then two Exitloops should occur, without getting an error $val.
											While 1
												$out = StderrRead($ret)
												If @error Then
													; Exit the loop if the process closes or StderrRead returns an error.
													ExitLoop
												EndIf
												;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
												$err = 1
												_GUICtrlEdit_AppendText($Edit_console, @CRLF & $out)
												_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
											WEnd
											If $out <> "" Then $results &= $out
											ExitLoop
										Else
											If $out <> "" Then
												$output = StringSplit($out, @CR, 1)
												For $o = 1 To $output[0]
													$out = $output[$o]
													$out = StringStripWS($out, 7)
													If $out <> "" Then
														$out = $out & @CRLF
														_GUICtrlEdit_AppendText($Edit_console, $out)
														_GUICtrlEdit_Scroll($Edit_console, $SB_PAGEDOWN)
														If StringInStr($out, "Everything is Ok") > 0 Then
															$result = "good"
															;MsgBox($MB_SYSTEMMODAL, "Stderr Read:", $out)
														EndIf
														$results &= $out
														$line = $line + 1
														If $line = 25 Then
															$text = $results & "###### SEE THE '" & $fnam & " - Results.txt' FILE FOR FULL DETAIL ######" & @CRLF
															_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
														ElseIf $line = 50 Then
															GUICtrlSetData($Edit_console, $text)
															$line = 26
															_GUICtrlEdit_EmptyUndoBuffer($Edit_console)
														EndIf
													EndIf
												Next
											EndIf
										EndIf
										If GUICtrlRead($Checkbox_during) = $GUI_CHECKED Then
											$cancel = 1
											GUICtrlSetState($Checkbox_during, $GUI_UNCHECKED)
											$ans = MsgBox(33 + 262144 + 256, "Stop Query", _
											   "Do you really want to cancel processing" & @LF & _
											   "right NOW, before the current job has" & @LF & _
											   "fully completed?" & @LF & @LF & _
											   "OK = STOP NOW." & @LF & _
											   "CANCEL = Let current job finish first.", 0, $ConsoleGUI)
											If $ans = 1 Then
												; Quit or Exit testing
												If GUICtrlRead($Checkbox_kill) = $GUI_CHECKED Then
													Run(@SystemDir & '\taskkill.exe /IM "' & $pid & '" /T /F', @SystemDir, @SW_HIDE)
												Else
													ProcessClose($pid)
												EndIf
												$cancel = 1
												ExitLoop
											ElseIf $ans = 2 Then
												; Leave until current job finished
												GUICtrlSetState($Checkbox_stop, $GUI_CHECKED)
											EndIf
										EndIf
									Wend
								Else
									$err = 3
								EndIf
							EndIf
							If GUICtrlRead($Checkbox_save) = $GUI_CHECKED Then FileWrite($resfile, $results)
							;
							If ($err = "" And $cancel = "") And ($fext = ".exe" Or ($result = "good" And $zip = 1)) Then
								$passed = "(PASSED) "
								_FileWriteLog($logfle, "(PASSED) " & $path)
								_ReplaceStringInFile($listfle, $path & @CRLF, "")
							Else
								If $err = 1 Then
									$passed = "(FAILED) "
								ElseIf $err = 2 Then
									$passed = "(ERROR) "
								ElseIf $err = 3 Then
									$passed = "(7-Zip MISSING) "
								ElseIf $result = "" And $zip = 1 Then
									$passed = "(ERRED) "
								Else
									$passed = "(CANCELLED) "
								EndIf
								_FileWriteLog($logfle, $passed & $path)
								If $cancel = 1 Then _FileWriteLog($logfle, "(USER CANCELLED)")
							EndIf
							;
							_GUICtrlListBox_DeleteString($List_jobs, 0)
							GUICtrlSetData($List_done, $passed & $path)
							GUICtrlSetData($Input_title, "")
							GUICtrlSetData($Input_path, "")
							GUICtrlSetData($Label_state, "FINISHED " & $job)
							GUICtrlSetBkColor($Label_state, 0x00FF00) ; Green
							Sleep(3000)
							If GUICtrlRead($Button_ontop) = $GUI_CHECKED Then
								If $ontop = 4 Then
									WinSetOnTop($ConsoleGUI, "", 1)
									$ontop = 1
								EndIf
							Else
								If $ontop = 1 Then
									WinSetOnTop($ConsoleGUI, "", 0)
									$ontop = 4
								EndIf
							EndIf
						Else
							_FileWriteLog($logfle, "MISSING = " & $path)
						EndIf
					EndIf
					If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then
						GUICtrlSetState($Checkbox_stop, $GUI_UNCHECKED)
						$ans = MsgBox(33 + 262144 + 256, "Stop Query", _
						   "Do you really want to cancel processing" & @LF & _
						   "before any other jobs have been tested?" & @LF & @LF & _
						   "OK = STOP ALL NOW." & @LF & _
						   "CANCEL = Continue with testing.", 0, $ConsoleGUI)
						If $ans = 1 Then
							; Quit or Exit testing
							$cancel = 1
						Else
							$cancel = ""
						EndIf
					EndIf
					If $cancel = 1 Then ExitLoop
				Next
				GUICtrlSetState($Button_info, $GUI_ENABLE)
				$start = 2
				If GUICtrlRead($Checkbox_exit) = $GUI_CHECKED Then $close = 1
				;
				If GUICtrlRead($Checkbox_beep) = $GUI_CHECKED Then Beep($frequency, $duration)
				;
				IniWrite($inifle, "Testing", "finished", _Now())
				;
				$shutdown = GUICtrlRead($Combo_shutdown)
				If $shutdown <> "none" Then
					$ans = MsgBox(262193, "Shutdown Query", _
						"PC is set to shutdown in 99 seconds." & @LF & @LF & _
						"OK = Shutdown." & @LF & _
						"CANCEL = Abort shutdown.", 99, $ConsoleGUI)
					If $ans = 1 Or $ans = -1 Then
						If $shutdown = "Shutdown" Then
							; Shutdown
							$code = 1 + 4 + 16
						ElseIf $shutdown = "Hibernate" Then
							; Hibernate
							$code = 64
						ElseIf $shutdown = "Standby" Then
							; Standby
							$code = 32
						ElseIf $shutdown = "Powerdown" Then
							; Powerdown
							$code = 8 + 4 + 16
						ElseIf $shutdown = "Logoff" Then
							; Logoff
							$code = 0 + 4 + 16
						EndIf
						Shutdown($code)
					EndIf
				EndIf
				;
				If $close = 1 Then
					If GUICtrlRead($Checkbox_show) = $GUI_CHECKED Then
						$show = 1
					Else
						$show = 4
					EndIf
				EndIf
				;MsgBox(262144 + 64, "Text", $text & " - " & $line, 0, $ConsoleGUI)
			EndIf
		Case Else
			;;;
		EndSelect
	WEnd
	;If $beep = 1 Then Beep($frequency, $duration)
	;
	If $show = 1 And $start = 2 And $close = 1 Then MsgBox(262144 + 64, "Testing", "All jobs have finished!")
	;
	;Done.
	;Not a supported Inno Setup installer!
	;Done with 1 error.
	;
	;Stream error while extracting files!
	; â””â”€ error reason: zlib error: iostream error
	;If you are sure the setup file is not corrupted, consider
	;filing a bug report at http://innoextract.constexpr.org/issues
	;Done with 1 error.
	;
	;- "app/data.zip"
	;Warning: Checksum mismatch:
	;├─ actual:   SHA-1 48b430840d9398452052cfa0822e673897b6cbbe
	;└─ expected: SHA-1 2c2dd16ce66b3da5517e3465e57c63d36735fbd4
	;Integrity test failed!
	;Done with 1 error and 1 warning.
EndFunc ;=> ImitationConsoleGUI


Func AddFileToList()
	GUICtrlSetBkColor($Label_drop, $COLOR_BLACK)
	GUICtrlSetColor($Label_drop, $COLOR_WHITE)
	;
	GUISetState(@SW_DISABLE, $DropboxGUI)
	GUICtrlSetState($Button_start, $GUI_DISABLE)
	GUICtrlSetState($Button_list, $GUI_DISABLE)
	GUICtrlSetState($Button_log, $GUI_DISABLE)
	GUICtrlSetState($Button_opts, $GUI_DISABLE)
	;
	_PathSplit($srcfle, $drv, $dir, $fnam, $fext)
	If $fext = ".exe" Or $fext = ".zip" Or $fext = ".7z" Or $fext = ".rar" Or $fext = ".sh" Then
		If Not FileExists($listfle) Then _FileCreate($listfle)
		FileWriteLine($listfle, $srcfle)
		_FileReadToArray($listfle, $array)
		$array = _ArrayUnique($array)
		_FileCreate($listfle)
		$array = _ArrayToString($array, @CRLF, 2)
		FileWrite($listfle, $array & @CRLF)
	Else
		MsgBox(262192, "File Error", "Only EXE or ZIP or 7Z or RAR or SH (not yet) are supported!", 0, $DropboxGUI)
	EndIf
	;
	GUISetState(@SW_ENABLE, $DropboxGUI)
	GUICtrlSetState($Button_start, $GUI_ENABLE)
	GUICtrlSetState($Button_list, $GUI_ENABLE)
	GUICtrlSetState($Button_log, $GUI_ENABLE)
	GUICtrlSetState($Button_opts, $GUI_ENABLE)
	;
	GUICtrlSetData($Label_drop, $target)
	GUICtrlSetBkColor($Label_drop, $boxcol)
	GUICtrlSetColor($Label_drop, $textcol)
EndFunc ;=> AddFileToList

Func GetFileSize()
	Local $f, $file, $files, $foldpth
	$size = FileGetSize($path)
	If $fext = ".exe" Then
		$foldpth = StringTrimRight($drv & $dir, 1)
		$files = _FileListToArray($foldpth, $fnam & "*.bin", $FLTA_FILES , True)
		If Not @error Then
			If $files[0] > 0 Then
				For $f = 1 To $files[0]
					$file = $files[$f]
					$size = $size + FileGetSize($file)
				Next
			EndIf
		EndIf
	EndIf
	If $size > 1023 Then
		If $size > 1048575 Then
			If $size > 1073741823 Then
				$size = Round($size / 1073741824, 2) & " GBs"
			Else
				$size = Round($size / 1048576, 2) & " MBs"
			EndIf
		Else
			$size = Ceiling($size / 1024) & " KBs"
		EndIf
	Else
		$size = $size & " bytes"
	EndIf
	GUICtrlSetData($Input_size, $size)
EndFunc ;=> GetFileSize

; Provided by Lazycat, June 23, 2006 in AutoIt Example Scripts (Drop multiple files on any control)
Func WM_DROPFILES_FUNC($hWnd, $msgID, $wParam, $lParam)
    Local $nSize, $pFileName, $i
    Local $nAmt = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", 0xFFFFFFFF, "ptr", 0, "int", 255)
    For $i = 0 To $nAmt[0] - 1
        $nSize = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", 0, "int", 0)
        $nSize = $nSize[0] + 1
        $pFileName = DllStructCreate("char[" & $nSize & "]")
        DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", DllStructGetPtr($pFileName), "int", $nSize)
        ReDim $gaDropFiles[$i+1]
        $gaDropFiles[$i] = DllStructGetData($pFileName, 1)
        $pFileName = 0
    Next
	If IsArray($gaDropFiles) Then
		_ArraySort($gaDropFiles, 0, 0)
	EndIf
EndFunc ;=> WM_DROPFILES_FUNC

