#!/usr/bin/oscript-cgi

#Использовать fs
#Использовать json
#Использовать messenger

Перем ПарсерJSON;
Перем КаталогПубликации;
Перем ИмяКомнаты;
Перем Мессенджер;

Функция ПолучитьСоединениеGithub()
	Сервер = "https://api.github.com";
	_Соединение = Новый HTTPСоединение(Сервер);
	
	Возврат _Соединение;
КонецФункции

Функция ПолучитьЗаголовкиЗапросаGithub(ТокенАвторизации)
	
	_Заголовки = Новый Соответствие();
	_Заголовки.Вставить("Accept", "application/vnd.github.v3+json");
	_Заголовки.Вставить("User-Agent", "oscript-library-autobuilder");
	
	_Заголовки.Вставить("Authorization", СтрШаблон("token %1", ТокенАвторизации));
	
	Возврат _Заголовки;
	
КонецФункции

Функция ПолучитьИмяПакетаИзИмениФайла(ИмяФайла)
	
	ИмяПакетаМассив = СтрРазделить(ИмяФайла, "-");
	ИмяПакета = "";
	Для сч = 0 По ИмяПакетаМассив.ВГраница() - 1 Цикл
		ИмяПакета = ИмяПакета + ИмяПакетаМассив[сч] + "-";
	КонецЦикла;
	ИмяПакета = Лев(ИмяПакета, СтрДлина(ИмяПакета) - 1);
	
	Возврат ИмяПакета;
	
КонецФункции

Функция ПолучитьВерсиюПакетаИзИмениФайла(ИмяФайла)
	
	ИмяПакетаМассив = СтрРазделить(ИмяФайла, "-");
	Версия = ИмяПакетаМассив[ИмяПакетаМассив.ВГраница()];
	Версия = СтрЗаменить(Версия, ".ospx", "");

	Возврат Версия;
	
КонецФункции

Функция ПолучитьИмяПользователяПоТокенуАвторизации(ТокенАвторизации)
	
	Соединение = ПолучитьСоединениеGithub();
	РесурсРепозиторий = "/user";
	Заголовки = ПолучитьЗаголовкиЗапросаGithub(ТокенАвторизации);
	ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, Заголовки);
	
	ОтветРепозиторий  = Соединение.Получить(ЗапросРепозиторий);
	ТелоОтвета = ОтветРепозиторий.ПолучитьТелоКакСтроку();
	
	Если ОтветРепозиторий.КодСостояния <> 200 Тогда
		ВывестиЗаголовок("Status", "401");
		ВызватьИсключение ТелоОтвета;
	КонецЕсли;
	
	ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(ТелоОтвета);
	АвторизованныйПользователь = ДанныеОтвета["login"];
	
	Возврат АвторизованныйПользователь;
	
КонецФункции

Процедура ПроверитьЧтоПользовательИмеетПраваОтправкиВРепозиторий(ИмяПользователя, ИмяРепозитория)
	
	// TODO: Системный токен
	ТокенАвторизации = ВебЗапрос.ENV["HTTP_OAUTH_TOKEN"];
	
	Соединение = ПолучитьСоединениеGithub();
	РесурсРепозиторий = СтрШаблон("/repos/oscript-library/%1/collaborators", ИмяРепозитория);
	Заголовки = ПолучитьЗаголовкиЗапросаGithub(ТокенАвторизации);
	ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, ПолучитьЗаголовкиЗапросаGithub(ТокенАвторизации));
	
	ОтветРепозиторий  = Соединение.Получить(ЗапросРепозиторий);
	ТелоОтвета = ОтветРепозиторий.ПолучитьТелоКакСтроку();
	
	Если ОтветРепозиторий.КодСостояния <> 200 Тогда
		ВывестиЗаголовок("Status", "500");
		ВызватьИсключение ТелоОтвета;
	КонецЕсли;
	
	ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(ТелоОтвета);
	
	Для Каждого ДанныеКоллаборатора Из ДанныеОтвета Цикл
		Если ДанныеКоллаборатора["login"] = ИмяПользователя И ДанныеКоллаборатора["permissions"]["push"] Тогда
			ПользовательИмеетПраваОтправки = Истина;
		КонецЕсли;
	КонецЦикла;
	
	Если НЕ ПользовательИмеетПраваОтправки Тогда
		ВывестиЗаголовок("Status", "401");
		ВызватьИсключение "Пользователь не имеет права отправки в репозиторий пакета";
	КонецЕсли;
	
КонецПроцедуры

Процедура СформироватьList(КаталогПубликации)
	
	ПутьКСпискуПакетов = ОбъединитьПути(КаталогПубликации, "list.txt");
	
	НайденныеФайлы = НайтиФайлы(КаталогПубликации, ПолучитьМаскуВсеФайлы(), Ложь);
	
	ЗаписьТекста = Новый ЗаписьТекста(ПутьКСпискуПакетов, КодировкаТекста.UTF8NoBom);
	
	Для Каждого НайденныйФайл Из НайденныеФайлы Цикл	
		Если НайденныйФайл.ЭтоФайл() Тогда
			Продолжить;
		КонецЕсли;
		
		ЗаписьТекста.ЗаписатьСтроку(НайденныйФайл.Имя);	
	КонецЦикла;
	
	ЗаписьТекста.Закрыть();
	
КонецПроцедуры	

Функция ПрочестьСекретныйПараметр(ИмяПараметра)

	ЧтениеТекста = Новый ЧтениеТекста;
	ЧтениеТекста.Открыть("/hub_backend.secret", КодировкаТекста.UTF8);
	ТекстФайла = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	ЧислоСтрок = СтрЧислоСтрок(ТекстФайла);

	Если ЧислоСтрок = 0 Тогда
		Возврат "";
	КонецЕсли;

	Для сч = 1 По ЧислоСтрок Цикл
		Строка = СтрПолучитьСтроку(ТекстФайла, сч);
		Если СтрРазделить(Строка, "=")[0] = ИмяПараметра Тогда
			Возврат СтрРазделить(Строка, "=")[1];
		КонецЕсли;
	КонецЦикла;

	Возврат "";

КонецФункции

Процедура Инициализация()
	ПарсерJSON = Новый ПарсерJSON;
	
	СистемнаяИнформация = Новый СистемнаяИнформация;
	КаталогПубликации = ПрочестьСекретныйПараметр("PATH_TO_OSCRIPT_HUB");
	Если НЕ ЗначениеЗаполнено(КаталогПубликации) Тогда
		КаталогПубликации = "/var/www/hub.oscript.io";
	КонецЕсли;
	
	ТокенАвторизацииГиттер = ПрочестьСекретныйПараметр("GITTER_OAUTH_TOKEN");
	ИмяКомнаты = ПрочестьСекретныйПараметр("GITTER_ROOM");
	Мессенджер = Неопределено;
	
	Если ЗначениеЗаполнено(ТокенАвторизацииГиттер) Тогда
		Мессенджер = Новый Мессенджер();
		Мессенджер.ИнициализацияGitter(ТокенАвторизацииГиттер);
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(ИмяКомнаты) Тогда
		ИмяКомнаты = "EvilBeaver/oscript-library";  
	КонецЕсли;

	ВывестиЗаголовок("Content-type", "text/html; charset=utf-8");
	
КонецПроцедуры

////////////////////////////////////

Инициализация();

ТокенАвторизации = ВебЗапрос.ENV["HTTP_OAUTH_TOKEN"];
ДанныеФайла = ВебЗапрос.ПолучитьТелоКакДвоичныеДанные();
ИмяФайла = ВебЗапрос.ENV["HTTP_FILE_NAME"];
Канал = ВебЗапрос.ENV["HTTP_CHANNEL"];

Если НРег(Канал) = "stable" Тогда
	КаталогПубликации = КаталогПубликации + "/donwload";
Иначе
	КаталогПубликации = КаталогПубликации + "/dev-channel";
КонецЕсли; 

АвторизованныйПользователь = ПолучитьИмяПользователяПоТокенуАвторизации(ТокенАвторизации);

ИДПакета = ПолучитьИмяПакетаИзИмениФайла(ИмяФайла);
ПроверитьЧтоПользовательИмеетПраваОтправкиВРепозиторий(АвторизованныйПользователь, ИДПакета);
ВерсияПакета = ПолучитьВерсиюПакетаИзИмениФайла(ИмяФайла);

////////////////

ПутьККаталогуПакета = ОбъединитьПути(КаталогПубликации, ИДПакета);
ФС.ОбеспечитьКаталог(ПутьККаталогуПакета);

ДанныеФайла.Записать(ОбъединитьПути(ПутьККаталогуПакета, ИмяФайла));
ДанныеФайла.Записать(ОбъединитьПути(ПутьККаталогуПакета, ИДПакета + ".ospx"));

СформироватьList(КаталогПубликации);

Если НРег(Канал) = "stable" И Мессенджер <> Неопределено Тогда
	СообщениеГиттер = СтрШаблон(
		"## %1 [%2]%3Репозиторий: %4%5%6",
		ИДПакета,
		ВерсияПакета,
		Символы.ПС,
		"https://github.com/oscript-library/" + ИДПакета,
		Символы.ПС,
		"`// AutoBuilder`"
	);
	Мессенджер.ОтправитьСообщение(Мессенджер.ДоступныеПротоколы().gitter, ИмяКомнаты, СообщениеГиттер);
КонецЕсли;
