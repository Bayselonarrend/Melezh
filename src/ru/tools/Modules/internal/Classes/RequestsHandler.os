﻿// MIT License

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
Перем ПроцессорРасширений;
Перем Логгер;
Перем ХранилищеНастроек;
Перем ОбработчикСеансов;
Перем МенеджерСоединенийSQLite;
Перем ПутьСервера;

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ПутьПроекта_, МодульПрокси_, ОбъектОПИ_, КаталогиСервера_) Экспорт
    
    ПутьСервера    = КаталогиСервера_["Корень"];
    ПутьРасширений = КаталогиСервера_["Расширения"];

    МенеджерСоединенийSQLite = Новый("SQLiteConnectionManager");
    МенеджерСоединенийSQLite.Инициализировать(ПутьПроекта_);
    
    ХранилищеНастроек = Новый("SettingsVault");
    ХранилищеНастроек.Инициализировать(МенеджерСоединенийSQLite, МодульПрокси_);
    
    Логгер = Новый("Logger");
    Логгер.Инициализировать(ХранилищеНастроек);
    
    ОбработчикСеансов = Новый("SessionsHandler");
    ОбработчикСеансов.Инициализировать(МенеджерСоединенийSQLite, ХранилищеНастроек);
    
    ПроцессорДействий = Новый("ActionsProcessor");
    ПроцессорДействий.Инициализировать(ОбъектОПИ_, МодульПрокси_, МенеджерСоединенийSQLite, Логгер, ХранилищеНастроек);
        
    ПроцессорUI   = Новый("UIProcessor");
    ПроцессорUI.Инициализировать(ПутьСервера, ОбработчикСеансов, ХранилищеНастроек);

    ПроцессорРасширений = Новый("ExtensionsProcessor");
    ПроцессорРасширений.Инициализировать(ОбъектОПИ_, ХранилищеНастроек, ПутьРасширений);

    ПроцессорAPI  = Новый("APIProcessor");
    ПроцессорAPI.Инициализировать(МодульПрокси_, МенеджерСоединенийSQLite, ОбработчикСеансов, ОбъектОПИ_, ХранилищеНастроек, Логгер, ПроцессорРасширений);
    
КонецПроцедуры

Процедура ОсновнаяОбработка(Контекст, СледующийОбработчик) Экспорт
    
    Попытка
        
        Контекст.Ответ.Заголовки["Server"] = "Melezh/0.2.0 (Kestrel)";
        
        Результат = ОбработатьЗапрос(Контекст, СледующийОбработчик);
        
    Исключение
        
        Результат = Toolbox.ОшибкаОбработки(Контекст, 500, ИнформацияОбОшибке());
        
        Если Контекст.Ответ.КодСостояния = 200 Тогда
            Контекст.Ответ.КодСостояния = 500;
        КонецЕсли;
        
    КонецПопытки;
    
    ВыполнитьСборкуМусора();
    
    Если Результат <> Неопределено Тогда
        
        Если OPI_Инструменты.ЭтоКоллекция(Результат) Тогда
            Контекст.Ответ.Заголовки["Content-Type"] = "application/json;charset=utf-8";
        КонецЕсли;
        
        OPI_ПреобразованиеТипов.ПолучитьДвоичныеДанные(Результат, Истина, Ложь);
        
        ЗаписьДанных = Новый ЗаписьДанных(Контекст.Ответ.Тело);
        ЗаписьДанных.Записать(Результат);
        ЗаписьДанных.Закрыть();
         
    КонецЕсли;
    
КонецПроцедуры

Функция ОбработатьЗапрос(Контекст, СледующийОбработчик)
    
    Результат = Неопределено;

    БазовыйПуть = ХранилищеНастроек.ВернутьБазовыйПуть();
    Путь        = ПолучитьПутьЗапроса(Контекст, БазовыйПуть);

    Если СтрНачинаетсяС(Путь, "api") Тогда
        Результат = ПроцессорAPI.ОсновнаяОбработка(Контекст, Путь);
    Иначе

        Результат = ПроцессорДействий.ОсновнаяОбработка(Контекст, Путь);

        Если Контекст.Ответ.КодСостояния = 404 Тогда

            РезультатUI = ПроцессорUI.ОсновнаяОбработка(Контекст, Путь);

            Если Контекст.Ответ.КодСостояния <> 404 Тогда
                Результат = РезультатUI;
            КонецЕсли;

        КонецЕсли;

    КонецЕсли;
    
    Возврат Результат;
    
КонецФункции

Функция ПолучитьПутьЗапроса(Контекст, БазовыйПуть)

    Путь = Контекст.Запрос.Путь;
    
    Путь = ?(СтрНачинаетсяС(Путь    , "/")    , Прав(Путь, СтрДлина(Путь) - 1) , Путь);
    Путь = ?(СтрЗаканчиваетсяНа(Путь, "/")    , Лев(Путь , СтрДлина(Путь) - 1) , Путь);

    Если Не ЗначениеЗаполнено(БазовыйПуть) Или БазовыйПуть = "/" Тогда
        Возврат Путь;
    КонецЕсли;

    ЧастиБазы   = СтрРазделить(БазовыйПуть, "/", Ложь);

    КоличествоЧастейБазы = ЧастиБазы.Количество();

    Если КоличествоЧастейБазы <> 0 Тогда

        ЧастиПути    = СтрРазделить(Путь, "/", Ложь);
        НовыйПуть    = Новый Массив;
        БазаПройдена = Ложь;

        Для Н = 0 По ЧастиПути.Количество() - 1 Цикл

            ТекущаяЧастьПути = ЧастиПути[Н];

            Если Н > ЧастиБазы.ВГраница() Или ТекущаяЧастьПути <> ЧастиБазы[Н] Тогда
                БазаПройдена = Истина;
            КонецЕсли;

            Если БазаПройдена Тогда
                НовыйПуть.Добавить(ТекущаяЧастьПути);
            КонецЕсли;
            
        КонецЦикла;

        Путь = СтрСоединить(НовыйПуть, "/");

    КонецЕсли;

    Возврат Путь;
    
КонецФункции

#КонецОбласти
