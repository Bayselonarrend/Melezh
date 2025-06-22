#Use "./internal"

Var FullProjectSettings;
Var ProjectSettingsUI;
Var ProjectSettings;
Var LastUpdate;

Var ConnectionManager;
Var ProxyModule;

#Region Internal

Procedure Initialize(ConnectionManager_, ProxyModule_) Export
	
	ProxyModule = ProxyModule_;
	ConnectionManager = ConnectionManager_;
	LastUpdate = CurrentDate();
	
	FillSettings(True);
	
EndProcedure

Function ReturnProjectSettingsFull() Export
	
	FillSettings();
	Return FullProjectSettings;
	
EndFunction

Function ReturnProjectSettingsUI() Export
	
	FillSettings();
	Return ProjectSettingsUI;
	
EndFunction

Function ReturnSetting(Val Name) Export
	
	FillSettings();
	Setting = ProjectSettings.Get(Name);

	Return Setting;
	
EndFunction

Function ReturnBasePath() Export

	BasePath = String(ReturnSetting("base_path"));

    BasePath = ?(StrStartsWith(BasePath , "/"), BasePath, "/" + BasePath);
    BasePath = ?(StrEndsWith(BasePath, "/"), BasePath, BasePath + "/");

	Return BasePath;

EndFunction

Function WriteProjectSettings(Val Data) Export
	
	ConnectionRW = ConnectionManager.GetRWConnection();
	Result = ProxyModule.FillProjectSettings(ConnectionRW, Data);
	FillSettings(True);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Procedure FillSettings(Val Forced = False)

	CurrentDate = CurrentDate();
	
	If Forced Or CurrentDate > LastUpdate + 60 Then
		LastUpdate = CurrentDate;
	Else
		Return;
	EndIf;
	
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
