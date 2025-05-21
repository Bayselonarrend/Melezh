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
#Use "./internal"
#Use "./internal/Classes/internal"

#Region Variables

Var ActionsProcessor;
Var APIProcessor;
Var UIProcessor;
Var Logger;
Var SettingsVault;
Var SessionsHandler;
Var SQLiteConnectionManager;

#EndRegion

#Region Internal

Procedure Initialize(ProjectPath_, ProxyModule_, OPIObject_, ServerPath_) Export

    SQLiteConnectionManager = New("SQLiteConnectionManager");
    SQLiteConnectionManager.Initialize(ProjectPath_);

    SettingsVault = New("SettingsVault");
    SettingsVault.Initialize(SQLiteConnectionManager, ProxyModule_);

    Logger = New("Logger");
    Logger.Initialize(SettingsVault);

    SessionsHandler = New("SessionsHandler");
    SessionsHandler.Initialize(SQLiteConnectionManager, SettingsVault);

    ActionsProcessor = New("ActionsProcessor");
    ActionsProcessor.Initialize(OPIObject_, ProxyModule_, SQLiteConnectionManager, Logger);

    APIProcessor = New("APIProcessor");
    APIProcessor.Initialize(ProxyModule_, SQLiteConnectionManager, SessionsHandler, OPIObject_, SettingsVault, Logger);

    UIProcessor = New("UIProcessor");
    UIProcessor.Initialize(ServerPath_, SessionsHandler);

EndProcedure

Procedure MainHandle(Context, NextHandler) Export

    Try

        Context.Response.Headers["Server"] = "Melezh/0.0.1 (Kestrel)";
        
        Result = ProcessRequest(Context, NextHandler);
        
    Except

        Result = Toolbox.HandlingError(Context, 500, ErrorInfo());

        If Context.Response.StatusCode = 200 Then
            Context.Response.StatusCode = 500;
        EndIf;

    EndTry;

    RunGarbageCollection();

    If Result <> Undefined Then

        If OPI_Tools.ThisIsCollection(Result) Then
            Context.Response.WriteAsJson(Result);
        Else

            OPI_TypeConversion.GetBinaryData(Result, True, False);

            DataWriter = New DataWriter(Context.Response.Body);
            DataWriter.Write(Result);
            DataWriter.Close();

        EndIf;

    EndIf;

EndProcedure

Function ProcessRequest(Context, NextHandler)

    Path = Context.Request.Path;

    Path = ?(StrStartsWith(Path , "/") , Right(Path, StrLen(Path) - 1) , Path);
    Path = ?(StrEndsWith(Path, "/") , Left(Path , StrLen(Path) - 1) , Path);

    If StrStartsWith(Path, "api") Then
        Result = APIProcessor.MainHandle(Context, Path);
    ElsIf StrStartsWith(Path, "ui") Then
        Result = UIProcessor.MainHandle(Context, Path);
    ElsIf Not StrFind(Path, "/") Then
        Result = ActionsProcessor.MainHandle(Context, Path);
    Else
        Result = Toolbox.HandlingError(Context, 404, "Not Found");
    EndIf;

    Return Result;

EndFunction

#EndRegion
