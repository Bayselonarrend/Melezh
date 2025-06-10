#Use oint
#Use "./internal"

Var ServerPath;
Var SessionsHandler;
Var SettingsVault;

#Region Internal

Procedure Initialize(ServerPath_, SessionsHandler_, SettingsVault_) Export

	ServerPath = ServerPath_;
	SessionsHandler = SessionsHandler_;
	SettingsVault = SettingsVault_;

EndProcedure

Function MainHandle(Val Context, Val Path) Export

	Result = Undefined;

	If Path = "ui" Then

		ReturnUIPage(Context);

	ElsIf Path = "ui/login" Then

		Result = AuthorizeSession(Context);

	ElsIf Path = "ui/logout" Then

		SessionsHandler.DeleteSession(Context);
		Toolbox.Redirection(Context, "/ui");

	Else
		Result = Toolbox.HandlingError(Context, 404, "Not Found");
	EndIf;

	RunGarbageCollection();

    Return Result;

EndFunction

#EndRegion

#Region Private

Procedure ReturnUIPage(Context)

	BasePath = String(SettingsVault.GetSetting("base_path"));
	Context.Response.StatusCode = 200;
	
	If SessionsHandler.AuthorizedSession(Context) Then 

		Toolbox.ReturnHTMLPage(Context, ServerPath, "console.html", BasePath);

	Else

		Toolbox.ReturnHTMLPage(Context, ServerPath, "login.html", BasePath);

	EndIf;

EndProcedure

Function AuthorizeSession(Context)

	Result = SessionsHandler.AuthorizeSession(Context);

	Return Result;

EndFunction

#EndRegion
