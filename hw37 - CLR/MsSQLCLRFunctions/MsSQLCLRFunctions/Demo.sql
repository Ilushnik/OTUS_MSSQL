use fitness_crm

--home work
DROP FUNCTION IF EXISTS dbo.SplitStringCLR
DROP AGGREGATE IF EXISTS dbo.StringAgg
GO
DROP ASSEMBLY IF EXISTS CustomCLRFunctions
GO
CREATE ASSEMBLY CustomCLRFunctions
FROM 'C:\Users\Julia\DataGripProjects\otus\hw37 - CLR\MsSQLCLRFunctions\MsSQLCLRFunctions\bin\Debug\MsSQLCLRFunctions.dll'
WITH PERMISSION_SET = SAFE;
GO
--функция разделяющая текст на строки
CREATE FUNCTION dbo.SplitStringCLR (@inputString NVARCHAR(MAX), @delimiter NVARCHAR(10))
RETURNS TABLE (Value NVARCHAR(MAX))
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SplitString;
go;
SELECT * from dbo.SplitStringCLR ('string1,string2,string3', ',')
-- функция для объединения стоки в единый текст
CREATE AGGREGATE dbo.StringAgg (@value NVARCHAR(MAX))
    RETURNS nvarchar(max)
EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.StringAggregator];
go;
SELECT dbo.StringAgg(val) from (VALUES ('string1') , ('string2'), ('string3')) as data(val)

-- end homework


--original file testing function

-- Чистим от предыдущих экспериментов
DROP FUNCTION IF EXISTS dbo.fn_SayHello
GO
DROP PROCEDURE IF EXISTS dbo.usp_SayHello
GO
DROP ASSEMBLY IF EXISTS CustomCLRFunctions
GO

-- Включаем CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

-- clr strict security 
-- 1 (Enabled): заставляет Database Engine игнорировать сведения PERMISSION_SET о сборках 
-- и всегда интерпретировать их как UNSAFE. По умолчанию, начиная с SQL Server 2017.

reconfigure;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE fitness_crm SET TRUSTWORTHY ON;

-- Подключаем dll 
-- Измените путь к файлу!
CREATE ASSEMBLY CustomCLRFunctions
FROM 'C:\Users\Julia\DataGripProjects\otus\hw37 - CLR\MsSQLCLRFunctions\MsSQLCLRFunctions\bin\Debug\MsSQLCLRFunctions.dll'
WITH PERMISSION_SET = SAFE;  

-- DROP ASSEMBLY SimpleDemoAssembly

-- Файл сборки (dll) на диске больше не нужен, она копируется в БД

-- Как посмотреть зарегистрированные сборки 

-- SSMS
-- <DB> -> Programmability -> Assemblies 

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies

-- Подключить функцию из dll - AS EXTERNAL NAME
CREATE FUNCTION dbo.fn_SayHello(@Name nvarchar(100))  
RETURNS nvarchar(100)
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SayHelloFunction;
GO 

-- Без namespace будет так:
-- [SimpleDemoAssembly].[DemoClass].SayHelloFunction

-- Используем функцию
SELECT dbo.fn_SayHello('OTUS Student')

-- Подключить процедуру из dll - AS EXTERNAL NAME 
CREATE PROCEDURE dbo.usp_SayHello  
(  
    @Name nvarchar(50)
)  
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SayHelloProcedure;
GO 

-- Используем ХП
exec dbo.usp_SayHello @Name = 'OTUS Student';

-- --------------------------

-- Список подключенных CLR-объектов
SELECT * FROM sys.assembly_modules

-- Посмотреть "код" сборки
-- SSMS: <DB> -> Programmability -> Assemblies -> Script Assembly as -> CREATE To