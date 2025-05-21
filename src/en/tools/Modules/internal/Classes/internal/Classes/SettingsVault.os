#Use "./internal"

Var FullProjectSettings;
Var ProjectSettingsUI;
Var ProjectSettings;

Var ConnectionManager;
Var ProxyModule;

#Region Internal

Procedure Initialize(ConnectionManager_, ProxyModule_) Export
	
	ProxyModule = ProxyModule_;
	ConnectionManager = ConnectionManager_;
	
	FillSettings();
	
EndProcedure

Function ReturnProjectSettingsFull() Export
	
	Return FullProjectSettings;
	
EndFunction

Function ReturnProjectSettingsUI() Export
	
	Return ProjectSettingsUI;
	
EndFunction

Function ReturnSetting(Val Name) Export
	
	Return ProjectSettings.Get(Name);
	
EndFunction

Function WriteProjectSettings(Val Data) Export
	
	ConnectionRW = ConnectionManager.GetRWConnection();
	Result = ProxyModule.FillProjectSettings(ConnectionRW, Data);
	FillSettings();
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Procedure FillSettings()
	
	ConnectionRO = ConnectionManager.GetROConnection();
	BaseSettings = ProxyModule.GetProjectSettings(ConnectionRO);
	
	If Not BaseSettings["result"] Then
		Raise BaseSettings["error"];	
	EndIf;
	
	FullProjectSettings = BaseSettings;
	ProjectSettings = New Map();
	UISettingsTable = New Array;
	
	For Each Setting In BaseSettings["data"] Do

		ProjectSettings.Insert(Setting["name"], Setting["value"]);

		If Not Setting["name"] = "ui_password" Then
			UISettingsTable.Add(Setting);
		EndIf;

	EndDo;

	ProjectSettingsUI = New Structure("result,data", true, UISettingsTable);
	
EndProcedure

#EndRegion
