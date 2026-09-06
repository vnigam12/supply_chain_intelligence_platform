# Select the database to work with
USE DataCo_supply_chain;

SHOW VARIABLES LIKE '%timeout%';
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';

# Task 3: Conversion and Sales analysis (2015–2018)
## How do Benefit per order and Sales per customer vary across different customer segments?
SELECT C.Customer_Segment, COUNT(DISTINCT C.Customer_Id) AS Total_Customers,
    COUNT(DISTINCT FS.Order_Id) AS Total_Orders,
    ROUND(SUM(FS.Sales) / COUNT(DISTINCT FS.Customer_Id), 2) AS Avg_Sales_Per_Customer,
    ROUND(SUM(FS.Benefit_per_order) / COUNT(DISTINCT FS.Order_Id), 2) AS Avg_Benefit_Per_Order,
    ROUND(SUM(FS.Sales), 2) AS Total_Segment_Sales,
    ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Segment_Profit
FROM factsales AS FS
JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
GROUP BY C.Customer_Segment
ORDER BY Avg_Sales_Per_Customer DESC;

## What is the average discount_rage given by category and is there any different between customer country?
SELECT C.Customer_Country, DC.Category_Name, COUNT(DISTINCT FS.Order_Id) AS Total_Orders,
    ROUND(SUM(FS.Sales), 2) AS Total_Revenue, ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Profit,
    ROUND(AVG(FS.Order_Item_Discount_Rate) * 100, 2) AS Avg_Discount_Rate_Percentage,
    ROUND(SUM(FS.Order_Item_Discount), 2) AS Total_Discounts_Given
FROM factsales AS FS
JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id
GROUP BY C.Customer_Country, DC.Category_Name
ORDER BY C.Customer_Country, Total_Revenue DESC;

# What are the top 10 best-performing product categories by total sales revenue across different geographic regions, and how volume-dense and profitable are they?
WITH RankedSales AS (
    SELECT DC.Category_Name, DL.Order_Region, SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
        ROUND(SUM(FS.Sales), 2) AS Total_Sales, ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Profit,
        DENSE_RANK() OVER (PARTITION BY DL.Order_Region ORDER BY SUM(FS.Sales) DESC) AS Sales_Rank
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
    GROUP BY DC.Category_Name, DL.Order_Region
)
SELECT Category_Name, Order_Region, Total_Quantity_Ordered,
    Total_Sales, Total_Profit, Sales_Rank
FROM RankedSales
WHERE Sales_Rank <= 10
ORDER BY Order_Region, Sales_Rank;

## What are the top 10 best-performing product categories by total sales revenue across different geographic regions with annual YoY growth?
WITH AnnualSalesBase AS (
    SELECT YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Order_Year, DC.Category_Name, DL.Order_Region, 
        SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
        ROUND(SUM(FS.Sales), 2) AS Total_Sales, 
        ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Profit
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
    GROUP BY YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')), DC.Category_Name, DL.Order_Region),
SalesWithYoY AS (
    SELECT Order_Year, Category_Name, Order_Region, Total_Quantity_Ordered, Total_Sales, Total_Profit,
        -- Pull the previous year's sales for the same category and region
        LAG(Total_Sales, 1) OVER (PARTITION BY Order_Region, Category_Name ORDER BY Order_Year) AS Previous_Year_Sales,

        -- Rank the categories within each region per specific year
        DENSE_RANK() OVER (PARTITION BY Order_Year, Order_Region ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM AnnualSalesBase
)
SELECT Order_Year, Sales_Rank, Category_Name, Order_Region, Total_Quantity_Ordered, Total_Sales, Total_Profit,
    -- Handle the first year baseline case cleanly (returns NULL or 0% instead of breaking)
    CASE 
        WHEN Previous_Year_Sales IS NULL THEN NULL
        ELSE ROUND(((Total_Sales - Previous_Year_Sales) / Previous_Year_Sales) * 100, 2)
    END AS YoY_Sales_Growth_Percentage
FROM SalesWithYoY
WHERE Sales_Rank <= 10
ORDER BY Order_Year DESC, Order_Region ASC, Sales_Rank ASC;

## What are the top 10 best-performing product categories by total sales revenue across different geographic regions with overall period growth rate?
WITH RegionalCategoryBoundaries AS (
    -- Find the absolute earliest and latest operational years for each category per region
    SELECT DC.Category_Name, DL.Order_Region,
        MIN(YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d'))) AS Start_Year,
        MAX(YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d'))) AS End_Year
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
    GROUP BY DC.Category_Name, DL.Order_Region
),
OverallPeriodSales AS (
    -- Aggregate lifetime performance metrics and extract boundary sales
    SELECT DC.Category_Name, DL.Order_Region, 
        SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
        ROUND(SUM(FS.Sales), 2) AS Lifetime_Total_Sales, 
        ROUND(SUM(FS.Benefit_per_order), 2) AS Lifetime_Total_Profit,
        -- Capture sales from the earliest year
        ROUND(SUM(CASE 
            WHEN YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d')) = RCB.Start_Year 
            THEN FS.Sales ELSE 0 
        END), 2) AS Initial_Year_Sales,
        
        -- Capture sales from the most lastest year
        ROUND(SUM(CASE 
            WHEN YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d')) = RCB.End_Year 
            THEN FS.Sales ELSE 0 
        END), 2) AS Final_Year_Sales,
        
        -- Rank categories within each region based on their lifetime total revenue contribution
        DENSE_RANK() OVER (PARTITION BY DL.Order_Region ORDER BY SUM(FS.Sales) DESC) AS Sales_Rank
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
    JOIN RegionalCategoryBoundaries AS RCB 
        ON DC.Category_Name = RCB.Category_Name 
        AND DL.Order_Region = RCB.Order_Region
    GROUP BY DC.Category_Name, DL.Order_Region, RCB.Start_Year, RCB.End_Year
)
SELECT Sales_Rank, Category_Name, Order_Region, Total_Quantity_Ordered, Lifetime_Total_Sales, Lifetime_Total_Profit,
    
    -- Compute the total growth percentage over the timeline
    CASE 
        WHEN Initial_Year_Sales = 0 THEN NULL
        ELSE ROUND(((Final_Year_Sales - Initial_Year_Sales) / Initial_Year_Sales) * 100, 2)
    END AS Overall_Period_Growth_Percentage
FROM OverallPeriodSales
WHERE Sales_Rank <= 10
ORDER BY Order_Region ASC, Sales_Rank ASC;

## What are the top 10 best-performing product categories by total sales revenue with overall period growth rate?
WITH CategoryTimeBoundaries AS (
    -- Step 1: Find the absolute earliest and latest operational years for each category globally
    SELECT 
        DC.Category_Name,
        MIN(YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d'))) AS Start_Year,
        MAX(YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d'))) AS End_Year
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    GROUP BY DC.Category_Name
),
OverallCategorySales AS (
    -- Step 2: Aggregate global lifetime metrics and extract baseline boundary sales
    SELECT 
        DC.Category_Name, 
        SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
        ROUND(SUM(FS.Sales), 2) AS Lifetime_Total_Sales, 
        ROUND(SUM(FS.Benefit_per_order), 2) AS Lifetime_Total_Profit,
        
        -- Capture global sales from the category's earliest starting year
        ROUND(SUM(CASE 
            WHEN YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d')) = CTB.Start_Year 
            THEN FS.Sales ELSE 0 
        END), 2) AS Initial_Year_Sales,
        
        -- Capture global sales from the category's most recent final year
        ROUND(SUM(CASE 
            WHEN YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR(8)), '%Y%m%d')) = CTB.End_Year 
            THEN FS.Sales ELSE 0 
        END), 2) AS Final_Year_Sales,
        
        -- Rank categories globally based on their lifetime total revenue contribution
        DENSE_RANK() OVER (ORDER BY SUM(FS.Sales) DESC) AS Sales_Rank
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN CategoryTimeBoundaries AS CTB ON DC.Category_Name = CTB.Category_Name
    GROUP BY DC.Category_Name, CTB.Start_Year, CTB.End_Year
)
SELECT 
    Sales_Rank,
    Category_Name, 
    Total_Quantity_Ordered,
    Lifetime_Total_Sales, 
    Lifetime_Total_Profit,
    
    -- Step 3: Compute the overall total growth percentage over the timeline
    CASE 
        WHEN Initial_Year_Sales = 0 THEN NULL
        ELSE ROUND(((Final_Year_Sales - Initial_Year_Sales) / Initial_Year_Sales) * 100, 2)
    END AS Overall_Period_Growth_Percentage
FROM OverallCategorySales
WHERE Sales_Rank <= 10
ORDER BY Sales_Rank ASC;

## Are DataCo's highest-revenue regions and categories actually our most profitable ones?
SELECT DL.Market, DL.Order_Region AS Shipping_Region, DCat.Category_Name,
    SUM(FS.Order_Item_Quantity) AS Total_Units_Sold, ROUND(SUM(FS.Sales), 2) AS Total_Sales_Revenue,
    ROUND(SUM(FS.Order_Profit_Per_Order), 2) AS Net_Profit,
	ROUND((SUM(FS.Order_Profit_Per_Order) / SUM(FS.Sales)) * 100, 2) AS Profit_Margin_Percentage,
    RANK() OVER (ORDER BY SUM(FS.Sales) DESC) AS Revenue_Rank,
    RANK() OVER (ORDER BY SUM(FS.Order_Profit_Per_Order) DESC) AS Profit_Rank
FROM FactSales AS FS
JOIN DimLocation AS DL ON FS.Location_Id = DL.Location_Id
JOIN DimCategory AS DCat ON FS.Category_Id = DCat.Category_Id
GROUP BY DL.Market, DL.Order_Region, DCat.Category_Name
ORDER BY Revenue_Rank, Profit_Rank, Market, Total_Sales_Revenue DESC;

## Is high sales volume driven by a few bulk orders or a high frequency of individual purchases?
WITH OrderTotals AS (
    SELECT FS.Order_Id, SUM(FS.Order_Item_Quantity) AS Total_Units_In_Order, SUM(FS.Sales) AS Total_Sales_Value
    FROM FactSales AS FS
    GROUP BY FS.Order_Id
),
OrderSegmentation AS (
    SELECT Order_Id, Total_Units_In_Order, Total_Sales_Value,
        CASE 
            WHEN Total_Units_In_Order = 1 THEN '1. Individual (1 Unit)'
            WHEN Total_Units_In_Order BETWEEN 2 AND 4 THEN '2. Small Consumer (2-4 Units)'
            WHEN Total_Units_In_Order BETWEEN 5 AND 9 THEN '3. Mid-Market / Multi-Buy (5-9 Units)'
            ELSE '4. Commercial / Bulk (10+ Units)'
        END AS Order_Size_Segment
    FROM OrderTotals
)
SELECT OS.Order_Size_Segment, COUNT(OS.Order_Id) AS Total_Placed_Orders,
    ROUND((COUNT(OS.Order_Id) / (SELECT COUNT(*) FROM OrderTotals)) * 100, 2) AS Order_Percentage_Total,
    SUM(OS.Total_Units_In_Order) AS Aggregate_Units_Sold,
    ROUND((SUM(OS.Total_Units_In_Order) / (SELECT SUM(Total_Units_In_Order) FROM OrderTotals)) * 100, 2) AS Units_Percentage_Total,
    ROUND(SUM(OS.Total_Sales_Value), 2) AS Total_Revenue_Generated,
    ROUND((SUM(OS.Total_Sales_Value) / (SELECT SUM(Total_Sales_Value) FROM OrderTotals)) * 100, 2) AS Total_Revenue_Percentage,
    ROUND(AVG(OS.Total_Sales_Value), 2) AS Avg_Ticket_Value_Per_Order
FROM OrderSegmentation AS OS
GROUP BY OS.Order_Size_Segment
ORDER BY OS.Order_Size_Segment ASC;

## What payment types are used for orders and how do they contribute to revenue?
SELECT OD.Payment_Type, COUNT(DISTINCT FS.Order_Id) AS Total_Orders, 
	ROUND((COUNT(DISTINCT FS.Order_Id) / SUM(COUNT(DISTINCT FS.Order_Id)) OVER()) * 100, 2) AS Order_Volume_Share_Percentage,
    ROUND(SUM(FS.Sales), 2) AS Total_Sales_Revenue,
    ROUND(SUM(FS.Sales) / COUNT(DISTINCT FS.Order_Id), 2) AS Avg_Order_Value
FROM factsales AS FS
JOIN dimorderdetails AS OD ON FS.Order_Id = OD.Order_Id
GROUP BY OD.Payment_Type
ORDER BY Total_Sales_Revenue DESC;

## What are the most frequently browsed products, categories, or departments broken down by year?
SELECT YEAR(FW.Timestamp) AS Traffic_Year, DC.Category_Name, DD.Department_Name, DP.Product_Name, 
    COUNT(*) AS Total_Page_Views,
    ROUND((COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY YEAR(FW.Timestamp))) * 100, 2) AS Product_Traffic_Share_Percentage,
    COUNT(DISTINCT FW.Log_Id) AS Unique_Visitors
FROM factwebtraffic AS FW
JOIN dimproduct AS DP ON FW.Product_Card_Id = DP.Product_Card_Id
JOIN dimcategory AS DC ON FW.Category_Id = DC.Category_Id
JOIN dimdepartment AS DD ON FW.Department_Id = DD.Department_Id
GROUP BY YEAR(FW.Timestamp), DC.Category_Name, DD.Department_Name, DP.Product_Name
ORDER BY Traffic_Year DESC, Total_Page_Views DESC; 

## How many web sessions are linked to an actual order?
SELECT COUNT(FW.Associated_Order_Id IS NOT NULL) AS Sessions_With_Orders, COUNT(*) AS Total_Web_Sessions,
    ROUND((COUNT(FW.Associated_Order_Id) / COUNT(*)) * 100, 2) AS Session_To_Order_Link_Rate_Percentage
FROM factwebtraffic AS FW;

## What day of the week do most orders or web traffic events occur?
SELECT DAYNAME(FW.Timestamp) AS Day_Of_Week, COUNT(*) AS Total_Web_Hits,
    ROUND((COUNT(FW.Log_Id) / SUM(COUNT(*)) OVER()) * 100, 2) AS Traffic_Share_Percentage,
    COUNT(FW.Associated_Order_Id) AS Orders_Placed,
    ROUND((COUNT(FW.Associated_Order_ID) / COUNT(FW.Log_Id)) * 100, 2) AS Web_Conversion_Rate_Percentage
FROM factwebtraffic AS FW
GROUP BY DAYNAME(FW.Timestamp), WEEKDAY(FW.Timestamp)
ORDER BY WEEKDAY(FW.Timestamp) ASC;

## What products are most heavily browsed on each weekday and which ones convert best (Top 5 each day)?
WITH DailyProductMetrics AS (
    SELECT WEEKDAY(FW.Timestamp) AS Weekday_Index, DAYNAME(FW.Timestamp) AS Day_Of_Week,
        DP.Product_Name, COUNT(FW.Log_Id) AS Unique_Visitors, COUNT(FW.Associated_Order_Id) AS Orders_Placed,
		ROUND((COUNT(FW.Associated_Order_Id) / COUNT(FW.Log_Id)) * 100, 2) AS Web_Conversion_Rate_Percentage,
        ROW_NUMBER() OVER(PARTITION BY WEEKDAY(FW.Timestamp) ORDER BY COUNT(FW.Log_Id) DESC) AS Browsed_Volume_Rank,
        ROW_NUMBER() OVER(PARTITION BY WEEKDAY(FW.Timestamp) ORDER BY (COUNT(FW.Associated_Order_Id) / COUNT(FW.Log_Id)) DESC) AS Conversion_Rate_Rank
    FROM factwebtraffic AS FW
    JOIN dimproduct AS DP ON FW.Product_Card_Id = DP.Product_Card_Id
    GROUP BY WEEKDAY(FW.Timestamp), DAYNAME(FW.Timestamp), DP.Product_Name
)
SELECT Day_Of_Week, Product_Name, Unique_Visitors, Orders_Placed, Web_Conversion_Rate_Percentage
FROM DailyProductMetrics
-- Filters down to show only the Top 5 most browsed OR Top 5 best converting products for each day
WHERE Browsed_Volume_Rank <= 5 OR (Conversion_Rate_Rank <= 5 AND Orders_Placed > 2)
ORDER BY Weekday_Index ASC;

## What is the conversion rate from browsing a product to purchasing it broken down by year?
SELECT YEAR(FW.Timestamp) AS Traffic_Year, DP.Product_Name,  DC.Category_Name, DD.Department_Name, 
	COUNT(FW.Log_Id) AS Total_Browsing_Events, COUNT(FW.Log_Id) AS Unique_Browsers,
    COUNT(FW.Associated_Order_Id) AS Successful_Purchases,
    ROUND((COUNT(FW.Associated_Order_Id) / COUNT(FW.Log_Id)) * 100, 2) AS Web_Conversion_Rate_Percentage
FROM factwebtraffic AS FW
JOIN dimproduct AS DP ON FW.Product_Card_Id = DP.Product_Card_Id
JOIN dimcategory AS DC ON FW.Category_Id = DC.Category_Id
JOIN dimdepartment AS DD ON FW.Department_Id = DD.Department_Id 
GROUP BY YEAR(FW.Timestamp), DD.Department_Name, DC.Category_Name, DP.Product_Name
ORDER BY Web_Conversion_Rate_Percentage DESC;

## Join all table for Python analysis
-- Master sales table
DROP TABLE IF EXISTS master_sales_denormalized_view;
CREATE TABLE master_sales_denormalized_view AS
SELECT FS.Order_Item_Id, FS.Order_Id, DC.Customer_Id, FS.Product_Card_Id, FS.Category_Id, FS.Department_Id,
    FS.Location_Id, FS.Shipping_Id,
    DC.Customer_Name, DC.Customer_Segment, DC.Customer_City, DC.Customer_State, DC.Customer_Country,
    DP.Product_Name, DP.Product_Price, DP.Product_Status,
    DCat.Category_Name, DD.Department_Name,
    DL.Order_City AS Shipping_City, DL.Order_Country AS Shipping_Country, DL.Order_Region AS Shipping_Region,
    DL.Order_State, DL.Market,
    DS.Shipping_Mode, DS.Delivery_Status, DS.Late_delivery_risk, DS.Shipping_Date_Key,
    OD.Order_Status, OD.Payment_Type, OD.Order_Date_Key,
    DDATE.Weekday AS Order_Weekday,
    FS.Sales, FS.Order_Item_Total, FS.Order_Profit_Per_Order, FS.Benefit_per_order,
    FS.Sales_per_customer, FS.Order_Item_Quantity, FS.Order_Item_Discount,
    FS.Order_Item_Discount_Rate, FS.Order_Item_Product_Price,
    FS.Order_Item_Profit_Ratio, FS.Days_for_shipping_real,
    FS.Days_for_shipment_scheduled, FS.Latitude, FS.Longitude
FROM FactSales AS FS
LEFT JOIN DimCustomer AS DC ON FS.Customer_Id = DC.Customer_Id
LEFT JOIN DimProduct AS DP ON FS.Product_Card_Id = DP.Product_Card_Id
LEFT JOIN DimCategory AS DCat ON FS.Category_Id = DCat.Category_Id
LEFT JOIN DimDepartment AS DD ON FS.Department_Id = DD.Department_Id
LEFT JOIN DimLocation AS DL ON FS.Location_Id = DL.Location_Id
LEFT JOIN DimShipping AS DS ON FS.Shipping_Id = DS.Shipping_Id
LEFT JOIN DimOrderDetails AS OD ON FS.Order_Id = OD.Order_Id
LEFT JOIN DimDate AS DDATE ON FS.Order_Date_Key = DDATE.Date_Key;

-- Save the sales records straight to designated folder
SELECT * INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\master_sales_export.csv'
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM master_sales_denormalized_view;

-- Final validation row count check
SELECT COUNT(*) AS Stored_Sales_Rows FROM master_sales_denormalized_view;


## Customer Journey Analysis: Linking Web Traffic to Sales (Master View)
DROP TABLE IF EXISTS master_customer_journey_view;
CREATE TABLE master_customer_journey_view AS
WITH UniqueSalesHeader AS (
    SELECT FS.Order_Id, MAX(FS.Order_Date_Key) AS Order_Date_Key, MAX(FS.Order_Item_Id) AS Order_Item_Id, 
        MAX(FS.Customer_Id) AS Customer_Id, MAX(FS.Product_Card_Id) AS Product_Card_Id,
        MAX(FS.Category_Id) AS Category_Id, MAX(FS.Department_Id) AS Department_Id,
        MAX(FS.Location_Id) AS Location_Id, MAX(FS.Shipping_Id) AS Shipping_Id,
        SUM(FS.Sales) AS Total_Sales_Value, SUM(FS.Order_Item_Total) AS Net_Order_Total,
        SUM(FS.Order_Profit_Per_Order) AS Total_Order_Profit, SUM(FS.Benefit_per_order) AS Total_Benefit,
        SUM(FS.Sales_per_customer) AS Total_Sales_Per_Customer, SUM(FS.Order_Item_Quantity) AS Total_Units_In_Order,
        SUM(FS.Order_Item_Discount) AS Total_Order_Discounts, AVG(FS.Order_Item_Discount_Rate) AS Avg_Order_Discount_Rate,
        AVG(FS.Order_Item_Product_Price) AS Avg_Product_Price, AVG(FS.Order_Item_Profit_Ratio) AS Avg_Profit_Ratio,
        MAX(FS.Days_for_shipping_real) AS Days_for_shipping_real, MAX(FS.Days_for_shipment_scheduled) AS Days_for_shipment_scheduled,
        MAX(FS.Latitude) AS Latitude, MAX(FS.Longitude) AS Longitude
    FROM FactSales AS FS
    GROUP BY FS.Order_Id
)
SELECT FW.Log_Id, FW.Timestamp AS Web_Access_Timestamp, FW.Associated_Order_Id,
    FW.IP_Address, FW.URL, USH.Order_Item_Id,
    USH.Order_Id, USH.Customer_Id, USH.Product_Card_Id, USH.Category_Id, USH.Department_Id,
    USH.Location_Id, USH.Shipping_Id,
    DC.Customer_Name, DC.Customer_Segment, DC.Customer_City, DC.Customer_State, DC.Customer_Country,
    DP.Product_Name, DP.Product_Price, DP.Product_Status,
    DCat.Category_Name, DD.Department_Name,
    DL.Order_City AS Shipping_City, DL.Order_Country AS Shipping_Country, DL.Order_Region AS Shipping_Region,
    DL.Order_State, DL.Market,
    DS.Shipping_Mode, DS.Delivery_Status, DS.Late_delivery_risk, DS.Shipping_Date_Key,
    OD.Order_Status, OD.Payment_Type, OD.Order_Date_Key,
    DDATE.Weekday AS Order_Weekday,
    USH.Total_Sales_Value AS Sales, USH.Net_Order_Total AS Order_Item_Total,
    USH.Total_Order_Profit AS Order_Profit_Per_Order, USH.Total_Benefit AS Benefit_per_order,
    USH.Total_Sales_Per_Customer AS Sales_per_customer, USH.Total_Units_In_Order AS Order_Item_Quantity,
    USH.Total_Order_Discounts AS Order_Item_Discount, USH.Avg_Order_Discount_Rate AS Order_Item_Discount_Rate,
    USH.Avg_Product_Price AS Order_Item_Product_Price, USH.Avg_Profit_Ratio AS Order_Item_Profit_Ratio,
    USH.Days_for_shipping_real, USH.Days_for_shipment_scheduled,
    USH.Latitude, USH.Longitude
FROM FactWebTraffic AS FW
LEFT JOIN UniqueSalesHeader AS USH ON FW.Associated_Order_Id = USH.Order_Id
LEFT JOIN DimCustomer AS DC ON USH.Customer_Id = DC.Customer_Id
LEFT JOIN DimProduct AS DP ON USH.Product_Card_Id = DP.Product_Card_Id
LEFT JOIN DimCategory AS DCat ON USH.Category_Id = DCat.Category_Id
LEFT JOIN DimDepartment AS DD ON USH.Department_Id = DD.Department_Id
LEFT JOIN DimLocation AS DL ON USH.Location_Id = DL.Location_Id
LEFT JOIN DimShipping AS DS ON USH.Shipping_Id = DS.Shipping_Id
LEFT JOIN DimOrderDetails AS OD ON USH.Order_Id = OD.Order_Id
LEFT JOIN DimDate AS DDATE ON USH.Order_Date_Key = DDATE.Date_Key;

-- Save the sales records straight to designated folder
SELECT * INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\master_customer_journey.csv'
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM master_customer_journey_view;

-- Final verification check
SELECT COUNT(*) AS Final_Stored_Rows FROM master_customer_journey_view;
SELECT * FROM master_sales_denormalized_view;
SELECT * FROM master_customer_journey_view;

SELECT COUNT(Associated_Order_Id) AS Final_Stored_Rows FROM master_customer_journey_view;
SELECT COUNT(Associated_Order_Id) AS Final_Stored_Rows 
FROM master_customer_journey_view
WHERE Associated_Order_Id IS NOT NULL;