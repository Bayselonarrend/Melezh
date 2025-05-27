Procedure CompleteCompositionWithExtensions(OPIObject, ExtensionsCatalog) Export

    ExtensionFiles = FindFiles(ExtensionsCatalog, "*.os");

    For Each FileExtension In ExtensionFiles Do

        Try
            ParametersTable = ParseModule(FileExtension);
            OPIObject.CompleteCompositionCache(FileExtension.BaseName, ParametersTable);
        Except
            Message(StrTemplate("Error applying the extension %1", DetailErrorDescription(ErrorInfo())));
        EndTry;

    EndDo;

EndProcedure

Function ParseModule(Module)
    
    CompositionTable = New ValueTable();
    CompositionTable.Columns.Add("Library");
    CompositionTable.Columns.Add("Module");
    CompositionTable.Columns.Add("Method");
    CompositionTable.Columns.Add("SearchMethod");
    CompositionTable.Columns.Add("Parameter");
    CompositionTable.Columns.Add("Description");
    CompositionTable.Columns.Add("MethodDescription");
    CompositionTable.Columns.Add("Region");
    
    Parser = New("EmbeddedLanguageParser");
    ModuleDocument = New TextDocument;
    ModuleDocument.Read(Module.FullName, "UTF-8");

    ModuleText = ModuleDocument.GetText();
    ModuleStructure = Parser.Parse(ModuleText);
    CurrentRegion = "Common methods";

    For Each Method In ModuleStructure.Declarations Do
  
        If Method.Type = "InstructionPreprocessorRegion" Then
            CurrentRegion = Synonymizer(Method.Name);
        EndIf;
        
        If Method.Type = "MethodDeclaration" And Method.Signature.Export = True Then
            ParseMethodComment(ModuleDocument, Method, Module, CurrentRegion, CompositionTable);	       
        EndIf;
        
    EndDo;

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
