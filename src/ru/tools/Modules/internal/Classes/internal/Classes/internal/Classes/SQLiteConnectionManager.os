#Использовать oint

Перем СоединениеRO;
Перем СоединениеRW;

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ПутьПроекта_) Экспорт
	
	ПутьПроектаRO     = СтрШаблон("file:%1?mode=ro", ПутьПроекта_);

	СоединениеRO = OPI_SQLite.ОткрытьСоединение(ПутьПроектаRO);
	СоединениеRW = OPI_SQLite.ОткрытьСоединение(ПутьПроекта_);
	
КонецПроцедуры

Функция ПолучитьСоединениеRO() Экспорт

	Возврат СоединениеRO;

КонецФункции

Функция ПолучитьСоединениеRW() Экспорт
	
	Возврат СоединениеRW;

КонецФункции

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

#EndRegion

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

#EndRegion

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

#EndRegion