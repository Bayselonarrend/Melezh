#Use oint

Var ConnectionRO;
Var ConnectionRW;
Var RWGuard;

#Region Internal

Procedure Initialize(ProjectPath_) Export
	
	ROProjectPath = StrTemplate("file:%1?mode=ro", ProjectPath_);

	ConnectionRO = OPI_SQLite.CreateConnection(ROProjectPath);
	ConnectionRW = OPI_SQLite.CreateConnection(ProjectPath_);
	RWGuard = True;

EndProcedure

Function GetROConnection() Export

	Return ConnectionRO;

EndFunction

Function GetRWConnection() Export

	Counter = 0;

	While Not RWGuard Or Counter < 10 Do
		Sleep(200);
		Counter = Counter + 1;
	EndDo;

	RWGuard = False;
	
	Return ConnectionRW;

EndFunction

Procedure ReturnRWConnection() Export
	RWGuard = True;
EndProcedure

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

#EndRegion