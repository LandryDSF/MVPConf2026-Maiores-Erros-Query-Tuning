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

 Este script utiliza os dados do Banco AdventureWorks, utilizar
 o link abaixo para obter o banco:
 https://learn.microsoft.com/pt-br/sql/samples/adventureworks-install-configure

***********************************************************************/
USE master
go
CREATE DATABASE HandsOn_MVP2026
go
ALTER DATABASE HandsOn_MVP2026 SET RECOVERY simple
go


/******************************
 Cria tabelas para o Hands On
*******************************/
use HandsOn_MVP2026
go

set nocount on

/*********************
 Customer
**********************/
DROP TABLE IF exists dbo.Customer
go
CREATE TABLE dbo.Customer(
CustomerID int IDENTITY NOT NULL CONSTRAINT pk_Customer PRIMARY KEY,
FirstName nvarchar(50) NULL,
MiddleName nvarchar(50) NULL,
Lastname nvarchar(50) NULL,
PersonType nchar(900) NULL,
EmailPromotion int NULL,
Region varchar(2) NULL,
DataCadastro datetime NULL) 
go

INSERT dbo.Customer
(FirstName, MiddleName, Lastname, PersonType, EmailPromotion, Region, DataCadastro)

SELECT FirstName, MiddleName, Lastname, PersonType,
EmailPromotion, 'RJ' as Region, 
dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
go

INSERT dbo.Customer
(FirstName, MiddleName, Lastname, PersonType, EmailPromotion, Region, DataCadastro)

SELECT FirstName, MiddleName, Lastname, PersonType,
EmailPromotion, 'RJ' as Region, 
dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE FirstName not like 'G%'
go 50

/*********************
 SalesOrderHeader
**********************/
DROP TABLE IF exists dbo.SalesOrderHeader
go
CREATE TABLE dbo.SalesOrderHeader (
SalesOrderID int IDENTITY NOT NULL CONSTRAINT pk_SalesOrderHeader PRIMARY KEY,
RevisionNumber tinyint NOT NULL,
OrderDate datetime NOT NULL,
DueDate datetime NOT NULL,
ShipDate datetime NULL,
Status tinyint NOT NULL,
OnlineOrderFlag bit NOT NULL,
SalesOrderNumber nvarchar(25) NOT NULL,
PurchaseOrderNumber nvarchar(25) NULL,
AccountNumber nvarchar(15) NULL,
CustomerID int NOT NULL,
SalesPersonID int NULL,
SubTotal money NOT NULL,
TaxAmt money NOT NULL,
Freight money NOT NULL,
TotalDue money NOT NULL,
Comment nvarchar(128) NULL,
rowguid uniqueidentifier NOT NULL,
ModifiedDate datetime NOT NULL)
go

INSERT dbo.SalesOrderHeader
(RevisionNumber, 
OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, SubTotal, TaxAmt, Freight, TotalDue, Comment, rowguid, ModifiedDate)
SELECT RevisionNumber, 
dateadd(second,abs(checksum(newid())) % 86400, OrderDate) as OrderDate, 
DueDate, ShipDate, Status, OnlineOrderFlag, 
replace(SalesOrderNumber,'SO','') as SalesOrderNumber, 
PurchaseOrderNumber, h.AccountNumber, h.CustomerID, 
SalesPersonID, SubTotal, TaxAmt, Freight, TotalDue, Comment, h.rowguid, h.ModifiedDate
FROM AdventureWorks.Sales.SalesOrderHeader h
go

INSERT dbo.SalesOrderHeader
(RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, SubTotal, TaxAmt, Freight, TotalDue, Comment, rowguid, ModifiedDate)
SELECT RevisionNumber, 
dateadd(second,abs(checksum(newid())) % 86400, OrderDate) as OrderDate, 
DueDate, ShipDate, Status, OnlineOrderFlag, 
replace(SalesOrderNumber,'SO','') as SalesOrderNumber, 
PurchaseOrderNumber, h.AccountNumber, h.CustomerID, 
SalesPersonID, SubTotal, TaxAmt, Freight, TotalDue, Comment, h.rowguid, h.ModifiedDate
FROM AdventureWorks.Sales.SalesOrderHeader h
WHERE SalesOrderNumber not in ('43659','43660','43661','43662','43663')
go 500

/********************** Fim Cria Tabelas **************************/

EXEC sp_spaceused 'dbo.Customer'
-- 945.669 linhas / 1,8 GB

EXEC sp_spaceused 'dbo.SalesOrderHeader'
-- 15.763.965 linhas 2,3 GB




/***********************************************************
 Uso de Função em coluna
************************************************************/
set statistics io on

CREATE INDEX IX_Customer_FirstName ON dbo.Customer (FirstName)
INCLUDE (CustomerID, LastName)
-- WITH DROP_EXISTING

DROP INDEX dbo.Customer.IX_Customer_FirstName

-- Função LEFT()
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE left(FirstName,1) = 'A'
-- Clustered Index Scan = Table Scan -> Table 'Customer'. Scan count 5, logical reads 252971
-- Index Scan ------------------------> Table 'Customer'. Scan count 1, logical reads 4589

-- Trocando por LIKE
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName like 'G%'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 7

SELECT CustomerID, FirstName, LastName--, DataCadastro
FROM dbo.Customer WHERE FirstName like '%G%'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 114
-- Table Scan: Table 'Customer'. Scan count 1, logical reads 155



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



/***********************************************************
 - Problema de desempenho com conversão implícita
************************************************************/
UPDATE dbo.SalesOrderHeader set SalesOrderNumber = replace(SalesOrderNumber,'SO','')

CREATE INDEX IX_SalesOrderHeader_SalesOrderNumber
ON dbo.SalesOrderHeader (SalesOrderNumber)
INCLUDE (SalesOrderID, OrderDate, Status)

SELECT SalesOrderID, OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = 53683
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 162

SELECT SalesOrderID, OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = '53683'
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 2
/*
nvarchar - UNICODE  2 bytes
varchar - Code Page 1 byte
*/

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesOrderNumber


/***********************************************************
 Operação Aritmética em Coluna
************************************************************/
CREATE INDEX IX_SalesOrderHeader_SalesOrderID
ON dbo.SalesOrderHeader (SalesOrderID)
INCLUDE (SalesOrderNumber, OrderDate, Status)

--ALTER TABLE dbo.SalesOrderHeader ADD SalesOrderIDx2 as (SalesOrderID * 2) persisted

-- Consulta 1
SELECT SalesOrderID, SalesOrderID * 2 as SalesOrderIDx2,SalesOrderNumber, 
OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderID * 2 >= 144480
-- 2.884 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 162

-- Consulta 2
SELECT SalesOrderID, SalesOrderID * 2 as SalesOrderIDx2,SalesOrderNumber, 
OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderID >= 144480 / 2
-- 2.884 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 17

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesOrderID


/**************************************
 BETWEEN x IN
***************************************/
CREATE INDEX IX_Customer_CustomerID 
ON dbo.Customer(CustomerID)
INCLUDE (FirstName,Lastname,DataCadastro)

-- Consulta 1 (IN)
SELECT CustomerID,FirstName,Lastname,DataCadastro 
FROM dbo.Customer
WHERE CustomerID IN (11000,11001,11002,11003,11004,11005)
-- 6 linhas
-- Index Seek: Table 'Customer'. Scan count 6, logical reads 12

-- Consulta 2 (BETWEEN)
SELECT CustomerID,FirstName,Lastname,DataCadastro 
FROM dbo.Customer 
WHERE CustomerID BETWEEN 11000 and 11005
-- 6 linhas
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 2

DROP INDEX dbo.Customer.IX_Customer_CustomerID




-- Exclui Tabelas
DROP TABLE IF exists dbo.Customer
DROP TABLE IF exists dbo.SalesOrderHeader
go
