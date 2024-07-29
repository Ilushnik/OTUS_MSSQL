/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%'
   or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select *
from Purchasing.Suppliers s
         left join Purchasing.PurchaseOrders po on s.SupplierID = po.SupplierID
where po.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select o.OrderID,
       OrderDate,
       FORMAT(OrderDate, 'd', 'ru-ru')    as [дату заказа],
       FORMAT(OrderDate, 'MMMM', 'ru-ru') as [название месяца],
       datepart(quarter, OrderDate)       as 'номер квартала',
       (month(OrderDate) / 3) + 1         as 'треть года',
       CustomerName/*,
       UnitPrice,
       Quantity*/
from Sales.Orders o
         inner join Sales.OrderLines OL on o.OrderID = OL.OrderID
         inner join Sales.Customers C on C.CustomerID = o.CustomerID
where UnitPrice > 100
   or Quantity > 20
order by [номер квартала], [треть года], [дату заказа]

select o.OrderID,
       OrderDate,
       FORMAT(OrderDate, 'd', 'ru-ru')    as [дату заказа],
       FORMAT(OrderDate, 'MMMM', 'ru-ru') as [название месяца],
       datepart(quarter, OrderDate)       as 'номер квартала',
       (month(OrderDate) / 3) + 1         as 'треть года',
       CustomerName/*,
       UnitPrice,
       Quantity*/
from Sales.Orders o
         inner join Sales.OrderLines OL on o.OrderID = OL.OrderID
         inner join Sales.Customers C on C.CustomerID = o.CustomerID
where UnitPrice > 100
   or Quantity > 20
order by [номер квартала], [треть года], [дату заказа]
offset 1000 rows fetch next 100 rows only


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select DM.DeliveryMethodName, PO.ExpectedDeliveryDate, s.SupplierName, p.FullName as ContactPerson
from Purchasing.Suppliers s
         inner join Purchasing.PurchaseOrders PO on s.SupplierID = PO.SupplierID
         inner join Application.People p on PO.ContactPersonID = p.PersonID
         inner join Application.DeliveryMethods DM on DM.DeliveryMethodID = s.DeliveryMethodID
where FORMAT(PO.ExpectedDeliveryDate, N'MM.yyyy') = '01.2013'
  and DM.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
  and PO.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 c.CustomerName, P.FullName
from Sales.Orders O
         inner join Sales.Customers C on C.CustomerID = O.CustomerID
         inner join Application.People P on O.SalespersonPersonID = P.PersonID
order by OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct C.CustomerID, C.CustomerName, C.PhoneNumber
from Sales.Orders o
         inner join Sales.OrderLines OL on o.OrderID = OL.OrderID
         inner join Sales.Customers C on C.CustomerID = o.CustomerID
         inner join Warehouse.StockItems SI on SI.StockItemID = OL.StockItemID
where SI.StockItemName = 'Chocolate frogs 250g'
