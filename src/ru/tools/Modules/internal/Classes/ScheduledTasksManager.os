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

#Использовать oint
#Использовать "./internal"
#Использовать "./internal/Classes/internal"

#Область ОписаниеПеременных

Перем МодульПрокси;
Перем ПланировщикЗаданий;
Перем МенеджерСоединенийSQLite;
Перем ПроцессорДействий;
Перем МенеджерФоновыхЗаданий;

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(СтруктураИнициализации) Экспорт
	
	МенеджерФоновыхЗаданий          = Новый("МенеджерФоновыхЗаданий");
	
	МодульПрокси             = СтруктураИнициализации["МодульПрокси"];
	ПланировщикЗаданий       = СтруктураИнициализации["ПланировщикЗаданий"];
	МенеджерСоединенийSQLite = СтруктураИнициализации["МенеджерСоединенийSQLite"];
	ПроцессорДействий        = СтруктураИнициализации["ПроцессорДействий"];
	
	СоединениеRO        = МенеджерСоединенийSQLite.ПолучитьСоединениеRO();
	СуществующиеЗадания = МодульПрокси.ПолучитьСписокРегламентныхЗаданий(СоединениеRO);
	
	Если Не СуществующиеЗадания["result"] Тогда
		ВызватьИсключение СуществующиеЗадания["error"];
	КонецЕсли;
	
	ПланировщикЗаданий.Инициализировать();
	
	Для Каждого Задание Из СуществующиеЗадания["data"] Цикл
		
		ИмяЗадания = Строка(Задание["id"]);
		Расписание = Задание["cron"];
		Обработчик = Задание["handler"];
		
		Добавление = ПланировщикЗаданий.ДобавитьЗадание(ИмяЗадания, Расписание);
		
		Если Не Добавление["result"] Тогда
			Сообщить(СтрШаблон("Ошибка добавления задания %1: %2", ИмяЗадания, Добавление["error"]));
		КонецЕсли;
		
		Если Строка(Задание["active"]) = "0" Тогда
			ПланировщикЗаданий.ОтключитьЗадание(ИмяЗадания);
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура Запустить() Экспорт
	
	Сообщить("Запуск отслеживания событий!");
	
	Пока Истина Цикл
		
		Задание = ПланировщикЗаданий.ОжидатьСобытие();
		
		Если ЗначениеЗаполнено(Задание) Тогда
			
			МассивПараметров = Новый Массив;
			МассивПараметров.Добавить(Задание);
			
			МенеджерФоновыхЗаданий.Выполнить(ЭтотОбъект, "ВыполнитьОбработку", МассивПараметров);
			
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ВыполнитьОбработку(Задание) Экспорт
	
	Попытка
		СоединениеRO = МенеджерСоединенийSQLite.ПолучитьСоединениеRO();
		
		ОписаниеЗадания  = МодульПрокси.ПолучитьРегламентноеЗадание(СоединениеRO, Задание);
		
		Если ОписаниеЗадания["result"] Тогда

			ДанныеЗадания = ОписаниеЗадания["data"];
			
			Если Строка(ДанныеЗадания["active"]) = "0" Тогда
				ПланировщикЗаданий.ОтключитьЗадание(ДанныеЗадания["id"]);
				Возврат;
			КонецЕсли;

			Имя = ДанныеЗадания["handler"];

		Иначе
			ВызватьИсключение Имя["error"];
		КонецЕсли;
		
		ТекущийОбработчик = МодульПрокси.ПолучитьОбработчикЗапросов(СоединениеRO, Имя);
		ТекущийОбработчик = ТекущийОбработчик["data"];
		ТекущийОбработчик = ?(ТипЗнч(ТекущийОбработчик) = Тип("Массив"), ТекущийОбработчик[0], ТекущийОбработчик);
		
		ПроцессорДействий.ВыполнитьУниверсальнуюОбработку(Неопределено, ТекущийОбработчик, Новый Структура, Неопределено, Имя);
		
	Исключение
		Сообщить(СтрШаблон("Ошибка при выполнении задания планировщика %1: %2", Задание, ПодробноеПредставлениеОшибки(ИнформацияОбОшибке())));
	КонецПопытки;
	
КонецПроцедуры

#КонецОбласти

#Region Alternate

Procedure Initialize(InitializationStructure) Export
	Инициализировать(InitializationStructure);
EndProcedure

Procedure Start() Export
	Запустить();
EndProcedure

Procedure PerformHandling(Task) Export
	ВыполнитьОбработку(Task);
EndProcedure

#EndRegion