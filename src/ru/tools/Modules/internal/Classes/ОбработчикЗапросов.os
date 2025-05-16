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

#Область ОписаниеПеременных

Перем ПроцессорДействий;
Перем ПроцессорAPI;
Перем ПроцессорUI;

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ПутьПроекта_, МодульПрокси_, ОбъектОПИ_, ПутьСервера_) Экспорт

    ОбработчикСеансов = Новый ("ОбработчикСеансов");
    ОбработчикСеансов.Инициализировать(ПутьПроекта_, МодульПрокси_);

    ПроцессорДействий = Новый("ПроцессорДействий");
    ПроцессорДействий.Инициализировать(ОбъектОПИ_, МодульПрокси_, ПутьПроекта_);

    ПроцессорAPI  = Новый("ПроцессорAPI");
    ПроцессорAPI.Инициализировать(МодульПрокси_, ПутьПроекта_, ОбработчикСеансов, ОбъектОПИ_);

    ПроцессорUI   = Новый("ПроцессорUI");
    ПроцессорUI.Инициализировать(ПутьСервера_, ОбработчикСеансов);

КонецПроцедуры

Процедура ОсновнаяОбработка(Контекст, СледующийОбработчик) Экспорт

    Попытка
        Результат = ОбработатьЗапрос(Контекст);
        ВыполнитьСборкуМусора();
    Исключение

        ВыполнитьСборкуМусора();

        Информация = ИнформацияОбОшибке();
        Результат  = Новый Структура("result,error", Ложь, Информация.Описание);

        Если СтрНайти(Информация.ИсходнаяСтрока, "ВызватьИсключение") = 0 Тогда

            ФайлМодуля = Новый Файл(Информация.ИмяМодуля);

            СтруктураИсключения = Новый Структура;
            СтруктураИсключения.Вставить("module", ФайлМодуля.Имя);
            СтруктураИсключения.Вставить("row"   , Информация.НомерСтроки);
            СтруктураИсключения.Вставить("code"  , СокрЛП(Информация.ИсходнаяСтрока));

            Результат.Вставить("exception", СтруктураИсключения);

        КонецЕсли;

        Контекст.Ответ.КодСостояния = 500;

    КонецПопытки;

    Если Результат <> Неопределено Тогда

        JSON = OPI_Инструменты.JSONСтрокой(Результат);

        Контекст.Ответ.ТипКонтента = "application/json;charset=UTF8";
        Контекст.Ответ.Записать(JSON);

    КонецЕсли;

КонецПроцедуры

Функция ОбработатьЗапрос(Контекст)

    Путь = Контекст.Запрос.Путь;

    Путь = ?(СтрНачинаетсяС(Путь    , "/")    , Прав(Путь, СтрДлина(Путь) - 1) , Путь);
    Путь = ?(СтрЗаканчиваетсяНа(Путь, "/")    , Лев(Путь , СтрДлина(Путь) - 1) , Путь);

    Если СтрНачинаетсяС(Путь, "api") Тогда
        Результат = ПроцессорAPI.ОсновнаяОбработка(Контекст, Путь);
    ИначеЕсли СтрНачинаетсяС(Путь, "ui") Тогда
        Результат = ПроцессорUI.ОсновнаяОбработка(Контекст, Путь);
    Иначе
        Результат = ПроцессорДействий.ОсновнаяОбработка(Контекст, Путь);
    КонецЕсли;

    Возврат Результат;

КонецФункции

#КонецОбласти
