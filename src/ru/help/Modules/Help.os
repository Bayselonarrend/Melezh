#Использовать "../../tools"
#Использовать oint-cli

#Область СлужебныйПрограммныйИнтерфейс

Процедура ВывестиНачальнуюСтраницу(Знач Версия) Экспорт
	

	Консоль.ЦветТекста = ЦветКонсоли.Зеленый;
	Консоль.ВывестиСтроку("");

	Консоль.ЦветТекста = ЦветКонсоли.Бирюза;
	ColorOutput.Вывести("
		| ______  _____________________________________  __
		| ___   |/  /__  ____/__  /___  ____/__  /__  / / /
		| __  /|_/ /__  __/  __  / __  __/  __  /__  /_/ / 
		| _  /  / / _  /___  _  /___  /___  _  /__  __  /  
		| /_/  /_/  /_____/  /_____/_____/  /____/_/ /_/   
		|");
		
	Консоль.ЦветТекста = ЦветКонсоли.Желтый;

	ColorOutput.Вывести("
		|                          
		| Добро пожаловать в (Melezh|#color=Белый) v (" + Версия + "|#color=Бирюза)!
		|
		| Структура вызова:
	    | 
		| "
		+ "(melezh|#color=Белый) "
		+ "(<метод>|#color=Бирюза) " 
		+ "(--опция1|#color=Серый) "
		+ "(""|#color=Зеленый)"
		+ "(Значение|#color=Белый)"
		+ "(""|#color=Зеленый) "
		+ "(...|#color=Белый) "
		+ "(--опцияN|#color=Серый) "
		+ "(""|#color=Зеленый)"
		+ "(Значение|#color=Белый)"
		+ "(""|#color=Зеленый) ");

	ColorOutput.ВывестиСтроку("
		|
		| Вызов метода без параметров возвращает справку
		| (meleth|#color=Белый) (--help|#color=Серый) - получение списка доступных методов"); 
		

	Консоль.ЦветТекста = ЦветКонсоли.Белый;
	ColorOutput.ВывестиСтроку("
		|
		| (Стандартные опции:|#color=Желтый)
		|
		|  (--help|#color=Бирюза)  - выводит справку по методу или список всех методов. Аналогично вызову метода без параметров
		|  (--debug|#color=Бирюза) - флаг, отвечающий за предоставление более подробной информации при работе программы
		|  (--out|#color=Бирюза)   - путь к файлу сохранения результата
		|");
	
	Консоль.ЦветТекста = ЦветКонсоли.Желтый;
	ColorOutput.ВывестиСтроку(" Полную документацию можно найти по адресу: (https://openintegrations.dev|#color=Зеленый)" + Символы.ПС);

	Консоль.ВывестиСтроку("");
	Консоль.ЦветТекста = ЦветКонсоли.Белый;

	ЗавершитьРаботу(0);
	
КонецПроцедуры

Процедура ВывестиСправкуПоМетодам(Знач ТаблицаПараметров) Экспорт

	Консоль.ЦветТекста = ЦветКонсоли.Белый;

	ТаблицаПараметров.Свернуть("Метод,Область");

	ColorOutput.ВывестиСтроку(" (##|#color=Зеленый) Доступные методы: " + Символы.ПС);
	Консоль.ЦветТекста = ЦветКонсоли.Белый;

	ТекущаяОбласть       = "";
	Счетчик              = 0;
	КоличествоПараметров = ТаблицаПараметров.Количество();


	Для каждого СтрокаМетода Из ТаблицаПараметров Цикл

		Первый    = Ложь;
		Последний = Ложь;

		Если ТекущаяОбласть <> СтрокаМетода.Область Тогда
			ТекущаяОбласть = СтрокаМетода.Область;
			ColorOutput.ВывестиСтроку("    (o|#color=Желтый) (" + ТекущаяОбласть + "|#color=Бирюза)");
			Первый = Истина;
		КонецЕсли;

		Если Счетчик >= КоличествоПараметров - 1 Тогда
			Последний = Истина;
		Иначе
			Последний = ТаблицаПараметров[Счетчик + 1].Область <> ТекущаяОбласть;
		КонецЕсли;

		Если Первый И Последний Тогда
			Метка = "└───";
		ИначеЕсли Первый Тогда
			Метка = "└─┬─";
		ИначеЕсли Последний Тогда
			Метка = "  └─";
		Иначе
			Метка = "  ├─";
		КонецЕсли;
		
		ColorOutput.ВывестиСтроку("    (" + Метка + "|#color=Желтый) " + СтрокаМетода.Метод);

		Счетчик = Счетчик + 1;
	КонецЦикла;

	Сообщить(Символы.ПС);
	Консоль.ЦветТекста = ЦветКонсоли.Белый;

	ЗавершитьРаботу(0);

КонецПроцедуры

Процедура ВывестиСправкуПоПараметрам(Знач ТаблицаПараметров) Экспорт 

	Если ТаблицаПараметров.Количество() = 0 Тогда
		ВывестиСообщениеИсключения("Метод");
	КонецЕсли;

	ИмяМетода    = ТаблицаПараметров[0].Метод;
	ТекстСправки = "
	| (##|#color=Зеленый) Метод (" + ИмяМетода + "|#color=Бирюза)
	| (##|#color=Зеленый) "       + ТаблицаПараметров[0].ОписаниеМетода; 
	
	ColorOutput.ВывестиСтроку(ТекстСправки);
	ТекстСправки = "";

	ОбработатьТабуляциюСправки(ТаблицаПараметров);

	Для Каждого ПараметрМетода Из ТаблицаПараметров Цикл

		ТекстСправки = ТекстСправки 
			+ Символы.ПС
			+ "    ("
			+ ПараметрМетода["Параметр"]
			+ "|#color=Желтый) - "
			+ ПараметрМетода["Описание"];

	КонецЦикла;

	ColorOutput.ВывестиСтроку(ТекстСправки + Символы.ПС);

	ЗавершитьРаботу(0);
	
КонецПроцедуры

Процедура ВывестиСообщениеИсключения(Знач Причина, Знач ФайлВывода = "") Экспорт

	ФайлВывода = Строка(ФайлВывода);

	Если Причина = "Команда" Тогда
		Текст = "Некорректная команда! Проверьте правильность ввода";
		Код   = 1;

	ИначеЕсли Причина = "Метод" Тогда
		Текст = "Некорректный метод! Проверьте правильность ввода";
		Код   = 2;
		
	Иначе
		Текст = "Непредвиденная ошибка!: " + Причина;
		Код   = 99;
	КонецЕсли;

	Текст = Символы.ПС + Текст + Символы.ПС;
	
	Сообщить(Текст, СтатусСообщения.ОченьВажное);

	Если ЗначениеЗаполнено(ФайлВывода) Тогда

		ТекстДД = ПолучитьДвоичныеДанныеИзСтроки(Текст);

		Попытка
			ТекстДД.Записать(ФайлВывода);
			Сообщить("Сообщение об ошибке сохранено в файл: " + ФайлВывода, СтатусСообщения.Внимание);
		Исключение
			Сообщить("Не удалось сохранить ошибку в файл вывода: " + ОписаниеОшибки(), СтатусСообщения.Внимание);
		КонецПопытки;

	КонецЕсли;

	ЗавершитьРаботу(Код);

КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ОбработатьТабуляциюСправки(ТаблицаПараметров)

	Параметр_			= "Параметр";
	МаксимальнаяДлина 	= 15;

	Для Каждого ПараметрМетода Из ТаблицаПараметров Цикл
			
		Пока Не СтрДлина(ПараметрМетода[Параметр_]) = МаксимальнаяДлина Цикл
			ПараметрМетода[Параметр_] = ПараметрМетода[Параметр_] + " ";
		КонецЦикла;

		ТекущееОписание    = ПараметрМетода["Описание"];
		МассивОписания     = СтрРазделить(ТекущееОписание, Символы.ПС);
		НачальнаяТабуляция = 4;

		Если МассивОписания.Количество() = 1 Тогда
			Продолжить;
		Иначе

			Для Н = 1 По МассивОписания.ВГраница() Цикл

				ТекущийЭлемент = МассивОписания[Н];
				НеобходимаяДлина = СтрДлина(ТекущийЭлемент) + СтрДлина(ПараметрМетода[Параметр_] + " - ") + НачальнаяТабуляция;

				Пока СтрДлина(МассивОписания[Н]) < НеобходимаяДлина Цикл
					МассивОписания[Н] = " " + МассивОписания[Н];
				КонецЦикла;

			КонецЦикла;

			ПараметрМетода["Описание"] = СтрСоединить(МассивОписания, Символы.ПС);	
			
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

#КонецОбласти