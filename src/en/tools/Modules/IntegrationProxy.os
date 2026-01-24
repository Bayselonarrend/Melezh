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
#Use "../../env/cronos/core"


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
// Create - Boolean - Create a new project if it doesnt exist - create
//
// Returns:
// Structure Of KeyAndValue - Server shutdown result
Function RunProject(Val Port, Val Project, Val Create = False) Export

    If Not OPI_Tools.IsOneScript() Then
        BackgroundTasksManager = Undefined;
        Raise "This function is only available for calling in OneScript!";
    EndIf;

    OPI_TypeConversion.GetNumber(Port);

    Check = CheckRestoreProject(Project, Create);

    If Not Check["result"] Then
        Return Check;
    EndIf;

    InitializationStructure = GetMechanismInitializationStructure(Project);

    BackgroundTasksManager = New("BackgroundTasksManager");
    BackgroundTaskArray = New Array;
    TaskDescriptionArray = New Array;

    // Web-server

    ParameterArray = New Array;
    ParameterArray.Add(Project);
    ParameterArray.Add(Port);
    ParameterArray.Add(InitializationStructure);

    MethodName = "StartWebServer";

    TaskDescriptionArray.Add(New Structure("Method,Parameters", MethodName, ParameterArray));

    // Scheduler

    ParameterArray = New Array;
    ParameterArray.Add(Project);
    ParameterArray.Add(InitializationStructure);

    MethodName = "StartScheduledTasksManager";

    TaskDescriptionArray.Add(New Structure("Method,Parameters", MethodName, ParameterArray));

    // Launch

    For Each TaskDescription In TaskDescriptionArray Do

        NewTask = BackgroundTasksManager.Execute(ЭтотОбъект, TaskDescription["Method"], TaskDescription["Parameters"], True);
        BackgroundTaskArray.Add(NewTask);

    EndDo;

    While True Do

        FailedTask = BackgroundTasksManager.WaitAny(BackgroundTaskArray);
        TaskObject = BackgroundTaskArray[FailedTask];

        Try
            Error = DetailErrorDescription((TaskObject.ExceptionInfo));
        Except
            Error = "";
        EndTry;

        Message(StrTemplate("Critical error in task %1: %2 Restarting...", FailedTask, Error));

        Sleep(5000);

        TaskDescription = TaskDescriptionArray[FailedTask];

        NewTask = BackgroundTasksManager.Execute(ЭтотОбъект, TaskDescription["Method"], TaskDescription["Parameters"], True);
        BackgroundTaskArray.Set(FailedTask, NewTask);

    EndDo;

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

        SettingsDefinition = Undefined;

        TDN = New TypeDescription("Number");
        TDB = New TypeDescription("Boolean");

        For Each SettingsPart In Result["data"] Do

            DataType = SettingsPart["type"];

            If Not ValueIsFilled(DataType) Then

                If Not ValueIsFilled(SettingsDefinition) Then
                    SettingsDefinition = GetDefaultSettings();
                EndIf;

                CurrentDefinition = SettingsDefinition.Get(SettingsPart["name"]);

                If ValueIsFilled(CurrentDefinition) Then
                    DataType = CurrentDefinition["type"];
                EndIf;

            EndIf;

            If DataType = "bool" Then

                CurrentValue = SettingsPart["value"];

                If TypeOf(CurrentValue) = Type("String") Then
                
                    SettingsPart["value"] = ?(CurrentValue = "0", 0, CurrentValue);
                    SettingsPart["value"] = ?(CurrentValue = "1", 1, CurrentValue);

                EndIf;

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
    Table = ConstantValue("SettingsTable");
    CurrentSettings = OPI_SQLite.GetRecords(Table, , , , , Project);

    If Not CurrentSettings["result"] Then
        Return CurrentSettings;
    Else
        CurrentSettings = CurrentSettings["data"];
    EndIf;

    For Each Setting In CurrentSettings Do

        CurrentValue = Setting["value"];
        CurrentType = Setting["type"];

        If OPI_Tools.CollectionFieldExists(Settings, Setting["name"], CurrentValue) Then

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
        SecretKey.Insert("error", "Failed to generate the UID of the handler. Try again!");
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

#Region HandlersOptions

Function SetHandlerOption(Val Project, Val HandlersKey, Val Option, Val Value) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    OPI_TypeConversion.GetLine(HandlersKey);
    OPI_TypeConversion.GetLine(Option);

    FiltersArray = New Array;

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "key");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", HandlersKey);
    FilterStructure.Insert("raw" , False);
    FiltersArray.Add(FilterStructure);

    FilterStructure = New Structure;
    FilterStructure.Insert("field", "option");
    FilterStructure.Insert("value", Option);
    FiltersArray.Add(FilterStructure);

    Table = ConstantValue("HandlersOptionTable");
    Result = OPI_SQLite.GetRecords(Table, , FiltersArray, , , Project);

    If Result["result"] Then

        RecordAmount = Result["data"].Count();

        RecordStructure = New Structure("value", Value);

        If RecordAmount <> 0 Then
            Result = OPI_SQLite.UpdateRecords(Table, RecordStructure, FiltersArray, Project);
        Else
            Result = New Structure("result,error", False, "Option not found!");
        EndIf;

        If Result["result"] Then
            Result = GetHandlerOption(Project, HandlersKey);
        EndIf;

    EndIf;

    Return Result;

EndFunction

Function GetHandlerOption(Val Project, Val HandlersKey) Export

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

#Region ScheduledTasks

// Add scheduled task
// Adds a new handler to the project
//
// Note
// Schedule format:^
// sec min hour day of month month day of week year^
// 0 30 9,12,15 1,15 May-Aug Mon,Wed,Fri 2018/2
//
// Parameters:
// Project - String - Project filepath - proj
// HandlersKey - String - Handlers key - handler
// Schedule - String - Schedule in extended cron format - cron
//
// Returns:
// Structure Of KeyAndValue - Task addition result
Function AddScheduledTask(Val Project, Val HandlersKey, Val Schedule) Export

    OPI_TypeConversion.GetLine(Schedule);
    OPI_TypeConversion.GetLine(HandlersKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Result = GetRequestsHandler(Project, HandlersKey);

    If Not Result["result"] Then
        Return Result;
    EndIf;

    RecordStructure = New Structure;
    RecordStructure.Insert("handler" , HandlersKey);
    RecordStructure.Insert("cron" , Schedule);
    RecordStructure.Insert("active" , True);

    HandlersTableName = ConstantValue("TaskTable");
    Connection = OPI_SQLite.CreateConnection(Project);
    Result = OPI_SQLite.AddRecords(HandlersTableName, RecordStructure, False, Connection);

    If Result["result"] Then

        TaskID = OPI_SQLite.ExecuteSQLQuery("SELECT LAST_INSERT_ROWID();", , , Connection);

        If TaskID["result"] Then
            Result.Insert("id", String(TaskID["data"][0]["LAST_INSERT_ROWID()"]));
        Else
            Result.Insert("id", "Object created, but failed to get its ID: " + TaskID["error"]);
        EndIf;

    EndIf;

    Return Result;

EndFunction

// Delete scheduled task
// Deletes scheduled task from project
//
// Parameters:
// Project - String - Project filepath - proj
// TaskID - Number - Task ID - task
//
// Returns:
// Structure Of KeyAndValue - Deleting result
Function DeleteScheduledTask(Val Project, Val TaskID) Export

    OPI_TypeConversion.GetLine(TaskID);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("TaskTable");

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "id");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", TaskID);
    FilterStructure.Insert("raw" , False);

    Result = OPI_SQLite.DeleteRecords(Table, FilterStructure, Project);

    Return Result;

EndFunction

// Get scheduled task list
// Gets the list of scheduled tasks in the project
//
// Parameters:
// Project - String - Project filepath - proj
//
// Returns:
// Structure Of KeyAndValue - Task list
Function GetScheduledTaskList(Val Project) Export

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("TaskTable");
    Result = OPI_SQLite.GetRecords(Table, , , , , Project);

    Return Result;

EndFunction

// Get scheduled task
// Gets task information by ID
//
// Parameters:
// Project - String - Project filepath - proj
// TaskID - String - Task ID - task
//
// Returns:
// Structure Of KeyAndValue - Handlers information
Function GetScheduledTask(Val Project, Val TaskID) Export

    OPI_TypeConversion.GetLine(TaskID);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    Table = ConstantValue("TaskTable");

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "id");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", TaskID);
    FilterStructure.Insert("raw" , False);

    Result = OPI_SQLite.GetRecords(Table, , FilterStructure, , , Project);

    If Result["result"] Then

        If Result["data"].Count() = 0 Then
            Result = FormResponse(False, "Task not found!");
        Else
            Result["data"] = Result["data"][0];
        EndIf;
        
    EndIf;

    Return Result;

EndFunction

// Update scheduled task
// Changes the schedule of the selected scheduled task
//
// Parameters:
// Project - String - Project filepath - proj
// TaskID - String - Task ID - task
// Schedule - String - Schedule in extended cron format - cron
//
// Returns:
// Structure Of KeyAndValue - Task update result
Function UpdateScheduledTask(Val Project, Val TaskID, Val Schedule = "", Val HandlersKey = "") Export

    OPI_TypeConversion.GetLine(TaskID);
    OPI_TypeConversion.GetLine(Schedule);
    OPI_TypeConversion.GetLine(HandlersKey);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = OPI_SQLite.CreateConnection(Result["path"]);;
    EndIf;

    Task = GetScheduledTask(Project, TaskID);

    If Not Task["result"] Then
        Return Task;
    EndIf;

    RecordStructure = New Structure;

    If ValueIsFilled(Schedule) Then
        RecordStructure.Insert("cron", Schedule);
    EndIf;

    If ValueIsFilled(HandlersKey) Then

        RequestsHandler = GetRequestsHandler(Project, HandlersKey);

        If Not RequestsHandler["result"] Then
            Return RequestsHandler;
        EndIf;

        RecordStructure.Insert("handler", HandlersKey);

    EndIf;

    FilterStructure = New Structure;

    FilterStructure.Insert("field", "id");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", TaskID);
    FilterStructure.Insert("raw" , False);

    TaskTableName = ConstantValue("TaskTable");

    Result = OPI_SQLite.UpdateRecords(TaskTableName
        , RecordStructure
        , FilterStructure
        , Project);

    Return Result;

EndFunction

// Enable scheduled task
// Enables scheduled task by ID
//
// Parameters:
// Project - String - Project filepath - proj
// TaskID - String - Task ID - task
//
// Returns:
// Structure Of KeyAndValue - Switching result
Function EnableScheduledTask(Val Project, Val TaskID) Export

    Return SwitchScheduledTask(Project, TaskID, True);

EndFunction

// Disable scheduled task
// Disables scheduled task by ID
//
// Parameters:
// Project - String - Project filepath - proj
// TaskID - String - Task ID - task
//
// Returns:
// Structure Of KeyAndValue - Switching result
Function DisableScheduledTask(Val Project, Val TaskID) Export

    Return SwitchScheduledTask(Project, TaskID, False);

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

Procedure StartWebServer(Project, Port, InitializationStructure) Export

    TypeServer = Type("WebServer");

    ServersSettings = New Array(1);
    ServersSettings[0] = Port;

    WebServer = New(TypeServer, ServersSettings);

    Handler = New("RequestsHandler");
    Handler.Initialize(InitializationStructure);

    WebServer.AddRequestsHandler(Handler, "MainHandle");
    WebServer.Run();

EndProcedure

Procedure StartScheduledTasksManager(Project, InitializationStructure) Export

    STaskManager = New("ScheduledTasksManager");
    STaskManager.Initialize(InitializationStructure);
    STaskManager.Start();
        
EndProcedure

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

    If Not ProjectFile.Exists() Then
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

    If BaseFile.Exists() And BaseFile.IsDirectory() Then

        Counter = 0;

        While BaseFile.Exists() Do

            NewPath = Path + "/new_project_" + String(Counter) + ".oint";
            BaseFile = New File(NewPath);

            Counter = Counter + 1;

        EndDo;

    EndIf;

    FullPath = BaseFile.FullName;

    If Not BaseFile.Exists() Then

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

Function CheckRestoreProject(Val Path, Val Create = False)

    OPI_TypeConversion.GetBoolean(Create);
    OPI_TypeConversion.GetLine(Path);
    OPI_Tools.RestoreEscapeSequences(Path);

    BaseFile = New File(Path);
    FullPath = BaseFile.FullName;

    If Not BaseFile.Exists() And Not Create Then

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

Function GetMechanismInitializationStructure(Val Project)

    If False Then
        IntegrationProxy = Undefined;
    EndIf;

    RequestsHandler = New("RequestsHandler");
    OPIObject = New("LibraryComposition");
    TaskScheduler = New("Scheduler");
    
    ServerCatalogs = GetServerCatalogs();
    ProxyModule = IntegrationProxy;

    SQLiteConnectionManager = New("SQLiteConnectionManager");
    SQLiteConnectionManager.Initialize(Project);

    SettingsVault = New("SettingsVault");
    SettingsVault.Initialize(SQLiteConnectionManager, ProxyModule);
    
    Logger = New("Logger");
    Logger.Initialize(SettingsVault);

    ActionsProcessor = New("ActionsProcessor");
    ActionsProcessor.Initialize(OPIObject, ProxyModule, SQLiteConnectionManager, Logger, SettingsVault);

    InitializationStructure = New Structure;
    InitializationStructure.Insert("ProjectPath" , Project);
    InitializationStructure.Insert("ServerCatalogs" , ServerCatalogs);
    InitializationStructure.Insert("RequestsHandler" , RequestsHandler);
    InitializationStructure.Insert("OPIObject" , OPIObject);
    InitializationStructure.Insert("ProxyModule" , ProxyModule);
    InitializationStructure.Insert("SQLiteConnectionManager", SQLiteConnectionManager);
    InitializationStructure.Insert("SettingsVault" , SettingsVault);
    InitializationStructure.Insert("Logger" , Logger);
    InitializationStructure.Insert("ActionsProcessor" , ActionsProcessor);
    InitializationStructure.Insert("TaskScheduler" , TaskScheduler);

    Return InitializationStructure;
    
EndFunction

Function FormResponse(Val Result, Val Text, Val Path = "")

    
    Response = New Structure();
    Response.Insert("result", Result);
    Response.Insert(?(Result, "message", "error"), Text);

    If ValueIsFilled(Path) Then
        Response.Insert("path", Path);
    EndIf;

    Return Response;

EndFunction

Function ConstantValue(Val Key)

    If Key = "HandlersTable" Then Return "handlers"
    ElsIf Key = "ArgsTable" Then Return "arguments"
    ElsIf Key = "SettingsTable" Then Return "settings"
    ElsIf Key = "HandlersOptionTable" Then Return "options"
    ElsIf Key = "TaskTable" Then Return "scheduler_tasks"

    Else Return "" EndIf;

EndFunction

Function TableConstantNames(Val HandlersOnly = True)

    ArrayOfNames = New Array;
    ArrayOfNames.Add("HandlersTable");
    ArrayOfNames.Add("ArgsTable");

    If Not HandlersOnly Then
        ArrayOfNames.Add("SettingsTable");
        ArrayOfNames.Add("TaskTable");
    EndIf;

    Return ArrayOfNames;

EndFunction

Function CreateNewProject(Path)

    FileObject = New File(Path);

    If Not FileObject.Exists() Then
        EmptyFile = GetBinaryDataFromString("");
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

    Result = CreateOptionTable(Path);

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

    Result = CreateSchedulerTaskTable(Path);

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

Function CreateOptionTable(Path)

    TableStructure = New Map();
    TableStructure.Insert("key" , "TEXT");
    TableStructure.Insert("option" , "TEXT");
    TableStructure.Insert("value" , "TEXT");
    TableStructure.Insert("type" , "TEXT");
    TableStructure.Insert("description", "TEXT");

    ArgsTableName = ConstantValue("HandlersOptionTable");
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

Function CreateSchedulerTaskTable(Path)

    TableStructure = New Map();
    TableStructure.Insert("id" , "INTEGER PRIMARY KEY AUTOINCREMENT");
    TableStructure.Insert("handler" , "TEXT");
    TableStructure.Insert("cron" , "TEXT");
    TableStructure.Insert("active" , "BOOLEAN");

    SettingTableName = ConstantValue("TaskTable");
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

    CurrentList = New ValueList();

    For Each Setting In CurrentSettings Do
        CurrentList.Add(Setting["name"]);
    EndDo;

    DefaultSettings_ = New Array;

    For Each DefaultSetting In DefaultSettings Do

        SettingValue = DefaultSetting.Value;

        If CurrentList.FindByValue(SettingValue["name"]) = Undefined Then
            DefaultSettings_.Add(SettingValue);
        EndIf;

    EndDo;

    DefaultSettings = DefaultSettings_;

    Result = OPI_SQLite.AddRecords(SettingTableName, DefaultSettings, , Path);

    Return Result;

EndFunction

Function GetDefaultSettings()

    SettingsList = New Map();
    SettingsFields = "name,description,value,type";

    SettingsList.Insert("ui_password" , New Structure(SettingsFields, "ui_password" , "Web console login Password", "admin", "string"));
    
    SettingsList.Insert("res_wrapper" , New Structure(SettingsFields, "res_wrapper" , "The flag for using the Melezh {'result':true, 'data': <primary response>} wrapper over the original function responses (does not affect non-JSON responses))", "true", "bool"));
    SettingsList.Insert("req_max_size" , New Structure(SettingsFields, "req_max_size" , "The maximum allowed request body size (in bytes). Requests exceeding this limit will be rejected. 0 - no limitation", "209715200", "number"));
    SettingsList.Insert("logs_path" , New Structure(SettingsFields, "logs_path" , "Logs save path. To disable logging, set the value to empty", LogDirectory(), "string"));
    SettingsList.Insert("logs_req_headers" , New Structure(SettingsFields, "logs_req_headers" , "Logging of incoming request headers", "true", "bool"));
    SettingsList.Insert("logs_req_body" , New Structure(SettingsFields, "logs_req_body" , "Logging the body of incoming requests", "true", "bool"));
    SettingsList.Insert("logs_req_max_size", New Structure(SettingsFields, "logs_req_max_size", "Disable logging logs_req_body for requests over this size (in bytes). 0 - no limitation", "104857600", "number"));
    SettingsList.Insert("logs_res_body" , New Structure(SettingsFields, "logs_res_body" , "Logging the body of outgoing responses", "true", "bool"));
    SettingsList.Insert("logs_res_max_size", New Structure(SettingsFields, "logs_res_max_size", "Disable logging logs_res_body for requests over this size (in bytes). 0 - no limitation", "104857600", "number"));
    SettingsList.Insert("base_path" , New Structure(SettingsFields, "base_path" , "Base path of the API. All routes will be available with the specified prefix. For example: /melezh", "", "string"));
    SettingsList.Insert("ext_path" , New Structure(SettingsFields, "ext_path" , "Additional extensions directory (requires restart or cache update to apply)", "", "string"));
    SettingsList.Insert("ui_show" , New Structure(SettingsFields, "ui_show" , "Enables and disables the availability of the Web Console", "true", "bool"));
    SettingsList.Insert("index_redirect" , New Structure(SettingsFields, "index_redirect" , "Replaces the output of the title (root) page of Melezh with a redirect to the specified path", "", "string"));
    SettingsList.Insert("auth_attempts" , New Structure(SettingsFields, "auth_attempts" , "Maximum number of allowed incorrect password attempts during authorization. 0 - unlimited.", "0", "number"));
    SettingsList.Insert("auth_ban_duration", New Structure(SettingsFields, "auth_ban_duration", "Lockout duration when maximum allowed authorization attempts are exceeded (in minutes))", "0", "number"));
    
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

Function SwitchScheduledTask(Val Project, Val TaskID, Val Activity)

    OPI_TypeConversion.GetLine(TaskID);
    OPI_TypeConversion.GetBoolean(Activity);

    Result = CheckProjectExistence(Project);

    If Not Result["result"] Then
        Return Result;
    Else
        Project = Result["path"];
    EndIf;

    RecordStructure = New Structure("active", Activity);
    FilterStructure = New Structure;

    FilterStructure.Insert("field", "id");
    FilterStructure.Insert("type" , "=");
    FilterStructure.Insert("value", TaskID);
    FilterStructure.Insert("raw" , False);

    HandlersTableName = ConstantValue("TaskTable");

    Result = OPI_SQLite.UpdateRecords(HandlersTableName
        , RecordStructure
        , FilterStructure
        , Project);

    Return Result;

EndFunction

Function LogDirectory()

    Try
        MelezhCatalog = StrTemplate("%1%2", StrReplace(TempFilesDir(), "\", "/"), "Melezh");
        MelezhFile = New File(MelezhCatalog);

        If Not MelezhFile.Exists() Then
            CreateDirectory(MelezhCatalog);
        EndIf;

        ProjectCatalog = StrTemplate("%1/%2", MelezhCatalog, String(New UUID()));
        ProjectFile = New File(ProjectCatalog);

        If Not ProjectFile.Exists() Then
        
            CreateDirectory(ProjectCatalog);

        Else

            While ProjectFile.Exists() Do

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

Function GetSetting(Val Name, Val Project) 

    BaseSettings = GetProjectSettings(Project);
    Result = Undefined;
	
	If Not BaseSettings["result"] Then
		Raise BaseSettings["error"];	
	EndIf;
		
	For Each Setting In BaseSettings["data"] Do

		If Setting["name"] = Name Then
			Result = Setting["value"];
		EndIf;

	EndDo;

    Return Result;

EndFunction

#EndRegion

#EndRegion

#Region Alternate

Function СоздатьПроект(Val Путь) Export
	Return CreateProject(Путь);
EndFunction

Function ЗапуститьПроект(Val Порт, Val Проект, Val Создавать = False) Export
	Return RunProject(Порт, Проект, Создавать);
EndFunction

Function ПолучитьНастройкиПроекта(Val Проект) Export
	Return GetProjectSettings(Проект);
EndFunction

Function ЗаполнитьНастройкиПроекта(Val Проект, Val Настройки) Export
	Return FillProjectSettings(Проект, Настройки);
EndFunction

Function УстановитьНастройкуПроекта(Val Проект, Val Настройка, Val Значение) Export
	Return SetProjectSetting(Проект, Настройка, Значение);
EndFunction

Function СменитьПарольUI(Val Проект, Val Пароль) Export
	Return UpdateUIPassword(Проект, Пароль);
EndFunction

Function ДобавитьОбработчикЗапросов(Val Проект, Val БиблиотекаОПИ, Val ФункцияОПИ, Val Метод = "GET") Export
	Return AddRequestsHandler(Проект, БиблиотекаОПИ, ФункцияОПИ, Метод);
EndFunction

Function ПолучитьСписокОбработчиковЗапросов(Val Проект) Export
	Return GetRequestsHandlersList(Проект);
EndFunction

Function ПолучитьОбработчикЗапросов(Val Проект, Val КлючОбработчика) Export
	Return GetRequestsHandler(Проект, КлючОбработчика);
EndFunction

Function УдалитьОбработчикЗапросов(Val Проект, Val КлючОбработчика) Export
	Return DeleteRequestsHandler(Проект, КлючОбработчика);
EndFunction

Function ИзменитьОбработчикЗапросов(Val Проект, Val КлючОбработчика, Val БиблиотекаОПИ = "", Val ФункцияОПИ = "", Val Метод = "") Export
	Return UpdateRequestsHandler(Проект, КлючОбработчика, БиблиотекаОПИ, ФункцияОПИ, Метод);
EndFunction

Function ОтключитьОбработчикЗапросов(Val Проект, Val КлючОбработчика) Export
	Return DisableRequestsHandler(Проект, КлючОбработчика);
EndFunction

Function ВключитьОбработчикЗапросов(Val Проект, Val КлючОбработчика) Export
	Return EnableRequestsHandler(Проект, КлючОбработчика);
EndFunction

Function ОбновитьКлючОбработчика(Val Проект, Val КлючОбработчика, Val НовыйКлюч = "") Export
	Return UpdateHandlersKey(Проект, КлючОбработчика, НовыйКлюч);
EndFunction

Function УстановитьОпциюОбработчика(Val Проект, Val КлючОбработчика, Val Опция, Val Значение) Export
	Return SetHandlerOption(Проект, КлючОбработчика, Опция, Значение);
EndFunction

Function ПолучитьОпцииОбработчика(Val Проект, Val КлючОбработчика) Export
	Return GetHandlerOption(Проект, КлючОбработчика);
EndFunction

Function УстановитьАргументОбработчика(Val Проект, Val КлючОбработчика, Val Аргумент, Val Значение, Val Строгий = True) Export
	Return SetHandlerArgument(Проект, КлючОбработчика, Аргумент, Значение, Строгий);
EndFunction

Function ПолучитьАргументыОбработчика(Val Проект, Val КлючОбработчика) Export
	Return GetHandlerArguments(Проект, КлючОбработчика);
EndFunction

Function ОчиститьАргументыОбработчика(Val Проект, Val КлючОбработчика) Export
	Return ClearHandlerArguments(Проект, КлючОбработчика);
EndFunction

Function ДобавитьРегламентноеЗадание(Val Проект, Val КлючОбработчика, Val Расписание) Export
	Return AddScheduledTask(Проект, КлючОбработчика, Расписание);
EndFunction

Function УдалитьРегламентноеЗадание(Val Проект, Val IDЗадания) Export
	Return DeleteScheduledTask(Проект, IDЗадания);
EndFunction

Function ПолучитьСписокРегламентныхЗаданий(Val Проект) Export
	Return GetScheduledTaskList(Проект);
EndFunction

Function ПолучитьРегламентноеЗадание(Val Проект, Val IDЗадания) Export
	Return GetScheduledTask(Проект, IDЗадания);
EndFunction

Function ИзменитьРегламентноеЗадание(Val Проект, Val IDЗадания, Val Расписание = "", Val КлючОбработчика = "") Export
	Return UpdateScheduledTask(Проект, IDЗадания, Расписание, КлючОбработчика);
EndFunction

Function ВключитьРегламентноеЗадание(Val Проект, Val IDЗадания) Export
	Return EnableScheduledTask(Проект, IDЗадания);
EndFunction

Function ОтключитьРегламентноеЗадание(Val Проект, Val IDЗадания) Export
	Return DisableScheduledTask(Проект, IDЗадания);
EndFunction

Function ПолучитьУникальныйКлючОбработчика(Путь) Export
	Return ReceiveUniqueHandlerKey(Путь);
EndFunction

Procedure ЗапуститьВебСервер(Проект, Порт, СтруктураИнициализации) Export
	StartWebServer(Проект, Порт, СтруктураИнициализации);
EndProcedure

Procedure ЗапуститьМенеджерРегламентныхЗаданий(Проект, СтруктураИнициализации) Export
	StartScheduledTasksManager(Проект, СтруктураИнициализации);
EndProcedure

#EndRegion