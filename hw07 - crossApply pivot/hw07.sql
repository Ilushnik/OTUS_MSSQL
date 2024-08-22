/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

/*
SELECT
  c.CustomerName, o.OrderDate, COUNT(*) AS OrderCount
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE o.CustomerID IN (2, 3, 4)
group by o.OrderDate, c.CustomerName*/

WITH CustomerPurchase AS (
 SELECT
  c.CustomerName,  DATEADD(DAY,1,EOMONTH(o.OrderDate,-1)) AS OrderDate, COUNT(*) AS OrderCount
FROM Sales.Orders o
INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE o.CustomerID IN (2, 3, 4)
group BY DATEADD(DAY,1,EOMONTH(o.OrderDate,-1)) , c.CustomerName
)
SELECT FORMAT(p.OrderDate, 'dd.MM.yyyy')
      ,p.[Tailspin Toys (Medicine Lodge, KS)] AS [Medicine Lodge, KS]
      ,p.[Tailspin Toys (Peeples Valley, AZ)] AS [Peeples Valley, AZ]
      ,p.[Tailspin Toys (Sylvanite, MT)] AS [Sylvanite, MT]
FROM (
	SELECT *
	FROM CustomerPurchase cp
) t
PIVOT (
	SUM(OrderCount)
	FOR CustomerName IN ([Tailspin Toys (Medicine Lodge, KS)], [Tailspin Toys (Peeples Valley, AZ)], [Tailspin Toys (Sylvanite, MT)])
) p
ORDER BY p.orderdate;




/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

WITH AddressList AS (
SELECT DeliveryAddressLine1 FROM Sales.Customers UNION ALL
SELECT DeliveryAddressLine2 FROM Sales.Customers UNION ALL
SELECT PostalAddressLine1 FROM Sales.Customers UNION ALL
SELECT PostalAddressLine2 FROM Sales.Customers
)
SELECT c.CustomerName, a.DeliveryAddressLine1 AS AddressLine FROM Sales.Customers c
CROSS APPLY AddressList a
WHERE c.CustomerName LIKE 'Tailspin Toys%'

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так,
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT
  c.CountryID
 ,c.CountryName
 ,c2.Code
FROM Application.Countries c
CROSS APPLY (SELECT
    CAST(c2.IsoNumericCode AS NVARCHAR(3)) AS Code
  FROM Application.Countries c2
  WHERE c2.CountryID = c.CountryID
  UNION ALL
  SELECT
    c3.IsoAlpha3Code
  FROM Application.Countries c3
  WHERE c3.CountryID = c.CountryID) c2
ORDER BY c.CountryID

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT
  c.CustomerID
 ,c.CustomerName
 ,p.StockItemID
 ,p.UnitPrice
 ,p.OrderDate
FROM Sales.Customers c
CROSS APPLY (SELECT TOP 2
    o.OrderDate
   ,ol.UnitPrice
   ,ol.StockItemID
  FROM Sales.Orders o
  INNER JOIN Sales.OrderLines ol
    ON o.OrderID = ol.OrderID
  WHERE o.CustomerID = c.CustomerID
  ORDER BY ol.UnitPrice DESC) p

