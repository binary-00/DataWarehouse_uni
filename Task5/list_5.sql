-- 1. Create a new schema in the AdventureWorks2019 database
CREATE SCHEMA list_five;

-- 2. Create new Dimension and Fact Tables inside that schema
CREATE TABLE list_five.DIM_CUSTOMER (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Title VARCHAR(50),
    City VARCHAR(50),
    TerritoryName VARCHAR(50),
    CountryRegionCode CHAR(3) DEFAULT '000',
    [Group] VARCHAR(50) DEFAULT 'Unknown'
);

CREATE TABLE list_five.DIM_PRODUCT (
    ProductID INT PRIMARY KEY,
    Name VARCHAR(50),
    ListPrice DECIMAL(19,4),
    Color VARCHAR(15) DEFAULT 'Unknown',
    SubCategoryName VARCHAR(50) DEFAULT 'Unknown',
    CategoryName VARCHAR(50),
    Weight DECIMAL(8,2),
    Size VARCHAR(5),
    IsPurchased BIT
);

CREATE TABLE list_five.DIM_SALESPERSON (
    SalesPersonID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Title VARCHAR(50),
    Gender CHAR(1),
    CountryRegionCode CHAR(3) DEFAULT '000',
    [Group] VARCHAR(50) DEFAULT 'Unknown'
);

CREATE TABLE list_five.FACT_SALES (
    ProductID INT,
    CustomerID INT,
    SalesPersonID INT,
    OrderDate INT,
    ShipDate INT,
    OrderQty SMALLINT,
    UnitPrice DECIMAL(19,4),
    UnitPriceDiscount DECIMAL(19,4),
    LineTotal DECIMAL(38,6),
    
	FOREIGN KEY (ProductID) REFERENCES list_five.DIM_PRODUCT(ProductID),
	FOREIGN KEY (CustomerID) REFERENCES list_five.DIM_CUSTOMER(CustomerID),
	FOREIGN KEY (SalesPersonID) REFERENCES list_five.DIM_SALESPERSON(SalesPersonID)
);

-- 3. Create DIM_TIME based on OrderDate and ShipDate
CREATE TABLE list_five.DIM_TIME (
	DateKey INT PRIMARY KEY,
	[Year] SMALLINT,
	[Month] TINYINT,
	[Day] TINYINT
);

INSERT INTO list_five.DIM_TIME (DateKey, [Year], [Month], [Day])
SELECT DISTINCT 
	OrderDate AS DateKey,
	DATEPART(YEAR, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Year],
	DATEPART(MONTH, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Month],
	DATEPART(DAY, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Day]
FROM list_five.FACT_SALES
UNION
SELECT DISTINCT 
	ShipDate AS DateKey,
	DATEPART(YEAR, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Year],
	DATEPART(MONTH, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Month],
	DATEPART(DAY, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Day]
FROM list_five.FACT_SALES;

-- 4. Add integrity constraints between tables (based on foreign and primary keys)
ALTER TABLE list_five.FACT_SALES
ADD FOREIGN KEY (OrderDate) REFERENCES list_five.DIM_TIME(DateKey);

ALTER TABLE list_five.FACT_SALES
ADD FOREIGN KEY (ShipDate) REFERENCES list_five.DIM_TIME(DateKey);

-----------------------------------------
DROP TABLE [list_five].[FACT_SALES]
DROP TABLE [list_five].[DIM_TIME] 
DROP TABLE [list_five].[DIM_SALESPERSON]
DROP TABLE [list_five].[DIM_PRODUCT]
DROP TABLE [list_five].[DIM_CUSTOMER]

DROP SCHEMA list_five

SELECT * FROM [list_five].[DIM_CUSTOMER]
SELECT * FROM [list_five].[DIM_PRODUCT]
SELECT * FROM [list_five].[DIM_SALESPERSON]
SELECT * FROM [list_five].[DIM_TIME]
SELECT * FROM [list_five].[FACT_SALES]
