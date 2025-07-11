<img src="media/eng.png?1" align="left" width="32"> *This package is also available in English: [Click!](https://github.com/Bayselonarrend/Melezh/blob/master/README_ENG.md)*

 <hr>

![image](/media/cover_s.png)



# Melezh

[![OpenIntegrations](media/addon.svg)](https://github.com/Bayselonarrend/OpenIntegrations)
[![OpenYellow](https://img.shields.io/endpoint?url=https://openyellow.org/data/badges/6/976752838.json)](https://openyellow.org/grid?data=top&repo=976752838)
[![OneScript](media/oscript.svg)](https://github.com/EvilBeaver/OneScript) 
[![OneScript](media/boosty.svg)](https://boosty.to/bayselonarrend)


Серверная версия Открытого пакета интеграций, предоставляющая единый настраиваемый HTTP API для доступа к его библиотекам и произвольным `.os` скриптам (расширениям), с возможностью установки значений по умолчанию, веб-консолью и встроенным логированием входящих запросов

## Принцип работы

Данный сервер устанавливается поверх `oint` - консольного приложения [Открытого пакета интеграций](https://github.com/Bayselonarrend/OpenIntegrations), и позволяет удаленно вызывать его методы посредством HTTP-запросов из любого места так, как это происходило бы в консоли на локальной машине. Melezh использует встроенный в OneScript сервер Kestrel для приема HTTP-запросов, а затем интерпретирует их в команды `oint` (или вызовы функций модулей-расширений) для дальнейшего выполнения

Решение имеет гибкую систему настроек, позволяющую определить ограничения списка доступных команд и методов, а также установить значения параметров для выполнения команд по умолчанию. Это позволяет как просто уменьшить количество передаваемых данных, так и скрыть чувствительные данные от клиентской стороны в случае необходимости


## Пример начальной настройки

В этом примере создается новый файл проекта с настройкой обработчика GET-запросов для функции `ОтправитьТекстовоеСообщение` из библиотеки работы с Telegram. Также в нем устанавливается значение по умолчанию для параметра `token` без возможности перезаписи ("строгий"):

```powershell

melezh СоздатьПроект                 --path R:\test_proj.melezh
melezh ДобавитьОбработчикЗапросов    --proj R:\test_proj.melezh --lib telegram --func ОтправитьТекстовоеСообщение --method GET
melezh УстановитьАргументОбработчика --proj R:\test_proj.melezh --handler 42281f11b --arg token --value "***" --strict true
melezh ЗапуститьПроект               --proj R:\test_proj.melezh --port 7788

```

Обработчик будет доступен на `localhost:7788/42281f11b`, где `42281f11b` - идентификатор, получаемый при вызове `ДобавитьОбработчикЗапросов`, являясь одновременно и ключом обработчика для настройки, и URL-эндпоинтом для обращений

Пример запроса для отправки текстового сообщения:

```url
http://localhost:7788/42281f11b?chat=123123123&text="Hello world!"
```

Как можно заметить, мы не передаем токен, так как он установлен по умолчанию

## Веб-интерфейс

Кроме CLI интерфейса, для более простой интерактивной настройки и управления, можно использовать встроенную в Melezh веб-консоль:

![chrome_aDGtJZRrD8](https://github.com/user-attachments/assets/25762182-19b5-446c-8135-e87339cd7b02)

*На записи: вход в консоль, добавление нового обработчика для создания новости в Bitrix24 с указанием двух параметров по умолчанию, отключение двух обработчиков, просмотр подробностей одного из последних событий, просмотр всех логов по одному из обработчиков за сегодня*

<br>

**Веб-консоль позволяет:**
- Следить за последними событиями сервера
- Добавлять, изменять и удалять обработчики, менять состав параметров по умолчанию
- Включать и отключать обработчики на время
- Просматривать подробные логи по каждому обработанному запросу
- Изменять настройки сервера

Если вы только начинаете работу с Melezh, то рекомендуется начать именно с этого режима. Получить доступ к веб-консоли можно по адресу `localhost:<ваш порт>/ui` после создания и запуска проекта

## Установка

<img src="/media/box_s.png" align="left" width="200">

<br>

Melezh может быть установлен при помощи Windows-установщика, `rpm` или `deb`-пакета, пакета для OneScript, а также внутри Docker-контейнера. Необходимые файлы находятся в релизах данного репозитория <br><hr>
*Узнать больше о способе и процессе установки можно на [соответствующей странице документации](https://openintegrations.dev/docs/Addons/Melezh/Start/Installation)*

<br>

## Документация

<img src="https://github.com/user-attachments/assets/44614ade-d524-475b-ad5e-f4790994e836" align="left" width="200">

<br>

Больше информации о консольных командах, логировании, возможностях Web UI и работе с Melezh в целом можно найти в [онлайн-документации](https://openintegrations.dev/docs/Addons/Melezh). Она находится на том же портале, что и документация основного проекта - Открытого пакета интеграций, где вы также сможете найти информацию и о методах, доступных в качестве функций-обработчиков внутри Melezh. Текст документации доступен в двух вариантах - на русском и английском языках

<br>

## Поддержать проект

![image](media/boosty.png)

Если вам нравится этот или другие мои проекты, то вы можете поддержать меня [на Boosty](https://boosty.to/bayselonarrend) (регулярно или единоразово). При подписке от 500 рублей открывается доступ в приватный Telegram-чат, где можно задать интересующие вопросы о проекте и получить помощь от меня напрямую. Также присутствует спонсорская подписка для компаний с приоритетной поддержкой и размещением логотипа в списке спонсоров

**Спасибо за вашу поддержку!**

___
>![Infostart](https://github.com/Bayselonarrend/TelegramEnterprise/raw/main/infostart.svg)
>
>Статьи на Инфостарте:<br>
>- [Melezh: ваш персональный центр интеграций с внешними API и сервисами](https://infostart.ru/1c/articles/2402538/)<br>
