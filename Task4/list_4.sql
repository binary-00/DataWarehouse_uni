-- 1. Create a new schema in the AdventureWorks2019 database
CREATE SCHEMA list_four;

-- 2. Create new Dimension and Fact Tables inside that schema
CREATE TABLE list_four.DIM_CUSTOMER (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Title VARCHAR(50),
    City VARCHAR(50),
    TerritoryName VARCHAR(50),
    CountryRegionCode CHAR(3) DEFAULT '000',
    [Group] VARCHAR(50) DEFAULT 'Unknown'
);

CREATE TABLE list_four.DIM_PRODUCT (
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

CREATE TABLE list_four.DIM_SALESPERSON (
    SalesPersonID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Title VARCHAR(50),
    Gender CHAR(1),
    CountryRegionCode CHAR(3) DEFAULT '000',
    [Group] VARCHAR(50) DEFAULT 'Unknown'
);

CREATE TABLE list_four.FACT_SALES (
    ProductID INT,
    CustomerID INT,
    SalesPersonID INT,
    OrderDate INT,
    ShipDate INT,
    OrderQty SMALLINT,
    UnitPrice DECIMAL(19,4),
    UnitPriceDiscount DECIMAL(19,4),
    LineTotal DECIMAL(38,6),
    
	FOREIGN KEY (ProductID) REFERENCES list_four.DIM_PRODUCT(ProductID),
	FOREIGN KEY (CustomerID) REFERENCES list_four.DIM_CUSTOMER(CustomerID),
	FOREIGN KEY (SalesPersonID) REFERENCES list_four.DIM_SALESPERSON(SalesPersonID)
);

-- 3. Create DIM_TIME based on OrderDate and ShipDate
CREATE TABLE list_four.DIM_TIME (
	DateKey INT PRIMARY KEY,
	[Year] SMALLINT,
	[Month] TINYINT,
	[Day] TINYINT
);

INSERT INTO list_four.DIM_TIME (DateKey, [Year], [Month], [Day])
SELECT DISTINCT 
	OrderDate AS DateKey,
	DATEPART(YEAR, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Year],
	DATEPART(MONTH, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Month],
	DATEPART(DAY, CAST(CAST(OrderDate AS CHAR(8)) AS DATE)) AS [Day]
FROM list_four.FACT_SALES
UNION
SELECT DISTINCT 
	ShipDate AS DateKey,
	DATEPART(YEAR, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Year],
	DATEPART(MONTH, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Month],
	DATEPART(DAY, CAST(CAST(ShipDate AS CHAR(8)) AS DATE)) AS [Day]
FROM list_four.FACT_SALES;

-- 4. Add integrity constraints between tables (based on foreign and primary keys)
ALTER TABLE list_four.FACT_SALES
ADD FOREIGN KEY (OrderDate) REFERENCES list_four.DIM_TIME(DateKey);

ALTER TABLE list_four.FACT_SALES
ADD FOREIGN KEY (ShipDate) REFERENCES list_four.DIM_TIME(DateKey);

----------------------------------------------------------------------
INSERT INTO list_four.DIM_CUSTOMER (CustomerID, FirstName, LastName, Title, City, TerritoryName, CountryRegionCode)
SELECT DISTINCT c.CustomerID, p.FirstName, p.LastName, p.Title, a.City, t.Name AS TerritoryName, '000' AS CountryRegionCode
FROM Sales.Customer AS c
JOIN Person.Person AS p
ON c.PersonID = p.BusinessEntityID
JOIN Person.BusinessEntityAddress AS bea
ON bea.BusinessEntityID = c.StoreID
JOIN Person.Address AS a
ON a.AddressID = bea.AddressID
JOIN Sales.SalesTerritory AS t
ON t.TerritoryID = c.TerritoryID;


INSERT INTO list_four.DIM_PRODUCT (ProductID, Name, ListPrice, Color, SubCategoryName, CategoryName, Weight, Size)
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    p.Color,
    sc.Name AS SubCategoryName,
    c.Name AS CategoryName,
    p.Weight,
    p.Size
FROM Production.Product AS p
LEFT JOIN Production.ProductSubcategory AS sc
ON p.ProductSubcategoryID = sc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS c
ON sc.ProductCategoryID = c.ProductCategoryID;


INSERT INTO list_four.DIM_SALESPERSON (SalesPersonID, FirstName, LastName, Title, CountryRegionCode)
SELECT 
    sp.BusinessEntityID AS SalesPersonID,
    p.FirstName,
    p.LastName,
    p.Title,
    t.CountryRegionCode
FROM Sales.SalesPerson AS sp
JOIN Person.Person AS p
ON sp.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesTerritory AS t
ON sp.TerritoryID = t.TerritoryID;



INSERT INTO list_four.FACT_SALES (ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal)
SELECT 
    sod.ProductID,
    soh.CustomerID,
    soh.SalesPersonID,
    CAST(REPLACE(CONVERT(VARCHAR(10), soh.OrderDate, 111), '/', '') AS INT) AS OrderDate,
    CAST(REPLACE(CONVERT(VARCHAR(10), soh.ShipDate, 111), '/', '') AS INT) AS ShipDate,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod
ON soh.SalesOrderID = sod.SalesOrderID
WHERE EXISTS (
    SELECT 1
    FROM list_four.DIM_SALESPERSON AS sp
    WHERE sp.SalesPersonID = soh.SalesPersonID
)
AND EXISTS (
    SELECT 1
    FROM list_four.DIM_TIME AS t
    WHERE t.DateKey = CAST(REPLACE(CONVERT(VARCHAR(10), soh.OrderDate, 111), '/', '') AS INT)
);



INSERT INTO list_four.DIM_TIME (DateKey, [Year], [Month], [Day])
SELECT DISTINCT 
    CAST(REPLACE(CONVERT(VARCHAR(10), soh.ShipDate, 111), '/', '') AS INT) AS DateKey,
    DATEPART(YEAR, soh.ShipDate) AS [Year],
    DATEPART(MONTH, soh.ShipDate) AS [Month],
    DATEPART(DAY, soh.ShipDate) AS [Day]
FROM Sales.SalesOrderHeader AS soh
WHERE NOT EXISTS (
    SELECT 1
    FROM list_four.DIM_TIME AS t
    WHERE t.DateKey = CAST(REPLACE(CONVERT(VARCHAR(10), soh.ShipDate, 111), '/', '') AS INT)
);

----------------------------------------------------------------------

TRUNCATE TABLE list_four.FACT_SALES;
TRUNCATE TABLE list_four.DIM_TIME;
TRUNCATE TABLE list_four.DIM_SALESPERSON;
TRUNCATE TABLE list_four.DIM_PRODUCT;
TRUNCATE TABLE list_four.DIM_CUSTOMER;

DROP TABLE list_four.FACT_SALES;
DROP TABLE list_four.DIM_TIME;
DROP TABLE list_four.DIM_SALESPERSON;
DROP TABLE list_four.DIM_PRODUCT;
DROP TABLE list_four.DIM_CUSTOMER;

DROP SCHEMA list_four;

SELECT * FROM list_four.DIM_PRODUCT
SELECT * FROM list_four.DIM_TIME
SELECT * FROM list_four.DIM_CUSTOMER
SELECT * FROM list_four.DIM_SALESPERSON
SELECT * FROM list_four.FACT_SALES


----------------------
--
CREATE TABLE list_four.load_status (
    id INT IDENTITY(1,1) PRIMARY KEY,
    table_name VARCHAR(50),
    status VARCHAR(50),
    timestamp DATETIME DEFAULT GETDATE()
);


INSERT INTO list_four.load_status (table_name, status)
VALUES 
('DIM_CUSTOMER', 'Success'),
('DIM_PRODUCT', 'Success'),
('DIM_SALESPERSON', 'Success'),
('FACT_SALES', 'Success'),
('DIM_TIME', 'Success');


SELECT * FROM list_four.load_status

DROP TABLE list_four.load_status