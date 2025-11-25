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

Перем ОбъектКомпоненты;

#Область ПрограммныйИнтерфейс

Процедура Инициализировать(Знач СтруктураРасписания = "") Экспорт

	Если ЗначениеЗаполнено(СтруктураРасписания) Тогда

		Если Не ТипЗнч(СтруктураРасписания) = Тип("Структура")
			И Не ТипЗнч(СтруктураРасписания) = Тип("Соответствие") Тогда

			ВызватьИсключение "Расписание должно быть валидной коллекцией ключ и значение!";
		КонецЕсли;

		РасписаниеСтрокой = РасписаниеВСтроку(СтруктураРасписания);

	Иначе
		РасписаниеСтрокой = "";
	КонецЕсли;

	ТекущийПуть = СтрЗаменить(ТекущийСценарий().Каталог, "\", "/");
	ТекущийПуть = СтрРазделить(ТекущийПуть, "/");

	ТекущийПуть.Удалить(ТекущийПуть.ВГраница());
	ТекущийПуть.Удалить(ТекущийПуть.ВГраница());

	ТекущийПуть.Добавить("addins");
	ТекущийПуть.Добавить("Cronos.zip");

	ПодключитьВнешнююКомпоненту(СтрСоединить(ТекущийПуть, "/"), "Cronos", ТипВнешнейКомпоненты.Native);

	ОбъектКомпоненты = Новый("AddIn.Cronos.Main");
	Результат = ОбъектКомпоненты.Init(РасписаниеСтрокой);
	
	РезультатИнициализации = ПрочитатьJSONТекст(Результат);

	Если Не РезультатИнициализации["result"] Тогда
		ВызватьИсключение Результат;
	КонецЕсли
	
КонецПроцедуры

Функция ОжидатьСобытие() Экспорт

	Событие = ОбъектКомпоненты.NextEvent();

	Пока Событие = "" Цикл

		Приостановить(100);
		Событие = ОбъектКомпоненты.NextEvent();

	КонецЦикла;

	Возврат Событие;
	
КонецФункции

Функция ДобавитьЗадание(Знач Имя, Знач Расписание) Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.AddJob(Строка(Имя), Расписание));
КонецФункции

Функция УдалитьЗадание(Знач Имя) Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.RemoveJob(Строка(Имя)));
КонецФункции

Функция ИзменитьРасписаниеЗадания(Знач Имя, Знач Расписание) Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.UpdateJob(Строка(Имя), Расписание));
КонецФункции

Функция ВключитьЗадание(Знач Имя) Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.EnableJob(Строка(Имя)));
КонецФункции

Функция ОтключитьЗадание(Знач Имя) Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.DisableJob(Строка(Имя)));
КонецФункции

Функция ПолучитьСписокЗаданий() Экспорт
	Возврат ПрочитатьJSONТекст(ОбъектКомпоненты.GetJobList());
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ПрочитатьJSONТекст(Знач Текст)

	ЧтениеJSON = Новый ЧтениеJSON();
	ЧтениеJSON.УстановитьСтроку(Текст);

	Результат = ПрочитатьJSON(ЧтениеJSON);

	ЧтениеJSON.Закрыть();

	Возврат Результат;

КонецФункции

Функция РасписаниеВСтроку(Знач Расписание)

	Попытка

		ЗаписьJSON = Новый ЗаписьJSON();
		ЗаписьJSON.УстановитьСтроку();
		ЗаписатьJSON(ЗаписьJSON, Расписание);
		Возврат ЗаписьJSON.Закрыть();

	Исключение
		ВызватьИсключение "Ошибка преобразования расписания в JSON строку!";
	КонецПопытки;

КонецФункции

#КонецОбласти

#Region Alternate



#EndRegion