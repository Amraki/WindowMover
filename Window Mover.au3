; Options
Opt("WinTitleMatchMode", 2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase
Opt("GUIOnEventMode", 1) ; 1= OnEvent Mode vs default MessageLoop Mode

; Includes
#include <Array.au3>
#include <Date.au3>
#include <Misc.au3>
#include <NoFocusLines.au3> ; Thanks Melba23! -- https://www.autoitscript.com/forum/topic/101733-prevent-dotted-focus-lines-on-controls/
_NoFocusLines_Global_Set() ; Must be called before GUI is created
#include <WinAPI.au3>
#include <Window Mover_Gui.isf>

Global $ScriptName = StringLeft(@ScriptName, StringLen(@ScriptName) - 4) ; Get script name without extension
Global $iniFile = @ScriptDir & "/" & $ScriptName & " Config.ini" ; Name config file

If FileExists($iniFile) Then
	Local $iniMenuMode = IniReadSection($iniFile, "General")
	
	If StringUpper($iniMenuMode[0][1]) = "NO" Then
		_MoveWindows()
		_Exit()
	EndIf
	
	_PullConfigToList() ; Populate gui list with saved windows
EndIf

WinWait($ScriptName, "", 120)
GUISetState(@SW_SHOW, $hGUI) ; Show Menu GUI

While 1
	Sleep(1000) ; A full second shouldn't hurt, right?
Wend

Func _Exit()
	GUIDelete($hGUI)
	Exit
EndFunc

Func _CloseGui()
	_MoveWindows()
	_Exit()
EndFunc

Func _SetStatus($sStatus = "") ; Blank string clears status message
	If $sStatus <> "" Then
		$sStatus = _DateTimeFormat(_NowCalc(), 3) & " - " & $sStatus
	EndIf
	
	GUICtrlSetData($labelStatus, $sStatus)
EndFunc

Func _CopyGithubToClipboard()
	ClipPut("github.com/Amraki")
	_SetStatus("Github URL copied to clipboard")
EndFunc

Func _CopyAutoItURLToClipboard()
	ClipPut("autoitscript.com")
	_SetStatus("AutoIt URL copied to clipboard")
EndFunc

Func _SaveToConfig()
	; Update Run Mode
	If GUICtrlRead($radioMenu) = 1 Then ; Script opens menu
		IniWriteSection($iniFile, "General", "DefaultRunMenu=Yes")
	ElseIf GUICtrlRead($radioMoveWindows) = 1 Then ; Script just moves already configured windows
		IniWriteSection($iniFile, "General", "DefaultRunMenu=No")
	EndIf
	
	; Update Saved Windows
	Local $numWindows = _GUICtrlListView_GetItemCount($listWinTable)		
	Local $aListItemText, $sNewWindows
	
	For $i = 0 To $numWindows - 1	
		$aListItemText = StringSplit(_GUICtrlListView_GetItemTextString($listWinTable, $i), "|", 2)
		$sNewWindows &= $aListItemText[0] & "=" & StringReplace(_ArrayToString($aListItemText, "|", 1), "|", ",") & @LF ; Concantenate list data for config file
		$sNewWindows = StringReplace($sNewWindows, ",,", "") ; Crude but simple way to eliminate double commas if W and H are blank
	Next
	
	Local $Result = IniWriteSection($iniFile, "Windows", $sNewWindows) ; Overwrite "Windows" section of config file
	
	If $Result = 1 Then
		_SetStatus("Save Complete")
	Else
		_SetStatus("Error Saving")
	EndIf
EndFunc

Func _TestWinMove()
	If _ValidateWindowValues() = 0 Then
		Return
	EndIf
		
	Local $tempTitle = GUICtrlRead($inputTitle)
	Local $tempX = GUICtrlRead($inputX)
	Local $tempY = GUICtrlRead($inputY)
	Local $tempW = GUICtrlRead($inputW)
	Local $tempH = GUICtrlRead($inputH)
	
	Local $aCurrentWinPos = WinGetPos($tempTitle)
	
	; Check if window is already in location being tested - TODO: try to simplify (maybe change temp variables to array, remove blanks, then compare)
	If $tempW = "" Then ; Don't check width values
		If ($aCurrentWinPos[0] = $tempX) And ($aCurrentWinPos[1] = $tempY) And ($aCurrentWinPos[3] = $tempH) Then
			$Result = True
		EndIf
	ElseIf $tempH = "" Then ; Don't check height values
		If ($aCurrentWinPos[0] = $tempX) And ($aCurrentWinPos[1] = $tempY) And ($aCurrentWinPos[2] = $tempW) Then
			$Result = True
		EndIf
	ElseIf ($tempW = "") And ($tempH = "") Then ; Don't check width or height values
		If ($aCurrentWinPos[0] = $tempX) And ($aCurrentWinPos[1] = $tempY) And ($aCurrentWinPos[2] = $tempW) And ($aCurrentWinPos[3] = $tempH) Then
			$Result = True
		EndIf
	Else ; Check all values
		If ($aCurrentWinPos[0] = $tempX) And ($aCurrentWinPos[1] = $tempY) And ($aCurrentWinPos[2] = $tempW) And ($aCurrentWinPos[3] = $tempH) Then
			$Result = True
		EndIf
	EndIf
	
	If $Result = True Then
		_SetStatus("Move/Resize window before testing")
		Return
	EndIf
	
	If $tempW = "" Then
		$tempW = Default
	EndIf
	If $tempH = "" Then
		$tempH = Default
	EndIf

	WinMove($tempTitle, "", $tempX, $tempY, $tempW, $tempH)
EndFunc

Func _ToggleEnabled()
	Local $idSelectedListItem = GUICtrlRead($listWinTable)
	If StringInStr(StringUpper(GUICtrlRead($idSelectedListItem)), "YES") Then
		; Disable Window
		GUICtrlSetData($idSelectedListItem, "No||||||")
	ElseIf StringInStr(StringUpper(GUICtrlRead($idSelectedListItem)), "NO") Then
		; Enable Window
		GUICtrlSetData($idSelectedListItem, "Yes||||||")
	EndIf
EndFunc

Func _RemoveWindowFromList()
	Local $idSelectedListItem = GUICtrlRead($listWinTable)
	GUICtrlDelete($idSelectedListItem)
EndFunc

Func _ValidateWindowValues()	
	Select
		Case GUICtrlRead($inputTitle) = ""
			_SetStatus("Error: Missing required value: Title")
		
		Case GUICtrlRead($inputX) = ""
			_SetStatus("Error: Missing required value: X")
			
		Case GUICtrlRead($inputY) = ""
			_SetStatus("Error: Missing required value: Y")
	
		Case Else
			Return 1 ; No required values missing
	EndSelect	
	
	Return 0
EndFunc

Func _AddWindowToList()
	If _ValidateWindowValues() = 0 Then
		Return
	EndIf
	
	GUICtrlCreateListViewItem("Yes|" & GUICtrlRead($inputTitle) & "|" & _
										GUICtrlRead($inputX) & "|" & _
										GUICtrlRead($inputY) & "|" & _
										GUICtrlRead($inputW) & "|" & _
										GUICtrlRead($inputH), $listWinTable)
EndFunc

Func _EditSelectedListItem() ; Select window row then click list headers 
	Local $idSelectedListItem = GUICtrlRead($listWinTable)
	If $idSelectedListItem = 0 Then ; Nothing is selected
		Return
	EndIf
	Local $aSLI = StringSplit(GUICtrlRead($idSelectedListItem), "|", 2) ; Make array of parameters
	
	GUICtrlSetData($inputTitle, $aSLI[1])
	GUICtrlSetData($inputX, $aSLI[2])
	GUICtrlSetData($inputY, $aSLI[3])
	
	If UBound($aSLI) > 3 Then ; Width and Height are given
		GUICtrlSetData($inputW, $aSLI[4])
		GUICtrlSetData($inputH, $aSLI[5])
	EndIf
	
	_SetStatus("Selected window values loaded")
EndFunc

Func _PullConfigToList()
	$iniInfo = IniReadSection($iniFile, "Windows")
	
	If Not IsArray($iniInfo) Then ; Section is likely blank or corrupted
		_SetStatus("Unable to read config file")
		Return
	EndIf
	
	For $num = 1 To $iniInfo[0][0]
		Local $aWinInfo = StringSplit($iniInfo[$num][1], ",", 2) ; Make array of parameters

		Switch UBound($aWinInfo) ; Check number of parameters. 3 = no width and height
			Case 3
				GUICtrlCreateListViewItem($iniInfo[$num][0] & "|" & $aWinInfo[0] & "|" & $aWinInfo[1] & "|" & $aWinInfo[2], $listWinTable)
			Case 5
				GUICtrlCreateListViewItem($iniInfo[$num][0] & "|" & $aWinInfo[0] & "|" & $aWinInfo[1] & "|" & $aWinInfo[2] & "|" & $aWinInfo[3] & "|" & $aWinInfo[4], $listWinTable)
		EndSwitch

		Sleep(100)
	Next
EndFunc

Func _MoveWindows() ; Move windows currently in config file
	$iniInfo = IniReadSection($iniFile, "Windows")
	
	If Not IsArray($iniInfo) Then
		_SetStatus("Unable to read config file")
		Return
	EndIf
	
	For $num = 1 To $iniInfo[0][0]
	   Local $aWinInfo = StringSplit($iniInfo[$num][1], ",", 2) ; Make array of parameters

	   If Not WinExists($aWinInfo[0]) Or StringUpper($iniInfo[$num][0]) = "NO" Then
		  ContinueLoop ; Skip window if not open
	   Else
		  WinSetState($aWinInfo[0], "", @SW_RESTORE) ; Make sure window isn't minimized
	   EndIf

	   Do
		  Switch UBound($aWinInfo) ; Check number of parameters. 3 = no width and height
			 Case 3
				WinMove($aWinInfo[0], "", $aWinInfo[1], $aWinInfo[2])
			 Case 5
				WinMove($aWinInfo[0], "", $aWinInfo[1], $aWinInfo[2], $aWinInfo[3], $aWinInfo[4])
		  EndSwitch

		  Sleep(100)

		  $currPos = WinGetPos($aWinInfo[0]) ; Get windows position to check if move was successful
	   Until ($currPos[0] = $aWinInfo[1]) And ($currPos[1] = $aWinInfo[2])
	Next
EndFunc

Func _GetWinInfo()
	Local $g_tStruct = DllStructCreate($tagPOINT), $hWnd, $hTitle, $hOldTitle
	
	Do
		DllStructSetData($g_tStruct, "x", MouseGetPos(0)) ; Update X coordinate with mouse position
		DllStructSetData($g_tStruct, "y", MouseGetPos(1)) ; Update Y coordinate with mouse position
        $hWnd = _WinAPI_WindowFromPoint($g_tStruct) ; Retrieve the window handle.
			
		$hTitle = WinGetTitle(_WinAPI_GetAncestor($hWnd, 2))
		If $hTitle <> $hOldTitle Then
			ToolTip($hTitle) ; Set the tooltip with the handle under the mouse pointer.
		Else
			Sleep(100)
		EndIf
    Until _IsPressed("01")
	
	ToolTip("")

	$aWinInfo = WinGetPos($hTitle)
	GUICtrlSetData($inputTitle, $hTitle)
	GUICtrlSetData($inputX, $aWinInfo[0])
	GUICtrlSetData($inputY, $aWinInfo[1])
	GUICtrlSetData($inputW, $aWinInfo[2])
	GUICtrlSetData($inputH, $aWinInfo[3])

	Sleep(1000)
	WinActivate($ScriptName)
EndFunc
