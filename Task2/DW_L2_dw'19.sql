-- 4
SELECT YEAR(OrderDate) AS OrderYear, SUM(TotalProductCost) AS TotalSales
FROM FactInternetSales
GROUP BY GROUPING SETS(YEAR(OrderDate), ())
ORDER BY YEAR(OrderDate);

-- 7
SELECT EnglishProductName, ListPrice,
    CASE
        WHEN ListPrice < 20.00 THEN 'Inexpensive'
        WHEN ListPrice BETWEEN 20.00 AND 75.00 THEN 'Regular'
        WHEN ListPrice BETWEEN 75.00 AND 750.00 THEN 'High'
        ELSE 'Expensive'
    END AS PriceCategory
FROM DimProduct
WHERE ListPrice IS NOT NULL
ORDER BY ListPrice;

-- 9
SELECT 
    pc.EnglishProductCategoryName AS CategoryName,
    COUNT(DISTINCT p.ProductKey) AS NumberOfProducts,
    COUNT(CASE WHEN p.EnglishProductName IS NULL THEN 1 END) AS NumberOfNullNames,
    MAX(p.EnglishProductName) AS MostCommonName,
    MIN(p.EnglishProductName) AS LeastCommonName,
    COUNT(DISTINCT p.EnglishProductName) AS NumberOfDifferentNames,
    CASE WHEN COUNT(DISTINCT p.EnglishProductName) = 1 AND MAX(p.EnglishProductName) IS NULL THEN 'NULL' ELSE 'Not NULL' END AS NeutralCategoryName
FROM 
    AdventureWorksDW2019.dbo.DimProduct p
LEFT JOIN 
    AdventureWorksDW2019.dbo.DimProductSubcategory psc ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
LEFT JOIN 
    AdventureWorksDW2019.dbo.DimProductCategory pc ON psc.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY 
    pc.EnglishProductCategoryName;