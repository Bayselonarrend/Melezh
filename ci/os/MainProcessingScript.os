#Использовать oint/tools/http
#Использовать "./internal"
#Использовать "./internal/Classes/internal"

Процедура ПриСозданииОбъекта()

    Результат = OPI_ЗапросыHTTP.НовыйЗапрос()
        .Инициализировать("https://raw.githubusercontent.com/Bayselonarrend/OpenIntegrations/refs/heads/main/ci/config_global.json")
		.УстановитьФайлОтвета("./ci/config_global.json")
		.ОбработатьЗапрос("GET");

	Если Результат.ВернутьОтвет().КодСостояния > 299 Тогда
		ВызватьИсключение Результат.ВернутьОтветКакСтроку();
	КонецЕсли;
		
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
