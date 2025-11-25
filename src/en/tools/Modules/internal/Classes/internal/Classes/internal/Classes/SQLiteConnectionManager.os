#Use oint

Var ConnectionRO;
Var ConnectionRW;

#Region Internal

Procedure Initialize(ProjectPath_) Export
	
	ROProjectPath = StrTemplate("file:%1?mode=ro", ProjectPath_);

	ConnectionRO = OPI_SQLite.CreateConnection(ROProjectPath);
	ConnectionRW = OPI_SQLite.CreateConnection(ProjectPath_);
	
EndProcedure

Function GetROConnection() Export

	Return ConnectionRO;

EndFunction

Function GetRWConnection() Export
	
	Return ConnectionRW;

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

#EndRegion