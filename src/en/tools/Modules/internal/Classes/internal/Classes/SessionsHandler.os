#Use "./internal"

Var SessionList;
Var ConnectionManager;
Var SettingsVault;

Var TrackFailedAttempts;
Var Attempts;
Var BlockingDuration;

Var BlockList;
Var AttemptsList;

#Region Internal

Procedure Initialize(ConnectionManager_, SettingsVault_) Export
	
	SessionList = New Map;
	ConnectionManager = ConnectionManager_;
	SettingsVault = SettingsVault_;
	
	BlockList = New Map();
	AttemptsList = New Map();
	
EndProcedure

Function AuthorizeSession(Context) Export
	
	Result = False;
	
	If Context.Request.Method <> "POST" Then
		Return Toolbox.HandlingError(Context, 405, "Method Not Allowed");
	EndIf;
	
	ClientIP = Context.Connection.RemoteIPAddress;

	If CheckAuthorizationBlock(ClientIP) Then
		Return Toolbox.HandlingError(Context, 429, "Maximum number of failed authorization attempts exceeded. Please try again later.");
	EndIf;
	
	ContentLength = Context.Request.ContentLength;
	ContentLength = ?(ContentLength = Undefined, 0, ContentLength);
	
	If ContentLength > 50000 Then
		Return Toolbox.HandlingError(Context, 413, "Payload Too Large");
	EndIf;
	
	RequestBody = Context.Request.Body;
	
	Try
		Password = Context.Request.Form["password"][0];
	Except
		Return Toolbox.HandlingError(Context, 400, "Bad Request");
	EndTry;
	
	If Password = ProjectPassword() Then
		
		Cookie = String(New UUID());
		
		While SessionList.Get(Cookie) <> Undefined Do
			Cookie = String(New UUID());
		EndDo;
		
		SessionList.Insert(Cookie, True);
		
		Context.Response.Cookie.Append("melezh", Cookie);
		Context.Response.StatusCode = 200;
		
		Result = New Structure("result", True);

		AttemptsList.Delete(ClientIP);
		
	Else
		
		Result = Toolbox.HandlingError(Context, 400, "Wrong password!");
		
	EndIf;
	
	RunGarbageCollection();
	
	Return Result;
	
EndFunction

Function AuthorizedSession(Context) Export
	
	AuthToken = GetCookieAuth(Context);
	
	If ValueIsFilled(AuthToken) Then
		
		Authorized = SessionList.Get(AuthToken);
		Authorized = ?(ValueIsFilled(Authorized), Authorized, False);
		
	Else
		Authorized = False;
	EndIf;
	
	Return Authorized;
	
EndFunction

Procedure DeleteSession(Context) Export
	
	AuthToken = GetCookieAuth(Context);
	SessionList.Delete(AuthToken);
	
EndProcedure

#EndRegion

#Region Private

Function GetCookieAuth(Context)
	
	Cookies = Context.Request.Cookie;
	Token = "";
	
	For Each Cookie In Cookies Do
		
		If Cookie.Key = "melezh" Then
			Token = Cookie.Value;
		EndIf;
		
	EndDo;
	
	Return Token;
	
EndFunction

Function CheckAuthorizationBlock(ClientIP)
	
	MaximumRetryCount = SettingsVault.ReturnSetting("auth_attempts");
	BlockingDuration = SettingsVault.ReturnSetting("auth_ban_duration");
	
	If MaximumRetryCount = 0 Or BlockingDuration = 0 Then
		Return False;
	EndIf;

	CurrentBlocking = BlockList.Get(ClientIP);

	If CurrentBlocking <> Undefined Then

		RemainingTime = CurrentBlocking - CurrentDate();

		If RemainingTime <= 0 Then
			BlockList.Delete(ClientIP);
		Else
			Return True;
		EndIf;

	EndIf;

	Attempts = AttemptsList.Get(ClientIP);
	Attempts = ?(Attempts = Undefined, 0, Attempts);

	If Attempts >= MaximumRetryCount Then
		AttemptsList.Delete(ClientIP);
		BlockList.Insert(ClientIP, CurrentDate() + BlockingDuration * 60);
		Return True;
	Else
		Attempts = Attempts + 1;
		AttemptsList.Insert(ClientIP, Attempts);
		Return False;
	EndIf;
	
EndFunction

Function ProjectPassword()
	
	ConnectionRO = ConnectionManager.GetROConnection();
	Password = SettingsVault.ReturnSetting("ui_password");
	
	If Password = Undefined Then
		Raise "UI password was not found in the project settings. The project file may be corrupted!";
	Else
		Return Password;
	EndIf;
	
EndFunction

#EndRegion

#Region Alternate

Procedure Инициализировать(МенеджерСоединений_, ХранилищеНастроек_) Export
	Initialize(МенеджерСоединений_, ХранилищеНастроек_);
EndProcedure

Function АвторизоватьСеанс(Контекст) Export
	Return AuthorizeSession(Контекст);
EndFunction

Function АвторизованныйСеанс(Контекст) Export
	Return AuthorizedSession(Контекст);
EndFunction

Procedure УдалитьСеанс(Контекст) Export
	DeleteSession(Контекст);
EndProcedure

#EndRegion