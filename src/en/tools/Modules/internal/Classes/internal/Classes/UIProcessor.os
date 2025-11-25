#Use oint
#Use "./internal"

Var ServerPath;
Var SessionsHandler;
Var StaticProcessor;
Var SettingsVault;
Var BasePath;

#Region Internal

Procedure Initialize(ServerPath_, SessionsHandler_, SettingsVault_) Export

	ServerPath = ServerPath_;
	SessionsHandler = SessionsHandler_;
	SettingsVault = SettingsVault_;

	StaticProcessor = New("StaticProcessor");
	StaticProcessor.Initialize(SettingsVault, ServerPath);

EndProcedure

Function MainHandle(Val Context, Val Path) Export

	If Not SettingsVault.ReturnSetting("ui_show") Then
		Return Toolbox.HandlingError(Context, 403, "Access to the web console is restricted by Melezh settings. If you have already enabled ui_show in console mode, updating the settings on an already running server may take up to a minute");
	EndIf;

	Result = Undefined;
	Path = ?(ValueIsFilled(Path), Path, "index.html");

	Context.Response.StatusCode = 200;

	If StaticProcessor.ReturnStatic(Path, Context) Then
		Return Result;
	EndIf;

	If Path = "ui" Then

		ReturnUIPage(Context);

	ElsIf Path = "ui/login" Then

		Result = AuthorizeSession(Context);

	ElsIf Path = "ui/logout" Then

		SessionsHandler.DeleteSession(Context);
		StaticProcessor.Redirection("ui", Context);

	Else
		Result = Toolbox.HandlingError(Context, 404, "Not Found");
	EndIf;

	RunGarbageCollection();

    Return Result;

EndFunction

#EndRegion

#Region Private

Procedure ReturnUIPage(Context)

	Context.Response.StatusCode = 200;
	
	If SessionsHandler.AuthorizedSession(Context) Then 

		StaticProcessor.ReturnStatic("console.html", Context);

	Else

		StaticProcessor.ReturnStatic("login.html", Context);

	EndIf;

EndProcedure

Function AuthorizeSession(Context)

	Result = SessionsHandler.AuthorizeSession(Context);

	Return Result;

EndFunction

#EndRegion

#Region Alternate

Procedure Initialize(ServerPath_, SessionsHandler_, SettingsVault_) Export
	Initialize(ServerPath_, SessionsHandler_, SettingsVault_);
EndProcedure

Function MainHandle(Val Context, Val Path) Export
	Return MainHandle(Context, Path);
EndFunction

#EndRegion


#Region Alternate

Procedure Инициализировать(ПутьСервера_, ОбработчикСеансов_, ХранилищеНастроек_) Export
	Initialize(ПутьСервера_, ОбработчикСеансов_, ХранилищеНастроек_);
EndProcedure

Function ОсновнаяОбработка(Val Контекст, Val Путь) Export
	Return MainHandle(Контекст, Путь);
EndFunction

#EndRegion