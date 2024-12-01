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

Alter VIEW DataWarehouseExample
as SELECT --s.SubscriptionId,
       row_number() OVER (ORDER BY s.PurchaseDate, u.UserId) N,
          s.PurchaseDate,
          s.ActiveStartDate,
          s.ActiveEndDate,
          --s.SoldUserId,
          --t.TransactionId,
          t.Date,
          t.Price as TransactionPrice,
          --c.ClientId,
          c.Name as ClientName,
          c.Surname  as ClientSurname,
          c.PhoneNumber,
         -- u.UserId,
          u.Name as UserName,
          u.Surname as UserSurname,
          u.Password,
          st.SubscriptionTypeId,
          st.Name as SubscriptionTypeName,
          st.Price SubscriptionTypeNamePrice,
          st.DurationInDays
   from dbo.Subscription s
INNER JOIN dbo.[Transaction] t ON s.TransactionId = t.TransactionId
INNER JOIN dbo.Client c ON c.ClientId = s.ClientId
INNER JOIN dbo.[User] u ON u.UserId = s.SoldUserId
inner JOIN dbo.SubscriptionType st on s.SubscriptionTypeId = st.SubscriptionTypeId

SELECT * from DataWarehouseExample dwe


SET IDENTITY_INSERT dbo.Client ON;
INSERT INTO fitness_crm.dbo.Client (ClientId, Name, Surname, PhoneNumber) VALUES (2, N'Клиент 1', N' ', 11111111111);
INSERT INTO fitness_crm.dbo.Client (ClientId, Name, Surname, PhoneNumber) VALUES (3, N'Клиент 2', N' ', 22222222222);
INSERT INTO fitness_crm.dbo.Client (ClientId, Name, Surname, PhoneNumber) VALUES (4, N'Клиент 3', N' ', 33333333333);
SET IDENTITY_INSERT dbo.Client OFF;


INSERT INTO fitness_crm.dbo.[User] (UserId, Name, Surname, Password) VALUES (N'B0E86CC2-6272-4678-A972-1A38C9E80BEA', N'Администратор 1', N'', N'11111111111');
INSERT INTO fitness_crm.dbo.[User] (UserId, Name, Surname, Password) VALUES (N'FE03E878-90B8-4F23-BD2D-1B7A988CE8A4', N'Администратор 2', N'', N'22222222222222');
INSERT INTO fitness_crm.dbo.[User] (UserId, Name, Surname, Password) VALUES (N'50695443-5D84-4E35-A312-4D9620015B95', N'Администратор 3', N'', N'3333333333333333');


SET IDENTITY_INSERT dbo.SubscriptionType ON;
INSERT INTO fitness_crm.dbo.SubscriptionType (SubscriptionTypeId, Name, Price, DurationInDays) VALUES (1, N'1 месяц', 2000.0000, 30);
INSERT INTO fitness_crm.dbo.SubscriptionType (SubscriptionTypeId, Name, Price, DurationInDays) VALUES (2, N'3 месяца', 5000.0000, 150);
SET IDENTITY_INSERT dbo.SubscriptionType OFF;

SET IDENTITY_INSERT dbo.[Transaction] ON;
INSERT INTO fitness_crm.dbo.[Transaction] (TransactionId, Date, Price) VALUES (1, N'2024-11-09 20:32:57.0000000', 2000.0000);
INSERT INTO fitness_crm.dbo.[Transaction] (TransactionId, Date, Price) VALUES (2, N'2024-11-25 20:34:47.0000000', 2000.0000);
INSERT INTO fitness_crm.dbo.[Transaction] (TransactionId, Date, Price) VALUES (3, N'2024-12-01 20:36:51.0000000', 5000.0000);
SET IDENTITY_INSERT dbo.[Transaction] OFF;

SET IDENTITY_INSERT dbo.Subscription ON;
INSERT INTO fitness_crm.dbo.Subscription (SubscriptionId, SubscriptionTypeId, ClientId, PurchaseDate, ActiveStartDate, ActiveEndDate, SoldUserId, TransactionId) VALUES (3, 1, 2, N'2024-11-09 20:28:50.0000000', N'2024-11-09 20:29:08.0000000', N'2024-12-09 20:29:26.0000000', N'B0E86CC2-6272-4678-A972-1A38C9E80BEA', 1);
INSERT INTO fitness_crm.dbo.Subscription (SubscriptionId, SubscriptionTypeId, ClientId, PurchaseDate, ActiveStartDate, ActiveEndDate, SoldUserId, TransactionId) VALUES (5, 1, 3, N'2024-11-25 20:35:08.0000000', N'2024-11-25 20:35:11.0000000', N'2024-12-25 20:35:14.0000000', N'B0E86CC2-6272-4678-A972-1A38C9E80BEA', 2);
INSERT INTO fitness_crm.dbo.Subscription (SubscriptionId, SubscriptionTypeId, ClientId, PurchaseDate, ActiveStartDate, ActiveEndDate, SoldUserId, TransactionId) VALUES (6, 2, 4, N'2024-11-19 20:37:47.0000000', N'2024-12-01 20:37:53.0000000', N'2024-03-01 20:38:46.0000000', N'50695443-5D84-4E35-A312-4D9620015B95', 3);
SET IDENTITY_INSERT dbo.Subscription OFF;

