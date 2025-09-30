# 1commands

Обсудить [![Join the chat at https://gitter.im/EvilBeaver/oscript-library](https://badges.gitter.im/EvilBeaver/oscript-library.svg)](https://gitter.im/EvilBeaver/oscript-library?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![GitHub release](https://img.shields.io/github/release/artbear/1commands.svg)](https://github.com/artbear/1commands/releases) [![Build Status](http://build.oscript.io/buildStatus/icon?job=oscript-library/1commands/develop)](http://build.oscript.io/job/oscript-library/job/1commands/job/develop/) 
[![Build status](https://ci.appveyor.com/api/projects/status/ervidk37h9m0tgs5?svg=true)](https://ci.appveyor.com/project/artbear/1commands)

## Библиотека для упрощения работы c запуском различных приложений и командных файлов (cmd, bat, bash, PowerShell и др.) из oscript.

Позволяет выполнять рутинные операции по запуску приложений и командных файлов системы.

Пример работы:
```bsl
Команда = Новый Команда;

Команда.УстановитьКоманду("oscript");
Команда.ДобавитьПараметр("-version");	

// или сразу Команда.УстановитьСтрокуЗапуска("oscript -version");

КодВозврата = Команда.Исполнить();
Сообщить(КодВозврата);

Сообщить(Команда.ПолучитьВывод());
```

или запуск командного файла
```bsl
КомандныйФайл = Новый КомандныйФайл;
КомандныйФайл.Создать();

КомандныйФайл.ДобавитьКоманду("@echo off");	
КомандныйФайл.ДобавитьКоманду("oscript -version");	

Сообщить(КомандныйФайл.ПолучитьТекстФайла());

КодВозврата = КомандныйФайл.Исполнить();
Сообщить(КодВозврата);

Сообщить(КомандныйФайл.ПолучитьВывод());
```
или запуск командного файла PowerShell
```bsl
КомандныйФайл = Новый КомандныйФайл;
КомандныйФайл.УстановитьПриложение("C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe");
КомандныйФайл.Создать("",".ps1");

КомандныйФайл.ДобавитьКоманду("Get-Help");		

Сообщить(КомандныйФайл.ПолучитьТекстФайла());

КодВозврата = КомандныйФайл.Исполнить();
Сообщить(КодВозврата);

Сообщить(КомандныйФайл.ПолучитьВывод());
```

Так же описание функциональности содержится в папке `features`. В прилагающихся `step_definitions` можно подсмотреть больше примеров.

## FAQ

Вопрос:
>при использовании классов Команда/Командный файл происходит зависание выполнения команды.
В консоли та же команда выполняется без зависания.

>Например, при использовании `gitsync`. [Описание ошибки и расследование](https://github.com/artbear/1commands/issues/14)

>Что делать?

Ответ:
> Отключить режим использования немедленного вывода лога команды, использовав метод `ПоказыватьВыводНемедленно(Ложь);`
В этом случае вывод команды будет получен после завершения работы команды, а не во время ее выполнения.