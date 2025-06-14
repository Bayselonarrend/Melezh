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
// BSLLS:NumberOfOptionalParams-off
// BSLLS:UsingServiceTag-off
// BSLLS:LineLength-off

//@skip-check module-structure-top-region
//@skip-check module-structure-method-in-regions
//@skip-check wrong-string-literal-content
//@skip-check method-too-many-params
//@skip-check constructor-function-return-section

// Uncomment if OneScript is executed
#Use oint
#Use oint-cli
#Use "./internal"
#Use "../../env"

#Region Public

#Region ProjectsSetup

// Create project
// Creates a project file at the selected path
//
// Parameters:
// Path - String - Project filepath - path
//
// Returns:
// Structure Of KeyAndValue - Creating result
Function CreateProject(Val Path) Export

    Return NormalizeProject(Path);

EndFunction

// Run project
// Runs an integration proxy server
//
// Parameters:
// Port - Number - Server startup port - port
// Project - String - Project filepath - proj
// Returns:
// Structure Of KeyAndValue - Server shutdown result
Function RunProject(Val Port, Val Project) Export

    If Not OPI_Tools.IsOneScript() Then
        IntegrationProxy = Undefined;
        Raise "This function is only available for calling in OneScript!";
    EndIf;

    OPI_TypeConversion.GetNumber(Port);

    Check = CheckRestoreProject(Project);

    If Not Check["result"] Then
        Return Check;
    EndIf;

    TypeServer = Type("WebServer");

    ServersSettings = New Array(1);
    ServersSettings[0] = Port;

    WebServer = New(TypeServer, ServersSettings);
    Handler = New("RequestsHandler");
    OintContent = New("LibraryComposition");

    ServerCatalogs = GetServerCatalogs();

    Root = ServerCatalogs["Root"];
    ExtensionsCatalog = ServerCatalogs["Extensions"];

    Extensions.CompleteCompositionWithExtensions(OintContent, ExtensionsCatalog);
    Handler.Initialize(Project, IntegrationProxy, OintContent, Root);

    WebServer.AddRequestsHandler(Handler, "MainHandle");
    WebServer.Run();

    Return FormResponse(True, "Stopped");

EndFunction

// Get project settings
// Gets a list of all current project settings
//
// Parameters:
// Project - String - Project filepath - proj
// Returns:
// Structure Of KeyAndValue - Project settings list
Function GetProjectSettings(Val Project) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("SettingsTable");
    Result = OPI_SQLite.GetRecords(Table, , , , , Project);

    If Result["result"] Then

        TDN = New TypeDescription("Number");
        TDB = New TypeDescription("Boolean");

        For Each SettingsPart In Result["data"] Do

            DataType = SettingsPart["type"];

            If DataType = "bool" Then
                SettingsPart["value"] = TDB.AdjustValue(SettingsPart["value"]);
            ElsIf DataType = "number" Then
                SettingsPart["value"] = TDN.AdjustValue(SettingsPart["value"]);
            Else
                SettingsPart["value"] = String(SettingsPart["value"]);
            EndIf;

        EndDo;

    EndIf;

    Return Result;

EndFunction

// Fill project settings
// Fills in the settings from the passed collection
//
// Note
// If values are modified in a running project, the changes may take up to 60 seconds to be applied
//
// Parameters:
// Project - String - Project filepath - proj
// Settings - Map Of KeyAndValue - Collection key and value to fill in the settings - set
// Returns:
// Structure Of KeyAndValue - Project settings list
Function FillProjectSettings(Val Project, Val Settings) Export

    OPI_TypeConversion.GetLine(Project);
    OPI_TypeConversion.GetKeyValueCollection(Settings);

    Result = CheckProjectExistence(Project);
    CurrentSettings = GetProjectSettings(Project);

    If Not CurrentSettings["result"] Then
        Return CurrentSettings;
    Else
        CurrentSettings = CurrentSettings["data"];
    EndIf;

    For Each Setting In CurrentSettings Do

        CurrentValue = Setting["value"];
        CurrentType = Setting["type"];

        If OPI_Tools.CollectionFieldExist(Settings, Setting["name"], CurrentValue) Then

            If CurrentType = "bool" Then

                OPI_TypeConversion.GetBoolean(CurrentValue);
                Setting["value"] = ?(CurrentValue, "true", "false");

            ElsIf CurrentType = "number" Then
                
                OPI_TypeConversion.GetNumber(CurrentValue);
                Setting["value"] = String(CurrentValue);

            Else
                Setting["value"] = String(CurrentValue);
            EndIf;

        EndIf;

    EndDo;

    Table = ConstantValue("SettingsTable");
    Connection = OPI_SQLite.CreateConnection(Project);

    Result = OPI_SQLite.ClearTable(Table, Connection);

    If Not Result["result"] Then
        Return Result;
    EndIf;

    Result = OPI_SQLite.AddRecords(Table, CurrentSettings, , Connection);

    If Result["result"] Then
        Return New Structure("result", True);
    Else
        Return Result;
    EndIf;

EndFunction

// Set project setting
// Sets the value of the selected project setting
//
// Note
// If a value is modified in a running project, the change may take up to 60 seconds to be applied
//
// Parameters:
// Project - String - Project filepath - proj
// Setting - String - Project setting key - key
// Value - String - Value of project setting - value
// Returns:
// Structure Of KeyAndValue - Setting result
Function SetProjectSetting(Val Project, Val Setting, Val Value) Export

    OPI_TypeConversion.GetLine(Setting);
    OPI_TypeConversion.GetLine(Value);

    Return FillProjectSettings(Project, New Structure(Setting, Value));

EndFunction

// Update UI password
// Changes the password for logging into the web console
//
// Note
// If a value is modified in a running project, the change may take up to 60 seconds to be applied
//
// Parameters:
// Project - String - Project filepath - proj
// Password - String - New password - pass
// Returns:
// Structure Of KeyAndValue - Result of password change
Function UpdateUIPassword(Val Project, Val Password) Export

    OPI_TypeConversion.GetLine(Password);
    Return SetProjectSetting(Project, "ui_password", Password);

EndFunction

#EndRegion

#Region HandlersConfiguration

// Add request handler
// Adds a new handler to the project
//
// Parameters:
// Project - String - Project filepath - proj
// OintLibrary - String - Library name in CLI format - lib
// OintFunction - String - OpenIntegrations function name - func
// Method - String - HTTP method to be processed by the handler: GET, JSON, FORM - method
//
// Returns:
// Structure Of KeyAndValue - Result of handler modification
Function AddRequestsHandler(Val Project, Val OintLibrary, Val OintFunction, Val Method = "GET") Export

    OPI_TypeConversion.GetLine(OintLibrary);
    OPI_TypeConversion.GetLine(OintFunction);
    OPI_TypeConversion.GetLine(Method);

    Method = Upper(Method);
    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    If Not Method = "GET" And Not Method = "JSON" And Not Method = "FORM" Then
        Return FormResponse(False, StrTemplate("Unsupported method %1!", Method));
    EndIf;

    SecretKey = ReceiveUniqueHandlerKey(Project);

    If TypeOf(SecretKey) = Type("Map") Then
        SecretKey.Insert("message", "Failed to generate the UID of the handler. Try again!");
        Return SecretKey;
    EndIf;

    RecordStructure = New Structure;
    RecordStructure.Insert("library" , OintLibrary);
    RecordStructure.Insert("function", OintFunction);
    RecordStructure.Insert("key" , SecretKey);
    RecordStructure.Insert("method" , Method);
    RecordStructure.Insert("active" , True);

    HandlersTableName = ConstantValue("HandlersTable");
    Result = OPI_SQLite.AddRecords(HandlersTableName, RecordStructure, False, Project);

    If Result["result"] Then

          Result = New Structure;
          Result.Insert("result" , True);
          Result.Insert("key" , SecretKey);
          Result.Insert("url_example", "localhost:port/" + SecretKey);

    EndIf;

    Return Result;

EndFunction

// Get request handlers list
// Gets the list of handlers in the project
//
// Parameters:
// Project - String - Project filepath - proj
//
// Returns:
// Structure Of KeyAndValue - Handlers list
Function GetRequestsHandlersList(Val Project) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("HandlersTable");
    Result = OPI_SQLite.GetRecords(Table, , , , , Project);

    Return Result;

EndFunction

// Get request handler
// Gets information about the handler by key
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Handlers information
Function GetRequestsHandler(Val Project, Val HandlersKey) Export

    OPI_TypeConversion.GetLine(HandlersKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("HandlersTable");

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);

    Result = OPI_SQLite.GetRecords(Table, , FilterStructure, , , Project);

    If Result["result"] Then

        For Each Element In Result["data"] Do

            Arguments = GetHandlerArguments(Project, HandlersKey);
            Arguments = ?(Arguments["result"], Arguments["data"], Arguments);

            Element.Insert("args", Arguments);

        EndDo;

        RecordAmount = Result["data"].Count();

        If RecordAmount = 1 Then

            Result["data"] = Result["data"][0];

        Else

            If RecordAmount = 0 Then
                Result = FormResponse(False, "Handler not found!");
             EndIf;

        EndIf;

    EndIf;

    Return Result;

EndFunction

// Delete request handler
// Removes the request handler from the project
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Deleting result
Function DeleteRequestsHandler(Val Project, Val HandlersKey) Export

    OPI_TypeConversion.GetLine(HandlersKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("HandlersTable");

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);

    Results = New Map;
    Success = True;

    For Each Table In TableConstantNames() Do

        TableName = ConstantValue(Table);
        Result = OPI_SQLite.DeleteRecords(TableName, FilterStructure, Project);
        CurrentSuccess = Result["result"];

        Results.Insert(TableName, CurrentSuccess);

        Success = ?(Not CurrentSuccess, CurrentSuccess, Success);

    EndDo;

    Return New Structure("result,tables", Success, Results);

EndFunction

// Update request handler
// Changes the values of the request handler fields
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
// OintLibrary - String - Library name in CLI format - lib
// OintFunction - String - OpenIntegrations function name - func
// Method - String - HTTP method to be processed by the handler: GET, JSON, FORM - method
//
// Returns:
// Structure Of KeyAndValue - Result of changing the handler
Function UpdateRequestsHandler(Val Project
    , Val HandlersKey
    , Val OintLibrary = ""
    , Val OintFunction = ""
    , Val Method = "") Export

    OPI_TypeConversion.GetLine(OintLibrary);
    OPI_TypeConversion.GetLine(OintFunction);
    OPI_TypeConversion.GetLine(Method);
    OPI_TypeConversion.GetLine(HandlersKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    RecordStructure = New Structure;

    If ValueIsFilled(OintLibrary) Then
        RecordStructure.Insert("library" , OintLibrary);
    EndIf;

    If ValueIsFilled(OintFunction) Then
        RecordStructure.Insert("function", OintFunction);
    EndIf;

    If ValueIsFilled(Method) Then
        RecordStructure.Insert("method" , Method);
    EndIf;

    Result = ChangeHandlersFields(Project, HandlersKey, RecordStructure);

    Return Result;

EndFunction

// Disable request handler
// Disables the handler by key
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Switching result
Function DisableRequestsHandler(Val Project, Val HandlersKey) Export

    Return SwitchRequestsHandler(Project, HandlersKey, False);

EndFunction

// Enable request handler
// Enables the handler by key
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Switching result
Function EnableRequestsHandler(Val Project, Val HandlersKey) Export

    Return SwitchRequestsHandler(Project, HandlersKey, True);

EndFunction

// Update handlers key
// Replaces the handler key with a new one
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
// NewKey - String - Your own key, if necessary. New standard UUID by default - key
//
// Returns:
// Structure Of KeyAndValue - Handlers information
Function UpdateHandlersKey(Val Project, Val HandlersKey, Val NewKey = "") Export

    OPI_TypeConversion.GetLine(HandlersKey);
    OPI_TypeConversion.GetLine(NewKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    NewKey = ?(ValueIsFilled(NewKey), NewKey, GetUUID(9));

    RecordStructure = New Structure("key", NewKey);
    Result = ChangeHandlersFields(Project, HandlersKey, RecordStructure);

    If Not Result["result"] Then
        Return Result;
    EndIf;

    Result = GetRequestsHandler(Project, NewKey);

    Return Result;

EndFunction

#EndRegion

#Region ArgumentSetting

// Set handler argument
// Sets an argument to the handler function, allowing it to be unspecified when called
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
// Argument - String - CLI argument (option) for the handler function - arg
// Value - String - String argument value - value
// Strict - Boolean - True > argument cannot be overwritten with data from the query - strict
//
// Returns:
// Structure Of KeyAndValue - Setting result
Function SetHandlerArgument(Val Project
    , Val HandlersKey
    , Val Argument
    , Val Value
    , Val Strict = True) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    OPI_TypeConversion.GetLine(HandlersKey);
    OPI_TypeConversion.GetLine(Argument);
    OPI_TypeConversion.GetLine(Value);
    OPI_TypeConversion.GetBoolean(Strict);

    FiltersArray = New Array;

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);
    FiltersArray.Add(FilterStructure);

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "arg");
    FilterStructure.Insert("value", Argument);
    FiltersArray.Add(FilterStructure);

    Table = ConstantValue("ArgsTable");
    Result = OPI_SQLite.GetRecords(Table, , FiltersArray, , , Project);

    If Result["result"] Then

        RecordAmount = Result["data"].Count();

        RecordStructure = New Structure("value,strict", Value, Strict);

        If RecordAmount <> 0 Then
            Result = OPI_SQLite.UpdateRecords(Table, RecordStructure, FiltersArray, Project);
        Else

            RecordStructure.Insert("key", HandlersKey);
            RecordStructure.Insert("arg", Argument);
            Result = OPI_SQLite.AddRecords(Table, RecordStructure, False, Project);

        EndIf;

        If Result["result"] Then
            Result = GetRequestsHandler(Project, HandlersKey);
        EndIf;

    EndIf;

    Return Result;

EndFunction

// Get handler arguments
// Gets the list of handler arguments
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Handlers list
Function GetHandlerArguments(Val Project, Val HandlersKey) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    OPI_TypeConversion.GetLine(HandlersKey);

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);

    Table = ConstantValue("ArgsTable");
    FieldArray = StrSplit("arg,value,strict", ",");

    Result = OPI_SQLite.GetRecords(Table, FieldArray, FilterStructure, , , Project);

    Return Result;

EndFunction

// Clear handler arguments
// Deletes all previously values of the handler arguments
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
//
// Returns:
// Structure Of KeyAndValue - Cleaning result
Function ClearHandlerArguments(Val Project, Val HandlersKey) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    OPI_TypeConversion.GetLine(HandlersKey);

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);

    Table = ConstantValue("ArgsTable");

    Result = OPI_SQLite.DeleteRecords(Table, FilterStructure, Project);

    Return Result;

EndFunction

#EndRegion

#EndRegion

#Region Internal

Function ReceiveUniqueHandlerKey(Path) Export

    SecretKey = GetUUID(9);
    Table = ConstantValue("HandlersTable");

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", SecretKey);
    FilterStructure.Insert("raw" , False);

    Result = OPI_SQLite.GetRecords(Table, , FilterStructure, , , Path);

    If Not Result["result"] Then
        Return Result;
    EndIf;

    While Result["data"].Count() > 0 Do

        SecretKey = GetUUID(9);
        FilterStructure["value"] = SecretKey;

        Result = OPI_SQLite.GetRecords(Table, , FilterStructure, , , Path);

        If Not Result["result"] Then
            Return Result;
        EndIf;

    EndDo;

    Return SecretKey;

EndFunction

#EndRegion

#Region Private

#Region Project

Function CheckProjectExistence(Path)

    If OPI_AddIns.IsAddIn(Path) Then
        Return FormResponse(True, "", Path);
    EndIf;

    OPI_TypeConversion.GetLine(Path);
    OPI_Tools.RestoreEscapeSequences(Path);

    ProjectFile = New File(Path);
    Text = "Project file already exists!";
    Result = True;

    If Not ProjectFile.Exist() Then
        Text = "Project file not found at the specified path!";
        Result = False;
    EndIf;

    If ProjectFile.IsDirectory() Then
        Text = "The path to the directory is passed, not to the project file!";
        Result = False;
    EndIf;

    ResponseStructure = FormResponse(Result, Text, ProjectFile.FullName);

    Return ResponseStructure;

EndFunction

Function NormalizeProject(Path)

    OPI_TypeConversion.GetLine(Path);
    OPI_Tools.RestoreEscapeSequences(Path);

    BaseFile = New File(Path);

    If BaseFile.Exist() And BaseFile.IsDirectory() Then

        Counter = 0;

        While BaseFile.Exist() Do

            NewPath = Path + "/new_project_" + String(Counter) + ".oint";
            BaseFile = New File(NewPath);

            Counter = Counter + 1;

        EndDo;

    EndIf;

    FullPath = BaseFile.FullName;

    If Not BaseFile.Exist() Then

        Result = CreateNewProject(FullPath);

        If Result["result"] Then
            Text = "The project file has been successfully created!";
            Response = FormResponse(True, Text, FullPath);
        Else
            Response = Result;
        EndIf;

    Else

        Text = "The project file at the specified path already exists!";
        Response = FormResponse(False, Text, FullPath);

    EndIf;

    Return Response;

EndFunction

Function CheckRestoreProject(Val Path)

    OPI_TypeConversion.GetLine(Path);
    OPI_Tools.RestoreEscapeSequences(Path);

    BaseFile = New File(Path);
    FullPath = BaseFile.FullName;

    If Not BaseFile.Exist() Then
        Text = "The project file does not exist at the specified location!";
        Response = FormResponse(False, Text, FullPath);
    Else
        
        Result = CreateNewProject(FullPath);

        If Result["result"] Then
            Text = "The project file has been checked and converted to the required format!";
            Response = FormResponse(True, Text, FullPath);
        Else
            Response = Result;
        EndIf;

    EndIf;

    Return Response;

EndFunction

Function FormResponse(Val Result, Val Text, Val Path = "")

    Response = New Structure("result,message", Result, Text);

    If ValueIsFilled(Path) Then
        Response.Insert("path", Path);
    EndIf;

    Return Response;

EndFunction

Function ConstantValue(Val Key)

    If Key = "HandlersTable" Then Return "handlers"
    ElsIf Key = "ArgsTable" Then Return "arguments"
    ElsIf Key = "SettingsTable" Then Return "settings"

    Else Return "" EndIf;

EndFunction

Function TableConstantNames(Val HandlersOnly = True)

    ArrayOfNames = New Array;
    ArrayOfNames.Add("HandlersTable");
    ArrayOfNames.Add("ArgsTable");

    If Not HandlersOnly Then
        ArrayOfNames.Add("SettingsTable");
    EndIf;

    Return ArrayOfNames;

EndFunction

Function CreateNewProject(Path)

    FileObject = New File(Path);

    If Not FileObject.Exist() Then
        EmptyFile = ПолучитьДвоичныеДанныеИзСтроки("");
        EmptyFile.Write(Path);
    EndIf;

    Result = CreateHandlersTable(Path);

    If Not Result["result"] Then
        DeleteFiles(Path);
        Return Result;
    EndIf;

    Result = CreateArgsTable(Path);

    If Not Result["result"] Then
        DeleteFiles(Path);
        Return Result;
    EndIf;

    Result = CreateSettingsTable(Path);

    If Not Result["result"] Then
        DeleteFiles(Path);
        Return Result;
    EndIf;

    Result = SetDefaultSettings(Path);

    If Not Result["result"] Then
        DeleteFiles(Path);
        Return Result;
    EndIf;

    Return Result;

EndFunction

Function CreateHandlersTable(Path)

    TableStructure = New Structure();
    TableStructure.Insert("key" , "TEXT PRIMARY KEY NOT NULL UNIQUE");
    TableStructure.Insert("library" , "TEXT");
    TableStructure.Insert("function", "TEXT");
    TableStructure.Insert("method" , "TEXT");
    TableStructure.Insert("active" , "BOOLEAN");

    HandlersTableName = ConstantValue("HandlersTable");  
    Result = OPI_SQLite.EnsureTable(HandlersTableName, TableStructure, Path);

    Return Result;

EndFunction

Function CreateArgsTable(Path)

    TableStructure = New Map();
    TableStructure.Insert("key" , "TEXT");
    TableStructure.Insert("arg" , "TEXT");
    TableStructure.Insert("value" , "TEXT");
    TableStructure.Insert("strict" , "BOOLEAN");

    ArgsTableName = ConstantValue("ArgsTable");
    Result = OPI_SQLite.EnsureTable(ArgsTableName, TableStructure, Path);

    Return Result;

EndFunction

Function CreateSettingsTable(Path)

    TableStructure = New Map();
    TableStructure.Insert("name" , "TEXT PRIMARY KEY NOT NULL UNIQUE");
    TableStructure.Insert("description", "TEXT");
    TableStructure.Insert("value" , "TEXT");
    TableStructure.Insert("type" , "TEXT");

    SettingTableName = ConstantValue("SettingsTable");
    Result = OPI_SQLite.EnsureTable(SettingTableName, TableStructure, Path);

    Return Result;

EndFunction

Function SetDefaultSettings(Path)

    DefaultSettings = GetDefaultSettings();
    SettingTableName = ConstantValue("SettingsTable");

    Existing = OPI_SQLite.GetRecords(SettingTableName, "name", , , , Path);

    If Not Existing["result"] Then
        Return Existing;
    EndIf;

    CurrentSettings = Existing["data"];

    If ValueIsFilled(CurrentSettings) Then

        CurrentList = New ValueList();

        For Each Setting In CurrentSettings Do
            CurrentList.Add(Setting["name"]);
        EndDo;

        DefaultSettings_ = New Array;

        For Each DefaultSetting In DefaultSettings Do

            If CurrentList.FindByValue(DefaultSetting["name"]) = Undefined Then
                DefaultSettings_.Add(DefaultSetting);
            EndIf;

        EndDo;

        DefaultSettings = DefaultSettings_;

    EndIf;

    Result = OPI_SQLite.AddRecords(SettingTableName, DefaultSettings, , Path);

    Return Result;

EndFunction

Function GetDefaultSettings()

    SettingsList = New Array;
    SettingsFields = "name,description,value,type";

    SettingsList.Add(New Structure(SettingsFields, "ui_password" , "Web console login Password", "admin", "string"));
    SettingsList.Add(New Structure(SettingsFields, "res_wrapper" , "The flag for using the Melezh {'result':true, 'data': <primary response>} wrapper over the original function responses (does not affect non-JSON responses))", "true", "bool"));
    SettingsList.Add(New Structure(SettingsFields, "req_max_size" , "The maximum allowed request body size (in bytes). Requests exceeding this limit will be rejected. 0 - no limitation", "209715200", "number"));
    SettingsList.Add(New Structure(SettingsFields, "logs_path" , "Logs save path. To disable logging, set the value to empty", LogDirectory(), "string"));
    SettingsList.Add(New Structure(SettingsFields, "logs_req_headers" , "Logging of incoming request headers", "true", "bool"));
    SettingsList.Add(New Structure(SettingsFields, "logs_req_body" , "Logging the body of incoming requests", "true", "bool"));
    SettingsList.Add(New Structure(SettingsFields, "logs_req_max_size", "Disable logging logs_req_body for requests over this size (in bytes). 0 - no limitation", "104857600", "number"));
    SettingsList.Add(New Structure(SettingsFields, "logs_res_body" , "Logging the body of outgoing responses", "true", "bool"));
    SettingsList.Add(New Structure(SettingsFields, "logs_res_max_size", "Disable logging logs_res_body for requests over this size (in bytes). 0 - no limitation", "104857600", "number"));
    SettingsList.Add(New Structure(SettingsFields, "base_path" , "Base path of the API. All routes will be available with the specified prefix. For example: /melezh", "", "string"));
    
    Return SettingsList;
    
EndFunction

Function GetUUID(Val Length)
    Return Left(StrReplace(String(New UUID), "-", ""), Length);
EndFunction

Function ChangeHandlersFields(Val Project, Val HandlersKey, Val RecordStructure)

    If RecordStructure.Count() > 0 Then

        FilterStructure = New Structure;

        FilterStructure.Insert("field", "key");
        FilterStructure.Insert("type" , "=");
        FilterStructure.Insert("value", HandlersKey);
        FilterStructure.Insert("raw" , False);

        HandlersTableName = ConstantValue("HandlersTable");

        Result = OPI_SQLite.UpdateRecords(HandlersTableName
            , RecordStructure
            , FilterStructure
            , Project);

    Else
        Result = FormResponse(False, "Nothings changed!");
    EndIf;

    Return Result;

EndFunction

Function SwitchRequestsHandler(Val Project, Val HandlersKey, Val Activity)

    OPI_TypeConversion.GetLine(HandlersKey);
    OPI_TypeConversion.GetBoolean(Activity);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    RecordStructure = New Structure("active", Activity);
    Result = ChangeHandlersFields(Project, HandlersKey, RecordStructure);

    Return Result;

EndFunction

Function LogDirectory()

    Try
        MelezhCatalog = StrTemplate("%1%2", StrReplace(TempFilesDir(), "\", "/"), "Melezh");
        MelezhFile = New File(MelezhCatalog);

        If Not MelezhFile.Exist() Then
            CreateDirectory(MelezhCatalog);
        EndIf;

        ProjectCatalog = StrTemplate("%1/%2", MelezhCatalog, String(New UUID()));
        ProjectFile = New File(ProjectCatalog);

        If Not ProjectFile.Exist() Then
        
            CreateDirectory(ProjectCatalog);

        Else

            While ProjectFile.Exist() Do

                ProjectCatalog = StrTemplate("%1/%2", MelezhCatalog, String(New UUID()));
                ProjectFile = New File(ProjectCatalog);

            EndDo;

            CreateDirectory(ProjectCatalog);

        EndIf;
    Except
        ProjectCatalog = "";
    EndTry;
    
    Return ProjectCatalog;

EndFunction

#EndRegion

#Region Service

Function GetServerCatalogs()

    LaunchCatalog = EntryScript().Path;
    LaunchCatalog = StrReplace(LaunchCatalog, "\", "/");

    PathParts = StrSplit(LaunchCatalog, "/");

    PathParts.Delete(PathParts.UBound());
    PathParts.Delete(PathParts.UBound());

    MainDirectory = StrConcat(PathParts, "/");

    ExtensionsCatalog = MainDirectory + "/extensions/Modules";
    RootCatalog = MainDirectory + "/ui" ;

    Return New Structure("Root,Extensions", RootCatalog, ExtensionsCatalog);

EndFunction

#EndRegion

#EndRegion
