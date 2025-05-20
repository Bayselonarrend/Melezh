#Use oint
#Use "./internal"

Var OPIObject;
Var ProxyModule;
Var ConnectionManager;
Var Logger;

#Region Internal

Procedure Initialize(OPIObject_, ProxyModule_, ConnectionManager_, Logger_) Export

	OPIObject = OPIObject_;
	ProxyModule = ProxyModule_;
	ConnectionManager = ConnectionManager_;
    Logger = Logger_;

EndProcedure

Function MainHandle(Val Context, Val Path) Export

    RequestBody = Undefined;

    Try
        HandlerDescription = GetRequestHandler(Path);

        If HandlerDescription["result"] Then

            Handler = HandlerDescription["data"];
            Handler = ?(TypeOf(Handler) = Type("Array"), Handler[0], Handler);

            Result = PerformHandling(Context, Handler, RequestBody);

        Else
            Result = Toolbox.HandlingError(Context, 404, "Handler not found!");
        EndIf;

    Except
        Result = Toolbox.HandlingError(Context, 500, ErrorInfo());
    EndTry;
    
    Logger.WriteLog(Context, RequestBody, Result);

    RunGarbageCollection();

    Return Result;

EndFunction

#EndRegion

#Region Private

Function PerformHandling(Context, Handler, RequestBody)

    If Handler["active"] = 0 Then
        Return Toolbox.HandlingError(Context, 403, "This handler has been disabled on the server side!");
    EndIf;

    Method = Upper(Context.Request.Method);
    HandlersMethod = Upper(Handler["method"]);
    CheckMethod = ?(HandlersMethod = "FORM" Or HandlersMethod = "JSON", "POST", HandlersMethod);

    If Not Method = CheckMethod Then
        Return Toolbox.HandlingError(Context, 405, "Method " + Method + " is not available for this handler!");
    EndIf;

    If HandlersMethod = "GET" Then

        Result = ExecuteGetProcessing(Context, Handler);

    ElsIf HandlersMethod = "JSON" Then

        Result = ExecutePostProcessing(Context, Handler, RequestBody);

    ElsIf HandlersMethod = "FORM" Then

        Result = ExecuteFormDataProcessing(Context, Handler);

    Else

        Result = Toolbox.HandlingError(Context, 405, "Method " + Method + " is not available for this handler!");

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

        Else
            OPI_TypeConversion.GetLine(CurrentValue);
            ParametersBoiler.Insert(CurrentKey, CurrentValue);
        EndIf;

    EndDo;

    ExecutionStructure = OPIObject.FormMethodCallString(ParametersBoiler, Command, Method);

    Response = Undefined;

    If ExecutionStructure["Error"] Then
        Response = New Structure("result,error", False, "Error in the name of a command or handler function!");
    Else

        ExecutionText = ExecutionStructure["Result"];

        Execute(ExecutionText);

        If Not TypeOf(Response) = Type("BinaryData") Then
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
        EndIf;

        ParametersBoiler.Insert("--" + Parameter.Key, Value);

    EndDo;

    For Each Argument In StrictArgs Do
        ParametersBoiler.Insert(Argument.Key, Argument.Value);
    EndDo;

    Return ParametersBoiler;

EndFunction

Function GetRequestHandler(Path)

    ConnectionRO = ConnectionManager.GetROConnection();
    CurrentHandler = ProxyModule.GetRequestHandler(ConnectionRO, Path);

    Return CurrentHandler;

EndFunction

Function SplitFormData(Val Form) Export

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

#EndRegion
