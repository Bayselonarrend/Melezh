// MIT License

// Copyright (c) 2025 Anton Tsitavets

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// https://github.com/Bayselonarrend/OpenIntegrations

// BSLLS:Typo-off
// BSLLS:LatinAndCyrillicSymbolInWord-off
// BSLLS:IncorrectLineBreak-off
// BSLLS:UnusedLocalVariable-off
// BSLLS:UsingServiceTag-off
// BSLLS:NumberOfOptionalParams-off

//@skip-check module-unused-local-variable
//@skip-check method-too-many-params
//@skip-check module-structure-top-region
//@skip-check module-structure-method-in-regions
//@skip-check wrong-string-literal-content
//@skip-check use-non-recommended-method
//@skip-check module-accessibility-at-client
//@skip-check object-module-export-variable

#Use oint

#Region Variables

Var ProjectPath Export;
Var ProxyModule Export;
Var OPIObject Export;

#EndRegion

#Region Internal

Procedure MainHandle(Context, NextHandler) Export

    Try
        Result = ProcessRequest(Context);
    Except

        Information = ErrorInfo();
        Result = New Structure("result,error", False, Information.Description);

        If StrFind(Information.SourceString, "Raise") = 0 Then

            ModuleFile = New File(Information.ModuleName);

            ExceptionStructure = New Structure;
            ExceptionStructure.Insert("module", ModuleFile.Name);
            ExceptionStructure.Insert("row" , Information.LineNumber);
            ExceptionStructure.Insert("code" , TrimAll(Information.SourceString));

            Result.Insert("exception", ExceptionStructure);

        EndIf;

        Context.Response.StatusCode = 500;

    EndTry;

    JSON = OPI_Tools.JSONString(Result);

    Context.Response.ContentType = "application/json;charset=UTF8";
    Context.Response.Write(JSON);

EndProcedure

Function ProcessRequest(Context)

    Path = Context.Request.Path;

    Path = ?(StrStartsWith(Path , "/") , Right(Path, StrLen(Path) - 1) , Path);
    Path = ?(StrEndsWith(Path, "/") , Left(Path , StrLen(Path) - 1) , Path);

    HandlerDescription = ProxyModule.GetRequestHandler(ProjectPath, Path);

    If HandlerDescription["result"] Then

        Handler = HandlerDescription["data"];
        Handler = ?(TypeOf(Handler) = Type("Array"), Handler[0], Handler);

        Result = PerformHandling(Context, Handler);

    Else
        Result = HandlingError(Context, 404, "Handler not found!");
    EndIf;

    Return Result;

EndFunction

#EndRegion

#Region Private

Function PerformHandling(Context, Handler)

    Method = Upper(Context.Request.Method);
    HandlersMethod = Upper(Handler["method"]);
    CheckMethod = ?(HandlersMethod = "FORM", "POST", HandlersMethod);

    If Not Method = CheckMethod Then
        Return HandlingError(Context, 405, "Method " + Method + " is not available for this handler!");
    EndIf;

    If HandlersMethod = "GET" Then

        Result = ExecuteGetProcessing(Context, Handler);

    ElsIf HandlersMethod = "POST" Then

        Result = ExecutePostProcessing(Context, Handler);

    ElsIf HandlersMethod = "FORM" Then

        Result = ExecuteFormDataProcessing(Context, Handler);

    Else

        Result = HandlingError(Context, 405, "Method " + Method + " is not available for this handler!");

    EndIf;

    Return Result;

EndFunction

Function ExecuteGetProcessing(Context, Handler)

    Request = Context.Request;
    Parameters = Request.Parameters;

    Return PerformUniversalProcessing(Context, Handler, Parameters);

EndFunction

Function ExecutePostProcessing(Context, Handler)

    Request = Context.Request;

    Body = Request.Body;
    JSONReader = New JSONReader();
    JSONReader.OpenStream(Body);

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


        Response = New Structure("result,data", True, Response);

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

Function HandlingError(Context, Code, Text)

    Context.Response.StatusCode = Code;

    Return New Structure("result,error", False, Text);

EndFunction

#EndRegion
