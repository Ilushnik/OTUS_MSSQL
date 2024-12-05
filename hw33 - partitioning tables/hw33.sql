ALTER DATABASE fitness_crm ADD FILEGROUP YearData

ALTER DATABASE fitness_crm ADD FILE (
    NAME = N'Years',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\YearData.ndf',
    SIZE = 2000000 KB, FILEGROWTH = 60000 KB) TO FILEGROUP YearData


CREATE PARTITION FUNCTION fnYearPartition (Date)
    AS RANGE RIGHT FOR VALUES ('20230101', '20240101', '20250101')


CREATE PARTITION SCHEME schYearPartition AS PARTITION fnYearPartition ALL TO ( [YearData] )

--Таблица с данными
CREATE TABLE TransactionPartitionedTable
(
    ClientId int  NOT NULL,
    [Date]   DATE NOT NULL,
    Price    int  NOT NULL
) ON schYearPartition
(
    [Date]
)

--применяем секционирование
ALTER TABLE TransactionPartitionedTable
    ADD CONSTRAINT pk_TransctionTable PRIMARY KEY CLUSTERED ([Date]) ON schYearPartition ([Date])

--заполняем данными
INSERT INTO dbo.TransactionPartitionedTable
VALUES (1, '20220201', 100)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (2, '20230201', 150)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (4, '20230601', 120)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (5, '20240201', 160)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (6, '20250201', 180)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (7, '20260201', 110)

-- проверка секционирования
SELECT $PARTITION.fnYearPartition([Date]) AS Partition,
    COUNT(*) AS countRows,
    min([Date]), max([Date])
FROM TransactionPartitionedTable tpt
GROUP BY $PARTITION.fnYearPartition(tpt.[Date])
ORDER BY PARTITION

ALTER PARTITION SCHEME schYearPartition
NEXT USED [PRIMARY];

-- добавление тестовой секции
alter PARTITION FUNCTION fnYearPartition() split RANGE ('20200201')

INSERT INTO dbo.TransactionPartitionedTable
VALUES (8, '20180201', 110)
INSERT INTO dbo.TransactionPartitionedTable
VALUES (9, '200201', 110)


-- sliding

-- аривная таблица
CREATE TABLE TransactionPartitionedTableArchive
(
    ClientId int  NOT NULL,
    [Date]   DATE NOT NULL,
    Price    int  NOT NULL
) on YearData

ALTER TABLE TransactionPartitionedTableArchive
    ADD CONSTRAINT pk_TransctionTableArchive PRIMARY KEY CLUSTERED ([Date])

--перенос секции в архивную таблицу
ALTER TABLE dbo.TransactionPartitionedTable SWITCH PARTITION 1 TO dbo.TransactionPartitionedTableArchive

-- проверка наличия данных
SELECT * from TransactionPartitionedTableArchive tpta

ALTER PARTITION SCHEME schYearPartition
NEXT USED [PRIMARY];

-- добавление новой секции в
alter PARTITION FUNCTION fnYearPartition() SPLIT RANGE ('20260101')

