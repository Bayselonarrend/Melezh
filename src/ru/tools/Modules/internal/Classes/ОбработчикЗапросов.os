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

Перем ПроцессорДействий;
Перем ПроцессорAPI;
Перем ПроцессорUI;
Перем Логгер;
Перем ХранилищеНастроек;
Перем ОбработчикСеансов;

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ПутьПроекта_, МодульПрокси_, ОбъектОПИ_, ПутьСервера_) Экспорт

    ХранилищеНастроек = Новый("ХранилищеНастроек");
    ХранилищеНастроек.Инициализировать(ПутьПроекта_, МодульПрокси_);

    Логгер = Новый("Логгер");
    Логгер.Инициализировать(ХранилищеНастроек);

    ОбработчикСеансов = Новый ("ОбработчикСеансов");
    ОбработчикСеансов.Инициализировать(ПутьПроекта_, ХранилищеНастроек);

    ПроцессорДействий = Новый("ПроцессорДействий");
    ПроцессорДействий.Инициализировать(ОбъектОПИ_, МодульПрокси_, ПутьПроекта_, Логгер);

    ПроцессорAPI  = Новый("ПроцессорAPI");
    ПроцессорAPI.Инициализировать(МодульПрокси_, ПутьПроекта_, ОбработчикСеансов, ОбъектОПИ_, ХранилищеНастроек, Логгер);

    ПроцессорUI   = Новый("ПроцессорUI");
    ПроцессорUI.Инициализировать(ПутьСервера_, ОбработчикСеансов);

КонецПроцедуры

Процедура ОсновнаяОбработка(Контекст, СледующийОбработчик) Экспорт

    Попытка
        Результат = ОбработатьЗапрос(Контекст, СледующийОбработчик);
        
    Исключение

        Результат = Инструментарий.ОшибкаОбработки(Контекст, 500, ИнформацияОбОшибке());

        Если Контекст.Ответ.КодСостояния = 200 Тогда
            Контекст.Ответ.КодСостояния = 500;
        КонецЕсли;

    КонецПопытки;

    ВыполнитьСборкуМусора();

    Если Результат <> Неопределено Тогда

        OPI_ПреобразованиеТипов.ПолучитьКоллекцию(Результат);
        JSON = OPI_Инструменты.JSONСтрокой(Результат);

        Контекст.Ответ.ТипКонтента = "application/json;charset=UTF8";
        Контекст.Ответ.Записать(JSON);

    КонецЕсли;

КонецПроцедуры

Функция ОбработатьЗапрос(Контекст, СледующийОбработчик)

    Путь = Контекст.Запрос.Путь;

    Путь = ?(СтрНачинаетсяС(Путь    , "/")    , Прав(Путь, СтрДлина(Путь) - 1) , Путь);
    Путь = ?(СтрЗаканчиваетсяНа(Путь, "/")    , Лев(Путь , СтрДлина(Путь) - 1) , Путь);

    Если СтрНачинаетсяС(Путь, "api") Тогда
        Результат = ПроцессорAPI.ОсновнаяОбработка(Контекст, Путь);
    ИначеЕсли СтрНачинаетсяС(Путь, "ui") Тогда
        Результат = ПроцессорUI.ОсновнаяОбработка(Контекст, Путь);
    ИначеЕсли Не СтрНайти(Путь, "/") Тогда
        Результат = ПроцессорДействий.ОсновнаяОбработка(Контекст, Путь);
    Иначе
        Результат = Инструментарий.ОшибкаОбработки(Контекст, 404, "Not Found");
    КонецЕсли;

    Возврат Результат;

КонецФункции

#КонецОбласти
