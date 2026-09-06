# Select the database to work with
USE DataCo_supply_chain;

SHOW VARIABLES LIKE '%timeout%';
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';

# Task 1: Customer Analysis (2015–2018)
## Who is buying DataCo's products for the reporting period between 2015-2018, and what segments do they belong to?"
SELECT DISTINCT Customer_Segment, COUNT(Customer_Segment) AS Number_of_Customers
FROM dimcustomer
GROUP BY Customer_Segment
ORDER BY Number_of_Customers;

## Where are DataCo's customers primarily located by countries?
SELECT Customer_Country, COUNT(*) AS Total_Customers
FROM dimcustomer
GROUP BY Customer_Country
ORDER BY Total_Customers DESC, Customer_Country ASC;

### Breakdown of customers by countries, state and cities
WITH CleanedCustomers AS (
    SELECT Customer_Country, 
        -- Fix the State column if it contains numbers
        CASE 
            WHEN Customer_State REGEXP '^[0-9]+$' THEN Customer_City ELSE Customer_State 
        END AS Customer_State,
        -- Fix the City column if it contains the state abbreviation
        CASE 
            WHEN Customer_State REGEXP '^[0-9]+$' THEN 'Unknown City' ELSE Customer_City 
        END AS Customer_City
    FROM dimcustomer
)
SELECT Customer_Country, Customer_State, Customer_City,
    COUNT(*) AS Total_Customers_by_Cities,
    SUM(COUNT(*)) OVER (PARTITION BY Customer_State) AS Total_Customers_State,
    SUM(COUNT(*)) OVER (PARTITION BY Customer_Country) AS Total_Customers_by_Country
FROM CleanedCustomers
GROUP BY Customer_Country, Customer_State, Customer_City 
ORDER BY Customer_Country ASC, Total_Customers_by_Cities DESC, Total_Customers_State DESC, Total_Customers_by_Country DESC, Customer_State ASC, Customer_City ASC;

## How much is DataCo active customer base growing year-over-year within each customer segment?
WITH Active_Customers_Per_Year AS (
    -- Find distinct active customers per segment per year
    SELECT C.Customer_Segment,
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Active_Year,
        COUNT(DISTINCT C.Customer_Id) AS Active_Customer_Count
    FROM factsales AS FS
    JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
    GROUP BY C.Customer_Segment, YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d'))
),
Calculated_Growth AS (
    -- Calculate growth metrics 
    SELECT Customer_Segment, Active_Year, Active_Customer_Count,
        LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Segment ORDER BY Active_Year) AS Previous_Year_Active_Count,
        (Active_Customer_Count - LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Segment ORDER BY Active_Year)) AS Net_Segment_Change,
        ROUND(
            ((Active_Customer_Count - LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Segment ORDER BY Active_Year)) / 
            LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Segment ORDER BY Active_Year)) * 100, 2
        ) AS YoY_Active_Base_Growth_Percentage
    FROM Active_Customers_Per_Year
)
-- Filter out the baseline year and sort final output
SELECT * FROM Calculated_Growth
WHERE Previous_Year_Active_Count IS NOT NULL
ORDER BY Customer_Segment, Active_Year;

## Which markets had the decline and which market had increase in active customer base?
WITH Active_Customers_Per_Year AS (
    SELECT C.Customer_Country, C.Customer_Segment,
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Active_Year,
        COUNT(DISTINCT C.Customer_Id) AS Active_Customer_Count
    FROM factsales AS FS
    JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
    GROUP BY C.Customer_Country, C.Customer_Segment, YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d'))
),
Calculated_Growth AS (
    SELECT Customer_Country, Customer_Segment, Active_Year, Active_Customer_Count,
        LAG(Active_Customer_Count) OVER(
            PARTITION BY Customer_Country, Customer_Segment 
            ORDER BY Active_Year
        ) AS Previous_Year_Active_Count,
        (Active_Customer_Count - LAG(Active_Customer_Count) OVER(
            PARTITION BY Customer_Country, Customer_Segment ORDER BY Active_Year
        )) AS Net_Segment_Change
    FROM Active_Customers_Per_Year
)
-- Main query showing both increases and declines
SELECT Customer_Country, Customer_Segment, Active_Year, Previous_Year_Active_Count, Active_Customer_Count, Net_Segment_Change,
    ROUND((Net_Segment_Change / Previous_Year_Active_Count) * 100, 2) AS YoY_Active_Base_Growth_Percentage,
    -- Added a Growth Status column to clearly tag the result
    CASE 
        WHEN Net_Segment_Change > 0 THEN 'Increase'
        WHEN Net_Segment_Change < 0 THEN 'Decline'
        ELSE 'No Change'
    END AS Growth_Status
FROM Calculated_Growth
-- Adjusted Filter: Excludes the baseline first year, but keeps both positive and negative growth
WHERE Previous_Year_Active_Count IS NOT NULL 
-- Sorted by growth percentage in descending order (Largest increases first, major declines at the bottom)
ORDER BY Customer_Country, YoY_Active_Base_Growth_Percentage DESC;

## When customer segments experience expanding or contracting active bases, which product categories are driving those changes?
WITH Active_Customers_Per_Year AS (
    SELECT C.Customer_Country, C.Customer_Segment,
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Active_Year,
        COUNT(DISTINCT C.Customer_Id) AS Active_Customer_Count
    FROM factsales AS FS
    JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
    GROUP BY C.Customer_Country, C.Customer_Segment, YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d'))
),

Calculated_Growth AS (
    SELECT Customer_Country, Customer_Segment, Active_Year,
        CASE 
            WHEN (Active_Customer_Count - LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Country, Customer_Segment ORDER BY Active_Year)) > 0 THEN 'Increase'
            WHEN (Active_Customer_Count - LAG(Active_Customer_Count) OVER(PARTITION BY Customer_Country, Customer_Segment ORDER BY Active_Year)) < 0 THEN 'Decline'
            ELSE 'No Change'
        END AS Segment_Growth_Status
    FROM Active_Customers_Per_Year
),

Category_Sales_Per_Year AS (
    SELECT C.Customer_Country, C.Customer_Segment, DC.Category_Name,
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Active_Year,
        SUM(FS.Order_Item_Quantity) AS Total_Quantity,
        ROUND(SUM(FS.Sales), 2) AS Total_Sales
    FROM factsales AS FS
    JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    GROUP BY C.Customer_Country, C.Customer_Segment, DC.Category_Name, YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d'))
),

Category_Growth_Metrics AS (
    SELECT CS.Customer_Country, CS.Customer_Segment, CG.Segment_Growth_Status, CS.Category_Name, CS.Active_Year,
        LAG(CS.Total_Sales) OVER(PARTITION BY CS.Customer_Country, CS.Customer_Segment, CS.Category_Name ORDER BY CS.Active_Year) AS Initial_Sales_Amount,
        LAG(CS.Total_Quantity) OVER(PARTITION BY CS.Customer_Country, CS.Customer_Segment, CS.Category_Name ORDER BY CS.Active_Year) AS Initial_Quantity_Amount,
        CS.Total_Sales AS Current_Sales_Amount,
        CS.Total_Quantity AS Current_Quantity_Amount
    FROM Category_Sales_Per_Year AS CS
    JOIN Calculated_Growth AS CG ON CS.Customer_Country = CG.Customer_Country 
        AND CS.Customer_Segment = CG.Customer_Segment 
        AND CS.Active_Year = CG.Active_Year
)

SELECT Active_Year, Customer_Country, Customer_Segment, Segment_Growth_Status, Category_Name,
    -- Initial Metrics (Comparison Baselines)
    Initial_Sales_Amount, Initial_Quantity_Amount,
    -- Current Metrics
    Current_Sales_Amount, Current_Quantity_Amount,
    -- Growth Calculations (Absolute and Percentage)
    ROUND((Current_Sales_Amount - Initial_Sales_Amount), 2) AS Absolute_Sales_Growth,
    ROUND(((Current_Sales_Amount - Initial_Sales_Amount) / Initial_Sales_Amount) * 100, 2) AS Sales_Growth_Percentage,
    
    (Current_Quantity_Amount - Initial_Quantity_Amount) AS Absolute_Quantity_Growth,
    ROUND(((Current_Quantity_Amount - Initial_Quantity_Amount) / Initial_Quantity_Amount) * 100, 2) AS Quantity_Growth_Percentage

FROM Category_Growth_Metrics
-- Exclude the baseline first year where LAG columns are NULL
WHERE Initial_Sales_Amount IS NOT NULL AND Segment_Growth_Status IN ('Increase', 'Decline')
-- Grouping results visually by Year, then Country, sorting by the highest absolute revenue drivers
ORDER BY Active_Year ASC, Customer_Country ASC, Segment_Growth_Status DESC, Absolute_Sales_Growth DESC;


## What are the most popular product categories across different customer segments and countries, and what is their lifetime order frequency, total items purchased, and total sales?
SELECT C.Customer_Country, C.Customer_Segment, DC. Category_Name,
    COUNT(DISTINCT FS.Order_Id) AS Lifetime_Order_Frequency,
    SUM(FS.Order_Item_Quantity) AS Total_Items_Purchased,
    ROUND(SUM(FS.Sales), 2) AS Lifetime_Sales,
    SUM(SUM(FS.Order_Item_Quantity)) OVER(PARTITION BY C.Customer_Country, DC.Category_Name) AS Total_Category_Purchased
FROM factsales AS FS
JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
GROUP BY C.Customer_Country, C.Customer_Segment, DC.Category_Name
ORDER BY C.Customer_Country, C.Customer_Segment, Lifetime_Sales DESC;

## Which specific customers have the highest lifetime frequency of orders?
SELECT C.Customer_Country, C.Customer_Id, C.Customer_Name, C.Customer_Segment, DC.Category_Name,
    COUNT(DISTINCT FS.Order_Id) AS Lifetime_Order_Frequency,
    SUM(FS.Order_Item_Quantity) AS Total_Items_Purchased,
    ROUND(SUM(FS.Sales), 2) AS Lifetime_Sales,
    SUM(SUM(FS.Order_Item_Quantity)) OVER(PARTITION BY DC.Category_Name) AS Total_Category_Purchased
FROM factsales AS FS
JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
GROUP BY C.Customer_Country, C.Customer_Id, C.Customer_Name, C.Customer_Segment, DC.Category_Name
ORDER BY C.Customer_Country, Lifetime_Order_Frequency DESC,  DC.Category_Name, Lifetime_Sales DESC;