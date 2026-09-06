# Select the database to work with
USE DataCo_supply_chain;

SHOW VARIABLES LIKE '%timeout%';
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';

# Task 3: Shipping and Location Analysis (2015–2018)
## Where are DataCo's orders being shipped (by region and market)?
SELECT 
    YEAR(STR_TO_DATE(CAST(DS.Shipping_Date_Key AS CHAR), '%Y%m%d')) AS Year, 
    DL.Order_Region, DL.Market, COUNT(DS.Shipping_Id) AS Total_Shipped
FROM dimshipping AS DS
JOIN factsales AS FS ON FS.Shipping_Id = DS.Shipping_Id
JOIN dimlocation AS DL ON DL.Location_Id = FS.Location_Id
JOIN dimorderdetails AS OD ON OD.Order_Id = FS.Order_Id
GROUP BY 
    YEAR(STR_TO_DATE(CAST(DS.Shipping_Date_Key AS CHAR), '%Y%m%d')), 
	DL.Order_Region, DL.Market
ORDER BY Year ASC, Market ASC, Total_Shipped DESC; 

## What shipping modes (Shipping_Mode) are available to customers by market?
SELECT DL.Order_Region, DL.Market, DS.Shipping_Mode
FROM dimshipping AS DS
JOIN factsales AS FS ON FS.Shipping_Id = DS.Shipping_Id
JOIN dimlocation AS DL ON DL.Location_Id = FS.Location_Id
JOIN dimorderdetails AS OD ON OD.Order_Id = FS.Order_Id
GROUP BY DL.Order_Region, DL.Market, DS.Shipping_Mode
ORDER BY Market, Shipping_Mode;

## Which shipping modes and geographic regions suffer from the high rate of 'Late delivery' statuses?
SELECT DS.Shipping_Mode, DL.Order_Region,
    COUNT(DS.Shipping_ID) AS Total_Shipped,
    SUM(CASE WHEN DS.Delivery_Status = 'Late delivery' THEN 1 ELSE 0 END) AS Late_Orders,
    ROUND((SUM(CASE WHEN DS.Delivery_Status = 'Late delivery' THEN 1 ELSE 0 END) / COUNT(DS.Shipping_ID)) * 100, 2) AS Late_Delivery_Rate_Percentage
FROM factsales AS FS
JOIN dimlocation AS DL ON FS.Location_Id = DL.Location_Id
JOIN dimshipping AS DS ON FS.Shipping_Id = DS.Shipping_Id
GROUP BY DS.Shipping_Mode, DL.Order_Region 
ORDER BY DS.Shipping_Mode, Late_Delivery_Rate_Percentage DESC, DL.Order_Region;

## Is there any different in shipping time between different shipping mode and market?
WITH ShippingPerformance AS (
    SELECT DL.Market, DS.Shipping_Mode,
        ROUND(AVG(DS.Days_for_shipping_real), 2) AS Avg_Actual_Shipping_Days,
        ROUND(AVG(DS.Days_for_shipment_scheduled), 2) AS Avg_Scheduled_Shipping_Days,
		ROUND((SUM(CASE WHEN DS.Late_delivery_risk = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Late_Delivery_Risk_Percentage,
		COUNT(*) AS Total_Shipments
    FROM dimshipping AS DS
    JOIN factsales AS FS ON FS.Shipping_Id = DS.Shipping_Id
    JOIN dimlocation AS DL ON DL.Location_Id = FS.Location_Id
    GROUP BY DL.Market, DS.Shipping_Mode
    
)
SELECT Market, Shipping_Mode, Total_Shipments, Avg_Scheduled_Shipping_Days, Avg_Actual_Shipping_Days,
    ROUND((Avg_Actual_Shipping_Days - Avg_Scheduled_Shipping_Days), 2) AS Scheduled_vs_Actual_Gap_Days,
    Late_Delivery_Risk_Percentage
FROM ShippingPerformance
ORDER BY Market ASC, Shipping_Mode;
    
## Details breakdown by delivery_status
WITH ShippingPerformance AS (
    SELECT DL.Market, DS.Shipping_Mode, DS.Delivery_Status,
    ROUND(AVG(DS.Days_for_shipping_real), 2) AS Avg_Actual_Shipping_Days,
    ROUND(AVG(DS.Days_for_shipment_scheduled), 2) AS Avg_Scheduled_Shipping_Days,
    ROUND((SUM(CASE WHEN DS.Late_delivery_risk = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Late_Delivery_Risk_Percentage,
    COUNT(*) AS Total_Shipments
    FROM dimshipping AS DS
    JOIN factsales AS FS ON FS.Shipping_Id = DS.Shipping_Id
    JOIN dimlocation AS DL ON DL.Location_Id = FS.Location_Id
    GROUP BY DL.Market, DS.Shipping_Mode, DS.Delivery_Status
)
SELECT Market, Shipping_Mode, Delivery_Status,
    Total_Shipments, Avg_Scheduled_Shipping_Days, Avg_Actual_Shipping_Days,
    ROUND((Avg_Actual_Shipping_Days - Avg_Scheduled_Shipping_Days), 2) AS Scheduled_vs_Actual_Gap_Days,
    Late_Delivery_Risk_Percentage
FROM ShippingPerformance
ORDER BY Market ASC, Shipping_Mode ASC,
    -- Custom sort logic keeps your statuses organized intuitively within each shipping mode track
    CASE 
        WHEN Delivery_Status = 'Late delivery' THEN 1
        WHEN Delivery_Status = 'Shipping on time' THEN 2
        WHEN Delivery_Status = 'Advance shipping' THEN 3
        WHEN Delivery_Status = 'Shipping canceled' THEN 4
        ELSE 5
    END ASC;
    
## When do DataCo's experience peaks or spikes in order volumes (by month, or year)?
WITH MonthlySales AS (
    SELECT YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Year,
    MONTH(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Month,
    ROUND(SUM(FS.Sales), 2) AS Total_Sales, SUM(FS.Order_Item_Quantity) AS Total_Quantity
    FROM factsales AS FS
    GROUP BY YEAR, MONTH)
SELECT Year, Month, Total_Sales, Total_Quantity,
    RANK() OVER (PARTITION BY Year ORDER BY Total_Quantity DESC) AS Quantity_Rank
FROM MonthlySales
ORDER BY Year, Month;

## Which days of the week exhibit the highest volume of order submissions by year?
WITH RankedWeeklySales AS (
	SELECT YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Year, 
	FS.Order_Weekday,  ROUND(SUM(FS.Sales), 2) AS Total_Sales, SUM(FS.Order_Item_Quantity) AS Total_Quantity,
    DENSE_RANK() OVER (PARTITION BY YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d'))
            ORDER BY SUM(FS.Order_Item_Quantity) DESC) AS Weekday_Volume_Rank
    FROM factsales AS FS
    JOIN dimdate AS DD ON DD.Date_Key = FS.Order_Date_Key 
    GROUP BY YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')), FS.Order_Weekday
)
SELECT Weekday_Volume_Rank, Year, Order_Weekday, Total_Quantity, Total_Sales
FROM RankedWeeklySales
ORDER BY Year DESC, Weekday_Volume_Rank ASC;