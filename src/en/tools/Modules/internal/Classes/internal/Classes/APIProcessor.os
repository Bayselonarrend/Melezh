#Use oint
#Use "./internal"

Var ProxyModule;
Var ConnectionManager;
Var SessionsHandler;
Var ExtensionsProcessor;
Var OPIObject;
Var LibraryTable;
Var SettingsVault;
Var Logger;
Var StartDate;
Var AdviceArray;

#Region Internal

Procedure Initialize(ProxyModule_, ConnectionManager_, SessionsHandler_, OPIObject_, SettingsVault_, Logger_, ExtensionsProcessor_) Export
	
	ProxyModule = ProxyModule_;
	ConnectionManager = ConnectionManager_;
	SessionsHandler = SessionsHandler_;
	OPIObject = OPIObject_;
	SettingsVault = SettingsVault_;
	Logger = Logger_;
	StartDate = CurrentDate();
	ExtensionsProcessor = ExtensionsProcessor_;
	
	FillLibraryContent();
	FillAdvices();
	
EndProcedure

Function MainHandle(Val Context, Val Path) Export
	
	If Not SessionsHandler.AuthorizedSession(Context) Then
		RunGarbageCollection();
		Return Toolbox.HandlingError(Context, 401, "Authorization Error. Please refresh the page");
	EndIf;
	
	PathParts = StrSplit(Path, "/");
	NotFound = False;
	Result = Undefined;
	
	If PathParts.Count() >= 2 Then
		
		Command = Lower(PathParts[1]);
		
		If Command = "gethandlerslist" Then
			Result = ReturnHandlerList(Context);
		ElsIf Command = "updatestatus" Then
			Result = UpdateHandlerStatus(Context);
		ElsIf Command = "getlibraries" Then
			Result = ReturnLibraryList(Context);
		ElsIf Command = "getfunctions" Then
			Result = ReturnFunctionList(Context);
		ElsIf Command = "getargs" Then
			Result = ReturnArgumentList(Context);
		ElsIf Command = "createhandler" Then
			Result = CreateHandler(Context);
		ElsIf Command = "gethandler" Then
			Result = ReturnHandler(Context);
		ElsIf Command = "edithandler" Then
			Result = UpdateHandler(Context);
		ElsIf Command = "getnewkey" Then
			Result = ReturnNewHandlerKey(Context);
		ElsIf Command = "deletehandler" Then
			Result = DeleteRequestsHandler(Context);
		ElsIf Command = "getsettings" Then
			Result = ReturnProjectSettings(Context);
		ElsIf Command = "savesettings" Then
			Result = WriteProjectSettings(Context);
		ElsIf Command = "getlastevents" Then
			Result = ReturnLastActions(Context);
		ElsIf Command = "getevents" Then
			Result = ReturnActions(Context);
		ElsIf Command = "getsessioninfo" Then
			Result = ReturnSessionStatistic(Context);
		ElsIf Command = "getrandomadvice" Then
			Result = ReturnRandomAdvice(Context);
		ElsIf Command = "geteventdata" Then
			Result = ReturnEventInfo(Context);
		ElsIf Command = "getextensionslist" Then
			Result = ReturnExtensionsList(Context);
		ElsIf Command = "updateextensionsscache" Then
			Result = UpdateExtensionsCache(Context);
		Else
			NotFound = True;
		EndIf;
		
	Else
		NotFound = True;
	EndIf;
	
	If NotFound Then
		Result = Toolbox.HandlingError(Context, 404, "Not Found");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ReturnHandlerList(Context)
	
	Try
		
		ConnectionRO = ConnectionManager.GetROConnection();
		Result = ProxyModule.GetRequestsHandlersList(ConnectionRO);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnLibraryList(Context)
	
	LibrariesArray = New Array;
	
	For Each Library In LibraryTable Do
		
		LibraryName = Library["Name"];
		LibraryTitle = Library["Title"];
		
		LibrariesArray.Add(New Structure("name,title", LibraryName, LibraryTitle));
		
	EndDo;
	
	Context.Response.StatusCode = 200;
	Result = New Structure("result,data", True, LibrariesArray);
	
	Return Result;
	
EndFunction

Function ReturnFunctionList(Context)
	
	Try
		
		Library = Context.Request.Form["library"][0];

		Index = OPIObject.GetIndexData(Library);
		Composition = Index["Composition"].Copy();
		Composition.GroupBy("Method");
		
		FunctionArray = Composition.UnloadColumn("Method");
		OptionsArray = New Array;
		
		For Each OintFunction In FunctionArray Do
			OptionsArray.Add(New Structure("name,title", OintFunction, Synonymizer(OintFunction)));
		EndDo;
		
		Result = New Structure("result,data", True, OptionsArray);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnArgumentList(Context)
	
	Try
		
		Library = Context.Request.Form["library"][0];
		Method = Context.Request.Form["function"][0];
		
		Index = OPIObject.GetIndexData(Library);
		Composition = Index["Composition"].Copy();
		Composition.GroupBy("Method,Parameter,Description");
		
		ArgumentList = Composition.FindRows(New Structure("Method", Method));
		
		OptionsArray = New Array;
		
		For Each Argument In ArgumentList Do
			
			CurrentParameter = StrReplace(Argument["Parameter"], "--", "");

			If CurrentParameter = "melezhcontext" Then
				Continue;
			EndIf;

			OptionsArray.Add(New Structure("arg,description", CurrentParameter, Argument["Description"]));

		EndDo;
		
		Result = New Structure("result,data", True, OptionsArray);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnNewHandlerKey(Context)
	
	ConnectionRO = ConnectionManager.GetROConnection();
	NewKey = ProxyModule.ReceiveUniqueHandlerKey(ConnectionRO);
	
	KeyRecieved = TypeOf(NewKey) = Type("String");
	NewKey = ?(KeyRecieved, NewKey, NewKey["error"]);
	
	If KeyRecieved Then
		Result = New Structure("result,data", True, NewKey);
	Else
		Result = Toolbox.HandlingError(Context, 500, NewKey);
	EndIf;
	
	Return Result;
	
EndFunction

Function ReturnProjectSettings(Context)
	
	Try
		
		Result = SettingsVault.ReturnProjectSettingsUI();
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnLastActions(Context)
	
	Try
		Actions = Logger.ReturnLastActions();
		Result = New Structure("result,data", True, Actions);
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnActions(Context)
	
	Try
		
		Handler = Context.Request.Parameters["handler"];
		Date = Context.Request.Parameters["date"];
		
		Actions = Logger.ReturnActions(Handler, Date);
		Result = New Structure("result,data", True, Actions);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnSessionStatistic(Context)
	
	Try
		
		RequestAmount = Logger.ReturnResponsesAmount();
		Statistics = New Structure("start,processed", StartDate, RequestAmount);
		
		Result = New Structure("result,data", True, Statistics);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnRandomAdvice(Context)
	
	Try
		
		RNGenerator = New RandomNumberGenerator();
		RandomNumber = RNGenerator.RandomNumber(0, AdviceArray.Count() - 1);
		Advice = AdviceArray[RandomNumber];
		
		Statistics = New Structure("number,text", RandomNumber + 1, Advice);
		Result = New Structure("result,data", True, Statistics);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnEventInfo(Context)
	
	Try
		
		LogKey = String(Context.Request.Parameters["key"]);
		LogKey = StrReplace(LogKey, "/", "%2F");
		LogPath = SettingsVault.ReturnSetting("logs_path");
		
		If Not ValueIsFilled(LogPath) Then
			Return Toolbox.HandlingError(Context, 410, "No log path specified for the search!");
		EndIf;
		
		LogPath = FindFiles(LogPath, LogKey, True);
		
		If Not ValueIsFilled(LogPath) Then
			Return Toolbox.HandlingError(Context, 404, "No entry found. The path to the log directory may have been changed!");
		Else
			LogCatalog = LogPath[0].FullName;
		EndIf;
		
		ErrorFile = StrTemplate("%1/%2", LogCatalog, "error.json");
		ErrorObject = New File(ErrorFile);
		
		PrimaryFile = StrTemplate("%1/%2", LogCatalog, "req.info");
		PrimaryProject = New File(PrimaryFile);
		
		If Not PrimaryProject.Exist() Then
			
			If ErrorObject.Exist() Then
				
				OPI_TypeConversion.GetCollection(ErrorFile);
				OPI_TypeConversion.GetLine(ErrorFile);
				Error = "The recording was not performed correctly: " + ErrorFile;
				
			Else
				Error = "The record was not created or is corrupted!";
			EndIf;
			
			Return Toolbox.HandlingError(Context, 500, Error);
			
		EndIf;
		
		CorruptError = "The request information file has an incorrect format or is corrupted!";
		OPI_TypeConversion.GetKeyValueCollection(PrimaryFile, CorruptError);
		
		If ErrorObject.Exist() Then
			
			Try
				OPI_TypeConversion.GetCollection(ErrorFile);
				Error = ErrorFile["error"];
			Except
				OPI_TypeConversion.GetLine(ErrorFile, True);
				Error = ErrorFile;
			EndTry;
			
			PrimaryFile.Insert("error", StrTemplate("The logging was performed with an error: %1", Error));
		Else
			PrimaryFile.Insert("error", "");
		EndIf;
		
		HeadersFile = StrTemplate("%1/%2", LogCatalog, "req.headers");
		HeadersObject = New File(HeadersFile);
		
		If HeadersObject.Exist() Then
			OPI_TypeConversion.GetCollection(HeadersFile);
			PrimaryFile.Insert("headers", HeadersFile);
		Else
			PrimaryFile.Insert("headers", New Structure());
		EndIf;

		ResponseFile = StrTemplate("%1/%2", LogCatalog, "res.body");
		ResponseObject = New File(ResponseFile);

		If ResponseObject.Exist() Then

			ResponseFile_ = ResponseFile;
			OPI_TypeConversion.GetCollection(ResponseFile);

			If TypeOf(ResponseFile) = Type("Array") And ResponseFile[0] = ResponseFile_ Then
				ResponseFile = New Structure("File", ResponseFile_);
			EndIf;

			PrimaryFile.Insert("res_body", ResponseFile);

		EndIf;
		
		BodyFile = StrTemplate("%1/%2", LogCatalog, "req.body");
		BodyObject = New File(BodyFile);
		
		If BodyObject.Exist() Then
			
			OPI_TypeConversion.GetCollection(BodyFile);
			
			If TypeOf(BodyFile) = Type("Array") Then
				
				FormFiles = New Array;
				
				For Each File In BodyFile Do

					FileObject = New File(File);
					
					CurrentFileInfo = New Structure;
					CurrentFileInfo.Insert("name" , "-");
					CurrentFileInfo.Insert("file_name" , String(FileObject.Name));
					CurrentFileInfo.Insert("type" , "Full request body");
					CurrentFileInfo.Insert("size" , FileObject.Size());
					CurrentFileInfo.Insert("saved" , True);
					CurrentFileInfo.Insert("saved_path", FileObject.FullName);

					FormFiles.Add(CurrentFileInfo);
					
				EndDo;
				
				PrimaryFile.Insert("body", New Structure());
				PrimaryFile.Insert("melezh_request_files", FormFiles);
				
			Else
				
				FormFiles = BodyFile.Get("melezh_request_files");
				BodyFile.Delete("melezh_request_files");
				
				If Not ValueIsFilled(FormFiles) Then
					FormFiles = New Array;
				EndIf;
				
				PrimaryFile.Insert("body", BodyFile);
				PrimaryFile.Insert("melezh_request_files", FormFiles);
				
			EndIf;
			
		Else
			PrimaryFile.Insert("body", New Structure);
			PrimaryFile.Insert("melezh_request_files", New Array);
		EndIf;
		
		Result = New Structure("result,data", True, PrimaryFile);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, StrTemplate("Error receiving information: %1", ErrorDescription()));
	EndTry;
	
	Return Result;
	
EndFunction

Function WriteProjectSettings(Context)
	
	Try
		
		Data = Toolbox.GetJSON(Context);
		Result = SettingsVault.WriteProjectSettings(Data);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnHandler(Context)
	
	Try
		
		HandlersKey = Context.Request.Form["key"][0];
		
		ConnectionRO = ConnectionManager.GetROConnection();
		Result = ProxyModule.GetRequestsHandler(ConnectionRO, HandlersKey);
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function UpdateHandlerStatus(Context)
	
	Result = Undefined;
	
	Try
		
		HandlersKey = Context.Request.Form["key"][0];
		HandlerStatus = Context.Request.Form["active"][0];
		
		ConnectionRW = ConnectionManager.GetRWConnection();
		
		If HandlerStatus = "0" Then
			Result = ProxyModule.DisableRequestsHandler(ConnectionRW, HandlersKey);
		Else
			Result = ProxyModule.EnableRequestsHandler(ConnectionRW, HandlersKey);
		EndIf;
		
		If Result["result"] Then
			Context.Response.StatusCode = 200;
		Else
			Result = Toolbox.HandlingError(Context, 400, Result["error"]);
		EndIf;
		
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function CreateHandler(Context)
	
	Result = Undefined;
	HandlerUUID = Undefined;
	ConnectionRW = ConnectionManager.GetRWConnection();
	
	Try
		
		HandlerStructure = Toolbox.GetJSON(Context);
		
		Library = HandlerStructure["library"];
		OintMethod = HandlerStructure["function"];
		HTTPMethod = HandlerStructure["method"];
		Arguments = HandlerStructure["args"];
		UUID = HandlerStructure["key"];
		
		CurrentHandler = ProxyModule.AddRequestsHandler(ConnectionRW, Library, OintMethod, HTTPMethod);
		
		If Not CurrentHandler["result"] Then
			Raise CurrentHandler["error"];
		Else
			HandlerUUID = CurrentHandler["key"];
		EndIf;
		
		Result = ProxyModule.UpdateHandlersKey(ConnectionRW, HandlerUUID, UUID);
		
		If Not Result["result"] Then
			Raise Result["error"];
		Else
			HandlerUUID = UUID;
		EndIf;
		
		For Each Argument In Arguments Do
			
			ArgumentName = Argument["arg"];
			ArgumentValue = Argument["value"];
			ArgumentStrict = Argument["strict"];
			
			Adding = ProxyModule.SetHandlerArgument(ConnectionRW, HandlerUUID, ArgumentName, ArgumentValue, ArgumentStrict);
			
			If Not Adding["result"] Then
				Raise Adding["error"];
			EndIf;
			
		EndDo;
		
		Result = New Structure("result", True);
		Context.Response.StatusCode = 200;
		
	Except
		ProxyModule.DeleteRequestsHandler(ConnectionRW, HandlerUUID);
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function DeleteRequestsHandler(Context)
	
	Try
		Handler = Context.Request.Form["key"][0];
		ConnectionRW = ConnectionManager.GetRWConnection();
		Result = ProxyModule.DeleteRequestsHandler(ConnectionRW, Handler);
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function UpdateHandler(Context)
	
	Result = Undefined;
	HandlerUUID = Undefined;
	
	Try
		
		HandlerStructure = Toolbox.GetJSON(Context);
		UUID = HandlerStructure["originalKey"];
		
		ConnectionRO = ConnectionManager.GetROConnection();
		OldHandler = ProxyModule.GetRequestsHandler(ConnectionRO, UUID);
		
		If Not OldHandler["result"] Then
			Raise OldHandler["error"];
		Else
			
			OldHandler = OldHandler["data"];
			HandlerUUID = OldHandler["key"];
			
			OldHandler.Insert("originalKey", OldHandler["key"]);
			
		EndIf;
		
		UpdateHandlerData(HandlerUUID, HandlerStructure);
		
		Result = New Structure("result", True);
		Context.Response.StatusCode = 200;
		
	Except
		UpdateHandlerData(HandlerUUID, OldHandler);
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;
	
EndFunction

Function ReturnExtensionsList(Context)

	Try
		Result = ExtensionsProcessor.GetExtensionsList();
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;

EndFunction

Function UpdateExtensionsCache(Context)

	Try
		Result = ExtensionsProcessor.UpdateExtensionsList();
		FillLibraryContent();
	Except
		Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
	EndTry;
	
	Return Result;

EndFunction

Procedure UpdateHandlerData(HandlerUUID, HandlerStructure)
	
	NewKey = HandlerStructure["key"];
	Arguments = HandlerStructure["args"];
	Library = HandlerStructure["library"];
	OintMethod = HandlerStructure["function"];
	HTTPMethod = HandlerStructure["method"]; 
	
	ConnectionRW = ConnectionManager.GetRWConnection();
	
	If NewKey <> HandlerUUID Then
		
		Result = ProxyModule.UpdateHandlersKey(ConnectionRW, HandlerUUID, NewKey);
		
		If Not Result["result"] Then
			Raise Result["error"];
		Else
			HandlerUUID = NewKey;
		EndIf;
		
	EndIf;
	
	Cleaning = ProxyModule.ClearHandlerArguments(ConnectionRW, HandlerUUID);
	
	If Not Cleaning["result"] Then
		Raise Cleaning["error"];
	EndIf;
	
	For Each Argument In Arguments Do
		
		ArgumentName = Argument["arg"];
		ArgumentValue = Argument["value"];
		ArgumentStrict = Boolean(Argument["strict"]);
		
		Adding = ProxyModule.SetHandlerArgument(ConnectionRW, HandlerUUID, ArgumentName, ArgumentValue, ArgumentStrict);
		
		If Not Adding["result"] Then
			Raise Adding["error"];
		EndIf;
		
	EndDo;
	
	Updating = ProxyModule.UpdateRequestsHandler(ConnectionRW
	, HandlerUUID
	, Library
	, OintMethod
	, HTTPMethod);
	
	If Not Updating["result"] Then
		Raise Updating["error"];
	EndIf;
	
EndProcedure

Procedure FillLibraryContent()
	
	CommandMap = OPIObject.GetCommandModuleMapping();
	LibraryTable = New ValueTable();
	
	LibraryTable.Columns.Add("Name");
	LibraryTable.Columns.Add("Title");
	
	For Each Command In CommandMap Do
		
		CommandName = Command.Key;
		
		If CommandName = "tools" Then
			Continue;
		EndIf;
		
		Module = StrReplace(Command.Value, "OPI_", "");
		Synonym = Synonymizer(Module);
		
		NewLine = LibraryTable.Add();
		NewLine.Name = CommandName;
		NewLine.Title = Synonym;
		
	EndDo;
	
EndProcedure

Function Synonymizer(PropName)
	
	Var Synonym, N, Symbol, BeforeSymbol, NextSymbol, Capitalized, CapitalizedBefore, CapitalizedNext, StringLength;
	
	Synonym = Upper(Mid(PropName, 1, 1));
	StringLength = StrLen(PropName);
	
	For N = 2 To StringLength Do
		
		Symbol = Mid(PropName, N, 1);
		BeforeSymbol = Mid(PropName, N - 1, 1);
		NextSymbol = Mid(PropName, N + 1, 1);
		
		Capitalized = Symbol = Upper(Symbol);
		CapitalizedBefore = BeforeSymbol = Upper(BeforeSymbol);
		CapitalizedNext = NextSymbol = Upper(NextSymbol);
		
		If NOT CapitalizedBefore And Capitalized Then
			Synonym = Synonym + " " + Symbol;
		ElsIf Capitalized And Not CapitalizedNext Then
			Synonym = Synonym + " " + Symbol;
		Else
			Synonym = Synonym + Symbol;
		EndIf;
		
	EndDo;
	
	WordsArray = StrSplit(Synonym, " ");
	
	For N = 1 To WordsArray.UBound() Do
		
		CurrentWord = WordsArray[N];
		
		If StrLen(CurrentWord) = 1 Then
			WordsArray[N] = Lower(CurrentWord);
			Continue;
		Else
			
			SecondSymbol = Mid(CurrentWord, 2, 1);
			
			If SecondSymbol = Lower(SecondSymbol) Then
				WordsArray[N] = Lower(CurrentWord);
			Else
				WordsArray[N] = Upper(CurrentWord);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Synonym = StrConcat(WordsArray, " ");
	
	ChangeNameRegister(Synonym);
	
	Return Synonym;
	
EndFunction

Procedure ChangeNameRegister(Synonym)
	
	NamesMap = New Map();
	NamesMap.Insert("ozon", "Ozon");
	NamesMap.Insert("Bitrix 24", "Bitrix24");
	NamesMap.Insert("calendar", "Calendar");
	NamesMap.Insert("drive", "Drive");
	NamesMap.Insert("sheets", "Sheets");
	NamesMap.Insert("workspace", "Workspace");
	NamesMap.Insert("My SQL", "MySQL");
	NamesMap.Insert("Postgre SQL", "PostgreSQL");
	NamesMap.Insert("SQ lite", "SQLite");
	NamesMap.Insert("teams", "Teams");
	NamesMap.Insert("disk", "Disk");
	NamesMap.Insert("market", "Market");
	NamesMap.Insert("metrika", "Metrika");
	
	For Each Name In NamesMap Do
		Synonym = StrReplace(Synonym, Name.Key, Name.Value);
	EndDo;
	
EndProcedure

Procedure FillAdvices()
	
	AdviceArray = New Array;
	AdviceArray.Add("Handlers are the main objects of Melezh. You can add and modify them on the ""Handlers page.""");
	AdviceArray.Add("Each handler has a unique key. This key means the path where the handler receives requests (localhost/<key>)");
	AdviceArray.Add("A handler can only use one OpenIntegrations function as a processing mechanism at a time. But it can be changed at any time");
	AdviceArray.Add("Handlers can be disabled without deletion using the toggle switches on the ""Handlers page""");
	AdviceArray.Add("The set of libraries, functions and arguments available to handlers is the same as in any other OpenIntegrations implementation");
	AdviceArray.Add("Logs are stored as json files. A special structure of subdirectories is used to classify them");
	AdviceArray.Add("You can find and change the current log saving directory in the settings");
	AdviceArray.Add("You can quickly find logs for the handler you are interested in using one of the action buttons on the ""Handlers page""");
	AdviceArray.Add("The current console password can only be changed in console mode using the ChangeUIPassword command");
	AdviceArray.Add("The project file is a SQLite database, which can be viewed in any editor. The main thing is not to break anything......");
	AdviceArray.Add("Melezh is developed using OneScript and uses the Kestrel server, support for which was added in the 2.0 version of the engine");
	AdviceArray.Add("The default limit for the body of a request written to the log is 100 MB. If the request exceeds this value, it will not be logged");
	AdviceArray.Add("Each handler has customizable arguments. These are values that will be used by default if not specified in the request");
	AdviceArray.Add("If you set the handler argument to ""Strict"", it cannot be overwritten by the query data");
	
EndProcedure

#EndRegion
