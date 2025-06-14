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
