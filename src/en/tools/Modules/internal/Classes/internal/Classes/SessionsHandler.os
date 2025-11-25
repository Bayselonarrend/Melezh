#Use "./internal"

Var SessionList;
Var ConnectionManager;
Var SettingsVault;

#Region Internal

Procedure Initialize(ConnectionManager_, SettingsVault_) Export
	
	SessionList = New Map;
	ConnectionManager = ConnectionManager_;
	SettingsVault = SettingsVault_;
	
EndProcedure

Function AuthorizeSession(Context) Export
	
	Result = False;
	
	If Context.Request.Method <> "POST" Then
		Return Toolbox.HandlingError(Context, 405, "Method Not Allowed");
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

Procedure Initialize(ConnectionManager_, SettingsVault_) Export
	Initialize(ConnectionManager_, SettingsVault_);
EndProcedure

Function AuthorizeSession(Context) Export
	Return AuthorizeSession(Context);
EndFunction

Function AuthorizedSession(Context) Export
	Return AuthorizedSession(Context);
EndFunction

Procedure DeleteSession(Context) Export
	DeleteSession(Context);
EndProcedure

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