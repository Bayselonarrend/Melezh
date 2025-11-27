#Use oint

Var ConnectionRO;
Var ConnectionRW;
Var RWLock;

#Region Internal

Procedure Initialize(ProjectPath_) Export
	
	ROProjectPath = StrTemplate("file:%1?mode=ro", ProjectPath_);

	ConnectionRO = OPI_SQLite.CreateConnection(ROProjectPath);
	ConnectionRW = OPI_SQLite.CreateConnection(ProjectPath_);

	RWLock = False;

EndProcedure

Function GetROConnection() Export

	Return ConnectionRO;

EndFunction

Function GetRWConnection() Export
	
	Counter = 0;

	While RWLock = True And Counter < 0 Do
		Sleep(100);
	EndDo;

	RWLock = False;
	
	Return ConnectionRW;

EndFunction

Function LockRW() Export
	RWLock = True;
EndFunction

Function UnlockRW() Export
	RWLock = False;
EndFunction

#EndRegion

#Region Alternate

Procedure Инициализировать(ПутьПроекта_) Export
	Initialize(ПутьПроекта_);
EndProcedure

Function ПолучитьСоединениеRO() Export
	Return GetROConnection();
EndFunction

Function ПолучитьСоединениеRW() Export
	Return GetRWConnection();
EndFunction

Function ЗаблокироватьRW() Export
	Return LockRW();
EndFunction

Function РазблокироватьRW() Export
	Return UnlockRW();
EndFunction

#EndRegion