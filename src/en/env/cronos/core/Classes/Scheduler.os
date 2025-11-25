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

Var AddInObject;

#Region Public

Procedure Initialize(Val ScheduleStructure = "") Export

	If ValueIsFilled(ScheduleStructure) Then

		If Not TypeOf(ScheduleStructure) = Type("Structure")
			And Not TypeOf(ScheduleStructure) = Type("Map") Then

			Raise "Schedule must be a valid key-value collection!";
		EndIf;

		ScheduleAsString = ScheduleToString(ScheduleStructure);

	Else
		ScheduleAsString = "";
	EndIf;

	CurrentPath = StrReplace(CurrentScript().Path, "\", "/");
	CurrentPath = StrSplit(CurrentPath, "/");

	CurrentPath.Delete(CurrentPath.UBound());
	CurrentPath.Delete(CurrentPath.UBound());

	CurrentPath.Add("addins");
	CurrentPath.Add("Cronos.zip");

	AttachAddIn(StrConcat(CurrentPath, "/"), "Cronos", AddInType.Native);

	AddInObject = New("AddIn.Cronos.Main");
	Result = AddInObject.Init(ScheduleAsString);
	
	InitializationResult = ReadJSONText(Result);

	If Not InitializationResult["result"] Then
		Raise Result;
	EndIf
	
EndProcedure

Function WaitEvent() Export

	Event = AddInObject.NextEvent();

	While Event = "" Do

		Sleep(100);
		Event = AddInObject.NextEvent();

	EndDo;

	Return Event;
	
EndFunction

Function AddTask(Val Name, Val Schedule) Export
	Return ReadJSONText(AddInObject.AddJob(String(Name), Schedule));
EndFunction

Function DeleteTask(Val Name) Export
	Return ReadJSONText(AddInObject.RemoveJob(String(Name)));
EndFunction

Function UpdateTaskSchedule(Val Name, Val Schedule) Export
	Return ReadJSONText(AddInObject.UpdateJob(String(Name), Schedule));
EndFunction

Function EnableTask(Val Name) Export
	Return ReadJSONText(AddInObject.EnableJob(String(Name)));
EndFunction

Function DisableTask(Val Name) Export
	Return ReadJSONText(AddInObject.DisableJob(String(Name)));
EndFunction

Function GetTaskList() Export
	Return ReadJSONText(AddInObject.GetJobList());
EndFunction

#EndRegion

#Region Private

Function ReadJSONText(Val Text)

	JSONReader = New JSONReader();
	JSONReader.SetString(Text);

	Result = ReadJSON(JSONReader);

	JSONReader.Close();

	Return Result;

EndFunction

Function ScheduleToString(Val Schedule)

	Try

		JSONWriter = New JSONWriter();
		JSONWriter.SetString();
		WriteJSON(JSONWriter, Schedule);
		Return JSONWriter.Close();

	Except
		Raise "Error converting schedule to JSON string!";
	EndTry;

EndFunction

#EndRegion

#Region Alternate

Procedure Инициализировать(Val СтруктураРасписания = "") Export
	Initialize(СтруктураРасписания);
EndProcedure

Function ОжидатьСобытие() Export
	Return WaitEvent();
EndFunction

Function ДобавитьЗадание(Val Имя, Val Расписание) Export
	Return AddTask(Имя, Расписание);
EndFunction

Function УдалитьЗадание(Val Имя) Export
	Return DeleteTask(Имя);
EndFunction

Function ИзменитьРасписаниеЗадания(Val Имя, Val Расписание) Export
	Return UpdateTaskSchedule(Имя, Расписание);
EndFunction

Function ВключитьЗадание(Val Имя) Export
	Return EnableTask(Имя);
EndFunction

Function ОтключитьЗадание(Val Имя) Export
	Return DisableTask(Имя);
EndFunction

Function ПолучитьСписокЗаданий() Export
	Return GetTaskList();
EndFunction

#EndRegion