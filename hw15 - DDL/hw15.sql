-- Создать базу данных.

create database fitness_crm
go

use fitness_crm;
go;

-- 3-4 основные таблицы для своего проекта.
-- Первичные и внешние ключи для всех созданных таблиц.
CREATE TABLE dbo.Client (
  ClientId int IDENTITY(1,1) PRIMARY KEY NOT NULL,
  Name nvarchar(50) NOT NULL,
  Surname nvarchar(50) NOT NULL,
  PhoneNumber nvarchar(50)
);

CREATE TABLE dbo.SubscriptionType (
  SubscriptionTypeId int IDENTITY(1,1)  PRIMARY KEY NOT NULL,
  Name nvarchar(50) NOT NULL,
  Price int NOT NULL,
  DurationInDays int NOT NULL
);
CREATE TABLE dbo.[Transaction] (
  TransactionId int IDENTITY(1,1)  PRIMARY KEY NOT NULL,
  Date datetime2 NOT NULL,
  Price money NOT NULL
);

CREATE TABLE dbo.[User] (
  UserId uniqueidentifier PRIMARY KEY DEFAULT (newid()) NOT NULL,
  Name nvarchar(50) NOT NULL,
  Surname nvarchar(50) NOT NULL,
  Password nvarchar(20) NOT NULL
);
GO

CREATE TABLE dbo.Subscription (
  SubscriptionId int IDENTITY(1,1)  PRIMARY KEY  ,
  SubscriptionTypeId int NOT NULL,
  ClientId int NOT NULL,
  PurchaseDate datetime2 NOT NULL,
  ActiveStartDate datetime2,
  ActiveEndDate datetime2,
  SoldUserId uniqueidentifier NOT NULL,
  TransactionId int NOT NULL,
  FOREIGN KEY (ClientId) REFERENCES Client (ClientId),
  FOREIGN KEY (SubscriptionTypeId) REFERENCES SubscriptionType (SubscriptionTypeId),
  FOREIGN KEY (SoldUserId) REFERENCES [User] (UserId),
  FOREIGN KEY (TransactionId) REFERENCES [Transaction] (TransactionId)
);
GO



-- 1-2 индекса на таблицы.


create unique index Client_PhoneNumber_uindex
    on Client (PhoneNumber)

create index Transaction_Date_Price_index
    on [Transaction] (Date, Price)

-- Наложите по одному ограничению в каждой таблице на ввод данных.

Alter table dbo.Client  ADD CHECK (len(Client.PhoneNumber)=11)
Alter table dbo.SubscriptionType  ADD CHECK (Price>0)
Alter table dbo.[User]  ADD CHECK (len(trim(Password))>10)


CREATE VIEW SubscriptionSoldByUser
as
SELECT u.Name, COUNT(*) SubscriptionSoldCountfrom, SUM(t.Price) as ReceivedMoney
FROM dbo.Subscription s
       INNER JOIN dbo.[User] u ON u.UserId = s.SoldUserId
       INNER JOIN dbo.[Transaction] t ON s.TransactionId = t.TransactionId
GROUP BY u.Name
