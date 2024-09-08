/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION fWhaleCustomer() RETURNS int
BEGIN
    DECLARE @customerId int;
    ;
    WITH PurchasePrices AS (SELECT o.CustomerID, SUM(ol.UnitPrice * ol.Quantity) AS purchasePrice

                            FROM Sales.OrderLines ol
                                     INNER JOIN Sales.Orders o ON o.OrderID = ol.OrderID
                            GROUP BY o.CustomerID)
    SELECT TOP 1 @customerId = CustomerID
    FROM purchaseprices p
    ORDER BY p.purchaseprice DESC;
    RETURN @customerId;
END;

SELECT dbo.fWhaleCustomer() AS CustomerId;

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE pCustomerSpent @customerId float
AS
BEGIN


    SELECT SUM(ol.UnitPrice * ol.Quantity)
    FROM Sales.OrderLines ol
             INNER JOIN Sales.Orders o ON o.OrderID = ol.OrderID
    WHERE CustomerID = @customerId;

END
    EXEC pCustomerSpent 149;

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/


    -- берем процедуру из предыдущего задания и дописываем к ней функцию
    CREATE FUNCTION fCustomerSpent(@customerId int) RETURNS float
    BEGIN
        DECLARE @customerSpentMoney float;
        ;
        SELECT @customerSpentMoney = SUM(ol.UnitPrice * ol.Quantity)
        FROM Sales.OrderLines ol
                 INNER JOIN Sales.Orders o ON o.OrderID = ol.OrderID
        WHERE CustomerID = @customerId;
        RETURN @customerSpentMoney;
    END;

    --procedure
    EXEC pCustomerSpent 149;
    --function
SELECT dbo.fCustomerSpent(149);

    -- функция выполняется гораздо быстрее. Подозреваю из-за того что функция кэширует в себе опрееленные данные

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
*/

    CREATE FUNCTION fCustomerSpentTable(@customerId int)
        RETURNS @CustomerSpent TABLE
                               (
                                   spentMoney float
                               ) AS
    BEGIN
        INSERT INTO @CustomerSpent
        SELECT SUM(ol.UnitPrice * ol.Quantity)
        FROM Sales.OrderLines ol
                 INNER JOIN Sales.Orders o ON o.OrderID = ol.OrderID
        WHERE CustomerID = @customerId;
        RETURN;
    END;

SELECT c.CustomerID, p.spentMoney
FROM Sales.Customers c
         CROSS APPLY dbo.fCustomerSpentTable(c.CustomerID) p ;

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему.
*/
