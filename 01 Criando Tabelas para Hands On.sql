/**********************************************************************
 Palestra: Os Maiores Erros de Query Tuning no SQL Server:
           Nem Sempre é Falta de Índice

 Evento: MVP Conf 2026
 Palestrante: Prof. Landry Duailibe
 Tema deste script: Criando Tabelas

 Repositório:
 https://github.com/LandryDSF/MVPConf2026-Maiores-Erros-Query-Tuning

 Este script faz parte do material demonstrativo da palestra.
 Pode ser utilizado, modificado e distribuído conforme os termos 
 da licença MIT.
***********************************************************************/
USE Aula
go

/******************************
 Cria tabelas para o Hands On
*******************************/
DROP TABLE IF exists dbo.Customer
go
SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,PersonType,
EmailPromotion,'RJ' as Region, dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID

DROP TABLE IF exists dbo.SalesOrderHeader
go
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, DATEADD(hh,1,ShipDate) as ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, 
SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorks.Sales.SalesOrderHeader
/********************** Fim Cria Tabelas **************************/


/***********************************************************
 Uso de Função em coluna: LEFT, RIGHT
************************************************************/
set statistics io on

CREATE INDEX IX_Customer_FirstName ON dbo.Customer (FirstName)
INCLUDE (CustomerID, LastName)

-- Consulta 1
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE left(FirstName,1) = 'G'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 114

-- Consulta 2
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName like 'G%'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 7

SELECT CustomerID, FirstName, LastName--, DataCadastro
FROM dbo.Customer WHERE FirstName like '%G%'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 114
-- Table Scan: Table 'Customer'. Scan count 1, logical reads 155

DROP INDEX dbo.Customer.IX_Customer_FirstName

/***********************************************************
 - Uso de Função em coluna: CONVERT
************************************************************/
CREATE INDEX IX_SalesOrderHeader_DataCadastro 
ON dbo.SalesOrderHeader (ShipDate)
INCLUDE (SalesOrderID, CustomerID, TotalDue, OrderDate)

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate = '20110607'
-- Zero linhas

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE convert(varchar(8),ShipDate,112) = '20110607'
-- 43 linhas
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 181

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate >= '20110607' and ShipDate < '20110608'
-- 43 linhas
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 2


SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE year(ShipDate) = 2011
-- 1.566 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 181

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate >= '20110101' and ShipDate < '20120101'
-- 1.566 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 11

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_DataCadastro


-- Exclui Tabelas
DROP TABLE IF exists dbo.Customer
DROP TABLE IF exists dbo.SalesOrderHeader
go
