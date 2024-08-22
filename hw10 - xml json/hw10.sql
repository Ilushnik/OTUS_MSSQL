/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML.
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice

Загрузить эти данные в таблицу Warehouse.StockItems:
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName).

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
--open XML
DECLARE @xml XML
SELECT @xml = BulkColumn
FROM OPENROWSET(BULK '/home/hw10 - xml json/StockItems.xml', SINGLE_BLOB) x;

SELECT @xml;
DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xml;

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
             WITH (
                 [StockItemName] NVARCHAR(50) '@Name',
                 [ID] INT 'SupplierID',
                 [UnitPackageID] INT 'Package/UnitPackageID',
                 [OuterPackageID] INT 'Package/OuterPackageID',
                 [QuantityPerOuter] INT 'Package/QuantityPerOuter',
                 [TypicalWeightPerUnit] float 'Package/TypicalWeightPerUnit',
                 [LeadTimeDays] NVARCHAR(100) 'LeadTimeDays',
                 [IsChillerStock] bit 'IsChillerStock',
                 [TaxRate] FLOAT 'TaxRate');

MERGE INTO Warehouse.StockItems si
USING (SELECT *
       FROM OPENXML(@docHandle, N'/StockItems/Item')
                    WITH (
                        [StockItemName] NVARCHAR(50) '@Name',
                        [SupplierID] INT 'SupplierID',
                        [UnitPackageID] INT 'Package/UnitPackageID',
                        [OuterPackageID] INT 'Package/OuterPackageID',
                        [QuantityPerOuter] INT 'Package/QuantityPerOuter',
                        [TypicalWeightPerUnit] float 'Package/TypicalWeightPerUnit',
                        [LeadTimeDays] NVARCHAR(100) 'LeadTimeDays',
                        [IsChillerStock] bit 'IsChillerStock',
                        [TaxRate] FLOAT 'TaxRate',
                        [UnitPrice] FLOAT 'UnitPrice'
                        )) source
ON si.StockItemName = source.StockItemName
WHEN MATCHED THEN
    UPDATE
    SET si.UnitPackageID        = source.UnitPackageID,
        si.OuterPackageID       = source.OuterPackageID,
        si.QuantityPerOuter     = source.QuantityPerOuter,
        si.TypicalWeightPerUnit = source.TypicalWeightPerUnit,
        si.LeadTimeDays         = source.LeadTimeDays,
        si.IsChillerStock       = source.IsChillerStock,
        si.TaxRate              = source.TaxRate
WHEN NOT MATCHED THEN
    INSERT (SupplierID,
            StockItemName,
            UnitPackageID,
            OuterPackageID,
            QuantityPerOuter,
            TypicalWeightPerUnit,
            LeadTimeDays,
            IsChillerStock,
            TaxRate,
            UnitPrice,
            LastEditedBy)
    VALUES (source.SupplierID,
            source.StockItemName,
            source.UnitPackageID,
            source.OuterPackageID,
            source.QuantityPerOuter,
            source.TypicalWeightPerUnit,
            source.LeadTimeDays,
            source.IsChillerStock,
            source.TaxRate,
            source.UnitPrice,
            1);


----- XQuery ----
DECLARE @xml XML
SELECT @xml = BulkColumn
FROM OPENROWSET(BULK '/home/hw10 - xml json/StockItems.xml', SINGLE_BLOB) x;

SELECT t.Item.VALUE('(@Name)[1]', 'varchar(100)') AS [StockItemName],
       t.Item.VALUE('(SupplierID)[1]', 'int') AS [SupplierID],
       t.Item.VALUE('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID],
       t.Item.VALUE('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
       t.Item.VALUE('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
       t.Item.VALUE('(Package/TypicalWeightPerUnit)[1]', 'float') AS [TypicalWeightPerUnit],
       t.Item.VALUE('(LeadTimeDays)[1]', 'int') AS [LeadTimeDays],
       t.Item.VALUE('(IsChillerStock)[1]', 'bit') AS [IsChillerStock],
       t.Item.VALUE('(TaxRate)[1]', 'float') AS [TaxRate],
       t.Item.VALUE('(TaxRate)[1]', 'float') AS [TaxRate]
FROM @xml.NODES('/StockItems/Item') AS t(Item);

MERGE INTO Warehouse.StockItems si
USING (SELECT t.Item.VALUE('(@Name)[1]', 'varchar(100)') AS [StockItemName],
              t.Item.VALUE('(SupplierID)[1]', 'int') AS [SupplierID],
              t.Item.VALUE('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID],
              t.Item.VALUE('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
              t.Item.VALUE('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
              t.Item.VALUE('(Package/TypicalWeightPerUnit)[1]', 'float') AS [TypicalWeightPerUnit],
              t.Item.VALUE('(LeadTimeDays)[1]', 'int') AS [LeadTimeDays],
              t.Item.VALUE('(IsChillerStock)[1]', 'bit') AS [IsChillerStock],
              t.Item.VALUE('(TaxRate)[1]', 'float') AS [TaxRate],
              t.Item.VALUE('(UnitPrice)[1]', 'float') AS [UnitPrice]
       FROM @xml.NODES('/StockItems/Item') AS t(Item)) source
ON si.StockItemName = source.StockItemName
WHEN MATCHED THEN
    UPDATE
    SET si.UnitPackageID        = source.UnitPackageID,
        si.OuterPackageID       = source.OuterPackageID,
        si.QuantityPerOuter     = source.QuantityPerOuter,
        si.TypicalWeightPerUnit = source.TypicalWeightPerUnit,
        si.LeadTimeDays         = source.LeadTimeDays,
        si.IsChillerStock       = source.IsChillerStock,
        si.TaxRate              = source.TaxRate
WHEN NOT MATCHED THEN
    INSERT (SupplierID,
            StockItemName,
            UnitPackageID,
            OuterPackageID,
            QuantityPerOuter,
            TypicalWeightPerUnit,
            LeadTimeDays,
            IsChillerStock,
            TaxRate,
            UnitPrice,
            LastEditedBy)
    VALUES (source.SupplierID,
            source.StockItemName,
            source.UnitPackageID,
            source.OuterPackageID,
            source.QuantityPerOuter,
            source.TypicalWeightPerUnit,
            source.LeadTimeDays,
            source.IsChillerStock,
            source.TaxRate,
            source.UnitPrice,
            1);

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- экспорт не работает в линукс версии MSSQL. Проверить не удалось
-- https://stackoverflow.com/questions/59971345/cannot-enable-xp-cmdshell-on-sql-server-2017-express-on-linux
EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE

SELECT TOP 5 StockItemName AS [@Name],
             SupplierID,
             UnitPackageID AS [Package/UnitPackageID],
             OuterPackageID AS [Package/OuterPackageID],
             QuantityPerOuter AS [Package/QuantityPerOuter],
             TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
             LeadTimeDays,
             IsChillerStock,
             TaxRate,
             UnitPrice
FROM Warehouse.StockItems si
FOR XML PATH ('Item'), ROOT('StockItems');

DROP TABLE IF EXISTS ##AuditLogTempTable

SELECT A.MyXML
INTO ##AuditLogTempTable
FROM (SELECT CONVERT(nvarchar(max),
                     (SELECT TOP 5 StockItemName AS [@Name],
                                   SupplierID,
                                   UnitPackageID AS [Package/UnitPackageID],
                                   OuterPackageID AS [Package/OuterPackageID],
                                   QuantityPerOuter AS [Package/QuantityPerOuter],
                                   TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
                                   LeadTimeDays,
                                   IsChillerStock,
                                   TaxRate,
                                   UnitPrice
                      FROM Warehouse.StockItems si
                      FOR XML PATH ('Item'), ROOT('StockItems'))
                 , 0
                 ) AS MyXML) A

EXEC xp_cmdshell
     'bcp "SELECT MyXML FROM ##AuditLogTempTable" queryout "/home/hw10 - xml json/StockItemsExported.xml" -T -c -t,'


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT si.StockItemID, si.StockItemName, si.CustomFields,
       JSON_VALUE(si.CustomFields, '$.CountryOfManufacture'),
       JSON_VALUE(si.CustomFields, '$.Tags[0]')
FROM Warehouse.StockItems si

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%'
*/


SELECT si.StockItemID, si.StockItemName, si.CustomFields from Warehouse.StockItems si
cross APPLY OpenJson(si.CustomFields, '$.Tags')
WHERE value = 'Vintage'