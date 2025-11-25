#Use oint

Var SettingsVault;
Var LastActions;
Var RequestAmount;

#Region Internal

Procedure Initialize(SettingsVault_) Export
	
	SettingsVault = SettingsVault_;
	LastActions = New Array;
	RequestAmount = 0;
	
EndProcedure

Procedure WriteLog(Context, Handler, RequestBody, Val Result) Export
		
	RequestAmount = RequestAmount + 1;
	
	Try

		LogPath = SettingsVault.ReturnSetting("logs_path");
		HasContext = Context <> Undefined;
		
		If Not ValueIsFilled(LogPath) Then
			Return;		
		EndIf;

		RequestDate = CurrentDate();
		Identifier = Left(String(New UUID), 8);
		HandlerEscaped = StrReplace(String(Handler), "/", "%2F");
		RequestUUID = StrTemplate("%1-%2-%3", Format(RequestDate, "DF=hh-mm-ss"), Identifier, HandlerEscaped);
		WritingPath = OrganizeLogCatalog(LogPath, RequestDate, HandlerEscaped, RequestUUID);
		
		If RequestBody = Undefined Then

			If HasContext Then
				BodySize = Context.Request.ContentLength;
		    Else
				BodySize = 0;
			EndIf;

		Else
			BodySize = RequestBody.Size();
		EndIf;
		
		RecordRequestBody = SettingsVault.ReturnSetting("logs_req_body");
		RecordRequestHeaders = SettingsVault.ReturnSetting("logs_req_headers");
		RecordResponseBody = SettingsVault.ReturnSetting("logs_res_body");	
		MaxRequestSize = SettingsVault.ReturnSetting("logs_req_max_size");
		ResponseMaxSize = SettingsVault.ReturnSetting("logs_res_max_size");
		
		WriteRequestInfo(WritingPath, Context, RequestDate, BodySize, RequestUUID, Handler);

		If RecordRequestHeaders And HasContext Then
			WriteRequestHeaders(WritingPath, Context.Request.Headers);
		EndIf;
		
		If RecordRequestBody And HasContext Then

			If RequestBody <> Undefined Then
				
				WriteRequestBody(WritingPath, RequestBody, MaxRequestSize);
				
			ElsIf Context.Request.Form <> Undefined Then
				
				WriteRequestForm(WritingPath, Context.Request.Form, MaxRequestSize);
				
			EndIf;	
			
		EndIf;

		If RecordResponseBody Then

			OPI_TypeConversion.GetBinaryData(Result);

			If Result.Size() <= ResponseMaxSize Or Not ValueIsFilled(ResponseMaxSize) Then
				WriteLogFile(WritingPath, "res.body", Result);
			EndIf;

		EndIf;
		
	Except
		Error = New Structure("result,error", True, ErrorDescription());
		WriteLogFile(WritingPath, "error.json", Error);	
	EndTry;
	
	RunGarbageCollection();
	
EndProcedure

Procedure WriteRequestBody(WritingPath, RequestBody, MaxRequestSize)
	
	If ValueIsFilled(MaxRequestSize) Then
		RecordBody = RequestBody.Size() <= MaxRequestSize;
	Else
		RecordBody = True;
	EndIf;
	
	If RecordBody Then
		WriteLogFile(WritingPath, "req.body", RequestBody);
	EndIf;
	
EndProcedure

Procedure WriteRequestForm(WritingPath, RequestForm, MaxRequestSize)

	CheckSize = ValueIsFilled(MaxRequestSize);
	DataMap = New Map();

	For Each FormPart In RequestForm Do

		If FormPart.Key = "Files" Then
			Continue;
		EndIf;

		PartValue = String(FormPart.Value);
		DataMap.Insert(FormPart.Key, PartValue);

	EndDo;

	DataMap_ = OPI_Tools.CopyCollection(DataMap);
	OPI_TypeConversion.GetBinaryData(DataMap_, True);
	CurrentDataSize = DataMap_.Size();

	If CurrentDataSize > MaxRequestSize And CheckSize Then
		Return;
	EndIf;		

	If RequestForm.Files <> Undefined Then

		FileInfoArray = New Array;
		Counter = 1;

		For Each File In RequestForm.Files Do

			If File.Length + CurrentDataSize > MaxRequestSize And CheckSize Then

				FileSize = File.Length;
				Saved = False;
				FilePath = "";

			Else

				PrimaryName = ?(ValueIsFilled(File.FileName), File.FileName, StrTemplate("file%1.bin", Counter));
				FilePath = StrTemplate("%1/%2", WritingPath, PrimaryName);

				FileStream = New FileStream(FilePath, FileOpenMode.OpenOrCreate);
				StreamOfFile = File.OpenReadStream();
				StreamOfFile.CopyTo(FileStream);
				StreamOfFile.Close();
				FileStream.Close();

				RecordedFile = New File(FilePath);
				FileSize = RecordedFile.Size();
				CurrentDataSize = CurrentDataSize + FileSize;
				Saved = True;

			EndIf;

			CurrentFileInfo = New Structure;
			CurrentFileInfo.Insert("name" , String(File.Name));
			CurrentFileInfo.Insert("file_name" , String(File.FileName));
			CurrentFileInfo.Insert("type" , String(File.ContentType));
			CurrentFileInfo.Insert("size" , FileSize);
			CurrentFileInfo.Insert("saved" , Saved);
			CurrentFileInfo.Insert("saved_path", FilePath);

			FileInfoArray.Add(CurrentFileInfo);

			Counter = Counter + 1;

		EndDo;

		DataMap.Insert("melezh_request_files", FileInfoArray);

	EndIf;

	WriteLogFile(WritingPath, "req.body", DataMap);

EndProcedure

Procedure WriteRequestHeaders(WritingPath, Headers)

	HeadersMap = New Map();

	For Each Title In Headers Do

		HeaderValue = String(Title.Value);

		If ValueIsFilled(HeaderValue) Then
			HeadersMap.Insert(Title.Key, HeaderValue);
		EndIf;

	EndDo;

	If HeadersMap.Count() <> 0 Then
		WriteLogFile(WritingPath, "req.headers", HeadersMap);
	EndIf;
	
EndProcedure

Function ReturnLastActions() Export
	Return LastActions;
EndFunction

Function ReturnActions(Handler, Date) Export
	
	Result = New Array;
	LogPath = SettingsVault.ReturnSetting("logs_path");
	HandlerEscaped = StrReplace(String(Handler), "/", "%2F");
	
	If Not ValueIsFilled(LogPath) Then
		Return Result;		
	EndIf;
	
	LogPath = StrReplace(LogPath, "\", "/");
	LogPath = ?(StrEndsWith(LogPath, "/"), Left(LogPath, StrLen(LogPath) - 1), LogPath);
	
	LogPath = StrTemplate("%1/%2/%3", LogPath, HandlerEscaped, Date);
	PathFile = New File(LogPath);
	
	If Not PathFile.Exists() Then
		Return Result;
	EndIf;
	
	InformationFiles = FindFiles(LogPath, "req.info", True);	
	Result = New ValueList();
	
	For Each InformationFile In InformationFiles Do
		
		JSONReader = New JSONReader();
		JSONReader.OpenFile(InformationFile.FullName);
		
		Data = ReadJSON(JSONReader);
		Data.Delete("params");
		
		Result.Add(Data, Data["date"]);
		JSONReader.Close();
		
	EndDo;
	
	Result.SortByPresentation(SortDirection.Desc);
	Result = Result.UnloadValues();
	
	Return Result;
	
EndFunction

Function ReturnResponsesAmount() Export
	Return RequestAmount;
EndFunction

#EndRegion

#Region Private

Function OrganizeLogCatalog(Val LogPath, Val Date, Val Handler, Val UUID)
	
	PrimaryLogsCatalog = CheckCreateFolder(LogPath);
		
	HandlerCatalog = StrTemplate("%1/%2", PrimaryLogsCatalog, Handler);
	HandlerCatalog = CheckCreateFolder(HandlerCatalog);
	
	DateCatalog = StrTemplate("%1/%2", HandlerCatalog, Format(Date, "DF=yyyy-MM-dd"));
	DateCatalog = CheckCreateFolder(DateCatalog);
	
	RequestCatalog = StrTemplate("%1/%2", DateCatalog, UUID);
	RequestCatalog = CheckCreateFolder(RequestCatalog);
	
	Return RequestCatalog;
	
EndFunction

Function CheckCreateFolder(Val Path)
	
	Path = StrReplace(Path, "\", "/");
	Path = ?(StrEndsWith(Path, "/"), Left(Path, StrLen(Path) - 1), Path);
	
	CatalogFile = New File(Path);
	
	If Not CatalogFile.Exists() Then
		CreateDirectory(Path);
	EndIf;
	
	Return Path;
	
EndFunction

Function WriteRequestInfo(Val LogPath, Val Context, Val RequestDate, Val BodySize, Val RequestUUID, Val Handler)
	
	HasContext = Context <> Undefined;
	ContentType = Undefined;
	
	If HasContext Then
		ContentType = Context.Request.ContentType;
		ContentType = ?(ValueIsFilled(ContentType), ContentType, "<no/undefined>");
	Else
		ContentType = "LocalLaunch";
	EndIf;

	RequestData = New Structure;
	RequestData.Insert("key" , RequestUUID);
	RequestData.Insert("date" , RequestDate);		
	RequestData.Insert("method" , ?(HasContext, Context.Request.Method, "Task"));
	RequestData.Insert("type" , ContentType);
	RequestData.Insert("size" , ?(ValueIsFilled(BodySize), BodySize, 0));
	RequestData.Insert("status" , ?(HasContext, Context.Response.StatusCode, 0));
	RequestData.Insert("handler" , Handler);
	
	LastActions.Insert(0, RequestData);
	
	While LastActions.Count() > 30 Do
		LastActions.Delete(LastActions.Count() - 1);
	EndDo;
	
	If HasContext Then
		RequestData.Insert("protocol", Context.Request.Protocol);
		RequestData.Insert("form" , Context.Request.HasFormContentType);
		RequestData.Insert("params" , Context.Request.Parameters);
	Else
		RequestData.Insert("protocol", "LocalLaunch");
		RequestData.Insert("form" , False);
		RequestData.Insert("params" , New Array);
	EndIf;
	
	JSONWriter = New JSONWriter();
	JSONWriter.OpenFile(StrTemplate("%1/%2", LogPath, "req.info"));
	WriteJSON(JSONWriter, RequestData);
	JSONWriter.Close();
	
EndFunction

Procedure WriteLogFile(LogPath, FileName, Data)
	
	OPI_TypeConversion.GetBinaryData(Data);
	Data.Write(StrTemplate("%1/%2", LogPath, FileName));
	
EndProcedure

#EndRegion




#Region Alternate

Procedure Инициализировать(ХранилищеНастроек_) Export
	Initialize(ХранилищеНастроек_);
EndProcedure

Procedure ЗаписатьЛог(Контекст, Обработчик, ТелоЗапроса, Val Результат) Export
	WriteLog(Контекст, Обработчик, ТелоЗапроса, Результат);
EndProcedure

Function ВернутьПоследниеДействия() Export
	Return ReturnLastActions();
EndFunction

Function ВернутьДействия(Обработчик, Дата) Export
	Return ReturnActions(Обработчик, Дата);
EndFunction

Function ВернутьЧислоЗапросов() Export
	Return ReturnResponsesAmount();
EndFunction

#EndRegion