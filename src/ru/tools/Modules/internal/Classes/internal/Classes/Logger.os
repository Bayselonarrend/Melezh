#Использовать oint

Перем ХранилищеНастроек;
Перем ПоследниеДействия;
Перем ЧислоЗапросов;

#Область СлужебныйПрограммныйИнтерфейс

Процедура Инициализировать(ХранилищеНастроек_) Экспорт
	
	ХранилищеНастроек = ХранилищеНастроек_;
	ПоследниеДействия = Новый Массив;
	ЧислоЗапросов     = 0;
	
КонецПроцедуры

Процедура ЗаписатьЛог(Контекст, Обработчик, ТелоЗапроса, Знач Результат) Экспорт
		
	ЧислоЗапросов = ЧислоЗапросов + 1;
	
	Попытка

		ПутьЛогов = ХранилищеНастроек.ВернутьНастройку("logs_path");
		
		Если Не ЗначениеЗаполнено(ПутьЛогов) Тогда
			Возврат;		
		КонецЕсли;

		ДатаЗапроса              = ТекущаяДата();
		Идентификатор            = Лев(Строка(Новый УникальныйИдентификатор), 8);
		ОбработчикЭкранированный = СтрЗаменить(Строка(Обработчик), "/", "%2F");
		UUIDЗапроса              = СтрШаблон("%1-%2-%3", Формат(ДатаЗапроса, "ДФ=hh-mm-ss"), Идентификатор, ОбработчикЭкранированный);
		ПутьДляЗаписи            = ОрганизоватьКаталогЛога(ПутьЛогов, ДатаЗапроса, ОбработчикЭкранированный, UUIDЗапроса);
		
		Если ТелоЗапроса = Неопределено Тогда
			РазмерТела = Контекст.Запрос.ДлинаКонтента;
		Иначе
			РазмерТела = ТелоЗапроса.Размер();
		КонецЕсли;
		
		ЗаписыватьТелоЗапроса       = ХранилищеНастроек.ВернутьНастройку("logs_req_body");
		ЗаписыватьЗаголовкиЗапроса  = ХранилищеНастроек.ВернутьНастройку("logs_req_headers");
		ЗаписыватьТелоОтвета        = ХранилищеНастроек.ВернутьНастройку("logs_res_body");	
		МаксимальныйРазмерЗапроса   = ХранилищеНастроек.ВернутьНастройку("logs_req_max_size");
		МаксимальныйРазмерОтвета    = ХранилищеНастроек.ВернутьНастройку("logs_res_max_size");
		
		ЗаписатьИнформациюЗапроса(ПутьДляЗаписи, Контекст, ДатаЗапроса, РазмерТела, UUIDЗапроса, Обработчик);

		Если ЗаписыватьЗаголовкиЗапроса Тогда
			ЗаписатьЗаголовкиЗапроса(ПутьДляЗаписи, Контекст.Запрос.Заголовки);
		КонецЕсли;
		
		Если ЗаписыватьТелоЗапроса Тогда

			Если ТелоЗапроса <> Неопределено Тогда
				
				ЗаписатьТелоЗапроса(ПутьДляЗаписи, ТелоЗапроса, МаксимальныйРазмерЗапроса);
				
			ИначеЕсли Контекст.Запрос.Форма <> Неопределено Тогда
				
				ЗаписатьФормуЗапроса(ПутьДляЗаписи, Контекст.Запрос.Форма, МаксимальныйРазмерЗапроса);
				
			КонецЕсли;	
			
		КонецЕсли;

		Если ЗаписыватьТелоОтвета Тогда

			OPI_ПреобразованиеТипов.ПолучитьДвоичныеДанные(Результат);

			Если Результат.Размер() <= МаксимальныйРазмерОтвета Или Не ЗначениеЗаполнено(МаксимальныйРазмерОтвета) Тогда
				ЗаписатьФайлЛога(ПутьДляЗаписи, "res.body", Результат);
			КонецЕсли;

		КонецЕсли;
		
	Исключение
		Ошибка = Новый Структура("result,error", Истина, ОписаниеОшибки());
		ЗаписатьФайлЛога(ПутьДляЗаписи, "error.json", Ошибка);	
	КонецПопытки;
	
	ВыполнитьСборкуМусора();
	
КонецПроцедуры

Процедура ЗаписатьТелоЗапроса(ПутьДляЗаписи, ТелоЗапроса, МаксимальныйРазмерЗапроса)
	
	Если ЗначениеЗаполнено(МаксимальныйРазмерЗапроса) Тогда
		ЗаписыватьТело = ТелоЗапроса.Размер() <= МаксимальныйРазмерЗапроса;
	Иначе
		ЗаписыватьТело = Истина;
	КонецЕсли;
	
	Если ЗаписыватьТело Тогда
		ЗаписатьФайлЛога(ПутьДляЗаписи, "req.body", ТелоЗапроса);
	КонецЕсли;
	
КонецПроцедуры

Процедура ЗаписатьФормуЗапроса(ПутьДляЗаписи, ФормаЗапроса, МаксимальныйРазмерЗапроса)

	ПроверятьРазмер    = ЗначениеЗаполнено(МаксимальныйРазмерЗапроса);
	СоответствиеДанных = Новый Соответствие();

	Для Каждого ЧастьФормы Из ФормаЗапроса Цикл

		Если ЧастьФормы.Ключ = "Файлы" Тогда
			Продолжить;
		КонецЕсли;

		ЗначениеЧасти = Строка(ЧастьФормы.Значение);
		СоответствиеДанных.Вставить(ЧастьФормы.Ключ, ЗначениеЧасти);

	КонецЦикла;

	СоответствиеДанных_ = OPI_Инструменты.КопироватьКоллекцию(СоответствиеДанных);
	OPI_ПреобразованиеТипов.ПолучитьДвоичныеДанные(СоответствиеДанных_, Истина);
	ТекущийРазмерДанных = СоответствиеДанных_.Размер();

	Если ТекущийРазмерДанных > МаксимальныйРазмерЗапроса И ПроверятьРазмер Тогда
		Возврат;
	КонецЕсли;		

	Если ФормаЗапроса.Файлы <> Неопределено Тогда

		МассивИнформацииОФайлах = Новый Массив;
		Счетчик = 1;

		Для Каждого Файл Из ФормаЗапроса.Файлы Цикл

			Если Файл.Длина + ТекущийРазмерДанных > МаксимальныйРазмерЗапроса И ПроверятьРазмер Тогда

				РазмерФайла = Файл.Длина;
				Сохранен    = Ложь;
				ПутьКФайлу  = "";

			Иначе

				ОсновноеИмя = ?(ЗначениеЗаполнено(Файл.ИмяФайла), Файл.ИмяФайла, СтрШаблон("file%1.bin", Счетчик));
				ПутьКФайлу  = СтрШаблон("%1/%2", ПутьДляЗаписи, ОсновноеИмя);

				ФайловыйПоток = Новый ФайловыйПоток(ПутьКФайлу, РежимОткрытияФайла.ОткрытьИлиСоздать);
				ПотокФайла = Файл.ОткрытьПотокЧтения();
				ПотокФайла.КопироватьВ(ФайловыйПоток);
				ПотокФайла.Закрыть();
				ФайловыйПоток.Закрыть();

				ЗаписанныйФайл      = Новый Файл(ПутьКФайлу);
				РазмерФайла         = ЗаписанныйФайл.Размер();
				ТекущийРазмерДанных = ТекущийРазмерДанных + РазмерФайла;
				Сохранен            = Истина;

			КонецЕсли;

			ТекущаяИнформацияФайла = Новый Структура;
			ТекущаяИнформацияФайла.Вставить("name"      , Строка(Файл.Имя));
			ТекущаяИнформацияФайла.Вставить("file_name" , Строка(Файл.ИмяФайла));
			ТекущаяИнформацияФайла.Вставить("type"      , Строка(Файл.ТипКонтента));
			ТекущаяИнформацияФайла.Вставить("size"      , РазмерФайла);
			ТекущаяИнформацияФайла.Вставить("saved"     , Сохранен);
			ТекущаяИнформацияФайла.Вставить("saved_path", ПутьКФайлу);

			МассивИнформацииОФайлах.Добавить(ТекущаяИнформацияФайла);

			Счетчик = Счетчик + 1;

		КонецЦикла;

		СоответствиеДанных.Вставить("melezh_request_files", МассивИнформацииОФайлах);

	КонецЕсли;

	ЗаписатьФайлЛога(ПутьДляЗаписи, "req.body", СоответствиеДанных);

КонецПроцедуры

Процедура ЗаписатьЗаголовкиЗапроса(ПутьДляЗаписи, Заголовки)

	СоответствиеЗаголовков = Новый Соответствие();

	Для Каждого Заголовок Из Заголовки Цикл

		ЗначениеЗаголовка = Строка(Заголовок.Значение);

		Если ЗначениеЗаполнено(ЗначениеЗаголовка) Тогда
			СоответствиеЗаголовков.Вставить(Заголовок.Ключ, ЗначениеЗаголовка);
		КонецЕсли;

	КонецЦикла;

	Если СоответствиеЗаголовков.Количество() <> 0 Тогда
		ЗаписатьФайлЛога(ПутьДляЗаписи, "req.headers", СоответствиеЗаголовков);
	КонецЕсли;
	
КонецПроцедуры

Функция ВернутьПоследниеДействия() Экспорт
	Возврат ПоследниеДействия;
КонецФункции

Функция ВернутьДействия(Обработчик, Дата) Экспорт
	
	Результат                = Новый Массив;
	ПутьЛогов                = ХранилищеНастроек.ВернутьНастройку("logs_path");
	ОбработчикЭкранированный = СтрЗаменить(Строка(Обработчик), "/", "%2F");
	
	Если Не ЗначениеЗаполнено(ПутьЛогов) Тогда
		Возврат Результат;		
	КонецЕсли;
	
	ПутьЛогов = СтрЗаменить(ПутьЛогов, "\", "/");
	ПутьЛогов = ?(СтрЗаканчиваетсяНа(ПутьЛогов, "/"), Лев(ПутьЛогов, СтрДлина(ПутьЛогов) - 1), ПутьЛогов);
	
	ПутьЛогов = СтрШаблон("%1/%2/%3", ПутьЛогов, ОбработчикЭкранированный, Дата);
	ФайлПути  = Новый Файл(ПутьЛогов);
	
	Если Не ФайлПути.Существует() Тогда
		Возврат Результат;
	КонецЕсли;
	
	ФайлыИнформации  = НайтиФайлы(ПутьЛогов, "req.info", Истина);	
	Результат        = Новый СписокЗначений();
	
	Для Каждого ФайлИнформации Из ФайлыИнформации Цикл
		
		ЧтениеJSON = Новый ЧтениеJSON();
		ЧтениеJSON.ОткрытьФайл(ФайлИнформации.ПолноеИмя);
		
		Данные = ПрочитатьJSON(ЧтениеJSON);
		Данные.Удалить("params");
		
		Результат.Добавить(Данные, Данные["date"]);
		ЧтениеJSON.Закрыть();
		
	КонецЦикла;
	
	Результат.СортироватьПоПредставлению(НаправлениеСортировки.Убыв);
	Результат = Результат.ВыгрузитьЗначения();
	
	Возврат Результат;
	
КонецФункции

Функция ВернутьЧислоЗапросов() Экспорт
	Возврат ЧислоЗапросов;
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ОрганизоватьКаталогЛога(Знач ПутьЛогов, Знач Дата, Знач Обработчик, Знач UUID)
	
	ОсновнойКаталогЛогов = ПроверитьСоздатьКаталог(ПутьЛогов);
		
	КаталогОбработчика = СтрШаблон("%1/%2", ОсновнойКаталогЛогов, Обработчик);
	КаталогОбработчика = ПроверитьСоздатьКаталог(КаталогОбработчика);
	
	КаталогДаты = СтрШаблон("%1/%2", КаталогОбработчика, Формат(Дата, "ДФ=yyyy-MM-dd"));
	КаталогДаты = ПроверитьСоздатьКаталог(КаталогДаты);
	
	КаталогЗапроса = СтрШаблон("%1/%2", КаталогДаты, UUID);
	КаталогЗапроса = ПроверитьСоздатьКаталог(КаталогЗапроса);
	
	Возврат КаталогЗапроса;
	
КонецФункции

Функция ПроверитьСоздатьКаталог(Знач Путь)
	
	Путь = СтрЗаменить(Путь, "\", "/");
	Путь = ?(СтрЗаканчиваетсяНа(Путь, "/"), Лев(Путь, СтрДлина(Путь) - 1), Путь);
	
	ФайлКаталог = Новый Файл(Путь);
	
	Если Не ФайлКаталог.Существует() Тогда
		СоздатьКаталог(Путь);
	КонецЕсли;
	
	Возврат Путь;
	
КонецФункции

Функция ЗаписатьИнформациюЗапроса(Знач ПутьЛогов, Знач Контекст, Знач ДатаЗапроса, Знач РазмерТела, Знач UUIDЗапроса, Знач Обработчик)
	
	ТипКонтента = Контекст.Запрос.ТипКонтента;
	ТипКонтента = ?(ЗначениеЗаполнено(ТипКонтента), ТипКонтента, "<нет/неизвестно>");
	
	ДанныеЗапроса = Новый Структура;
	ДанныеЗапроса.Вставить("key"     , UUIDЗапроса);
	ДанныеЗапроса.Вставить("date"    , ДатаЗапроса);		
	ДанныеЗапроса.Вставить("method"  , Контекст.Запрос.Метод);
	ДанныеЗапроса.Вставить("type"    , ТипКонтента);
	ДанныеЗапроса.Вставить("size"    , ?(ЗначениеЗаполнено(РазмерТела), РазмерТела, 0));
	ДанныеЗапроса.Вставить("status"  , Контекст.Ответ.КодСостояния);
	ДанныеЗапроса.Вставить("handler" , Обработчик);
	
	ПоследниеДействия.Вставить(0, ДанныеЗапроса);
	
	Пока ПоследниеДействия.Количество() > 30 Цикл
		ПоследниеДействия.Удалить(ПоследниеДействия.Количество() - 1);
	КонецЦикла;
	
	ДанныеЗапроса.Вставить("protocol", Контекст.Запрос.Протокол);
	ДанныеЗапроса.Вставить("form"    , Контекст.Запрос.ЕстьФормыВТипеКонтента);
	ДанныеЗапроса.Вставить("params"  , Контекст.Запрос.Параметры);
	
	ЗаписьJSON = Новый ЗаписьJSON();
	ЗаписьJSON.ОткрытьФайл(СтрШаблон("%1/%2", ПутьЛогов, "req.info"));
	ЗаписатьJSON(ЗаписьJSON, ДанныеЗапроса);
	ЗаписьJSON.Закрыть();
	
КонецФункции

Процедура ЗаписатьФайлЛога(ПутьЛогов, ИмяФайла, Данные)
	
	OPI_ПреобразованиеТипов.ПолучитьДвоичныеДанные(Данные);
	Данные.Записать(СтрШаблон("%1/%2", ПутьЛогов, ИмяФайла));
	
КонецПроцедуры

#КонецОбласти
