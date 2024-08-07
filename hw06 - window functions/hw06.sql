/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

;
WITH dates AS (SELECT i2.InvoiceDate, FORMAT(i2.InvoiceDate, 'MM.yyyy') AS dateGroup
               FROM Sales.Invoices i2
               GROUP BY i2.InvoiceDate),
     totalByDate AS (
         (SELECT i2.InvoiceDate,
                 SUM(ol.Quantity * ol.UnitPrice) totalSum,
                 FORMAT(i2.InvoiceDate, 'MM.yyyy') AS dateGroup
          FROM Sales.Invoices i2
                   INNER JOIN Sales.OrderLines ol ON i2.OrderID = ol.OrderID
          GROUP BY i2.InvoiceDate))
SELECT d.InvoiceDate,
       d.dategroup,
       (SELECT SUM(tinn.totalsum)
        FROM totalbydate tInn
        WHERE tinn.InvoiceDate BETWEEN '20150101' AND EOMONTH(d.InvoiceDate)) AS sum
FROM dates d
WHERE d.InvoiceDate > '20150101'
ORDER BY d.InvoiceDate;


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
;
WITH dates AS (SELECT i2.InvoiceDate, FORMAT(i2.InvoiceDate, 'MM.yyyy') AS dateGroup
               FROM Sales.Invoices i2
               GROUP BY i2.InvoiceDate),
     totalByDateGroup AS (
         (SELECT FORMAT(i2.InvoiceDate, 'yyyyMM') dategrouporder,
                 FORMAT(i2.InvoiceDate, 'MM.yyyy') dateGroup,
                 SUM(ol.Quantity * ol.UnitPrice) totalSumMonth
          FROM Sales.Invoices i2
                   INNER JOIN Sales.OrderLines ol ON i2.OrderID = ol.OrderID
          WHERE i2.InvoiceDate >= '20150101'
          GROUP BY FORMAT(i2.InvoiceDate, 'yyyyMM'), FORMAT(i2.InvoiceDate, 'MM.yyyy'))),
     increasedTotal AS (SELECT g.dategroup,
                               g.dategrouporder,
                               g.totalSumMonth,
                               SUM(g.totalsummonth) OVER ( ORDER BY g.dategrouporder) totalIncreased
                        FROM totalbydategroup g)

SELECT d.InvoiceDate, t.dategroup, t.totalincreased
FROM dates d
         LEFT JOIN increasedTotal t ON d.dategroup = t.dategroup
WHERE d.InvoiceDate >= '20150101'
ORDER BY InvoiceDate
;


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных)
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;
WITH soldItems AS (SELECT i.InvoiceDate,
                          FORMAT(i.InvoiceDate, 'yyyyMM') AS month,
                          ol.Quantity,
                          ol.StockItemID,
                          SUM(ol.Quantity)
                              OVER ( PARTITION BY ol.StockItemID, FORMAT(i.InvoiceDate, 'yyyyMM') ) AS totalSold
                   FROM Sales.Invoices i
                            INNER JOIN Sales.OrderLines ol ON i.OrderID = ol.OrderID
                   WHERE i.InvoiceDate BETWEEN '20160101' AND '20161231'),
     soldItemsRanks AS (SELECT *, DENSE_RANK() OVER ( PARTITION BY si.month ORDER BY si.totalSold DESC ) rank
                        FROM soldItems si)
SELECT DISTINCT sir.month, sir.StockItemID, s.StockItemName, sir.totalSold, sir.rank
FROM soldItemsRanks sir
         LEFT JOIN Warehouse.StockItems S ON S.StockItemID = sir.StockItemID
WHERE sir.rank < 3
ORDER BY month, sir.totalSold DESC
;
/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT SI.StockItemID,
       SI.StockItemName,
       SI.Brand,
       SI.UnitPrice,
       COUNT(*) OVER ( ) totalItems,
       LEFT(SI.StockItemName, 1) firstletter,
       COUNT(*) OVER (
           PARTITION BY LEFT(SI.StockItemName, 1)
           ORDER BY LEFT(SI.StockItemName, 1)) totalItemsByFirstLetter,
       LAG(SI.StockItemID, 1) OVER (ORDER BY SI.StockItemName),
       ISNULL(LAG(SI.StockItemName, 2) OVER (ORDER BY SI.StockItemName), 'No items'),
       NTILE(30) OVER (ORDER BY si.TypicalWeightPerUnit)
FROM Warehouse.StockItems SI
;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

WITH customersOrdersRanks AS (SELECT o.SalespersonPersonID,
                                     o.CustomerID,
                                     o.OrderID,
                                     DENSE_RANK() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate DESC ) AS LatestRankOrder
                              FROM Sales.Orders o)
SELECT c.SalespersonPersonID,
       p.FullName,
       c.CustomerID,
       c2.CustomerName,
       o2.OrderDate,
       (SELECT SUM(ol.UnitPrice * ol.Quantity) AS OrderSum
        FROM Sales.OrderLines ol
        WHERE ol.OrderID = o2.OrderID) OrderSum
FROM customersOrdersRanks c
         LEFT JOIN Application.People p ON p.PersonID = c.SalespersonPersonID
         LEFT JOIN Sales.Customers c2 ON c2.CustomerID = c.CustomerID
         LEFT JOIN Sales.Orders o2 ON o2.OrderID = c.OrderID
WHERE c.latestrankorder = 1
;
/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;
WITH
CustomerItemsCostsRank AS (SELECT ol.OrderID,
                                  ol.StockItemID,
                                  ol.UnitPrice,
                                  o.CustomerID,
                                  ROW_NUMBER() OVER ( PARTITION BY o.CustomerID ORDER BY ol.UnitPrice DESC ) ItemSumRank
                           FROM Sales.OrderLines ol
                                    INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID)
SELECT cr.itemsumrank,
       cr.CustomerID,
       c.CustomerName,
       cr.StockItemID,
       cr.UnitPrice,
       (SELECT TOP 1 o.OrderDate FROM Sales.Orders o WHERE o.OrderID = cr.OrderID) OrderDate
FROM CustomerItemsCostsRank cr
         INNER JOIN Sales.Customers c ON c.CustomerID = cr.CustomerID
WHERE cr.ItemSumRank <= 2
ORDER BY CustomerID