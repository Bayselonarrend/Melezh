#Use "./internal"

Var OPIObject;
Var SettingsVault;
Var ExtensionsCatalog;
Var ExtensionsCache;
Var ActionsProcessor;

#Region Internal

Procedure Initialize(OPIObject_, SettingsVault_, ExtensionsCatalog_, ActionsProcessor_) Export
	
	OPIObject = OPIObject_;
	SettingsVault = SettingsVault_;
    ExtensionsCatalog = ExtensionsCatalog_;
    ExtensionsCache = New Map;
    ActionsProcessor = ActionsProcessor_;

    CompleteCompositionWithExtensions();
	
EndProcedure

Procedure CompleteCompositionWithExtensions() Export

    ExtensionsDirectories = GetExtensionDirectories();

    For Each CurrentExtensionsCatalog In ExtensionsDirectories Do
        
        ExtensionFiles = FindFiles(CurrentExtensionsCatalog, "*.os");

        For Each ExtensionFile In ExtensionFiles Do

            ConnectExtensionFile(ExtensionFile);

        EndDo;

    EndDo;

EndProcedure

Function ConnectExtensionFile(ExtensionFile, Test = False) Export

    Try

        ExtensionName = ExtensionFile.BaseName;

        If Not Toolbox.StringStartsWithLetter(ExtensionName) Then

            TroubleDescription = StrTemplate("Error applying extension %1: module name must start with a letter", ExtensionName);
            HandleConnectionException(ExtensionFile, TroubleDescription, Test);
            Return TroubleDescription;

        EndIf;

        Try 
            ObjectTest = LoadScript(ExtensionFile.FullName, New Structure("Melezh", ActionsProcessor));
        Except
            TroubleDescription = StrTemplate("Error applying the extension: %1", DetailErrorDescription(ErrorInfo()));
            HandleConnectionException(ExtensionFile, TroubleDescription, Test);
            Return TroubleDescription;
        EndTry;

        ParametersTable = ParseModule(ExtensionFile);

        If Not Test Then
            OPIObject.CompleteCompositionCache(ExtensionFile.BaseName, ParametersTable); 
            ActionsProcessor.ConnectExtensionScript(ExtensionFile.FullName, ExtensionFile.BaseName);
        EndIf;

    Except

        TroubleDescription = StrTemplate("Error applying the extension: %1", DetailErrorDescription(ErrorInfo()));
        HandleConnectionException(ExtensionFile, TroubleDescription, Test);
        Return TroubleDescription;

    EndTry;

    Return Undefined;

EndFunction

Function GetExtensionsList() Export

    ExtensionsArray = New Array;

    For Each Extension In ExtensionsCache Do

        CurrentExtension = New Structure;
        CurrentExtension.Insert("name" , Extension.Key);
        CurrentExtension.Insert("filepath", Extension.Value["filepath"]);
        CurrentExtension.Insert("count" , Extension.Value["count"]);
        
        ExtensionsArray.Add(CurrentExtension);

    EndDo;

    Return New Structure("result,data", True, ExtensionsArray);

EndFunction

Function UpdateExtensionsList() Export

    ExtensionsCache = New Map;
    OPIObject.InitializeCommonLists();
    ActionsProcessor.ClearActiveExtensionsList();
    CompleteCompositionWithExtensions();
    
    Return New Structure("result", True);

EndFunction

Function GetExtensionText(ModuleName) Export

    Extension = ExtensionsCache.Get(ModuleName);

    If Extension = Undefined Then
        Result = New Structure("result,error", False, "Extension with the specified name not found!");
    Else

        Text = GetStringFromBinaryData(New BinaryData(Extension["filepath"]));
        Result = New Structure("result,text", True, Text);

    EndIf;

    Return Result;

EndFunction

Function SaveExtensionsText(ModuleName, ModuleText) Export

    Extension = ExtensionsCache.Get(ModuleName);

    If Extension = Undefined Then
        Result = New Structure("result,error", False, "Extension with the specified name not found!");
    Else

        TextBD = GetBinaryDataFromString(ModuleText);
        TextBD.Write(Extension["filepath"]);

        Result = UpdateExtensionsList();

    EndIf;

    Return Result;

EndFunction

Function GetExtensionDirectoryList() Export
    Return New Structure("result,data", True, GetExtensionDirectories());
EndFunction

Function CreateExtensionFile(ModuleName, CreationDirectory) Export

    If Not Toolbox.StringStartsWithLetter(ModuleName) Then
        Return New Structure("result,error,code", False, "The module name must start with a letter!", 400);
    EndIf;

    ExtensionsDirectories = GetExtensionDirectories();
    IsAccessible = False;
    
    For Each CurrentExtensionsCatalog In ExtensionsDirectories Do

        If CurrentExtensionsCatalog = CreationDirectory Then
            IsAccessible = True;
        EndIf;

    EndDo;

    If Not IsAccessible Then
        Return New Structure("result,error,code", False, "The specified extension directory is incorrect", 404);
    EndIf;

    If ExtensionsCache.Get(ModuleName) <> Undefined Then
        Return New Structure("result,error,code", False, "An extension with this name already exists", 400);
    EndIf;

    SavePath = StrReplace(CreationDirectory, "\", "/");
    SavePath = ?(StrEndsWith(SavePath, "/"), SavePath, SavePath + "/");
    SavePath = StrTemplate("%1%2.os", SavePath, ModuleName);

    GetBinaryDataFromString("").Write(SavePath);

    Result = UpdateExtensionsList();

    Return Result;
    
EndFunction

Function DeleteExtensionFile(ModuleName) Export

    Extension = ExtensionsCache.Get(ModuleName);

    If Extension = Undefined Then
        Result = New Structure("result,error", False, "Extension with the specified name not found!");
    Else
      
        DeleteFiles(Extension["filepath"]);
        Result = UpdateExtensionsList();

    EndIf;

    Return Result;

EndFunction

#EndRegion

#Region Private

Function ParseModule(Module)
    
    CompositionTable = New ValueTable();
    CompositionTable.Columns.Add("Library");
    CompositionTable.Columns.Add("Module");
    CompositionTable.Columns.Add("Method");
    CompositionTable.Columns.Add("SearchMethod");
    CompositionTable.Columns.Add("Parameter");
    CompositionTable.Columns.Add("ParameterTrim");
    CompositionTable.Columns.Add("Description");
    CompositionTable.Columns.Add("MethodDescription");
    CompositionTable.Columns.Add("Region");
    
    Parser = New("EmbeddedLanguageParser");
    ModuleDocument = New TextDocument;
    ModuleDocument.Read(Module.FullName, "UTF-8");

    ModuleText = ModuleDocument.GetText();
    ModuleStructure = Parser.Parse(ModuleText);
    CurrentRegion = "Common methods";

    MethodCounter = 0;
    For Each Method In ModuleStructure.Declarations Do
  
        If Method.Type = "InstructionPreprocessorRegion" Then
            CurrentRegion = Synonymizer(Method.Name);
        EndIf;
        
        If Method.Type = "MethodDeclaration" And Method.Signature.Export = True Then

            ParseMethodComment(ModuleDocument, Method, Module, CurrentRegion, CompositionTable);	 

            If ValueIsFilled(CompositionTable) Then
                MethodCounter = MethodCounter + 1;      
            EndIf;

        EndIf;
        
    EndDo;

    AddExtensionToCache(Module.BaseName, Module.FullName, MethodCounter);

    Return CompositionTable;

EndFunction

Procedure ParseMethodComment(TextDocument, Method, Module, Region, CompositionTable)
    
    LineNumber = Method.Start.LineNumber;
    MethodName = Method.Signature.Name;
    
    CommentArray = CommentParsing(TextDocument, LineNumber);
    
    If CommentArray.Count() = 0 Then
        Return;
    EndIf;
    
    ParameterArray = New Array;
    MethodDescription = "";
    
    FormMethodStructure(CommentArray, ParameterArray, MethodDescription);
    FormParamsDescriptionTable(ParameterArray, Method, CompositionTable, Module, MethodDescription, Region);
    
EndProcedure

Function CommentParsing(Val TextDocument, Val LineNumber)
    
    CurrentRow = TextDocument.GetLine(LineNumber - 1);
    CommentText = CurrentRow;
    
    Counter	= 1;
    While StrFind(CurrentRow, "//") > 0 Do
        
        Counter = Counter + 1;
        
        CurrentRow = TextDocument.GetLine(LineNumber - Counter);
        CommentText = CurrentRow + Chars.LF + CommentText;
        
    EndDo;
    
    If StrFind(CommentText, "!NOCLI") > 0 Then
        Return New Array;
    EndIf;
    
    CommentArray = StrSplit(CommentText, "//", False);
    
    If CommentArray.Count() = 0 Then
        Message(CommentText);
        Return New Array;
    Else
        CommentArray.Delete(0);
    EndIf;
    
    Return CommentArray;
    
EndFunction

Procedure FormMethodStructure(Val CommentArray, ParameterArray, MethodDescription)
    
    RecordParameters = False;
    RecordDescription = True;
    
    Counter = 0;
    For Each CommentLine In CommentArray Do
        
        Counter = Counter + 1;
        
        If Not ValueIsFilled(TrimAll(CommentLine)) Then
            RecordDescription = False;
        EndIf;
        
        If RecordDescription = True And Counter > 1 Then
            MethodDescription = MethodDescription + CommentLine;
        EndIf;
        
        If StrFind(CommentLine, "Parameters:") > 0 Or StrFind(CommentLine, "Parameters:") > 0 Then
            RecordParameters = True;
            RecordDescription = False;
            
        ElsIf StrFind(CommentLine, "Returns:") > 0 Or StrFind(CommentLine, "Returns:") > 0 Then
            Break;
            
        ElsIf RecordParameters = True 
            And ValueIsFilled(TrimAll(CommentLine)) 
            And Not StrStartsWith(TrimAll(CommentLine), "*") Then
            
            ParameterArray.Add(CommentLine);
            
        Else
            Continue;
        EndIf;
        
    EndDo;
    
EndProcedure

Procedure FormParamsDescriptionTable(Val ParameterArray, Val Method, CompositionTable, Module, MethodDescription, Region)
    
    Delimiter = "-";
    ArrayOfCurrentItems = New Array;
    
    For Each MethodParameter In ParameterArray Do
        
        ParamItemsArray = StrSplit(MethodParameter, Delimiter, False);
        ItemsCount = ParamItemsArray.Count();
        
        For N = 0 To ParamItemsArray.UBound() Do
            ParamItemsArray[N] = TrimAll(ParamItemsArray[N]);
        EndDo;
        
        If ItemsCount < 4 Then
            
            For Each Current In ArrayOfCurrentItems Do
                CompositionTable.Delete(Current);
            EndDo;

            Return;
        EndIf;
         
        Name1C = ParamItemsArray[0];
        Name = "--" + ParamItemsArray[3];
        Types = ParamItemsArray[1];
        Description = ?(ItemsCount >= 5, ParamItemsArray[4], ParamItemsArray[2]);
        
        If ItemsCount > 5 Or StrFind(Name, " ") > 0 Then
            For Each Current In ArrayOfCurrentItems Do
                CompositionTable.Delete(Current);
            EndDo;
            Return;
        EndIf;

        Value = GetParametersDefaultValue(Name1C, Method);
        Library = Module.BaseName;
        
        If ValueIsFilled(Value) Then
            Description = Description + " (optional, def. val. - " + Value + ")";
        EndIf;
        
        NewLine = CompositionTable.Add();
        NewLine.Library = Library;
        NewLine.Module = Library;
        NewLine.Method = Method.Signature.Name;
        NewLine.SearchMethod = Upper(NewLine.Method);
        NewLine.Description = Description;
        NewLine.Region = Region;
        NewLine.Parameter = Name;

        If ValueIsFilled(MethodDescription) Then
            NewLine.MethodDescription = MethodDescription;
        EndIf;       

        ArrayOfCurrentItems.Add(NewLine);

    EndDo;
    
EndProcedure

Function GetParametersDefaultValue(Val Name, Val Method)
    
    Value = "";
    
    For Each MethodParameter In Method.Signature.Parameters Do
        
        If MethodParameter.Name = Name Then
            
            ParameterValue = MethodParameter.Value;
            If ValueIsFilled(ParameterValue) Then
                Try
                    Value = ParameterValue["Items"][0]["Value"];
                Except 
                    Value = ParameterValue.Value;
                EndTry;
                Value = ?(ValueIsFilled(Value), Value, "Empty value");
            EndIf;
            
        EndIf;
        
    EndDo;
    
    Return Value;
    
EndFunction

Function GetExtensionDirectories()

    ExtensionsDirectories = New Array;
    ExtensionsDirectories.Add(ExtensionsCatalog);
    
    ExtensionsAdditionalDirectory = SettingsVault.ReturnSetting("ext_path");

    If ValueIsFilled(ExtensionsAdditionalDirectory) Then
        ExtensionsDirectories.Add(ExtensionsAdditionalDirectory);
    EndIf;

    Return ExtensionsDirectories;

EndFunction

Function Synonymizer(PropName)
    
    Var Synonym, q, Symbol, BeforeSymbol, NextSymbol, Capitalized, CapitalizedBefore, CapitalizedNext, StringLength;
    
    Synonym = Upper(Mid(PropName, 1, 1));
    StringLength = StrLen(PropName);
    For q=2 To StringLength Do
        Symbol = Mid(PropName, q, 1);
        BeforeSymbol = Mid(PropName, q-1, 1);
        NextSymbol = Mid(PropName, q+1, 1);
        Capitalized = Symbol = Upper(Symbol);
        CapitalizedBefore = BeforeSymbol = Upper(BeforeSymbol);
        CapitalizedNext = NextSymbol = Upper(NextSymbol);
        
        // Variants
        If NOT CapitalizedBefore And Capitalized Then
            Synonym = Synonym + " " + Symbol;
        ElsIf Capitalized And NOT CapitalizedNext Then
            Synonym = Synonym + " " + Symbol;
        Else
            Synonym = Synonym + Symbol;
        EndIf;
    EndDo;
    
    Synonym = Upper(Left(Synonym,1)) + Lower(Mid(Synonym,2));
    
    Return Synonym;
    
EndFunction

Procedure AddExtensionToCache(Val Name, Val Path, Val Count)

    CacheStructure = New Structure("filepath,count", Path, Count);
    ExtensionsCache.Insert(Name, CacheStructure);

EndProcedure

Procedure HandleConnectionException(ExtensionFile, TroubleDescription, Test)

    If Not Test Then
        AddExtensionToCache(ExtensionFile.BaseName, ExtensionFile.FullName, TroubleDescription);
    EndIf;

    Message(TroubleDescription); 

EndProcedure

#EndRegion

#Region Alternate

Procedure Инициализировать(ОбъектОПИ_, ХранилищеНастроек_, КаталогРасширений_, ПроцессорДействий_) Export
	Initialize(ОбъектОПИ_, ХранилищеНастроек_, КаталогРасширений_, ПроцессорДействий_);
EndProcedure

Procedure ДополнитьСоставРасширениями() Export
	CompleteCompositionWithExtensions();
EndProcedure

Function ПодключитьФайлРасширения(ФайлРасширения, Тест = False) Export
	Return ConnectExtensionFile(ФайлРасширения, Тест);
EndFunction

Function ПолучитьСписокРасширений() Export
	Return GetExtensionsList();
EndFunction

Function ОбновитьСписокРасширений() Export
	Return UpdateExtensionsList();
EndFunction

Function ПолучитьТекстРасширения(ИмяМодуля) Export
	Return GetExtensionText(ИмяМодуля);
EndFunction

Function СохранитьТекстРасширения(ИмяМодуля, ТекстМодуля) Export
	Return SaveExtensionsText(ИмяМодуля, ТекстМодуля);
EndFunction

Function ПолучитьСписокКаталоговРасширений() Export
	Return GetExtensionDirectoryList();
EndFunction

Function СоздатьФайлРасширения(ИмяМодуля, КаталогСоздания) Export
	Return CreateExtensionFile(ИмяМодуля, КаталогСоздания);
EndFunction

Function УдалитьФайлРасширения(ИмяМодуля) Export
	Return DeleteExtensionFile(ИмяМодуля);
EndFunction

#EndRegion