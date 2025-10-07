#Use oint
#Use "./internal"

Var OPIObject;
Var ProxyModule;
Var ConnectionManager;
Var Logger;
Var SettingsVault;
Var ActiveExtensionsList;

#Region Internal

Procedure Initialize(OPIObject_, ProxyModule_, ConnectionManager_, Logger_, SettingsVault_) Export
    
    OPIObject = OPIObject_;
    ProxyModule = ProxyModule_;
    ConnectionManager = ConnectionManager_;
    Logger = Logger_;
    SettingsVault = SettingsVault_;

    ActiveExtensionsList = New Map();
    
EndProcedure

Function MainHandle(Val Context, Val Path) Export
    
    RequestBody = Undefined;
    NotFound = False;
    
    Try
        
        HandlerDescription = GetRequestsHandler(Path);
        
        If HandlerDescription["result"] Then
            
            Handler = HandlerDescription["data"];
            Handler = ?(TypeOf(Handler) = Type("Array"), Handler[0], Handler);
            
            Result = PerformHandling(Context, Handler, RequestBody);
            
        Else
            Result = Toolbox.HandlingError(Context, 404, "Not Found");
            NotFound = True;
        EndIf;
        
    Except
        
        ErrorInfo = ErrorInfo();
        ExecutionError = StrEndsWith(ErrorInfo.ModuleName, ":<exec>");
        ResponseCode = ?(ExecutionError, 400, 500);
        
        Result = Toolbox.HandlingError(Context, ResponseCode, ErrorInfo);
        
    EndTry;
    
    If Not NotFound Then
        Logger.WriteLog(Context, Path, RequestBody, Result);
    EndIf;
    
    RunGarbageCollection();
    
    Return Result;
    
EndFunction

Procedure ConnectExtensionScript(Val Path, Val Name) Export

    Try
        ActiveExtensionsList.Insert(Name, LoadScript(Path, New Structure("Melezh", ЭтотОбъект)));
    Except

        Error = StrTemplate("Failed to connect the extension script. It may already be connected (error description: %1)", ErrorDescription());
        Message(Error);

    EndTry;

EndProcedure

Procedure ClearActiveExtensionsList() Export
    ActiveExtensionsList = New Map();
EndProcedure

#EndRegion

#Region Private

#Region Main

Function PerformHandling(Context, Handler, RequestBody)
    
    If Not ValueIsFilled(Handler["active"]) Then
        Return Toolbox.HandlingError(Context, 403, "Forbidden");
    EndIf;
    
    If SizeExceeded(Context, RequestBody) Then
        Return Toolbox.HandlingError(Context, 413, "Payload Too Large");
    EndIf;
    
    Method = Upper(Context.Request.Method);
    HandlersMethod = Upper(Handler["method"]);
    CheckMethod = ?(HandlersMethod = "FORM" Or HandlersMethod = "JSON", "POST", HandlersMethod);
    
    If Not Method = CheckMethod Then
        Return Toolbox.HandlingError(Context, 405, "Method Not Allowed");
    EndIf;
    
    If HandlersMethod = "GET" Then
        
        Result = ExecuteGetProcessing(Context, Handler);
        
    ElsIf HandlersMethod = "JSON" Then
        
        Result = ExecutePostProcessing(Context, Handler, RequestBody);
        
    ElsIf HandlersMethod = "FORM" Then
        
        Result = ExecuteFormDataProcessing(Context, Handler);
        
    Else
        
        Result = Toolbox.HandlingError(Context, 405, "Method Not Allowed");
        
    EndIf;
    
    Return Result;
    
EndFunction

Function ExecuteGetProcessing(Context, Handler)
    
    Request = Context.Request;
    Parameters = Request.Parameters;
    
    Return PerformUniversalProcessing(Context, Handler, Parameters);
    
EndFunction

Function ExecutePostProcessing(Context, Handler, RequestBody)
    
    Request = Context.Request;
    
    DataReader = New DataReader(Request.Body);
    RequestBody = DataReader.Read().GetBinaryData();
    
    JSONReader = New JSONReader();
    JSONReader.SetString(ПолучитьСтрокуИзДвоичныхДанных(RequestBody));
    
    Parameters = ReadJSON(JSONReader, True);
    JSONReader.Close();
    
    Return PerformUniversalProcessing(Context, Handler, Parameters);
    
EndFunction

Function ExecuteFormDataProcessing(Context, Handler)
    
    #If Client Then
    Raise "The method is not available on the client!";
    #Else
    
    Request = Context.Request;
    
    If Not ValueIsFilled(Request.Form) Then
        Raise "No form data found in the request!";
    EndIf;
    
    Parameters = SplitFormData(Request.Form);
    
    Return PerformUniversalProcessing(Context, Handler, Parameters);
    
    #EndIf
    
EndFunction

Function PerformUniversalProcessing(Context, Handler, Parameters)
    
    #If Client Then
    Raise "The method is not available on the client!";
    #Else
    
    Arguments = Handler["args"];
    Command = Handler["library"];
    Method = Handler["function"];
    
    TFArray = New Array;
    ParametersBoiler = FormParameterBoiler(Arguments, Parameters);
    
    For Each Parameter In ParametersBoiler Do
        
        CurrentValue = Parameter.Value;
        CurrentKey = Parameter.Key;
        
        If TypeOf(CurrentValue) = Type("BinaryData") Then
            
            //@skip-check missing-temporary-file-deletion
            TFN = GetTempFileName();
            CurrentValue.Write(TFN);
            
            TFArray.Add(TFN);
            
            ParametersBoiler.Insert(CurrentKey, TFN);
            
        ElsIf TypeOf(CurrentValue) = Type("FormFile") Then
            
            //@skip-check missing-temporary-file-deletion
            TFN = GetTempFileName();
            
            StreamOfFile = CurrentValue.OpenReadStream();
            WriteStream = New FileStream(TFN, FileOpenMode.OpenOrCreate);
            
            StreamOfFile.CopyTo(WriteStream);
            
            StreamOfFile.Close();
            WriteStream.Close();
            
            TFArray.Add(TFN);
            
            ParametersBoiler.Insert(CurrentKey, TFN);

        ElsIf OPI_Tools.ThisIsCollection(CurrentValue) Then

            CurrentValue = OPI_Tools.JSONString(CurrentValue, , False);
            OPI_TypeConversion.GetLine(CurrentValue);

            ParametersBoiler.Insert(CurrentKey, CurrentValue);
            
        Else
            OPI_TypeConversion.GetLine(CurrentValue);
            ParametersBoiler.Insert(CurrentKey, CurrentValue);
        EndIf;
        
    EndDo;
    
    If ParametersBoiler.Get("--melezhcontext") = Undefined Then
        ParametersBoiler.Insert("--melezhcontext", "{MELEZHCONTEXT}");
    EndIf;

    ExecutionStructure = OPIObject.FormMethodCallString(ParametersBoiler, Command, Method, False);
    
    Response = Undefined;
    
    If ExecutionStructure["Error"] Then
        Response = New Structure("result,error", False, "Error in the name of a command or handler function!");
    Else
        
        ExecutionText = ExecutionStructure["Result"];
        ExecutionText = StrReplace(ExecutionText, "_melezhcontext = ""{MELEZHCONTEXT}""", "_melezhcontext = Context");

        If ActiveExtensionsList.Get(Command) <> Undefined Then
            ExecutionText = StrTemplate("%1 = ActiveExtensionsList.Get(""%1"");", Command) 
                + Chars.LF 
                + ExecutionText;
        EndIf;
        
        Execute(ExecutionText);
        
        If Not TypeOf(Response) = Type("BinaryData") 
            And SettingsVault.ReturnSetting("res_wrapper")
            And Not Context = Undefined Then

            Response = New Structure("result,data", True, Response);

        EndIf;
        
    EndIf;
    
    Try
        
        For Each TempFile In TFArray Do
            DeleteFiles(TempFile);
        EndDo;
        
    Except
        Message("Failed to delete temporary files!");
    EndTry;
    
    Return Response;
    
    #EndIf
    
EndFunction

Function FormParameterBoiler(Arguments, Parameters)
    
    StrictArgs = New Map;
    NonStrictArgs = New Map;
    
    For Each Argument In Arguments Do
        
        Key = "--" + Argument["arg"];
        Value = Argument["value"];
        Value = ?(StrStartsWith(Value , """"), Right(Value, StrLen(Value) - 1), Value);
        Value = ?(StrEndsWith(Value, """"), Left(Value , StrLen(Value) - 1), Value);
        
        If Argument["strict"] = 1 Then
            StrictArgs.Insert(Key, Value);
        Else
            NonStrictArgs.Insert(Key, Value);
        EndIf;
        
    EndDo;
    
    ParametersBoiler = NonStrictArgs;
    
    For Each Parameter In Parameters Do
        
        Value = Parameter.Value;
        
        If TypeOf(Value) = Type("String") Then
            Value = ?(StrStartsWith(Value , """"), Right(Value, StrLen(Value) - 1), Value);
            Value = ?(StrEndsWith(Value, """"), Left(Value , StrLen(Value) - 1), Value);
            Value = NormalizeString(Value);
        EndIf;
        
        ParametersBoiler.Insert("--" + Parameter.Key, Value);
        
    EndDo;
    
    For Each Argument In StrictArgs Do

        CurrentValue = Argument.Value;

        If TypeOf(CurrentValue) = Type("String") Then
            CurrentValue = NormalizeString(CurrentValue);
        EndIf;

        ParametersBoiler.Insert(Argument.Key, CurrentValue);

    EndDo;
    
    Return ParametersBoiler;
    
EndFunction

Function GetRequestsHandler(Path)
    
    ConnectionRO = ConnectionManager.GetROConnection();
    CurrentHandler = ProxyModule.GetRequestsHandler(ConnectionRO, Path);
    
    Return CurrentHandler;
    
EndFunction

Function SplitFormData(Val Form)
    
    DataMap = New Map;
    Files = Form.Files;
    
    For Each Field In Form Do
        
        DataMap.Insert(Field.Key, Field.Value);
        
    EndDo;
    
    For Each File In Files Do
        
        DataMap.Insert(File.Name, File);
        
    EndDo;
    
    Return DataMap;
    
EndFunction

Function SizeExceeded(Val Context, Val RequestBody)
    
    If RequestBody = Undefined Then
        BodySize = Context.Request.ContentLength;
    Else
        BodySize = RequestBody.Size();
    EndIf;

    MaxBodySize = SettingsVault.ReturnSetting("req_max_size");
    MaxBodySize = ?(ValueIsFilled(MaxBodySize), MaxBodySize, 0);
    BodySize = ?(ValueIsFilled(BodySize), BodySize, 0);
    
    If MaxBodySize <> 0 And BodySize > MaxBodySize Then
        Return True;
    Else
        Return False;
    EndIf;

EndFunction

Function NormalizeString(Val Value)

    Value = StrReplace(Value, Chars.LF, Chars.LF + "|");

    Return Value;

EndFunction
#EndRegion

#Region ExtensionContext

Function CallHandler(Val Path, Val Parameters) Export

    HandlerDescription = GetRequestsHandler(Path);
    
    If HandlerDescription["result"] Then
        
        Handler = HandlerDescription["data"];
        Handler = ?(TypeOf(Handler) = Type("Array"), Handler[0], Handler);

        Try
            Return PerformUniversalProcessing(Undefined, Handler, Parameters);
        Except
            Return New Structure("result,error", False, DetailErrorDescription(ErrorInfo()));
        EndTry;

    Else
        Return HandlerDescription;
    EndIf;

EndFunction

#EndRegion

#EndRegion
