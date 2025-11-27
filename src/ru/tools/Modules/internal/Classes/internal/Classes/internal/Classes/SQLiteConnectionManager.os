#Использовать oint

Перем СоединениеRO;
Перем СоединениеRW;
Перем RWGuard;

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ПутьПроекта_) Экспорт
	
	ПутьПроектаRO     = СтрШаблон("file:%1?mode=ro", ПутьПроекта_);

	СоединениеRO = OPI_SQLite.ОткрытьСоединение(ПутьПроектаRO);
	СоединениеRW = OPI_SQLite.ОткрытьСоединение(ПутьПроекта_);
	RWGuard      = Истина;

КонецПроцедуры

Функция ПолучитьСоединениеRO() Экспорт

	Возврат СоединениеRO;

КонецФункции

Функция ПолучитьСоединениеRW() Экспорт

	Пока Не RWGuard Цикл
		Приостановить(200);
	КонецЦикла;

	RWGuard = Ложь;
	
	Возврат СоединениеRW;

КонецФункции

Процедура ВернутьСоединениеRW() Экспорт
	RWGuard = Истина;
КонецПроцедуры

#КонецОбласти

#Region Alternate

Procedure Initialize(ProjectPath_) Export
	Инициализировать(ProjectPath_);
EndProcedure

Function GetROConnection() Export
	Return ПолучитьСоединениеRO();
EndFunction

Function GetRWConnection() Export
	Return ПолучитьСоединениеRW();
EndFunction

Procedure ReturnRWConnection() Export
	ВернутьСоединениеRW();
EndProcedure

#EndRegion