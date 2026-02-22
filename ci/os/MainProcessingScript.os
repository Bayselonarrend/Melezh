#Использовать "./internal"
#Использовать "./internal/Classes/internal"

Процедура ПриСозданииОбъекта()

	ДанныеПроекта = Новый ProjectData;

	Обработчик = Новый CLIMethods(ДанныеПроекта);
	Обработчик = Новый DictionariesMethods(ДанныеПроекта);
	Обработчик = Новый LocalizationMethods(ДанныеПроекта);
	Обработчик = Новый AlternativeNamesMethods(ДанныеПроекта);
	Обработчик = Новый DocsGenerator(ДанныеПроекта);
	Обработчик = Новый HashSumGenerator(ДанныеПроекта);
	Обработчик = Новый ReleaseFactory(ДанныеПроекта);

	CommonTools.СообщитьПроцесс("Processing complete!");

КонецПроцедуры
