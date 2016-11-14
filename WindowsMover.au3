Opt("WinTitleMatchMode", 2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase

Local $ScriptName = StringLeft(@ScriptName, StringLen(@ScriptName) - 4) ; Get script name without extension
Local $iniFile = @ScriptDir & "/" & $ScriptName & "Config.ini" ; Name config file
If FileExists($iniFile) Then
   Local $iniInfo = IniReadSection($iniFile, "Windows")
Else
   ; Create config file with example entries
   IniWriteSection($iniFile, "Windows", '1=Window Title,X position,Y position,Width (optional),Height (optional)' & @LF & _
									   '2=Internet Explorer,-1104,121,966,673')

   MsgBox(0, $ScriptName, "Config file generated. Update it and run again to use.")
   Exit
EndIf

For $num = 1 To $iniInfo[0][0]
   $winInfo = StringSplit($iniInfo[$num][1], ",", 2) ; Make array of parameters

   If Not WinExists($winInfo[0]) Then
	  ContinueLoop ; Skip window if not open
   Else
	  WinSetState($winInfo[0], "", @SW_RESTORE) ; Make sure window isn't minimized
   EndIf

   Do
	  Switch UBound($winInfo) ; Check number of parameters. 3 = no width and height
		 Case 3
			WinMove($winInfo[0], "", $winInfo[1], $winInfo[2])
		 Case 5
			WinMove($winInfo[0], "", $winInfo[1], $winInfo[2], $winInfo[3], $winInfo[4])
	  EndSwitch

	  Sleep(100)

	  $currPos = WinGetPos($winInfo[0]) ; Get windows position to check if move was successful
   Until ($currPos[0] = $winInfo[1]) And ($currPos[1] = $winInfo[2])
Next
