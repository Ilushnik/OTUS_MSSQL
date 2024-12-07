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
--������� ����������� ����� �� ������
CREATE FUNCTION dbo.SplitStringCLR (@inputString NVARCHAR(MAX), @delimiter NVARCHAR(10))
RETURNS TABLE (Value NVARCHAR(MAX))
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SplitString;
go;
SELECT * from dbo.SplitStringCLR ('string1,string2,string3', ',')
-- ������� ��� ����������� ����� � ������ �����
CREATE AGGREGATE dbo.StringAgg (@value NVARCHAR(MAX))
    RETURNS nvarchar(max)
EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.StringAggregator];
go;
SELECT dbo.StringAgg(val) from (VALUES ('string1') , ('string2'), ('string3')) as data(val)

-- end homework


--original file testing function

-- ������ �� ���������� �������������
DROP FUNCTION IF EXISTS dbo.fn_SayHello
GO
DROP PROCEDURE IF EXISTS dbo.usp_SayHello
GO
DROP ASSEMBLY IF EXISTS CustomCLRFunctions
GO

-- �������� CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

-- clr strict security 
-- 1 (Enabled): ���������� Database Engine ������������ �������� PERMISSION_SET � ������� 
-- � ������ ���������������� �� ��� UNSAFE. �� ���������, ������� � SQL Server 2017.

reconfigure;
GO

-- ��� ����������� �������� ������ � EXTERNAL_ACCESS ��� UNSAFE
ALTER DATABASE fitness_crm SET TRUSTWORTHY ON;

-- ���������� dll 
-- �������� ���� � �����!
CREATE ASSEMBLY CustomCLRFunctions
FROM 'C:\Users\Julia\DataGripProjects\otus\hw37 - CLR\MsSQLCLRFunctions\MsSQLCLRFunctions\bin\Debug\MsSQLCLRFunctions.dll'
WITH PERMISSION_SET = SAFE;  

-- DROP ASSEMBLY SimpleDemoAssembly

-- ���� ������ (dll) �� ����� ������ �� �����, ��� ���������� � ��

-- ��� ���������� ������������������ ������ 

-- SSMS
-- <DB> -> Programmability -> Assemblies 

-- ���������� ������������ ������ (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies

-- ���������� ������� �� dll - AS EXTERNAL NAME
CREATE FUNCTION dbo.fn_SayHello(@Name nvarchar(100))  
RETURNS nvarchar(100)
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SayHelloFunction;
GO 

-- ��� namespace ����� ���:
-- [SimpleDemoAssembly].[DemoClass].SayHelloFunction

-- ���������� �������
SELECT dbo.fn_SayHello('OTUS Student')

-- ���������� ��������� �� dll - AS EXTERNAL NAME 
CREATE PROCEDURE dbo.usp_SayHello  
(  
    @Name nvarchar(50)
)  
AS EXTERNAL NAME [CustomCLRFunctions].[MsSQLCLRFunctions.CustomCRLFunctions].SayHelloProcedure;
GO 

-- ���������� ��
exec dbo.usp_SayHello @Name = 'OTUS Student';

-- --------------------------

-- ������ ������������ CLR-��������
SELECT * FROM sys.assembly_modules

-- ���������� "���" ������
-- SSMS: <DB> -> Programmability -> Assemblies -> Script Assembly as -> CREATE To