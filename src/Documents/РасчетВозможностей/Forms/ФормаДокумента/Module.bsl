
&НаКлиенте
Процедура Рассчитать(Команда)
	РассчитатьНаСервере();
КонецПроцедуры

&НаСервере
Процедура РассчитатьНаСервере()
	Если Не ЗначениеЗаполнено(Объект.Дата) Тогда
		Объект.Дата = ТекущаяДата();
	КонецЕсли;
	
	ДеревоЗначений = РеквизитФормыВЗначение("Дерево");
	ДеревоЗначений.Строки.Очистить();
	 
	Запрос = Новый Запрос();
	
	Запрос.МенеджерВременныхТаблиц = Новый МенеджерВременныхТаблиц();
	Запрос.Текст = "ВЫБРАТЬ
	|	КамниОстатки.Камень КАК Предмет,
	|	КамниОстатки.КоличествоВНаличииОстаток КАК КоличествоВНаличии
	|ПОМЕСТИТЬ ВТОстатки
	|ИЗ
	|	РегистрНакопления.Камни.Остатки(&Период,) КАК КамниОстатки
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	РуныОстатки.Руна,
	|	РуныОстатки.КоличествоВНаличииОстаток
	|ИЗ
	|	РегистрНакопления.Руны.Остатки(&Период,) КАК РуныОстатки
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	РецептыРецепт.Ссылка.Результат КАК Рецепт,
	|	РецептыРецепт.Предмет КАК Составляющие,
	|	РецептыРецепт.Количество
	|ПОМЕСТИТЬ ВТРецепты
	|ИЗ
	|	Справочник.Рецепты.Рецепт КАК РецептыРецепт
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	РунныеСловаРуны.Ссылка КАК Ссылка,
	|	РунныеСловаРуны.Руна,
	|	Количество(РунныеСловаРуны.Руна) КАК Количество,
	|	СУММА(ЕСТЬNULL(ВТОстатки.КоличествоВНаличии, 0)) КАК КоличествоВНаличии
	|ИЗ
	|	Справочник.РунныеСлова.Руны КАК РунныеСловаРуны
	|		ЛЕВОЕ СОЕДИНЕНИЕ ВТОстатки КАК ВТОстатки
	|		ПО РунныеСловаРуны.Руна = ВТОстатки.Предмет
	|СГРУППИРОВАТЬ ПО
	|	РунныеСловаРуны.Руна,
	|	РунныеСловаРуны.Ссылка
	|ИТОГИ
	|ПО
	|	Ссылка";
	Запрос.УстановитьПараметр("Период", Объект.Дата);
	ВыборкаРунныеСлова = Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	
	Кэш = Новый Соответствие();
	ОбщийКэш = Новый Соответствие();
	ДополнительныеПараметры = Новый Структура();
	Пока ВыборкаРунныеСлова.Следующий() Цикл
		КорневаяСтрокаДерева = ДеревоЗначений.Строки.Добавить();
		КорневаяСтрокаДерева.Предмет = ВыборкаРунныеСлова.Ссылка;
		
		ВыборкаРуны = ВыборкаРунныеСлова.Выбрать();
		Пока ВыборкаРуны.Следующий() Цикл
			НоваяСтрокаРуна = КорневаяСтрокаДерева.Строки.Добавить();
			НоваяСтрокаРуна.Предмет = ВыборкаРуны.Руна;
			НоваяСтрокаРуна.КоличествоТребуемоеНаЕдиницу = ВыборкаРуны.Количество;
			НоваяСтрокаРуна.КоличествоВНаличии = ВыборкаРуны.КоличествоВНаличии;
			ЗаполнитьРецептСРекурсивно(НоваяСтрокаРуна, Запрос, Кэш, ОбщийКэш, ДополнительныеПараметры);
		КонецЦикла;
		РассчитатьРекурсивно(КорневаяСтрокаДерева);
	КонецЦикла;
	ЗначениеВРеквизитФормы(ДеревоЗначений, "Дерево");
КонецПроцедуры

&НаСервере
Процедура ПередЗаписьюНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	ДеревоЗначений = РеквизитФормыВЗначение("Дерево");
	ТекущийОбъект.ДеревоРасчета = Новый ХранилищеЗначения(ДеревоЗначений);
КонецПроцедуры

&НаСервере
Процедура ПриЧтенииНаСервере(ТекущийОбъект)
	ДеревоЗначений = ТекущийОбъект.ДеревоРасчета.Получить();
	Если ДеревоЗначений <> Неопределено Тогда
		ДеревоВрем = РеквизитФормыВЗначение("Дерево");
		Для Каждого СтрокаВрем ИЗ ДеревоЗначений.Строки Цикл
			НоваяСтрока = ДеревоВрем.Строки.Добавить();
			ЗаполнитьЗначенияСвойств(НоваяСтрока, СтрокаВрем);
			СкопироватьРекурсивно(НоваяСтрока, СтрокаВрем);
		КонецЦикла;
		
		ЗначениеВРеквизитФормы(ДеревоВрем, "Дерево");
	КонецЕсли;
	
КонецПроцедуры



// Заполнить рецепт с рекурсивно.
// 
// Параметры:
//  СтрокаДереваРецепт - см. Документ.РасчетВозможностей.Форма.ФормаДокумента.Дерево
Процедура ЗаполнитьРецептСРекурсивно(СтрокаДереваРецепт,
									 Запрос,
									 Знач КэшПодчиненнойВетки,
									 ОбщийКэш,
									 ДополнительныеПараметры)
	
	
	КэшВетки = Новый Соответствие();
	Для Каждого Соответствие Из КэшПодчиненнойВетки Цикл
		КэшВетки.Вставить(Соответствие.Ключ, Соответствие.Значение);
	КонецЦикла;
	КэшПодчиненнойВетки = КэшВетки; // СтрокаДереваРецепт - см. Документ.РасчетВозможностей.Форма.ФормаДокумента.Дерево
		
	Если КэшПодчиненнойВетки[СтрокаДереваРецепт.Предмет] <> Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	СуществующаяВетка = ОбщийКэш[СтрокаДереваРецепт.Предмет]; // СтрокаДереваРецепт - см. Документ.РасчетВозможностей.Форма.ФормаДокумента.Дерево 
	Если СуществующаяВетка <> Неопределено Тогда
		СкопироватьРекурсивно(СтрокаДереваРецепт, СуществующаяВетка);
		Возврат;
	КонецЕсли;
	
	Запрос.Текст = "ВЫБРАТЬ
	|	ВТРецепты.Рецепт,
	|	ВТРецепты.Составляющие,
	|	ВТРецепты.Количество,
	|	ЕСТЬNULL(ВТОстатки.КоличествоВНаличии, 0) КАК КоличествоВНаличии
	|ИЗ
	|	ВТРецепты КАК ВТРецепты
	|		ЛЕВОЕ СОЕДИНЕНИЕ ВТОстатки КАК ВТОстатки
	|		ПО ВТРецепты.Составляющие = ВТОстатки.Предмет
	|ГДЕ
	|	ВТРецепты.Рецепт В (&Рецепты)";
	Запрос.УстановитьПараметр("Рецепты", СтрокаДереваРецепт.Предмет);
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		НоваяСтрокаПредмет = СтрокаДереваРецепт.Строки.Добавить();
		НоваяСтрокаПредмет.Предмет = Выборка.Составляющие;
		НоваяСтрокаПредмет.КоличествоТребуемоеНаЕдиницу = Выборка.Количество;
		НоваяСтрокаПредмет.КоличествоВНаличии = Выборка.КоличествоВНаличии;
		КэшПодчиненнойВетки[СтрокаДереваРецепт.Предмет] = СтрокаДереваРецепт;
		ОбщийКэш[СтрокаДереваРецепт.Предмет] = СтрокаДереваРецепт;
		ЗаполнитьРецептСРекурсивно(НоваяСтрокаПредмет, Запрос, КэшПодчиненнойВетки, ОбщийКэш, ДополнительныеПараметры);		
	КонецЦикла;
	
КонецПроцедуры

// Рассчитать рекурсивно.
// 
// Параметры:
//  СтрокаДереваРецепт - см. Документ.РасчетВозможностей.Форма.ФормаДокумента.Дерево 
Процедура РассчитатьРекурсивно(СтрокаДереваРецепт)
	ВозможноеКоличество = 0;
	ВозможноеКоличествоСКрафтом = 0;
	Расчитано = Ложь;
	Для Каждого ПодчиненнаяСтрока Из СтрокаДереваРецепт.Строки Цикл
		РассчитатьРекурсивно(ПодчиненнаяСтрока);
		
		
		РасчетноеВозможноеКоличество = (ПодчиненнаяСтрока.КоличествоВНаличии  / ПодчиненнаяСтрока.КоличествоТребуемоеНаЕдиницу);
		РасчетноеВозможноеКоличествоСКрафтом = ((ПодчиненнаяСтрока.КоличествоВНаличии + ПодчиненнаяСтрока.КоличествоВозможное) / ПодчиненнаяСтрока.КоличествоТребуемоеНаЕдиницу);
		Если Расчитано Тогда
			ВозможноеКоличество = Мин(ВозможноеКоличество, Цел(РасчетноеВозможноеКоличество));
			ВозможноеКоличествоСКрафтом = Мин(ВозможноеКоличествоСКрафтом, Цел(РасчетноеВозможноеКоличествоСКрафтом));
		Иначе
			ВозможноеКоличество = Цел(РасчетноеВозможноеКоличество);
			ВозможноеКоличествоСКрафтом = Цел(РасчетноеВозможноеКоличествоСКрафтом);
			Расчитано = Истина;
		КонецЕсли;		
	КонецЦикла;
	СтрокаДереваРецепт.КоличествоВозможное = ВозможноеКоличество;
	СтрокаДереваРецепт.КоличествоВозможноеСУчетомКрафта = ВозможноеКоличествоСКрафтом;
КонецПроцедуры


// Скопировать рекурсивно.
// 
// Параметры:
//  СтрокаДереваПриемник - СтрокаДереваЗначений - Строка дерева приемник
//  СтрокаДереваИсточник - СтрокаДереваЗначений - Строка дерева источник
Процедура СкопироватьРекурсивно(СтрокаДереваПриемник, СтрокаДереваИсточник)
	Для Каждого ПодчиненнаяСтрока ИЗ СтрокаДереваИсточник.Строки Цикл
		НоваяСтрока = СтрокаДереваПриемник.Строки.Добавить();
		ЗаполнитьЗначенияСвойств(НоваяСтрока, ПодчиненнаяСтрока);
		СкопироватьРекурсивно(НоваяСтрока, ПодчиненнаяСтрока);
	КонецЦикла;
КонецПроцедуры

&НаКлиенте
Процедура ОткрытьОписание(Команда)
	МассивРун = Новый Массив();
	ОбработанныеСтроки = Новый Массив();
	Для Каждого ИдентификаторСтроки Из Элементы.Дерево.ВыделенныеСтроки Цикл
		Если ОбработанныеСтроки.Найти(ИдентификаторСтроки) <> Неопределено Тогда
			Продолжить;
		КонецЕсли;
		
		СтрокаДерева = Дерево.НайтиПоИдентификатору(ИдентификаторСтроки);
		Родитель = СтрокаДерева.ПолучитьРодителя();
		Пока Родитель <> Неопределено Цикл
			СтрокаДерева = Родитель;
			Родитель = СтрокаДерева.ПолучитьРодителя();
			ОбработанныеСтроки.Добавить(ИдентификаторСтроки);
		КонецЦикла;
		МассивРун.Добавить(СтрокаДерева.Предмет);
	КонецЦикла;
	
	ПараметрыОткрытия = Новый Структура("Руны", МассивРун);
	ОткрытьФорму("Отчет.ДоступныеСлова.Форма", ПараметрыОткрытия);
КонецПроцедуры
