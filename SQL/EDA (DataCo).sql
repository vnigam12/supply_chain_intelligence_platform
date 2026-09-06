SHOW VARIABLES LIKE '%timeout%';
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';
USE dataco_supply_chain;

# View the overall performance of DataCo for the reporting period

# What are the top 10 best-performing product categories by total sales revenue across different geographic regions, and how volume-dense and profitable are they?
SELECT DC.Category_Name, DL.Order_Region, SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
    ROUND(SUM(FS.Sales), 2) AS Total_Sales, ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Profit
FROM factsales AS FS
JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
GROUP BY DC.Category_Name, DL.Order_Region
ORDER BY Total_Sales DESC 
LIMIT 10;

WITH RankedSales AS (
    SELECT 
        DC.Category_Name, 
        DL.Order_Region,
        SUM(FS.Order_Item_Quantity) AS Total_Quantity_Ordered,
        ROUND(SUM(FS.Sales), 2) AS Total_Sales, 
        ROUND(SUM(FS.Benefit_per_order), 2) AS Total_Profit,
        DENSE_RANK() OVER (
            PARTITION BY DL.Order_Region 
            ORDER BY SUM(FS.Sales) DESC
        ) AS Sales_Rank
    FROM factsales AS FS
    JOIN dimcategory AS DC ON FS.Category_Id = DC.Category_Id
    JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
    GROUP BY DC.Category_Name, DL.Order_Region
)
SELECT 
    Category_Name,
    Order_Region,
    Total_Quantity_Ordered,
    Total_Sales,
    Total_Profit,
    Sales_Rank
FROM RankedSales
WHERE Sales_Rank <= 3
ORDER BY Order_Region, Sales_Rank;

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
master_sales_denormalized_view),
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


