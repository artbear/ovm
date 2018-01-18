#Использовать 1commands
#Использовать fluent
#Использовать fs

Перем ЭтоWindows;

Функция ВерсияУстановлена(Знач ПроверяемаяВерсия) Экспорт

	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ПроверяемаяВерсия);
	
	Результат = ФС.КаталогСуществует(КаталогУстановкиВерсии);
	Результат = Результат И ФС.ФайлСуществует(ОбъединитьПути(КаталогУстановкиВерсии, "bin", "oscript.exe"));

	Возврат Результат;

КонецФункции

Функция ЭтоТекущаяВерсия(Знач ПроверяемаяВерсия) Экспорт

	Если ПроверяемаяВерсия = "current" Тогда
		Возврат Истина;
	КонецЕсли;
	
	Если НЕ ВерсияУстановлена("current") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Если НЕ ВерсияУстановлена(ПроверяемаяВерсия) Тогда
		Возврат Ложь;
	КонецЕсли;

	ПутьКДвижкуТекущейВерсии = ПолучитьПутьКУстановленнойВерсии("current");
	ПутьКДвижкуПроверяемойВерсии = ПолучитьПутьКУстановленнойВерсии(ПроверяемаяВерсия);
	
	ФайлДвижкаТекущейВерсии = Новый Файл(ПутьКДвижкуТекущейВерсии);
	ФайлДвижкаПроверяемойВерсии = Новый Файл(ПутьКДвижкуПроверяемойВерсии);
	
	ФайлыПроверяемойВерсииСовпадаетСТекущейВерсией =
		ФайлДвижкаТекущейВерсии.ПолучитьВремяИзменения() = ФайлДвижкаПроверяемойВерсии.ПолучитьВремяИзменения()
			И ФайлДвижкаТекущейВерсии.ПолучитьВремяСоздания() = ФайлДвижкаПроверяемойВерсии.ПолучитьВремяСоздания();

	Возврат ФайлыПроверяемойВерсииСовпадаетСТекущейВерсией;

КонецФункции

Функция ПолучитьСписокУстановленныхВерсий() Экспорт
	
	УстановленныеВерсии = Новый ТаблицаЗначений;
	УстановленныеВерсии.Колонки.Добавить("Алиас");
	УстановленныеВерсии.Колонки.Добавить("Путь");
	УстановленныеВерсии.Колонки.Добавить("Версия");
	УстановленныеВерсии.Колонки.Добавить("ЭтоСимлинк");
	
	// TODO: определение симлинка на основании аттрибутов файла?
	МассивИменСимлинков = Новый Массив;
	МассивИменСимлинков.Добавить("current");
	
	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	НайденныеФайлы = НайтиФайлы(КаталогУстановки, ПолучитьМаскуВсеФайлы());
	Для Каждого НайденныйФайл Из НайденныеФайлы Цикл
		Если НЕ ВерсияУстановлена(НайденныйФайл.Имя) Тогда
			Продолжить;
		КонецЕсли;
		
		СтрокаВерсии = УстановленныеВерсии.Добавить();
		СтрокаВерсии.Алиас = НайденныйФайл.Имя;
		СтрокаВерсии.Путь = НайденныйФайл.ПолноеИмя;
		СтрокаВерсии.Версия = ПолучитьТочнуюВерсиюOneScript(СтрокаВерсии.Алиас);
		СтрокаВерсии.ЭтоСимлинк = МассивИменСимлинков.Найти(НайденныйФайл.Имя) <> Неопределено;

	КонецЦикла;
	
	Возврат УстановленныеВерсии;
	
КонецФункции

Функция ПолучитьСписокДоступныхКУстановкеВерсий() Экспорт
	
	ДоступныеВерсии = Новый ТаблицаЗначений;
	ДоступныеВерсии.Колонки.Добавить("Алиас");
	ДоступныеВерсии.Колонки.Добавить("Путь");
	
	Соединение = Новый HTTPСоединение("http://oscript.io");
	Запрос = Новый HTTPЗапрос("downloads/archive");
	
	Ответ = Соединение.Получить(Запрос);
	Если Ответ.КодСостояния <> 200 Тогда
		ВызватьИсключение Ответ.КодСостояния;
	КонецЕсли;
	
	ТелоСтраницы = Ответ.ПолучитьТелоКакСтроку();
	
	РегулярноеВыражение = Новый РегулярноеВыражение("<a href=""(\/downloads\/[^""]+)"">(\d+\.\d+\.\d+(\.\d+)?)");
	Совпадения = РегулярноеВыражение.НайтиСовпадения(ТелоСтраницы);
	Для Каждого СовпадениеРегулярногоВыражения Из Совпадения Цикл
		ГруппаАдрес = СовпадениеРегулярногоВыражения.Группы[1];
		ГруппаВерсия = СовпадениеРегулярногоВыражения.Группы[2];
		
		// TODO: Убрать после решения https://github.com/EvilBeaver/OneScript/issues/667
		Если ГруппаВерсия.Значение = "1.0.9" Тогда
			Продолжить;
		КонецЕсли;

		ДоступнаяВерсия = ДоступныеВерсии.Добавить();
		ДоступнаяВерсия.Алиас = ГруппаВерсия.Значение;
		ДоступнаяВерсия.Путь = "http://oscript.io" + ГруппаАдрес.Значение;
	КонецЦикла;

	Возврат ДоступныеВерсии;

КонецФункции

Функция ПолучитьСписокВсехВерсий() Экспорт

	СписокУстановленныхВерсий = ПолучитьСписокУстановленныхВерсий();
	СписокДоступныхВерсий = ПолучитьСписокДоступныхКУстановкеВерсий();

	ВсеВерсии = Новый ТаблицаЗначений;
	ВсеВерсии.Колонки.Добавить("Алиас", Новый ОписаниеТипов("Строка"));
	ВсеВерсии.Колонки.Добавить("Версия", Новый ОписаниеТипов("Строка"));
	ВсеВерсии.Колонки.Добавить("ПутьЛокальный", Новый ОписаниеТипов("Строка"));
	ВсеВерсии.Колонки.Добавить("ПутьСервер", Новый ОписаниеТипов("Строка"));
	ВсеВерсии.Колонки.Добавить("ЭтоСимлинк", Новый ОписаниеТипов("Булево"));

	Для Каждого ДоступнаяВерсия Из СписокДоступныхВерсий Цикл		
		СтрокаВсеВерсии = ВсеВерсии.Найти(ДоступнаяВерсия.Алиас, "Алиас");
		Если СтрокаВсеВерсии = Неопределено Тогда
			СтрокаВсеВерсии = ВсеВерсии.Добавить();
			СтрокаВсеВерсии.Алиас = ДоступнаяВерсия.Алиас;
			СтрокаВсеВерсии.ЭтоСимлинк = Ложь;	
		КонецЕсли;
		
		СтрокаВсеВерсии.ПутьСервер = ДоступнаяВерсия.Путь;
	КонецЦикла;

	Для Каждого УстановленнаяВерсия Из СписокУстановленныхВерсий Цикл	
		СтрокаВсеВерсии = ВсеВерсии.Найти(УстановленнаяВерсия.Алиас, "Алиас");
		Если СтрокаВсеВерсии = Неопределено Тогда
			СтрокаВсеВерсии = ВсеВерсии.Добавить();
			СтрокаВсеВерсии.Алиас = УстановленнаяВерсия.Алиас;
			СтрокаВсеВерсии.ЭтоСимлинк = УстановленнаяВерсия.ЭтоСимлинк;	
		КонецЕсли;
		
		СтрокаВсеВерсии.Версия = УстановленнаяВерсия.Версия;
		СтрокаВсеВерсии.ПутьЛокальный = УстановленнаяВерсия.Путь;
	КонецЦикла;
	
	ВсеВерсии.Сортировать("Алиас");
	
	Возврат ВсеВерсии;

КонецФункции

Функция ПолучитьТочнуюВерсиюOneScript(Знач ПроверяемаяВерсия)

	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ПроверяемаяВерсия);
	ПутьКИсполняемомуФайлу = ОбъединитьПути(КаталогУстановкиВерсии, "bin", "oscript.exe");
	
	Команда = Новый Команда();
	
	Если ЭтоWindows Тогда
		Команда.УстановитьКоманду(ПутьКИсполняемомуФайлу);
	Иначе
		Команда.УстановитьКоманду("mono");
		Команда.ДобавитьПараметр(ПутьКИсполняемомуФайлу);
	КонецЕсли;
	
	Команда.ДобавитьПараметр("-version");
	
	Команда.Исполнить();
	
	ВыводКоманды = СокрЛП(Команда.ПолучитьВывод());
	Если СтрЧислоСтрок(ВыводКоманды) > 1 Тогда
		РегулярноеВыражение = Новый РегулярноеВыражение("Version (\d+\.\d+\.\d+\.\d+)");
		Совпадения = РегулярноеВыражение.НайтиСовпадения(ВыводКоманды);
		Если Совпадения.Количество() = 1 Тогда
			ВыводКоманды = Совпадения[0].Группы[1].Значение;
		Иначе
			ВыводКоманды = "unknown";
		КонецЕсли;
	КонецЕсли;

	Возврат ВыводКоманды;
	
КонецФункции

Функция ПолучитьПутьКУстановленнойВерсии(Знач УстановленнаяВерсия) Экспорт
	УстановленныеВерсии = ПолучитьСписокУстановленныхВерсий();
	ПроцессорКоллекций = Новый ПроцессорКоллекций();
	ПроцессорКоллекций.УстановитьКоллекцию(УстановленныеВерсии);

	ДополнительныеПараметры = Новый Структура("УстановленнаяВерсия", УстановленнаяВерсия);
	ПутьКУстановленнойВерсии = ПроцессорКоллекций
		.Фильтровать(
			"Результат = Элемент.Алиас = ДополнительныеПараметры.УстановленнаяВерсия",
			ДополнительныеПараметры
		)
		.Обработать("Результат = Элемент.Путь")
		.Обработать("Результат = ОбъединитьПути(Элемент, ""bin"", ""oscript.exe"")")
		.ПолучитьПервый();
	
	Возврат ПутьКУстановленнойВерсии;
	
КонецФункции

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;
