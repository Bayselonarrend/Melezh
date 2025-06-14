Var SettingsVault;
Var ServerPath;
Var TypesMap;

#Region Internal

Procedure Initialize(SettingsVault_, ServerPath_) Export

	SettingsVault = SettingsVault_;
	ServerPath = ServerPath_;
	FillTypeMapping();

EndProcedure

Function ReturnStatic(Val Path, Val Context) Export

	Result = WriteFileInResponse(Path, Context);
	Return Result;

EndFunction

Function Redirection(Val Path, Val Context) Export

    BasePath = GetNormalizedBasePath();
    Context.Response.StatusCode = 303;
	Context.Response.Headers["Location"] = BasePath + Path;

EndFunction

#EndRegion

#Region Private

Function WriteFileInResponse(Path, Context) Export

    FileFullPath = StrTemplate("%1/%2", ServerPath, Path);
	FileObject = New File(FileFullPath);

	If Not FileObject.Exist() Then
		Return False;
	EndIf;

	Extension = FileObject.Extension;
	Page = New BinaryData(FileFullPath);

	SetDataTypeByExtension(Context, Extension);

	If Extension = ".html" Or Extension = ".js" Then

		Page = ПолучитьСтрокуИзДвоичныхДанных(Page);
		MBP = "#melezh_base_path#";

		If StrFind(Page, MBP) > 0 Then

			BasePath = GetNormalizedBasePath();
    		Page = StrReplace(Page, MBP, BasePath);
    		
		EndIf;

		Page = ПолучитьДвоичныеДанныеИзСтроки(Page);

	EndIf;

	ResponsePath = Context.Response.Body;
	ResponseRecord = New DataWriter(ResponsePath);
	
	ResponseRecord.Write(Page);
	ResponseRecord.Close();

	Return True;

EndFunction

Function GetNormalizedBasePath()

	BasePath = String(SettingsVault.ReturnSetting("base_path"));

    BasePath = ?(StrStartsWith(BasePath , "/"), BasePath, "/" + BasePath);
    BasePath = ?(StrEndsWith(BasePath, "/"), BasePath, BasePath + "/");

	Return BasePath;

EndFunction

Function SetDataTypeByExtension(Val Context, Val Extension)

	CurrentType = TypesMap.Get(Extension);
	CurrentType = ?(CurrentType = Undefined, "application/octet-stream", CurrentType);

	Context.Response.ContentType = CurrentType;

EndFunction

Procedure FillTypeMapping()

    TypesMap = New Map();
    
    // Text types
    TypesMap.Insert(".html", "text/html");
    TypesMap.Insert(".htm", "text/html");
    TypesMap.Insert(".txt", "text/plain");
    TypesMap.Insert(".css", "text/css");
    TypesMap.Insert(".js", "application/javascript");
    TypesMap.Insert(".json", "application/json");
    TypesMap.Insert(".xml", "application/xml");

    // Images
    TypesMap.Insert(".jpg", "image/jpeg");
    TypesMap.Insert(".jpeg", "image/jpeg");
    TypesMap.Insert(".png", "image/png");
    TypesMap.Insert(".gif", "image/gif");
    TypesMap.Insert(".bmp", "image/bmp");
    TypesMap.Insert(".webp", "image/webp");
    TypesMap.Insert(".svg", "image/svg+xml");

    // Fonts
    TypesMap.Insert(".woff", "font/woff");
    TypesMap.Insert(".woff2", "font/woff2");
    TypesMap.Insert(".ttf", "font/ttf");
    TypesMap.Insert(".otf", "font/opentype");

    // Video
    TypesMap.Insert(".mp4", "video/mp4");
    TypesMap.Insert(".webm", "video/webm");
    TypesMap.Insert(".ogg", "video/ogg");

    // Audio
    TypesMap.Insert(".mp3", "audio/mpeg");
    TypesMap.Insert(".wav", "audio/wav");
    TypesMap.Insert(".oga", "audio/ogg");

    // Documents
    TypesMap.Insert(".pdf", "application/pdf");
    TypesMap.Insert(".doc", "application/msword");
    TypesMap.Insert(".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
    TypesMap.Insert(".xls", "application/vnd.ms-excel");
    TypesMap.Insert(".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    TypesMap.Insert(".ppt", "application/vnd.ms-powerpoint");
    TypesMap.Insert(".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation");

    // Archives
    TypesMap.Insert(".zip", "application/zip");
    TypesMap.Insert(".rar", "application/x-rar-compressed");
    TypesMap.Insert(".7z", "application/x-7z-compressed");
    TypesMap.Insert(".tar", "application/x-tar");
    TypesMap.Insert(".gz", "application/gzip");

EndProcedure

#EndRegion
