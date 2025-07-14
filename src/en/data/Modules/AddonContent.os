Function GetVersion() Export
  Return "0.3.0";
EndFunction

Function GetComposition() Export

    CompositionTable = New ValueTable();
    CompositionTable.Columns.Add("Method");
    CompositionTable.Columns.Add("SearchMethod");
    CompositionTable.Columns.Add("Parameter");
    CompositionTable.Columns.Add("Description");
    CompositionTable.Columns.Add("MethodDescription");
    CompositionTable.Columns.Add("Region");

    NewLine = CompositionTable.Add();
    NewLine.Method = "CreateProject";
    NewLine.SearchMethod = "CREATEPROJECT";
    NewLine.Parameter = "--path";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Creates a project file at the selected path";


    NewLine = CompositionTable.Add();
    NewLine.Method = "RunProject";
    NewLine.SearchMethod = "RUNPROJECT";
    NewLine.Parameter = "--port";
    NewLine.Description = "Server startup port";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Runs an integration proxy server";


    NewLine = CompositionTable.Add();
    NewLine.Method = "RunProject";
    NewLine.SearchMethod = "RUNPROJECT";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetProjectSettings";
    NewLine.SearchMethod = "GETPROJECTSETTINGS";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Gets a list of all current project settings";


    NewLine = CompositionTable.Add();
    NewLine.Method = "FillProjectSettings";
    NewLine.SearchMethod = "FILLPROJECTSETTINGS";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Fills in the settings from the passed collection";


    NewLine = CompositionTable.Add();
    NewLine.Method = "FillProjectSettings";
    NewLine.SearchMethod = "FILLPROJECTSETTINGS";
    NewLine.Parameter = "--set";
    NewLine.Description = "Collection key and value to fill in the settings";
    NewLine.Region = "Projects setup";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetProjectSetting";
    NewLine.SearchMethod = "SETPROJECTSETTING";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Sets the value of the selected project setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetProjectSetting";
    NewLine.SearchMethod = "SETPROJECTSETTING";
    NewLine.Parameter = "--key";
    NewLine.Description = "Project setting key";
    NewLine.Region = "Projects setup";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetProjectSetting";
    NewLine.SearchMethod = "SETPROJECTSETTING";
    NewLine.Parameter = "--value";
    NewLine.Description = "Value of project setting";
    NewLine.Region = "Projects setup";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateUIPassword";
    NewLine.SearchMethod = "UPDATEUIPASSWORD";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Projects setup";
    NewLine.MethodDescription = "Changes the password for logging into the web console";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateUIPassword";
    NewLine.SearchMethod = "UPDATEUIPASSWORD";
    NewLine.Parameter = "--pass";
    NewLine.Description = "New password";
    NewLine.Region = "Projects setup";


    NewLine = CompositionTable.Add();
    NewLine.Method = "AddRequestsHandler";
    NewLine.SearchMethod = "ADDREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Adds a new handler to the project";


    NewLine = CompositionTable.Add();
    NewLine.Method = "AddRequestsHandler";
    NewLine.SearchMethod = "ADDREQUESTSHANDLER";
    NewLine.Parameter = "--lib";
    NewLine.Description = "Library name in CLI format";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "AddRequestsHandler";
    NewLine.SearchMethod = "ADDREQUESTSHANDLER";
    NewLine.Parameter = "--func";
    NewLine.Description = "OpenIntegrations function name";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "AddRequestsHandler";
    NewLine.SearchMethod = "ADDREQUESTSHANDLER";
    NewLine.Parameter = "--method";
    NewLine.Description = "HTTP method to be processed by the handler: GET, JSON, FORM (optional, default - GET)";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetRequestsHandlersList";
    NewLine.SearchMethod = "GETREQUESTSHANDLERSLIST";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Gets the list of handlers in the project";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetRequestsHandler";
    NewLine.SearchMethod = "GETREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Gets information about the handler by key";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetRequestsHandler";
    NewLine.SearchMethod = "GETREQUESTSHANDLER";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "DeleteRequestsHandler";
    NewLine.SearchMethod = "DELETEREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Removes the request handler from the project";


    NewLine = CompositionTable.Add();
    NewLine.Method = "DeleteRequestsHandler";
    NewLine.SearchMethod = "DELETEREQUESTSHANDLER";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateRequestsHandler";
    NewLine.SearchMethod = "UPDATEREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Changes the values of the request handler fields";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateRequestsHandler";
    NewLine.SearchMethod = "UPDATEREQUESTSHANDLER";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateRequestsHandler";
    NewLine.SearchMethod = "UPDATEREQUESTSHANDLER";
    NewLine.Parameter = "--lib";
    NewLine.Description = "Library name in CLI format (optional, default - Empty value)";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateRequestsHandler";
    NewLine.SearchMethod = "UPDATEREQUESTSHANDLER";
    NewLine.Parameter = "--func";
    NewLine.Description = "OpenIntegrations function name (optional, default - Empty value)";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateRequestsHandler";
    NewLine.SearchMethod = "UPDATEREQUESTSHANDLER";
    NewLine.Parameter = "--method";
    NewLine.Description = "HTTP method to be processed by the handler: GET, JSON, FORM (optional, default - Empty value)";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "DisableRequestsHandler";
    NewLine.SearchMethod = "DISABLEREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Disables the handler by key";


    NewLine = CompositionTable.Add();
    NewLine.Method = "DisableRequestsHandler";
    NewLine.SearchMethod = "DISABLEREQUESTSHANDLER";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "EnableRequestsHandler";
    NewLine.SearchMethod = "ENABLEREQUESTSHANDLER";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Enables the handler by key";


    NewLine = CompositionTable.Add();
    NewLine.Method = "EnableRequestsHandler";
    NewLine.SearchMethod = "ENABLEREQUESTSHANDLER";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateHandlersKey";
    NewLine.SearchMethod = "UPDATEHANDLERSKEY";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Handlers configuration";
    NewLine.MethodDescription = "Replaces the handler key with a new one";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateHandlersKey";
    NewLine.SearchMethod = "UPDATEHANDLERSKEY";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "UpdateHandlersKey";
    NewLine.SearchMethod = "UPDATEHANDLERSKEY";
    NewLine.Parameter = "--key";
    NewLine.Description = "Your own key, if necessary. New standard UUID by default (optional, default - Empty value)";
    NewLine.Region = "Handlers configuration";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetHandlerArgument";
    NewLine.SearchMethod = "SETHANDLERARGUMENT";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Argument setting";
    NewLine.MethodDescription = "Sets an argument to the handler function, allowing it to be unspecified when called";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetHandlerArgument";
    NewLine.SearchMethod = "SETHANDLERARGUMENT";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Argument setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetHandlerArgument";
    NewLine.SearchMethod = "SETHANDLERARGUMENT";
    NewLine.Parameter = "--arg";
    NewLine.Description = "CLI argument (option) for the handler function";
    NewLine.Region = "Argument setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetHandlerArgument";
    NewLine.SearchMethod = "SETHANDLERARGUMENT";
    NewLine.Parameter = "--value";
    NewLine.Description = "String argument value";
    NewLine.Region = "Argument setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "SetHandlerArgument";
    NewLine.SearchMethod = "SETHANDLERARGUMENT";
    NewLine.Parameter = "--strict";
    NewLine.Description = "True > argument cannot be overwritten with data from the query (optional, def. val. - Yes)";
    NewLine.Region = "Argument setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetHandlerArguments";
    NewLine.SearchMethod = "GETHANDLERARGUMENTS";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Argument setting";
    NewLine.MethodDescription = "Gets the list of handler arguments";


    NewLine = CompositionTable.Add();
    NewLine.Method = "GetHandlerArguments";
    NewLine.SearchMethod = "GETHANDLERARGUMENTS";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Argument setting";


    NewLine = CompositionTable.Add();
    NewLine.Method = "ClearHandlerArguments";
    NewLine.SearchMethod = "CLEARHANDLERARGUMENTS";
    NewLine.Parameter = "--proj";
    NewLine.Description = "Project filepath";
    NewLine.Region = "Argument setting";
    NewLine.MethodDescription = "Deletes all previously values of the handler arguments";


    NewLine = CompositionTable.Add();
    NewLine.Method = "ClearHandlerArguments";
    NewLine.SearchMethod = "CLEARHANDLERARGUMENTS";
    NewLine.Parameter = "--handler";
    NewLine.Description = "Handlers key";
    NewLine.Region = "Argument setting";

    Return CompositionTable;
EndFunction

