#Use oint

#Region Internal

Function CreateConnectionRO(Val Path) Export

    ROProjectPath = StrTemplate("file:%1?mode=ro", Path);
    ConnectionRO = OPI_SQLite.CreateConnection(ROProjectPath);

    If Not OPI_AddIns.IsAddIn(ConnectionRO) Then
        Raise OPI_Tools.JSONString(ConnectionRO);
    Else
        Return ConnectionRO;
    EndIf;

EndFunction

Function CreateConnectionRW(Val Path) Export

    ConnectionRW = OPI_SQLite.CreateConnection(Path);

    If Not OPI_AddIns.IsAddIn(ConnectionRW) Then
        Raise OPI_Tools.JSONString(ConnectionRW);
    Else
        Return ConnectionRW;
    EndIf;

EndFunction

Function GetJSON(Context) Export

    DataReader = New DataReader(Context.Request.Body);
    ReadingResult = DataReader.Read();
    Data = ReadingResult.GetBinaryData(); 

    JSON = New JSONReader();
    JSON.SetString(ПолучитьСтрокуИзДвоичныхДанных(Data));
    Result = ReadJSON(JSON, True);

    Return Result;

EndFunction

Function Redirection(Context, Path) Export
	Context.Response.StatusCode = 303;
	Context.Response.Headers["Location"] = Path;
EndFunction

Procedure ReturnHTMLPage(Context, ServerPath, Path) Export

	ResponsePath = Context.Response.Body;
	ResponseRecord = New DataWriter(ResponsePath);

	FileFullPath = StrTemplate("%1/%2", ServerPath, Path);
	ResponseRecord.Write(New BinaryData(FileFullPath));

	ResponseRecord.Close();

EndProcedure

Function HandlingError(Context, Code, Text) Export

    If TypeOf(Text) = Type("ErrorInfo") Then

        Result = New Structure("result,error", False, Text.Description);

        If StrFind(Text.SourceLine, "Raise") = 0 Then

            ModuleFile = New File(Text.ModuleName);

            ExceptionStructure = New Structure;
            ExceptionStructure.Insert("module", ModuleFile.Name);
            ExceptionStructure.Insert("row" , Text.LineNumber);
            ExceptionStructure.Insert("code" , TrimAll(Text.SourceLine));

            Result.Insert("exception", ExceptionStructure);

        EndIf;

    Else
        Result = New Structure("result,error", False, Text);
    EndIf;

    Context.Response.StatusCode = Code;
    Return Result;

EndFunction

Function GetBoolean(Val Value) Export

	If TypeOf(Value) = Type("String") Then
		Value = Upper(Value);
	EndIf;

	BoolMap = New Map();
	BoolMap.Insert(True , True);
	BoolMap.Insert(1 , True);
	BoolMap.Insert("1" , True);
	BoolMap.Insert("TRUE", True);
	BoolMap.Insert("TRUE" , True);

	BooleanValue = BoolMap.Get(Value);
	Return ?(BooleanValue = Undefined, False, True);
	
EndFunction

#EndRegion
