#Use "../../tools"
#Use oint-cli

#Region Internal

Procedure DisplayStartPage(Val Version) Export
	

	Консоль.TextColor = ConsoleColor.Green;
	Консоль.WriteLine("");

	Консоль.TextColor = ConsoleColor.Cyan;
	ColorOutput.Write("
		| ______  _____________________________________  __
		| ___   |/  /__  ____/__  /___  ____/__  /__  / / /
		| __  /|_/ /__  __/  __  / __  __/  __  /__  /_/ / 
		| _  /  / / _  /___  _  /___  /___  _  /__  __  /  
		| /_/  /_/  /_____/  /_____/_____/  /____/_/ /_/   
		|");
		
	Консоль.TextColor = ConsoleColor.Yellow;

	ColorOutput.Write("
		|                          
		| Welcome to (Melezh|#color=White) v (" + Version + "|#color=Cyan)!
		|
		| The structure of calls:
	    | 
		| "
		+ "(melezh|#color=White) "
		+ "(<method>|#color=Cyan) " 
		+ "(--option1|#color=Gray) "
		+ "(""|#color=Green)"
		+ "(Value|#color=White)"
		+ "(""|#color=Green) "
		+ "(...|#color=White) "
		+ "(--optionN|#color=Gray) "
		+ "(""|#color=Green)"
		+ "(Value|#color=White)"
		+ "(""|#color=Green) ");

	ColorOutput.WriteLine("
		|
		| Call method without parameters returns help
		| (meleth|#color=White) (--help|#color=Gray) - get a list of available methods"); 
		

	Консоль.TextColor = ConsoleColor.White;
	ColorOutput.WriteLine("
		|
		| (Standard options:|#color=Yellow)
		|
		|  (--help|#color=Cyan)  - outputs the method help or a list of all methods. Similar to calling a method without parameters
		|  (--debug|#color=Cyan) - a flag responsible for providing more detailed information during program operation
		|  (--out|#color=Cyan)   - the path to the result saving file (particularly binary data
		|");
	
	Консоль.TextColor = ConsoleColor.Yellow;
	ColorOutput.WriteLine(" Full documentation can be found at: (https://openintegrations.dev|#color=Green)" + Chars.LF);

	Консоль.WriteLine("");
	Консоль.TextColor = ConsoleColor.White;

	Exit(0);
	
EndProcedure

Procedure DisplayMethodHelp(Val ParametersTable) Export

	Консоль.TextColor = ConsoleColor.White;

	ParametersTable.GroupBy("Method,Region");

	ColorOutput.WriteLine(" (##|#color=Green) Available methods: " + Chars.LF);
	Консоль.TextColor = ConsoleColor.White;

	CurrentRegion       = "";
	Counter              = 0;
	NumberOfParameters = ParametersTable.Count();


	For each MethodLine In ParametersTable Do

		First    = False;
		Last = False;

		If CurrentRegion <> MethodLine.Region Then
			CurrentRegion = MethodLine.Region;
			ColorOutput.WriteLine("    (o|#color=Yellow) (" + CurrentRegion + "|#color=Cyan)");
			First = True;
		EndIf;

		If Counter >= NumberOfParameters - 1 Then
			Last = True;
		Else
			Last = ParametersTable[Counter + 1].Region <> CurrentRegion;
		EndIf;

		If First And Last Then
			Label = "└───";
		ElsIf First Then
			Label = "└─┬─";
		ElsIf Last Then
			Label = "  └─";
		Else
			Label = "  ├─";
		EndIf;
		
		ColorOutput.WriteLine("    (" + Label + "|#color=Yellow) " + MethodLine.Method);

		Counter = Counter + 1;
	EndDo;

	Message(Chars.LF);
	Консоль.TextColor = ConsoleColor.White;

	Exit(0);

EndProcedure

Procedure DisplayParameterHelp(Val ParametersTable) Export 

	If ParametersTable.Count() = 0 Then
		DisplayExceptionMessage("Method");
	EndIf;

	MethodName    = ParametersTable[0].Method;
	HelpText = "
	| (##|#color=Green) Method (" + MethodName + "|#color=Cyan)
	| (##|#color=Green) "       + ParametersTable[0].MethodDescription; 
	
	ColorOutput.WriteLine(HelpText);
	HelpText = "";

	HandleHelpTabulation(ParametersTable);

	For Each MethodParameter In ParametersTable Do

		HelpText = HelpText 
			+ Chars.LF
			+ "    ("
			+ MethodParameter["Parameter"]
			+ "|#color=Yellow) - "
			+ MethodParameter["Description"];

	EndDo;

	ColorOutput.WriteLine(HelpText + Chars.LF);

	Exit(0);
	
EndProcedure

Procedure DisplayExceptionMessage(Val Reason, Val OutputFile = "") Export

	OutputFile = String(OutputFile);

	If Reason = "Command" Then
		Text = "Incorrect command! Check input correctness";
		Code   = 1;

	ElsIf Reason = "Method" Then
		Text = "Incorrect method! Check input correctness";
		Code   = 2;
		
	Else
		Text = "Unexpected Error! " + Reason;
		Code   = 99;
	EndIf;

	Text = Chars.LF + Text + Chars.LF;
	
	Message(Text, MessageStatus.VeryImportant);

	If ValueIsFilled(OutputFile) Then

		TextBD = ПолучитьДвоичныеДанныеИзСтроки(Text);

		Try
			TextBD.Write(OutputFile);
			Message("The error message has been saved to a file: " + OutputFile, MessageStatus.Attention);
		Except
			Message("Failed to save the error to the output file: " + ErrorDescription(), MessageStatus.Attention);
		EndTry;

	EndIf;

	Exit(Code);

EndProcedure

#EndRegion

#Region Private

Procedure HandleHelpTabulation(ParametersTable)

	Parameter_			= "Parameter";
	MaximumLength 	= 15;

	For Each MethodParameter In ParametersTable Do
			
		While Not StrLen(MethodParameter[Parameter_]) = MaximumLength Do
			MethodParameter[Parameter_] = MethodParameter[Parameter_] + " ";
		EndDo;

		CurrentDescription    = MethodParameter["Description"];
		DescriptionArray     = StrSplit(CurrentDescription, Chars.LF);
		InitialTab = 4;

		If DescriptionArray.Count() = 1 Then
			Continue;
		Else

			For N = 1 To DescriptionArray.UBound() Do

				CurrentElement = DescriptionArray[N];
				RequiredLength = StrLen(CurrentElement) + StrLen(MethodParameter[Parameter_] + " - ") + InitialTab;

				While StrLen(DescriptionArray[N]) < RequiredLength Do
					DescriptionArray[N] = " " + DescriptionArray[N];
				EndDo;

			EndDo;

			MethodParameter["Description"] = StrConcat(DescriptionArray, Chars.LF);	
			
		EndIf;

	EndDo;

EndProcedure

#EndRegion
