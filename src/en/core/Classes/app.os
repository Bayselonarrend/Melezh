#Use oint
#Use oint-cli
#Use "../../tools"
#Use "../../help"
#Use "../../data"

Var Version; // Version program
Var Debugging; // Flag output debug information

Var Parser; // Object parser incoming data 

Var OutputFile; // Path redirection output in file
Var MethodsTable; // Table parameters current libraries
Var Module;
Var CurrentMethod;

#Region Private

#Region Main

Procedure MainHandler()
	
	Debugging = True;
	Testing = False;

	Parser = New("CommandLineArgumentParser");
	Version = AddonContent.GetVersion();
	MethodsTable = AddonContent.GetComposition();
	Module = "IntegrationProxy";
	
	DefineCurrentMethod();
	FormInput();

	Result = Parser.Parse(CommandLineArguments);
	ExecuteCommandProcessing(Result);

EndProcedure

Procedure DefineCurrentMethod()

	If CommandLineArguments.Count() > 0 Then
		CurrentMethod = CommandLineArguments[0];
	Else
		CurrentMethod = Undefined;
	EndIf;
	
EndProcedure

Procedure FormInput()

	Parser.AddParameter("Method");
	AddMethodsParameters();
	
	Parser.AddFlagParam("--help");
	Parser.AddFlagParam("--debug");

	Parser.AddNamedParam("--out");

EndProcedure

Procedure AddMethodsParameters();
	
	ParamsList = MethodsTable.FindRows(New Structure("SearchMethod", Upper(CurrentMethod)));

	For Each Parameter In ParamsList Do
		Parser.AddNamedParam(Parameter.Parameter);
	EndDo;
	
EndProcedure


Procedure ExecuteCommandProcessing(Val Parameters)
	
	Output = "";

	SetDebugMode(Parameters);
	SetOutputFile(Parameters);
	DisplayAdditionalInformation(Parameters);

	Try
			
		Output = GetProcessingResult(Parameters);

		ProcessJSONOutput(Output);
		ReportResult(Output, MessageStatus.Attention);

	Except
		HandleErrorOutput(Output, ErrorInfo());
	EndTry;
	
EndProcedure

Function GetProcessingResult(Val Parameters)

	Method = Parameters["Method"];
	IsHelp = Parameters["--help"];
	Response = "Function Returned Empty Value";

	NumberOfStandardParameters = 3;

	If Not ValueIsFilled(Method) Then

		If IsHelp Then
			Help.DisplayMethodHelp(MethodsTable);
		Else
			Help.DisplayStartPage(Version);
		EndIf;

	Else

		CommandSelection = New Structure("SearchMethod", Upper(Method));
		MethodParameters = MethodsTable.FindRows(CommandSelection);
	
		If Not ValueIsFilled(MethodParameters) Then
			Help.DisplayExceptionMessage("Method", OutputFile);
		EndIf;
	
		If Parameters.Count() = NumberOfStandardParameters Or Parameters["--help"] Then
			Help.DisplayParameterHelp(MethodParameters);
		EndIf;
	
		ExecutionText = FormMethodCallString(Parameters, MethodParameters, Module, Method);
	
		If Debugging Then
			Message(ExecutionText, MessageStatus.Attention);
		EndIf;

		Execute(ExecutionText);

		Return Response;

	EndIf;
	
EndFunction

#EndRegion

#Region Auxiliary

Procedure ProcessJSONOutput(Output)
	
	If EmptyOutput(Output) Then
		Output = New Structure;
	EndIf;

	If TypeOf(Output) = Type("Structure")
		Or TypeOf(Output) = Type("Map")
		Or TypeOf(Output) = Type("Array") Then
	
		Output = OPI_Tools.JSONString(Output, , , False);

	EndIf;

EndProcedure

Function FormMethodCallString(Val PassedParameters, Val MethodParameters, Val Module, Val Method)

	ExecutionText = "";
	CallString = Module + "." + Method + "(";
	Counter = 0;

	For Each RequiredParameter In MethodParameters Do

		ParameterName = RequiredParameter.Parameter;
		ParameterValue = PassedParameters.Get(ParameterName);

		If ValueIsFilled(ParameterValue) Then

			ParameterName = "Parameter" + StrReplace(ParameterName, "--", "_");

			ExecutionText = ExecutionText 
				+ Chars.LF 
				+ ParameterName
				+ " = """ 
				+ StrReplace(ParameterValue, """", """""")
				+ """;";

			If RequiresProcessingOfEscapeSequences(ParameterName, ParameterValue) Then

				ExecutionText = ExecutionText + "
				|OPI_Tools.ReplaceEscapeSequences(" + ParameterName + ");
				|";

			EndIf;

			CallString = CallString + ParameterName + ", ";
			Counter = Counter + 1;

		Else
			CallString = CallString + " , ";
		EndIf;

	EndDo;

	ExtraCharacters = 2;
	CallString = Left(CallString, StrLen(CallString) - ExtraCharacters);
	CallString = CallString + ");";
	CallString = "Response = " + CallString;
	ExecutionText = ExecutionText + Chars.LF + CallString;

	Return ExecutionText;

EndFunction

Procedure SetDebugMode(Val Parameters)

	If Parameters["--debug"] Then
		Debugging = True;
	Else
		Debugging = False;
	EndIf;

EndProcedure

Procedure SetOutputFile(Val Parameters)

	Output = Parameters["--out"];

	If ValueIsFilled(Output) Then
		OutputFile = Output;
	EndIf;

EndProcedure

Procedure DisplayAdditionalInformation(Parameters)

	If Debugging Then

		For each IntroductoryParameter In Parameters Do
			Message(IntroductoryParameter.Key + " : " + IntroductoryParameter.Value);	
		EndDo;

    EndIf;
	
EndProcedure

Procedure HandleErrorOutput(Output, ErrorInfo)

	Information = "";
	If ValueIsFilled(Output) Then

		If Debugging Then
			Information = DetailErrorDescription(ErrorInfo);
		EndIf;

		ReportResult(Output);
	Else

		If Debugging Then
			Information = DetailErrorDescription(ErrorInfo);
		Else
			Information = BriefErrorDescription(ErrorInfo);
		EndIf;
	
	EndIf;
	
	Help.DisplayExceptionMessage(Information, OutputFile);
	
EndProcedure

Procedure ReportResult(Val Text, Val Status = "")

	If Not ValueIsFilled(Status) Then
		Status = MessageStatus.NoStatus;
	EndIf;

	If ValueIsFilled(OutputFile) Then
		Text = WriteValueToFile(Text, OutputFile);
	ElsIf TypeOf(Text) = Type("BinaryData") Then
		Text = "It Seems Binary Data Was Received in Response! "
		    + "Next time, use the --out option to specify the path for saving";
		Status = MessageStatus.Information;
	Else 
		Text = String(Text);
	EndIf;

    Message(Text, Status);
	
EndProcedure

Function WriteValueToFile(Val Value, Val Path)
	
	StandardUnit = 1024;
	DataUnit = StandardUnit * StandardUnit;
	Value = ?(TypeOf(Value) = Type("BinaryData"), Value, String(Value));

	If TypeOf(Value) = Type("String") Then 

		PossibleFile = New File(Value);

		If PossibleFile.Exist() Then
			Path = Value;
		Else
			Value = ПолучитьДвоичныеДанныеИзСтроки(Value);
	    EndIf;

	EndIf;

	If TypeOf(Value) = Type("BinaryData") Then
        Value.Write(Path);
	EndIf;

	RecordedFile = New File(Path);

	If RecordedFile.Exist() Then
		Return "File with size " 
		    + String(Round(RecordedFile.Size() / DataUnit, 3)) 
			+ " MB was recorded in " 
			+ RecordedFile.FullName;
	Else
		Raise "File was not saved! Use the --debug flag for more information";
	EndIf;

EndFunction

Function EmptyOutput(Output)

	If TypeOf(Output) = Type("BinaryData") Then
		Return Output.Size() = 0;
	Else
		Return Not ValueIsFilled(Output);
	EndIf;
	
EndFunction

Function RequiresProcessingOfEscapeSequences(Val ParameterName, Val ParameterValue)

	ParamFile = New File(ParameterValue);
	ParamValueTrim = TrimAll(ParameterValue);

	Return Not StrStartsWith(ParamValueTrim, "{")
				And Not StrStartsWith(ParamValueTrim, "[") 
				And Not ParamFile.Exist() 
				And Not ParameterName = "Parameter_out";

EndFunction

#EndRegion

#EndRegion

Try
	MainHandler();	
Except
	
	If Debugging Then
		Information = ErrorDescription();
	Else
		Information = BriefErrorDescription(ErrorInfo());
	EndIf;

	Help.DisplayExceptionMessage(Information, OutputFile);

EndTry;
