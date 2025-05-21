#Use oint
#Use "./internal"

Var ServerPath;
Var SessionsHandler;

#Region Internal

Procedure Initialize(ServerPath_, SessionsHandler_) Export

	ServerPath = ServerPath_;
	SessionsHandler = SessionsHandler_;

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
		Result = Toolbox.HandlingError(Context, 404, "Not found");
	EndIf;

	RunGarbageCollection();

    Return Result;

EndFunction

#EndRegion

#Region Private

Procedure ReturnUIPage(Context)

	Context.Response.StatusCode = 200;

	If SessionsHandler.AuthorizedSession(Context) Then 

		ReturnHTMLPage(Context, "console.html");

	Else

		ReturnHTMLPage(Context, "login.html");

	EndIf;

EndProcedure

Procedure ReturnHTMLPage(Context, Path)

	ResponsePath = Context.Response.Body;
	ResponseRecord = New DataWriter(ResponsePath);

	FileFullPath = StrTemplate("%1/%2", ServerPath, Path);
	ResponseRecord.Write(New BinaryData(FileFullPath));

	ResponseRecord.Close();

EndProcedure

Function AuthorizeSession(Context)

	Result = SessionsHandler.AuthorizeSession(Context);

	Return Result;

EndFunction

#EndRegion
