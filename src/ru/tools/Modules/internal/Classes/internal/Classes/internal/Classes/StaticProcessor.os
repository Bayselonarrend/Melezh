Перем ХранилищеНастроек;
Перем ПутьСервера;
Перем СоответствиеТипов;

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ХранилищеНастроек_, ПутьСервера_) Экспорт

	ХранилищеНастроек = ХранилищеНастроек_;
	ПутьСервера       = ПутьСервера_;
	ЗаполнитьСоответствиеТипов();

КонецПроцедуры

Функция ВернутьСтатику(Знач Путь, Знач Контекст) Экспорт

	Результат = ЗаписатьФайлВОтвет(Путь, Контекст);
	Возврат Результат;

КонецФункции

Функция Перенаправление(Знач Путь, Знач Контекст) Экспорт

    БазовыйПуть = ХранилищеНастроек.ВернутьБазовыйПуть();
    Контекст.Ответ.КодСостояния = 303;
	Контекст.Ответ.Заголовки["Location"] = БазовыйПуть + Путь;

КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ЗаписатьФайлВОтвет(Путь, Контекст) Экспорт

    ПолныйПутьФайла = СтрШаблон("%1/%2", ПутьСервера, Путь);
	ФайлОбъект      = Новый Файл(ПолныйПутьФайла);

	Если Не ФайлОбъект.Существует() Тогда
		Возврат Ложь;
	КонецЕсли;

	Расширение = ФайлОбъект.Расширение;
	Страница   = Новый ДвоичныеДанные(ПолныйПутьФайла);

	УстановитьТипДанныхПоРасширению(Контекст, Расширение);

	Если Расширение = ".html" Или Расширение = ".js" Тогда

		Страница = ПолучитьСтрокуИзДвоичныхДанных(Страница);
		MBP      = "#melezh_base_path#";

		Если СтрНайти(Страница, MBP) > 0 Тогда

			БазовыйПуть = ХранилищеНастроек.ВернутьБазовыйПуть();
    		Страница = СтрЗаменить(Страница, MBP, БазовыйПуть);
    		
		КонецЕсли;

		Страница = ПолучитьДвоичныеДанныеИзСтроки(Страница);

	КонецЕсли;

	ПутьОтвета   = Контекст.Ответ.Тело;
	ЗаписьОтвета = Новый ЗаписьДанных(ПутьОтвета);
	
	ЗаписьОтвета.Записать(Страница);
	ЗаписьОтвета.Закрыть();

	Возврат Истина;

КонецФункции

Функция УстановитьТипДанныхПоРасширению(Знач Контекст, Знач Расширение)

	ТекущийТип = СоответствиеТипов.Получить(Расширение);
	ТекущийТип = ?(ТекущийТип = Неопределено, "application/octet-stream", ТекущийТип);

	Контекст.Ответ.ТипКонтента = ТекущийТип;

КонецФункции

Процедура ЗаполнитьСоответствиеТипов()

    СоответствиеТипов = Новый Соответствие();
    
    // Текстовые типы
    СоответствиеТипов.Вставить(".html", "text/html");
    СоответствиеТипов.Вставить(".htm", "text/html");
    СоответствиеТипов.Вставить(".txt", "text/plain");
    СоответствиеТипов.Вставить(".css", "text/css");
    СоответствиеТипов.Вставить(".js", "application/javascript");
    СоответствиеТипов.Вставить(".json", "application/json");
    СоответствиеТипов.Вставить(".xml", "application/xml");

    // Изображения
    СоответствиеТипов.Вставить(".jpg", "image/jpeg");
    СоответствиеТипов.Вставить(".jpeg", "image/jpeg");
    СоответствиеТипов.Вставить(".png", "image/png");
    СоответствиеТипов.Вставить(".gif", "image/gif");
    СоответствиеТипов.Вставить(".bmp", "image/bmp");
    СоответствиеТипов.Вставить(".webp", "image/webp");
    СоответствиеТипов.Вставить(".svg", "image/svg+xml");

    // Шрифты
    СоответствиеТипов.Вставить(".woff", "font/woff");
    СоответствиеТипов.Вставить(".woff2", "font/woff2");
    СоответствиеТипов.Вставить(".ttf", "font/ttf");
    СоответствиеТипов.Вставить(".otf", "font/opentype");

    // Видео
    СоответствиеТипов.Вставить(".mp4", "video/mp4");
    СоответствиеТипов.Вставить(".webm", "video/webm");
    СоответствиеТипов.Вставить(".ogg", "video/ogg");

    // Аудио
    СоответствиеТипов.Вставить(".mp3", "audio/mpeg");
    СоответствиеТипов.Вставить(".wav", "audio/wav");
    СоответствиеТипов.Вставить(".oga", "audio/ogg");

    // Документы
    СоответствиеТипов.Вставить(".pdf", "application/pdf");
    СоответствиеТипов.Вставить(".doc", "application/msword");
    СоответствиеТипов.Вставить(".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
    СоответствиеТипов.Вставить(".xls", "application/vnd.ms-excel");
    СоответствиеТипов.Вставить(".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    СоответствиеТипов.Вставить(".ppt", "application/vnd.ms-powerpoint");
    СоответствиеТипов.Вставить(".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation");

    // Архивы
    СоответствиеТипов.Вставить(".zip", "application/zip");
    СоответствиеТипов.Вставить(".rar", "application/x-rar-compressed");
    СоответствиеТипов.Вставить(".7z", "application/x-7z-compressed");
    СоответствиеТипов.Вставить(".tar", "application/x-tar");
    СоответствиеТипов.Вставить(".gz", "application/gzip");

КонецПроцедуры

#КонецОбласти

#Region Alternate

Procedure Initialize(SettingsVault_, ServerPath_) Export
	Инициализировать(SettingsVault_, ServerPath_);
EndProcedure

Function ReturnStatic(Val Path, Val Context) Export
	Return ВернутьСтатику(Path, Context);
EndFunction

Function Redirection(Val Path, Val Context) Export
	Return Перенаправление(Path, Context);
EndFunction

Function WriteFileInResponse(Path, Context) Export
	Return ЗаписатьФайлВОтвет(Path, Context);
EndFunction

#EndRegion

#Region Alternate

Procedure Initialize(SettingsVault_, ServerPath_) Export
	Инициализировать(SettingsVault_, ServerPath_);
EndProcedure

Function ReturnStatic(Val Path, Val Context) Export
	Return ВернутьСтатику(Path, Context);
EndFunction

Function Redirection(Val Path, Val Context) Export
	Return Перенаправление(Path, Context);
EndFunction

Function WriteFileInResponse(Path, Context) Export
	Return ЗаписатьФайлВОтвет(Path, Context);
EndFunction

#EndRegion

#Region Alternate

Procedure Initialize(SettingsVault_, ServerPath_) Export
	Инициализировать(SettingsVault_, ServerPath_);
EndProcedure

Function ReturnStatic(Val Path, Val Context) Export
	Return ВернутьСтатику(Path, Context);
EndFunction

Function Redirection(Val Path, Val Context) Export
	Return Перенаправление(Path, Context);
EndFunction

Function WriteFileInResponse(Path, Context) Export
	Return ЗаписатьФайлВОтвет(Path, Context);
EndFunction

#EndRegion