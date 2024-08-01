/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select FORMAT(I.InvoiceDate, 'yyyy')          as year,
       FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru') as month,
       avg(OL.Quantity * Ol.UnitPrice)        as AVG,
       sum(OL.Quantity * Ol.UnitPrice)        as SUM
from Sales.Invoices I
         inner join Sales.Orders O on O.OrderID = I.OrderID
         inner join Sales.OrderLines OL on O.OrderID = OL.OrderID
group by FORMAT(I.InvoiceDate, 'yyyy'), FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru')

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select FORMAT(I.InvoiceDate, 'yyyy')          as year,
       FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru') as month,
       avg(OL.Quantity * Ol.UnitPrice)        as AVG,
       sum(OL.Quantity * Ol.UnitPrice)        as SUM
from Sales.Invoices I
         inner join Sales.Orders O on O.OrderID = I.OrderID
         inner join Sales.OrderLines OL on O.OrderID = OL.OrderID
group by FORMAT(I.InvoiceDate, 'yyyy'), FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru')
having sum(OL.Quantity * Ol.UnitPrice) > 4600000

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/


select FORMAT(I.InvoiceDate, 'yyyy')          as year,
       FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru') as month,
       SI.StockItemName                       as ItemName,
       sum(OL.Quantity * Ol.UnitPrice)        as SUM,
       (select top 1 OInn.OrderDate
        from Sales.OrderLines olInn
                 inner join Sales.Orders OInn on OInn.OrderID = olInn.OrderID
        where olInn.StockItemID = SI.StockItemID
        order by OInn.OrderDate)
from Sales.Invoices I
         inner join Sales.Orders O on O.OrderID = I.OrderID
         inner join Sales.OrderLines OL on O.OrderID = OL.OrderID
         inner join Warehouse.StockItems SI on SI.StockItemID = OL.StockItemID
group by FORMAT(I.InvoiceDate, 'yyyy'), FORMAT(I.InvoiceDate, 'MMMM', 'ru-ru'), SI.StockItemID, SI.StockItemName
having sum(OL.Quantity) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

;with result as (select FORMAT(I.InvoiceDate, 'yyyy')            as year,
                       CAST(FORMAT(I.InvoiceDate, 'MM') as INT) as month,
                       avg(OL.Quantity * Ol.UnitPrice)          as AVG,
                       sum(OL.Quantity * Ol.UnitPrice)          as SUM
                from Sales.Invoices I
                         inner join Sales.Orders O on O.OrderID = I.OrderID
                         inner join Sales.OrderLines OL on O.OrderID = OL.OrderID
                group by FORMAT(I.InvoiceDate, 'yyyy'), CAST(FORMAT(I.InvoiceDate, 'MM') as INT)
                having sum(OL.Quantity * Ol.UnitPrice) > 4600000),
     dateRange as (select y.year, months.MonthNumber
                   from (select distinct r.year from result r) y
                            cross join (SELECT DATENAME(MONTH, DATEADD(MM, s.number, CONVERT(DATETIME, 0))) AS [MonthName],
                                               MONTH(DATEADD(MM, s.number, CONVERT(DATETIME, 0)))           AS [MonthNumber]
                                        FROM master.dbo.spt_values s
                                        WHERE [type] = 'P'
                                          AND s.number BETWEEN 0 AND 11) months)
select dRange.year as year, dRange.MonthNumber, isnull(res.AVG, 0) as AVG, isnull(res.SUM, 0) as SUM
from dateRange dRange
         left join result res on dRange.year = res.year and dRange.MonthNumber = res.month



/*SELECT DATENAME(MONTH, DATEADD(MM, s.number, CONVERT(DATETIME, 0))) AS [MonthName],
       MONTH(DATEADD(MM, s.number, CONVERT(DATETIME, 0)))           AS [MonthNumber]
FROM master.dbo.spt_values s
WHERE [type] = 'P'
  AND s.number BETWEEN 0 AND 11
ORDER BY 2


select *
from (values (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) v(monthsNumbers)*/