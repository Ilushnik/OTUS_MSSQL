/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson),
и не сделали ни одной продажи 04 июля 2015 года.
Вывести ИД сотрудника и его полное имя.
Продажи смотреть в таблице Sales.Invoices.
*/

select p.PersonID, p.FullName
from Application.People p
where p.IsSalesperson = 1
  and NOT exists(select i.SalespersonPersonID, i.InvoiceDate
             from Sales.Invoices i
             where i.InvoiceDate = '20150704'
               and I.SalespersonPersonID = p.PersonID)
;
WITH sales (SalePersonId) as (select DISTINCT i.SalespersonPersonID
                                        from Sales.Invoices i
                                        where i.InvoiceDate = '20150704'
                             )
select distinct p.PersonID, p.FullName, s.SalePersonId
from Application.People p
         LEFT join sales s on s.SalePersonId = p.PersonID
where p.IsSalesperson = 1 and s.SalePersonId is NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса.
Вывести: ИД товара, наименование товара, цена.
*/

select si.StockItemID, si.StockItemName, si.UnitPrice
from Warehouse.StockItems si
where UnitPrice = (select min(siInn.UnitPrice)
                   from Warehouse.StockItems siInn)
;
with LowestItemPrice (ItemId) as (select top 1 siInn.StockItemID
                                  from Warehouse.StockItems siInn
                                  order by siInn.UnitPrice)
select si.StockItemID, si.StockItemName, si.UnitPrice
from Warehouse.StockItems si
         inner join LowestItemPrice on LowestItemPrice.ItemId = si.StockItemID


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей
из Sales.CustomerTransactions.
Представьте несколько способов (в том числе с CTE).
*/

select top 5 *
from Sales.CustomerTransactions ct
order by ct.TransactionAmount desc

select *
from Application.People
where People.PersonID in
      (select top 5 ct.CustomerID from Sales.CustomerTransactions ct order by ct.TransactionAmount desc)
;
with top5Payments as (select top 5 ct.CustomerID from Sales.CustomerTransactions ct order by ct.TransactionAmount desc)
select *
from Application.People p
         inner join top5Payments t on t.CustomerID = p.PersonID

/*
4. Выберите города (ид и название), в которые были доставлены товары,
входящие в тройку самых дорогих товаров, а также имя сотрудника,
который осуществлял упаковку заказов (PackedByPersonID).
*/

select Cities.CityID, Cities.CityName, o.PickedByPersonID, *
from Sales.OrderLines ol
         inner join Sales.Orders O on O.OrderID = ol.OrderID
         inner join (select top 3 si.StockItemID, si.StockItemName
                     from Warehouse.StockItems si
                     order by si.UnitPrice desc) topItems on topItems.StockItemID = ol.StockItemID
         inner join Sales.Customers c on O.CustomerID = c.CustomerID
         inner join Application.Cities on c.DeliveryCityID = Cities.CityID
;
with topItems as (select top 3 si.StockItemID, si.StockItemName
                  from Warehouse.StockItems si
                  order by si.UnitPrice desc)
select Cities.CityID, Cities.CityName, o.PickedByPersonID, *
from Sales.OrderLines ol
         inner join Sales.Orders O on O.OrderID = ol.OrderID
         inner join topItems on topItems.StockItemID = ol.StockItemID
         inner join Sales.Customers c on O.CustomerID = c.CustomerID
         inner join Application.Cities on c.DeliveryCityID = Cities.CityID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса,
-- так и в сторону упрощения плана\ускорения.
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON.
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы).
-- Напишите ваши рассуждения по поводу оптимизации.

-- 5. Объясните, что делает и оптимизируйте запрос
SELECT Invoices.InvoiceID,
       Invoices.InvoiceDate,
       (SELECT People.FullName
        FROM Application.People
        WHERE People.PersonID = Invoices.SalespersonPersonID)                 AS SalesPersonName,
       SalesTotals.TotalSumm                                                  AS TotalSummByInvoice,
       (SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
        FROM Sales.OrderLines
        WHERE OrderLines.OrderId = (SELECT Orders.OrderId
                                    FROM Sales.Orders
                                    WHERE Orders.PickingCompletedWhen IS NOT NULL
                                      AND Orders.OrderId = Invoices.OrderId)) AS TotalSummForPickedItems
FROM Sales.Invoices
         JOIN
     (SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
      FROM Sales.InvoiceLines
      GROUP BY InvoiceId
      HAVING SUM(Quantity * UnitPrice) > 27000) AS SalesTotals
     ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

--Запрос ищет счета выставвленные клиенту, которые превышают сумму 27000
--оотбражает данные по счету, продажнику, общую сумму счета,уже полученные товары клиентом на сумму

-- для улучшение читабельности убраны подзапросы, сложные запросы перемещены в CTE, добавлены псевданимы таблиц
-- для ускорения выполнения убраны подзапросы в select и объеденены 2 запроса на получение данных о общей суммы счета и оплаченного
-- большого прироста производительности не наблиюдается. Ускорение всего на 4%
/*;
with SalesTotals as (SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
                     FROM Sales.InvoiceLines il
                     GROUP BY InvoiceId),
     pickedItemsSum as (SELECT SUM(ol.PickedQuantity * ol.UnitPrice) as pickedTotalSum, ol.OrderId
                        FROM Sales.Orders o
                                 inner join Sales.OrderLines OL on o.OrderID = OL.OrderID
                        where o.PickingCompletedWhen is not null
                        group by ol.OrderID)
SELECT i.InvoiceID,
       i.InvoiceDate,
       p.FullName         AS SalesPersonName,
       st.TotalSumm       AS TotalSummByInvoice,
       pis.pickedTotalSum AS TotalSummForPickedItems
FROM Sales.Invoices i
         inner join SalesTotals st ON st.InvoiceID = i.InvoiceID
         inner join Application.People p on p.PersonID = i.SalespersonPersonID
         inner join pickedItemsSum pis on pis.OrderID = i.OrderID
where st.TotalSumm > 27000
ORDER BY TotalSumm DESC*/


with SalesTotals as (SELECT SUM(ol.PickedQuantity * ol.UnitPrice) as pickedTotalSum,
                            ol.OrderId,
                            SUM(Quantity * UnitPrice)             AS TotalSumm
                     FROM Sales.Orders o
                              inner join Sales.OrderLines OL on o.OrderID = OL.OrderID
                              inner join Sales.Invoices I2 on o.OrderID = I2.OrderID
                     where o.PickingCompletedWhen is not null
                     group by ol.OrderID
                     having SUM(ol.PickedQuantity * ol.UnitPrice) > 27000
                     )
SELECT i.InvoiceID,
       i.InvoiceDate,
       p.FullName        AS SalesPersonName,
       st.TotalSumm      AS TotalSummByInvoice,
       st.pickedTotalSum AS TotalSummForPickedItems
FROM Sales.Invoices i
         inner join Application.People p on p.PersonID = i.SalespersonPersonID
         inner join SalesTotals st on st.OrderID = i.OrderID
--where st.TotalSumm > 27000
ORDER BY TotalSumm DESC



