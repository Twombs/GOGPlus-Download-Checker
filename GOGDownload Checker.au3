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

Global $7zip, $array, $atts, $boxcol, $cnt, $dir, $DropboxGUI, $drv, $fext, $fnam, $foldpdf, $foldrar
Global $foldzip, $inifle, $innoextract, $left, $listfle, $logfle, $notepad, $path, $pdf, $pdfcheck
Global $qpdf, $rarcheck, $size, $srcfle, $start, $style, $target, $text, $textcol, $top, $tot, $unrar
Global $version, $zipcheck

Global $gaDropFiles[1], $hWnd, $lParam, $msgID, $wParam
; NOTE - If using older AutoIt, then $WM_DROPFILES = 0x233 may need to be declared.

$7zip = @ScriptDir & "\7-Zip\7za.exe"
$foldpdf = @ScriptDir & "\QPDF"
$foldrar = @ScriptDir & "\UnRAR"
$foldzip = @ScriptDir & "\7-Zip"
$inifle = @ScriptDir & "\Settings.ini"
$innoextract = @ScriptDir & "\innoextract.exe"
$logfle = @ScriptDir & "\Log.txt"
$listfle = @ScriptDir & "\Files.txt"
$notepad = @WindowsDir & "\Notepad.exe "
$qpdf = @ScriptDir & "\QPDF\bin\qpdf.exe"
$target = @LF & "Drag && Drop" & @LF & "Downloaded" & @LF & "Game Files" & @LF & "HERE"
$unrar = @ScriptDir & "\UnRAR\UnRAR.exe"
$version = "v1.2 April update"

If Not FileExists($foldpdf) Then DirCreate($foldpdf)
If Not FileExists($foldrar) Then DirCreate($foldrar)
If Not FileExists($foldzip) Then DirCreate($foldzip)

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
				If FileExists($unrar) Then
					$rarcheck = 1
				Else
					$rarcheck = ""
					;MsgBox(262192, "Program Error", "UnRAR (UnRAR.exe) is Required for RAR files and is missing!", 0, $DropboxGUI)
				EndIf
				If FileExists($7zip) Then
					$zipcheck = 1
				Else
					$zipcheck = ""
					;MsgBox(262192, "Program Error", "7-Zip (7za.exe) is Required for ZIP files and is missing!", 0, $DropboxGUI)
				EndIf
				If FileExists($qpdf) Then
					$pdfcheck = 1
				Else
					$pdfcheck = ""
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
	Local $Button_info, $Button_ontop, $Checkbox_beep, $Checkbox_during, $Checkbox_exe, $Checkbox_exit, $Checkbox_images
	Local $Checkbox_kill, $Checkbox_list, $Checkbox_pdf, $Checkbox_rar, $Checkbox_results, $Checkbox_save, $Checkbox_send
	Local $Checkbox_sh, $Checkbox_show, $Checkbox_shutdown, $Checkbox_stay, $Checkbox_slash, $Checkbox_stop, $Checkbox_zip
	Local $Edit_console, $Group_console, $Group_done, $Group_job, $Group_jobs
	Local $Input_job, $Input_jobs,$Input_path, $Input_title
	Local $Label_check, $Label_job, $Label_path, $Label_size, $Label_state, $Label_status, $Label_title
	Local $List_done, $List_jobs
	;
	Local $a, $beep, $cancel, $close, $ConsoleGUI, $create, $dopdf, $dorar, $dosh, $dozip, $duration, $err, $errors, $exit
	Local $frequency, $height, $ind, $j, $job, $line, $list, $ontop, $o, $out, $output, $passed, $pid, $rar, $resfile, $resfold
	Local $results, $ret, $save, $send, $show, $shutdown, $shutoptions, $shutwarn, $skipped, $slash, $stay, $type, $width
	Local $zip
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
	$height = 590
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
	$Checkbox_exit = GUICtrlCreateCheckbox("Exit On Jobs Finished", 10, 495, 120, 20)
	GUICtrlSetTip($Checkbox_exit, "Close the Console after all Jobs are Finished!")
	$Checkbox_stay = GUICtrlCreateCheckbox("Stay Open On Error", 20, 515, 120, 20)
	GUICtrlSetTip($Checkbox_stay, "Keep the Console open if a testing error occurred!")
	;
	$Label_status = GUICtrlCreateLabel("Status", 140, 498, 50, 30, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_status, $Color_Black)
	GUICtrlSetColor($Label_status, $Color_White)
	$Label_state = GUICtrlCreateLabel("", 190, 498, 140, 30, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetColor($Label_state, $Color_Black)
	GUICtrlSetTip($Label_state, "Current state of Processing!")
	;
	$Checkbox_during = GUICtrlCreateCheckbox("Stop During", 340, 495, 75, 20)
	GUICtrlSetTip($Checkbox_during, "Stop during Current Job or Process!")
	$Checkbox_kill = GUICtrlCreateCheckbox("Kill not Close", 340, 515, 80, 20)
	GUICtrlSetTip($Checkbox_kill, "Kill the InnoExtract process, not close!")
	;
	$Label_shutdown = GUICtrlCreateLabel("Shutdown", 430, 502, 70, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_shutdown, $Color_Black)
	GUICtrlSetColor($Label_shutdown, $Color_White)
	$Combo_shutdown = GUICtrlCreateCombo("", 500, 502, 75, 21)
	GUICtrlSetTip($Combo_shutdown, "Shutdown Options!")
	;
	$Button_ontop = GUICtrlCreateCheckbox("ON Top", 585, 498, 60, 30, $BS_PUSHLIKE)
	GUICtrlSetFont($Button_ontop, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_ontop, "Toggle the window On Top setting!")
	;
	$Button_info = GUICtrlCreateButton("INFO", 655, 498, 45, 30)
	GUICtrlSetFont($Button_info, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Checkbox_stop = GUICtrlCreateCheckbox("Stop After Current Job", 10, 536, 120, 20)
	GUICtrlSetTip($Checkbox_stop, "Stop After Current Job or Process!")
	;
	$Label_check = GUICtrlCreateLabel("Files To Check", 140, 535, 90, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_check, $Color_Blue)
	GUICtrlSetColor($Label_check, $Color_White)
	;
	$Checkbox_exe = GUICtrlCreateCheckbox("EXE", 237, 536, 40, 20)
	GUICtrlSetTip($Checkbox_exe, "EXEcutable files (InnoSetup ones only)!")
	$Checkbox_zip = GUICtrlCreateCheckbox("ZIP", 283, 536, 40, 20)
	GUICtrlSetTip($Checkbox_zip, "Compressed files (ZIP, 7Z, BZ2 only)!")
	$Checkbox_rar = GUICtrlCreateCheckbox("RAR", 326, 536, 40, 20)
	GUICtrlSetTip($Checkbox_rar, "Compressed file (RAR only)!")
	$Checkbox_sh = GUICtrlCreateCheckbox("SH", 373, 536, 35, 20)
	GUICtrlSetTip($Checkbox_sh, "Linux compressed script file!")
	$Checkbox_pdf = GUICtrlCreateCheckbox("PDF", 413, 536, 40, 20)
	GUICtrlSetTip($Checkbox_pdf, "Document file (PDF only)!")
	$Checkbox_images = GUICtrlCreateCheckbox("IMAGE", 458, 536, 50, 20)
	GUICtrlSetTip($Checkbox_images, "Image files (not yet supported)!")
	;
	$Checkbox_list = GUICtrlCreateCheckbox("List Zip Content", 523, 536, 90, 20)
	GUICtrlSetTip($Checkbox_list, "List the Content of Zip files!")
	;
	$Checkbox_slash = GUICtrlCreateCheckbox("Underslash", 628, 536, 70, 20)
	GUICtrlSetTip($Checkbox_slash, "Add leading underslash to 'Results' name!")
	;
	$Checkbox_show = GUICtrlCreateCheckbox("Show a 'Finished' dialog", 10, 560, 130, 20)
	GUICtrlSetTip($Checkbox_show, "Show a 'Finished' dialog after all Jobs are Finished!")
	;
	$Checkbox_beep = GUICtrlCreateCheckbox("Beep on finish", 150, 560, 85, 20)
	GUICtrlSetTip($Checkbox_beep, "Beep after all Jobs are Finished!")
	;
	$Checkbox_save = GUICtrlCreateCheckbox("Enable creation of 'Results.txt' files", 245, 560, 180, 20)
	GUICtrlSetTip($Checkbox_save, "Enable creation of the 'Results.txt' files!")
	;
	$Checkbox_create = GUICtrlCreateCheckbox("Create a 'Results' folder", 435, 560, 130, 20)
	GUICtrlSetTip($Checkbox_create, "Create a folder for 'Results.txt' files!")
	;
	$Checkbox_send = GUICtrlCreateCheckbox("Send to 'Results' folder", 575, 560, 125, 20)
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
		$stay = IniRead($inifle, "On Testing Error", "stay_open", "")
		If $stay = "" Then
			$stay = 4
			IniWrite($inifle, "On Testing Error", "stay_open", $stay)
		EndIf
		GUICtrlSetState($Checkbox_stay, $stay)
		If $exit = 4 Then GUICtrlSetState($Checkbox_stay, $GUI_DISABLE)
		;
		$kill = IniRead($inifle, "Taskkill For Cancel", "use", "")
		If $kill = "" Then
			$kill = 1
			IniWrite($inifle, "Taskkill For Cancel", "use", $kill)
		EndIf
		GUICtrlSetState($Checkbox_kill, $kill)
		;
		$ontop = IniRead($inifle, "Console", "ontop", "")
		If $ontop = "" Then
			$ontop = 1
			IniWrite($inifle, "Console", "ontop", $ontop)
		EndIf
		GUICtrlSetState($Button_ontop, $ontop)
		If $ontop = 4 Then WinSetOnTop($ConsoleGUI, "", 0)
		;
		If FileExists($innoextract) Then
			GUICtrlSetState($Checkbox_exe, $GUI_CHECKED)
		EndIf
		GUICtrlSetState($Checkbox_exe, $GUI_DISABLE)
		;
		$dozip = IniRead($inifle, "Process Files", "zip", "")
		If FileExists($7zip) Then
			If $dozip = "" Then
				$dozip = 1
				IniWrite($inifle, "Process Files", "zip", $dozip)
			EndIf
			GUICtrlSetState($Checkbox_zip, $dozip)
			If $dozip = 4 Then GUICtrlSetState($Checkbox_list, $GUI_DISABLE)
			If $dosh = "" Then
				$dosh = 1
				IniWrite($inifle, "Process Files", "sh", $dosh)
			EndIf
			GUICtrlSetState($Checkbox_sh, $dosh)
		Else
			GUICtrlSetState($Checkbox_zip, $GUI_DISABLE)
			If $dozip = 1 Then MsgBox(262192, "Program Error", "7-Zip (7za.exe) is Required for ZIP files and is missing!", 0, $DropboxGUI)
			GUICtrlSetState($Checkbox_sh, $GUI_DISABLE)
			If $dosh = 1 Then MsgBox(262192, "Program Error", "7-Zip (7za.exe) is Required for SH files and is missing!", 0, $DropboxGUI)
			GUICtrlSetState($Checkbox_list, $GUI_DISABLE)
		EndIf
		;
		$dorar = IniRead($inifle, "Process Files", "rar", "")
		If FileExists($unrar) Then
			If $dorar = "" Then
				$dorar = 1
				IniWrite($inifle, "Process Files", "rar", $dorar)
			EndIf
			GUICtrlSetState($Checkbox_rar, $dorar)
		Else
			GUICtrlSetState($Checkbox_rar, $GUI_DISABLE)
			If $dorar = 1 Then MsgBox(262192, "Program Error", "UnRAR (UnRAR.exe) is Required for RAR files and is missing!", 0, $DropboxGUI)
		EndIf
		;
		$dopdf = IniRead($inifle, "Process Files", "pdf", "")
		If FileExists($qpdf) Then
			If $dopdf = "" Then
				$dopdf = 1
				IniWrite($inifle, "Process Files", "pdf", $dopdf)
			EndIf
			GUICtrlSetState($Checkbox_pdf, $dopdf)
		Else
			GUICtrlSetState($Checkbox_pdf, $GUI_DISABLE)
			If $dopdf = 1 Then MsgBox(262192, "Program Error", "QPDF (qpdf.exe) is Required for PDF files and is missing!", 0, $DropboxGUI)
		EndIf
		;
		; NOT YET SUPPORTED
		GUICtrlSetState($Checkbox_images, $GUI_DISABLE)
		;
		$list = IniRead($inifle, "Zip File Content", "list", "")
		If $list = "" Then
			$list = 4
			IniWrite($inifle, "Zip File Content", "list", $list)
		EndIf
		GUICtrlSetState($Checkbox_list, $list)
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
		$slash = IniRead($inifle, "Results Folder Name", "slash", "")
		If $slash = "" Then
			$slash = 4
			IniWrite($inifle, "Results Folder Name", "slash", $slash)
		EndIf
		GUICtrlSetState($Checkbox_slash, $slash)
		;
		If $save = 4 Then
			GUICtrlSetState($Checkbox_create, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_slash, $GUI_DISABLE)
		EndIf
		If $create = 4 And $save = 1 Then
			GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_slash, $GUI_DISABLE)
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
			$ans = MsgBox(262209 + 256, "Program Information", _
				"This program tests the integrity of game files downloaded from" & @LF & _
				"the GOG store. EXE (with BIN) files and ZIP files are supported." & @LF & @LF & _
				"The program uses InnoExtract to do the testing, which is freely" & @LF & _
				"available online. The 'innoextract.exe' file needs to exist in the" & @LF & _
				"same folder (directory) as this program." & @LF & @LF & _
				"The program also requires '7-Zip' to do the testing of ZIP files," & @LF & _
				"which is freely available online. The '7za.exe' file needs to exist" & @LF & _
				"in a '7-Zip' content folder, in the same folder as this program." & @LF & @LF & _
				"Program also requires 'UnRAR' to do the testing of RAR files," & @LF & _
				"which is freely available online. 'UnRAR.exe' file needs to exist" & @LF & _
				"in a 'UnRAR' content folder, in same folder as this program." & @LF & @LF & _
				"The program also requires 'QPDF' to do the testing of PDF files," & @LF & _
				"which is freely available online. The 'qpdf.exe' file needs to exist" & @LF & _
				"in a 'QPDF\bin' content folder, in same folder as this program." & @LF & @LF & _
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
				"Click OK to see more information", 0, $ConsoleGUI)
			If $ans = 1 Then
				MsgBox(262208, "Program Information", _
					"A 'Log.txt' file is also written to with a simple result for each file" & @LF & _
					"tested. If you wish to disable the creation of the 'Results.txt' files," & @LF & _
					"just change that setting on the Console window." & @LF & @LF & _
					"Both the LIST and LOG buttons on the dropbox, have right-click" & @LF & _
					"'Clear' options, for easy wiping ... or just edit them manually." & @LF & @LF & _
					"The 'Kill not Close' option, uses 'taskkill.exe' to close '7za.exe' or" & @LF & _
					"'innoextract.exe' if you stop during testing. It should hopefully" & @LF & _
					"not be required to close them, and perhaps best avoided." & @LF & @LF & _
					"During testing, some options can take a while to be responded" & @LF & _
					"to (i.e. 'Stop During' and 'ON Top'). NOTE - Settings cannot be" & @LF & _
					"permanently set (etc) during the testing process, and some do" & @LF & _
					"not enable others, like they do when not in the testing phase." & @LF & @LF & _
					"The programming language (AutoIt) used to code this program" & @LF & _
					"is not alas, multi-threaded ... but does a mighty fine job anyway." & @LF & @LF & _
					"Praise & BIG thanks as always, to Jon & team for free AutoIt." & @LF & @LF & _
					"© March 2020 - Created by Timboli. (" & $version & ")", 0, $ConsoleGUI)
			EndIf
		Case $msg = $Checkbox_zip
			; Compressed files (ZIP, 7Z, BZ2 only)
			If GUICtrlRead($Checkbox_zip) = $GUI_CHECKED Then
				$dozip = 1
				GUICtrlSetState($Checkbox_list, $GUI_ENABLE)
			Else
				$dozip = 4
				If $dosh = 4 Then GUICtrlSetState($Checkbox_list, $GUI_DISABLE)
			EndIf
			IniWrite($inifle, "Process Files", "zip", $dozip)
		Case $msg = $Checkbox_stay
			; Keep the Console open if a testing error occurred
			If GUICtrlRead($Checkbox_stay) = $GUI_CHECKED Then
				$stay = 1
			Else
				$stay = 4
			EndIf
			IniWrite($inifle, "On Testing Error", "stay_open", $stay)
		Case $msg = $Checkbox_slash
			; Add leading underslash to 'Results' name
			If GUICtrlRead($Checkbox_slash) = $GUI_CHECKED Then
				$slash = 1
			Else
				$slash = 4
			EndIf
			IniWrite($inifle, "Results Folder Name", "slash", $slash)
		Case $msg = $Checkbox_show
			; Show a 'Finished' dialog after all Jobs are Finished
			If GUICtrlRead($Checkbox_show) = $GUI_CHECKED Then
				$show = 1
			Else
				$show = 4
			EndIf
			IniWrite($inifle, "On Jobs Finished", "dialog", $show)
		Case $msg = $Checkbox_sh
			; Linux compressed script file
			If GUICtrlRead($Checkbox_sh) = $GUI_CHECKED Then
				$dosh = 1
				If $dozip = 4 Then GUICtrlSetState($Checkbox_list, $GUI_ENABLE)
			Else
				$dosh = 4
				If $dozip = 4 Then GUICtrlSetState($Checkbox_list, $GUI_DISABLE)
			EndIf
			IniWrite($inifle, "Process Files", "sh", $dosh)
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
				If $create = 1 Then
					GUICtrlSetState($Checkbox_send, $GUI_ENABLE)
					GUICtrlSetState($Checkbox_slash, $GUI_ENABLE)
				EndIf
			Else
				$save = 4
				GUICtrlSetState($Checkbox_create, $GUI_DISABLE)
				If $create = 1 Then
					GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
					GUICtrlSetState($Checkbox_slash, $GUI_DISABLE)
				EndIf
			EndIf
			IniWrite($inifle, "Testing Results", "save", $save)
		Case $msg = $Checkbox_rar
			; Compressed file (RAR only)
			If GUICtrlRead($Checkbox_rar) = $GUI_CHECKED Then
				$dorar = 1
			Else
				$dorar = 4
			EndIf
			IniWrite($inifle, "Process Files", "rar", $dorar)
		Case $msg = $Checkbox_pdf
			; Document file (PDF only)
			If GUICtrlRead($Checkbox_pdf) = $GUI_CHECKED Then
				$dopdf = 1
			Else
				$dopdf = 4
			EndIf
			IniWrite($inifle, "Process Files", "pdf", $dopdf)
		Case $msg = $Checkbox_list
			; List the Content of Zip files
			If GUICtrlRead($Checkbox_list) = $GUI_CHECKED Then
				$list = 1
			Else
				$list = 4
			EndIf
			IniWrite($inifle, "Zip File Content", "list", $list)
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
				GUICtrlSetState($Checkbox_stay, $GUI_ENABLE)
			Else
				$exit = 4
				GUICtrlSetState($Checkbox_stay, $GUI_DISABLE)
			EndIf
			IniWrite($inifle, "On Jobs Finished", "auto_exit", $exit)
		Case $msg = $Checkbox_create
			; Create a folder for 'Results.txt' files
			If GUICtrlRead($Checkbox_create) = $GUI_CHECKED Then
				$create = 1
				GUICtrlSetState($Checkbox_send, $GUI_ENABLE)
				GUICtrlSetState($Checkbox_slash, $GUI_ENABLE)
			Else
				$create = 4
				GUICtrlSetState($Checkbox_send, $GUI_DISABLE)
				GUICtrlSetState($Checkbox_slash, $GUI_DISABLE)
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
				$errors = 0
				$job = 0
				$skipped = 0
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
							$resfile = $drv & $dir & $fnam & $fext & " - Results.txt"
							;If $create = 1 Then
							If GUICtrlRead($Checkbox_create) = $GUI_CHECKED Then
								If GUICtrlRead($Checkbox_slash) = $GUI_CHECKED Then
									$resfold = $drv & $dir & "_Results"
								Else
									$resfold = $drv & $dir & "Results"
								EndIf
								DirCreate($resfold)
								;If $send = 1 Then
								If GUICtrlRead($Checkbox_send) = $GUI_CHECKED Then
									If FileExists($resfold) Then $resfile = $resfold & "\" & $fnam & $fext & " - Results.txt"
								EndIf
							EndIf
							;
							GUICtrlSetData($Edit_console, "")
							;Sleep(2000)
							;
							$cancel = ""
							$err = ""
							$pdf = ""
							$rar = ""
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
							ElseIf $fext = ".sh" And GUICtrlRead($Checkbox_sh) = $GUI_CHECKED Then
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
									If $result = "good" And GUICtrlRead($Checkbox_list) = $GUI_CHECKED Then
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
							ElseIf $fext = ".rar" And GUICtrlRead($Checkbox_rar) = $GUI_CHECKED Then
								GetFileSize()
								If $rarcheck = 1 Then
									$rar = 1
									FileChangeDir(@ScriptDir & "\UnRAR")
									$ret = Run('UnRAR.exe t "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
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
														If StringInStr($out, "All OK") > 0 Then
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
									$err = 4
								EndIf
							ElseIf ($fext = ".zip" Or $fext = ".7z" Or $fext = ".bz2") And GUICtrlRead($Checkbox_zip) = $GUI_CHECKED Then
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
									If $result = "good" And GUICtrlRead($Checkbox_list) = $GUI_CHECKED Then
										Sleep(2000)
										FileChangeDir(@ScriptDir & "\7-Zip")
										$ret = Run('7za.exe l "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
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
							ElseIf $fext = ".pdf" And GUICtrlRead($Checkbox_pdf) = $GUI_CHECKED Then
								GetFileSize()
								If $pdfcheck = 1 Then
									$pdf = 1
									FileChangeDir(@ScriptDir & "\QPDF\bin")
									$ret = Run('qpdf.exe --check "' & $path & '"', "", @SW_HIDE, $STDERR_MERGED)
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
														If StringInStr($out, "No syntax or stream encoding errors found") > 0 Then
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
									$err = 5
								EndIf
							Else
								$skipped = 1
							EndIf
							If $skipped = 1 Then
								$errors = $errors + 1
								$passed = "(SKIPPED) "
								_FileWriteLog($logfle, $passed & $path)
							Else
								If GUICtrlRead($Checkbox_save) = $GUI_CHECKED Then FileWrite($resfile, $results)
								;
								If ($err = "" And $cancel = "") And ($fext = ".exe" Or ($result = "good" And ($zip = 1 Or $rar = 1 Or $pdf = 1))) Then
									$passed = "(PASSED) "
									_FileWriteLog($logfle, $passed & $path)
									_ReplaceStringInFile($listfle, $path & @CRLF, "")
								Else
									$errors = $errors + 1
									If $err = 1 Then
										$passed = "(FAILED) "
									ElseIf $err = 2 Then
										$passed = "(ERROR) "
									ElseIf $err = 3 Then
										$passed = "(7-Zip MISSING) "
									ElseIf $err = 4 Then
										$passed = "(UnRAR MISSING) "
									ElseIf $err = 5 Then
										$passed = "(QPDF MISSING) "
									ElseIf $result = "" And ($zip = 1 Or $rar = 1 Or $pdf = 1) Then
										$passed = "(ERRED) "
									Else
										$passed = "(CANCELLED) "
									EndIf
									_FileWriteLog($logfle, $passed & $path)
									If $cancel = 1 Then _FileWriteLog($logfle, "(USER CANCELLED)")
								EndIf
							EndIf
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
				If GUICtrlRead($Checkbox_exit) = $GUI_CHECKED Then
					If GUICtrlRead($Checkbox_stay) = $GUI_CHECKED Then
						If $errors = 0 Then $close = 1
					Else
						$close = 1
					EndIf
				EndIf
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
	If $fext = ".exe" Or $fext = ".zip" Or $fext = ".7z" Or $fext = ".rar" Or $fext = ".sh" Or $fext = ".bz2" Or $fext = ".pdf" Then
		If Not FileExists($listfle) Then _FileCreate($listfle)
		FileWriteLine($listfle, $srcfle)
		_FileReadToArray($listfle, $array)
		$array = _ArrayUnique($array)
		_FileCreate($listfle)
		$array = _ArrayToString($array, @CRLF, 2)
		FileWrite($listfle, $array & @CRLF)
	Else
		MsgBox(262192, "File Error", "Only EXE & ZIP & 7Z & RAR & SH & BZ2 & PDF are supported!", 0, $DropboxGUI)
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
				$size = Round($size / 1073741824, 2) & " GB"
			Else
				$size = Round($size / 1048576, 1) & " MB"
			EndIf
		Else
			$size = Ceiling($size / 1024) & " KB"
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

