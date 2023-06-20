CREATE DATABASE twitter;

USE twitter;

CREATE TABLE twitter_data (
    Date DATE,
    Opening_price FLOAT,
    Highest_recorded FLOAT,
    Lowest_recorded FLOAT,
    Closing_price FLOAT,
    Adjusted_Closing FLOAT,
    Volume INT
);

SELECT * FROM twitter_data

-- VOLATILITY
-- daily price volatility for each day
SELECT Date, (Highest_recorded - Lowest_recorded) AS Daily_volatility
FROM twitter_data;

-- average daily price volatility for each day
SELECT AVG(Highest_recorded - Lowest_recorded) AS Average_daily_volatility
FROM twitter_data;

-- average daily price volatility by date
SELECT AVG(Highest_recorded - Lowest_recorded) AS Average_daily_volatility
FROM twitter_data
WHERE Date >= '2013-11-01' AND Date < '2013-12-01';

-- Average_daily_volatility by month
SELECT DATEPART(month, Date) AS Month, AVG(Highest_recorded - Lowest_recorded) AS Average_daily_volatility
FROM twitter_data
GROUP BY DATEPART(month, Date)
ORDER BY Month ASC;

-------------------------------------------------------------------------------------------------------------

-- Date dimension
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    Date DATE,
    Day INT,
    Month INT,
    Year INT
);

-- Populate the dimension
INSERT INTO DimDate (DateKey, Date, Day, Month, Year)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), Date, 112)) AS DateKey,
    Date,
    DATEPART(day, Date) AS Day,
    DATEPART(month, Date) AS Month,
    DATEPART(year, Date) AS Year
FROM twitter_data;


-- Fact table
CREATE TABLE FactTwitterData (
    DateKey INT,
    OpeningPrice FLOAT,
    ClosingPrice FLOAT,
    HighestRecorded FLOAT,
    LowestRecorded FLOAT,
    AdjustedClosing FLOAT,
    Volume INT
);

-- Populate Fact table
INSERT INTO FactTwitterData (DateKey, OpeningPrice, ClosingPrice, HighestRecorded, LowestRecorded, AdjustedClosing, Volume)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), Date, 112)) AS DateKey,
    Opening_price AS OpeningPrice,
    Closing_price AS ClosingPrice,
    Highest_recorded AS HighestRecorded,
    Lowest_recorded AS LowestRecorded,
    Adjusted_Closing AS AdjustedClosing,
    Volume
FROM twitter_data;

-------------------------------------------------------------------------------
-- RSI 
-- Create RSI dimension table
CREATE TABLE DimRSI (
    RSIKey INT PRIMARY KEY,
    DateKey INT,
    RSIValue FLOAT,
    IsOverbought BIT,
    IsOversold BIT,
    FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);

-- Populate RSI dimension table
INSERT INTO DimRSI (RSIKey, DateKey, RSIValue, IsOverbought, IsOversold)
SELECT
    ROW_NUMBER() OVER (ORDER BY DateKey) AS RSIKey,
    DateKey,
    RSIValue,
    CASE WHEN RSIValue > 70 THEN 1 ELSE 0 END AS IsOverbought,
    CASE WHEN RSIValue < 30 THEN 1 ELSE 0 END AS IsOversold
FROM
(
    SELECT
        DateKey,
        -- Calculate RSI using closing prices
        (CASE
            WHEN AvgGain IS NULL AND AvgLoss IS NULL THEN 50 -- Initial RSI value
            WHEN AvgLoss IS NULL OR AvgLoss = 0 THEN 100 -- RSI value for upward movement or avoid divide by zero error
            ELSE 100 - (100 / (1 + (AvgGain / AvgLoss))) -- RSI formula
        END) AS RSIValue
    FROM
    (
        SELECT
            DateKey,
            SUM(Gain) / 14 AS AvgGain,
            SUM(Loss) / 14 AS AvgLoss
        FROM
        (
            SELECT
                DateKey,
                CASE
                    WHEN ClosingPrice > Lag(ClosingPrice) OVER (ORDER BY DateKey) THEN ClosingPrice - Lag(ClosingPrice) OVER (ORDER BY DateKey)
                    ELSE 0
                END AS Gain,
                CASE
                    WHEN ClosingPrice < Lag(ClosingPrice) OVER (ORDER BY DateKey) THEN Lag(ClosingPrice) OVER (ORDER BY DateKey) - ClosingPrice
                    ELSE 0
                END AS Loss
            FROM FactTwitterData
        ) AS RSICalc
        GROUP BY DateKey
    ) AS RSIAvg
) AS RSIData;

-- Fact table with RSI data
CREATE TABLE FactRSI (
    DateKey INT,
    RSIKey INT,
    FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    FOREIGN KEY (RSIKey) REFERENCES DimRSI(RSIKey)
);

-- Populate Fact table with RSI data
INSERT INTO FactRSI (DateKey, RSIKey)
SELECT
    DateKey,
    RSIKey
FROM
(
    SELECT
        DateKey,
        RSIKey
    FROM DimRSI
) AS RSI;

SELECT * FROM FactRSI


