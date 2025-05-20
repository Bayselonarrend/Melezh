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

Function HandlingError(Context, Code, Text) Export

    If TypeOf(Text) = Type("ErrorInfo") Then

        Result = New Structure("result,error", False, Text.Description);

        If StrFind(Text.SourceString, "Raise") = 0 Then

            ModuleFile = New File(Text.ModuleName);

            ExceptionStructure = New Structure;
            ExceptionStructure.Insert("module", ModuleFile.Name);
            ExceptionStructure.Insert("row" , Text.LineNumber);
            ExceptionStructure.Insert("code" , TrimAll(Text.SourceString));

            Result.Insert("exception", ExceptionStructure);

        EndIf;

    Else
        Result = New Structure("result,error", False, Text);
    EndIf;

    Context.Response.StatusCode = Code;
    Return Result;

EndFunction

#EndRegion
