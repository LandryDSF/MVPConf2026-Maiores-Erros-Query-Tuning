/**********************************************************************
 Palestra: Os Maiores Erros de Query Tuning no SQL Server:
           Nem Sempre é Falta de Índice

 Evento: MVP Conf 2026
 Palestrante: Prof. Landry Duailibe
 Tema deste script: Função em coluna

 Repositório:
 https://github.com/LandryDSF/MVPConf2026-Maiores-Erros-Query-Tuning

 Este script faz parte do material demonstrativo da palestra.
 Pode ser utilizado, modificado e distribuído conforme os termos 
 da licença MIT.

***********************************************************************/
use HandsOn_MVP2026
go

/***********************************************************
 Uso de Função em coluna
************************************************************/
set statistics io on

-- DROP INDEX dbo.Customer.IX_Customer_FirstName
CREATE INDEX IX_Customer_FirstName ON dbo.Customer (FirstName)
INCLUDE (CustomerID, LastName)
-- WITH DROP_EXISTING






-- Função LEFT()
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE left(FirstName,1) = 'A'
-- Clustered Index Scan = Table Scan -> Table 'Customer'. Scan count 7, logical reads 252971 x 8Kb = 2.023.768 Kb = 1.976 MB
-- Index Scan ------------------------> Table 'Customer'. Scan count 1, logical reads 4589 x 8kb = 36.712 Kb = 35 MB

-- Trocando por LIKE
SELECT CustomerID, FirstName, LastName --, DataCadastro
FROM dbo.Customer WHERE FirstName like 'G%'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 7 x 8kb = 56 KB

SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName like '%G%'
-- Index Scan ------------------------> Table 'Customer'. Scan count 1, logical reads 4589 x 8kb = 36.712 Kb = 35 MB



/***********************************************************
 - Uso de Função em coluna: CONVERT
************************************************************/

-- DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate
CREATE INDEX IX_SalesOrderHeader_OrderDate
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (SalesOrderID, CustomerID, TotalDue, ShipDate)

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE OrderDate = '20110531'
-- Zero linhas

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE convert(varchar(8),OrderDate,112) = '20110531'
-- 21.543 linhas
-- Index Scan -> Table 'SalesOrderHeader'. Scan count 7, logical reads 74778 x 8kb = 598224 Kb = 584 MB







SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE OrderDate >= '20110607' and OrderDate < '20110608'
-- 43 linhas
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 2


SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE year(OrderDate) = 2011
-- 805.107 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 7, logical reads 74526

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE OrderDate >= '20110101' and OrderDate < '20120101'
-- 805.107 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 3792

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate


