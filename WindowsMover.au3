Opt("WinTitleMatchMode", 2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase

Global $ScriptName = StringLeft(@ScriptName, StringLen(@ScriptName) - 4)
Local $iniFile = @ScriptDir & "/" & $ScriptName & "Config.ini"
If FileExists($iniFile) Then
   Local $iniInfo = IniReadSection($iniFile, "Windows")
Else
   IniWriteSection($iniFile, "Windows", '1=Window Title,X position,Y position,Width (optional),Height (optional)' & @LF & _
									   '2=Internet Explorer,-1104,121,966,673')

   MsgBox(0, $ScriptName, "Config file generated. Update it and run again to use.")
   Exit
EndIf

For $num = 1 To $iniInfo[0][0]
   $winInfo = StringSplit($iniInfo[$num][1], ",", 2)

   If Not WinExists($winInfo[0]) Then
	  ContinueLoop
   Else
	  WinSetState($winInfo[0], "", @SW_RESTORE)
   EndIf

   Do
	  Switch UBound($winInfo)
		 Case 3
			WinMove($winInfo[0], "", $winInfo[1], $winInfo[2])
		 Case 5
			WinMove($winInfo[0], "", $winInfo[1], $winInfo[2], $winInfo[3], $winInfo[4])
	  EndSwitch

	  Sleep(100)

	  $currPos = WinGetPos($winInfo[0])
   Until ($currPos[0] = $winInfo[1]) And ($currPos[1] = $winInfo[2])
Next
