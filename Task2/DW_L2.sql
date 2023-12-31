--Prepare SQL queries within SQL Management Studio against DIMProduct table (AdventureWorksDW), that as a result:
--1. provides information about product�s name, product�s colour and number of items in stock (RebalancePoint or so) � do not use PIVOT yet;

SELECT
  Name AS ProductName,
  Color,
  ReorderPoint AS ItemsInStock
FROM
  Production.Product
WHERE
  Color IS NOT NULL
ORDER BY
  Color,
  ItemsInStock ASC;

--2. provides information about number of items in stock for different colours of products; please putcolours on columns, products� names on rows, and items in stock as values (use PIVOT)

SELECT 
    ProductName,
    ISNULL([Black], 0) AS [Black], 
    ISNULL([Blue], 0) AS [Blue], 
    ISNULL([Grey], 0) AS [Grey], 
    ISNULL([Multi], 0) AS [Multi], 
    ISNULL([Red], 0) AS [Red], 
    ISNULL([Silver], 0) AS [Silver], 
    ISNULL([White], 0) AS [White], 
    ISNULL([Yellow], 0) AS [Yellow]
FROM
(
    SELECT 
        p.Name AS ProductName,
        p.Color AS ProductColor,
        p.SafetyStockLevel AS QuantityInStock
    FROM 
        Production.Product p
) AS SourceTable
PIVOT
(
    SUM(QuantityInStock)
    FOR ProductColor IN ([Black], [Blue], [Grey], [Multi], [Red], [Silver], [White], [Yellow])
) AS PivotTable;

--3. provides information about average sales subtotal amounts in years due to months; please put months on columns, years on rows, and subtotal as values (use PIVOT)

SELECT *
FROM
(
    SELECT YEAR(OrderDate) AS [Year], DATENAME(MONTH, OrderDate) AS [Month], SubTotal
    FROM Sales.SalesOrderHeader
) AS SourceTable
PIVOT
(
    AVG(SubTotal)
    FOR [Month] IN ([January], [February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December])
) AS PivotTable
ORDER BY [Year];

--Prepare SQL queries (using grouping operator) within SQL Management Studio against FactIntenetSales table, that as a result: 
--4. provides information about sales value (TotalDue) for different years (aggregated) along with a total value of sales (TotalDue); (use either ROLLUP, CUBE or GROUPING SETS)

SELECT
  YEAR(OrderDate) AS OrderYear,
  SUM(TotalDue) AS TotalSales
FROM
  Sales.SalesOrderHeader
GROUP BY
  GROUPING SETS(YEAR(OrderDate), ())
ORDER BY
  YEAR(OrderDate);

--5. provides information about sales value for different products and different years, months and days � please provide sales summaries after each month, each year, and total value; (use a single SQL query with either ROLLUP, CUBE or GROUPING SETS)

SELECT
  Name AS ProductName,
  YEAR(OrderDate) AS OrderYear,
  MONTH(OrderDate) AS OrderMonth,
  DAY(OrderDate) AS OrderDay,
  SUM(TotalDue) AS TotalSales
FROM
  Sales.SalesOrderHeader
  JOIN Sales.SalesOrderDetail ON Sales.SalesOrderHeader.SalesOrderID = Sales.SalesOrderDetail.SalesOrderID
  JOIN Production.Product ON Sales.SalesOrderDetail.ProductID = Production.Product.ProductID
GROUP BY
  ROLLUP(
    Name,
    YEAR(OrderDate),
    MONTH(OrderDate),
    DAY(OrderDate)
  )
ORDER BY
  ProductName,
  YEAR(OrderDate),
  MONTH(OrderDate),
  DAY(OrderDate);

--6. that calculates total values over all possible groupings of location attributes �country, region, city (we need all possible sub totals, e.g., by different countries, different regions, different cities); (use a single SQL query with either ROLLUP, CUBE or GROUPING SETS)

SELECT 
  CR.CountryRegionCode AS CountryCode, 
  CR.Name AS CountryName, 
  SP.StateProvinceCode AS StateCode, 
  SP.Name AS StateName, 
  A.City, 
  SUM(SOH.TotalDue) AS TotalSales
FROM 
  Sales.SalesOrderHeader SOH
  JOIN Person.Address A ON SOH.ShipToAddressID = A.AddressID
  JOIN Person.StateProvince SP ON A.StateProvinceID = SP.StateProvinceID
  JOIN Person.CountryRegion CR ON SP.CountryRegionCode = CR.CountryRegionCode
GROUP BY 
  GROUPING SETS (
    (), -- Grand total
    (CR.CountryRegionCode, CR.Name),
    (CR.CountryRegionCode, CR.Name, SP.StateProvinceCode, SP.Name),
    (CR.CountryRegionCode, CR.Name, SP.StateProvinceCode, SP.Name, A.City)
  )
ORDER BY 
  CountryCode, StateCode, City;

--Prepare SQL queries within SQL Management Studio against DIMProduct, that as a result(use CASE):
--7. provides information about different product�s price categories:
--		a. ListPrice < 20.00 � Inexpensive
--		b. 20.00 < ListPrice < 75.00 � Regular
--		c. 75 < ListPrice < 750.00 � High
--		d. 750.00 < ListPrice �Expensive

SELECT ProductID, ListPrice,
    CASE
        WHEN ListPrice < 20.00 THEN 'Inexpensive'
        WHEN ListPrice BETWEEN 20.00 AND 75.00 THEN 'Regular'
        WHEN ListPrice BETWEEN 75.00 AND 750.00 THEN 'High'
        ELSE 'Expensive'
    END AS PriceCategory
FROM Production.Product;

--8. provides information about product�s name and weight displayed in kilograms (!!!). If the we ight is unavailable utilise 0. 

SELECT Name,
    CASE
        WHEN WeightUnitMeasureCode = 'LB' THEN CAST(Weight * 0.453592 AS DECIMAL(10, 2)) -- Convert pounds to kilograms
        WHEN WeightUnitMeasureCode = 'G' THEN CAST(Weight / 1000 AS DECIMAL(10, 2)) -- Convert grams to kilograms
        ELSE 0 -- Display 0 if weight is unavailable
    END AS WeightInKilograms
FROM Production.Product
ORDER BY WeightInKilograms;

--9. Analyze data in one table (containing product categories) in AdventureWorks and one table (DimProduct) in AdventureWorksDW. You have at least three approaches possible:
--		a. use DataQualityService on SQL Server, or
--		b. use Visual Studio and in a project for Integration Services use Data Profiling Task (and Data Profile Viewer), or
--		c. you can also write appropriate SQLs on your own to check
-- For the names of categories, determine the number of NULL values, most and least common value (withcount), how many different values there are, the neutral category name (is it NULL or anything else?).

SELECT 
    pc.name AS CategoryName,
    COUNT(DISTINCT p.ProductID) AS NumberOfProducts,
    COUNT(CASE WHEN p.Name IS NULL THEN 1 END) AS NumberOfNullNames,
    MAX(p.Name) AS MostCommonName,
    MIN(p.Name) AS LeastCommonName,
    COUNT(DISTINCT p.Name) AS NumberOfDifferentNames,
    CASE WHEN COUNT(DISTINCT p.Name) = 1 AND MAX(p.Name) IS NULL THEN 'NULL' ELSE 'Not NULL' END AS NeutralCategoryName
FROM 
    Production.ProductCategory pc
LEFT JOIN 
    Production.ProductSubcategory psc ON pc.ProductCategoryID = psc.ProductCategoryID
LEFT JOIN 
    Production.Product p ON psc.ProductSubcategoryID = p.ProductSubcategoryID
GROUP BY 
    pc.name;