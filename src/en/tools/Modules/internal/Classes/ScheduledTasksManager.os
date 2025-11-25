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

Var ProxyModule;
Var TaskScheduler;
Var SQLiteConnectionManager;
Var ActionsProcessor;
Var BackgroundTasksManager;

#EndRegion

#Region Internal

Procedure Initialize(InitializationStructure) Export
	
	BackgroundTasksManager = New("BackgroundTasksManager");
	
	ProxyModule = InitializationStructure["ProxyModule"];
	TaskScheduler = InitializationStructure["TaskScheduler"];
	SQLiteConnectionManager = InitializationStructure["SQLiteConnectionManager"];
	ActionsProcessor = InitializationStructure["ActionsProcessor"];
	
	ConnectionRO = SQLiteConnectionManager.GetROConnection();
	ExistingTasks = ProxyModule.GetScheduledTaskList(ConnectionRO);
	
	If Not ExistingTasks["result"] Then
		Raise ExistingTasks["error"];
	EndIf;
	
	TaskScheduler.Initialize();
	
	For Each Task In ExistingTasks["data"] Do
		
		TaskName = String(Task["id"]);
		Schedule = Task["cron"];
		Handler = Task["handler"];
		
		Adding = TaskScheduler.AddTask(TaskName, Schedule);
		
		If Not Adding["result"] Then
			Message(StrTemplate("Error adding task %1: %2", TaskName, Adding["error"]));
		EndIf;
		
		If String(Task["active"]) = "0" Then
			TaskScheduler.DisableTask(TaskName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure Start() Export
	
	Message("Starting event tracking!");
	
	While True Do
		
		Task = TaskScheduler.WaitEvent();
		
		If ValueIsFilled(Task) Then
			
			ParameterArray = New Array;
			ParameterArray.Add(Task);
			
			BackgroundTasksManager.Execute(ЭтотОбъект, "PerformHandling", ParameterArray);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PerformHandling(Task) Export
	
	Try
		ConnectionRO = SQLiteConnectionManager.GetROConnection();
		
		TaskDescription = ProxyModule.GetScheduledTask(ConnectionRO, Task);
		
		If TaskDescription["result"] Then

			TaskData = TaskDescription["data"];
			
			If String(TaskData["active"]) = "0" Then
				TaskScheduler.DisableTask(TaskData["id"]);
				Return;
			EndIf;

			Name = TaskData["handler"];

		Else
			Raise Name["error"];
		EndIf;
		
		CurrentHandler = ProxyModule.GetRequestsHandler(ConnectionRO, Name);
		CurrentHandler = CurrentHandler["data"];
		CurrentHandler = ?(TypeOf(CurrentHandler) = Type("Array"), CurrentHandler[0], CurrentHandler);
		
		ActionsProcessor.PerformUniversalProcessing(Undefined, CurrentHandler, New Structure, Undefined, Name);
		
	Except
		Message(StrTemplate("Error executing scheduler task %1: %2", Task, DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

#EndRegion

#Region Alternate

Procedure Initialize(InitializationStructure) Export
	Initialize(InitializationStructure);
EndProcedure

Procedure Start() Export
	Start();
EndProcedure

Procedure PerformHandling(Task) Export
	PerformHandling(Task);
EndProcedure

#EndRegion


#Region Alternate

Procedure Инициализировать(СтруктураИнициализации) Export
	Initialize(СтруктураИнициализации);
EndProcedure

Procedure Запустить() Export
	Start();
EndProcedure

Procedure ВыполнитьОбработку(Задание) Export
	PerformHandling(Задание);
EndProcedure

#EndRegion