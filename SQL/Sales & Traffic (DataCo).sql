```sql
/* ============================================================
   Database Configuration
   ============================================================ */

USE DataCo_supply_chain;

-- Review connection timeout configuration
SHOW VARIABLES LIKE '%timeout%';

-- Increase timeout limits for long-running analytical workloads
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

-- Validate timeout settings
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';


/* ============================================================
   Task 3: Conversion & Sales Analysis (2015–2018)
   ============================================================ */


/* ------------------------------------------------------------
   1. Customer Segment Performance
   Business Question:
   How do Sales per Customer and Benefit per Order vary
   across customer segments?
   ------------------------------------------------------------ */

SELECT
    dc.Customer_Segment,

    COUNT(DISTINCT fs.Customer_Id) AS Total_Customers,
    COUNT(DISTINCT fs.Order_Id) AS Total_Orders,

    ROUND(
        SUM(fs.Sales) / NULLIF(COUNT(DISTINCT fs.Customer_Id), 0),
        2
    ) AS Avg_Sales_Per_Customer,

    ROUND(
        SUM(fs.Benefit_per_order) /
        NULLIF(COUNT(DISTINCT fs.Order_Id), 0),
        2
    ) AS Avg_Benefit_Per_Order,

    ROUND(SUM(fs.Sales), 2) AS Total_Segment_Sales,

    ROUND(SUM(fs.Benefit_per_order), 2) AS Total_Segment_Profit

FROM FactSales AS fs
JOIN DimCustomer AS dc
    ON fs.Customer_Id = dc.Customer_Id

GROUP BY
    dc.Customer_Segment

ORDER BY
    Avg_Sales_Per_Customer DESC;


/* ------------------------------------------------------------
   2. Discount Analysis by Country & Category
   Business Question:
   What is the average discount rate by category and how
   does discounting vary across customer countries?
   ------------------------------------------------------------ */

SELECT
    dc.Customer_Country,
    dcat.Category_Name,

    COUNT(DISTINCT fs.Order_Id) AS Total_Orders,

    ROUND(SUM(fs.Sales), 2) AS Total_Revenue,
    ROUND(SUM(fs.Benefit_per_order), 2) AS Total_Profit,

    ROUND(
        100.0 * AVG(fs.Order_Item_Discount_Rate),
        2
    ) AS Avg_Discount_Rate_Percentage,

    ROUND(
        SUM(fs.Order_Item_Discount),
        2
    ) AS Total_Discounts_Given

FROM FactSales AS fs
JOIN DimCategory AS dcat
    ON fs.Category_Id = dcat.Category_Id
JOIN DimCustomer AS dc
    ON fs.Customer_Id = dc.Customer_Id

GROUP BY
    dc.Customer_Country,
    dcat.Category_Name

ORDER BY
    dc.Customer_Country ASC,
    Total_Revenue DESC;


/* ------------------------------------------------------------
   3. Top 10 Revenue-Generating Categories by Region
   Business Question:
   Which categories generate the highest revenue in each
   geographic region, and how profitable are they?
   ------------------------------------------------------------ */

WITH RegionalCategoryPerformance AS (

    SELECT
        dl.Order_Region,
        dcat.Category_Name,

        SUM(fs.Order_Item_Quantity) AS Total_Quantity_Ordered,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Total_Sales,

        ROUND(
            SUM(fs.Benefit_per_order),
            2
        ) AS Total_Profit,

        DENSE_RANK() OVER (
            PARTITION BY dl.Order_Region
            ORDER BY SUM(fs.Sales) DESC
        ) AS Sales_Rank

    FROM FactSales AS fs
    JOIN DimCategory AS dcat
        ON fs.Category_Id = dcat.Category_Id
    JOIN DimLocation AS dl
        ON fs.Location_Id = dl.Location_Id

    GROUP BY
        dl.Order_Region,
        dcat.Category_Name
)

SELECT
    Category_Name,
    Order_Region,
    Total_Quantity_Ordered,
    Total_Sales,
    Total_Profit,
    Sales_Rank

FROM RegionalCategoryPerformance

WHERE Sales_Rank <= 10

ORDER BY
    Order_Region ASC,
    Sales_Rank ASC;


/* ------------------------------------------------------------
   4. Top Categories by Region with Annual YoY Growth
   ------------------------------------------------------------ */

WITH AnnualCategorySales AS (

    SELECT
        dd.Year AS Order_Year,
        dcat.Category_Name,
        dl.Order_Region,

        SUM(fs.Order_Item_Quantity) AS Total_Quantity_Ordered,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Total_Sales,

        ROUND(
            SUM(fs.Benefit_per_order),
            2
        ) AS Total_Profit

    FROM FactSales AS fs

    JOIN DimDate AS dd
        ON fs.Order_Date_Key = dd.Date_Key

    JOIN DimCategory AS dcat
        ON fs.Category_Id = dcat.Category_Id

    JOIN DimLocation AS dl
        ON fs.Location_Id = dl.Location_Id

    GROUP BY
        dd.Year,
        dcat.Category_Name,
        dl.Order_Region
),

SalesWithYoY AS (

    SELECT
        *,
        
        LAG(Total_Sales) OVER (
            PARTITION BY Order_Region, Category_Name
            ORDER BY Order_Year
        ) AS Previous_Year_Sales,

        DENSE_RANK() OVER (
            PARTITION BY Order_Year, Order_Region
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank

    FROM AnnualCategorySales
)

SELECT
    Order_Year,
    Sales_Rank,
    Category_Name,
    Order_Region,
    Total_Quantity_Ordered,
    Total_Sales,
    Total_Profit,

    CASE
        WHEN Previous_Year_Sales IS NULL
             OR Previous_Year_Sales = 0
        THEN NULL

        ELSE ROUND(
            100.0 *
            (Total_Sales - Previous_Year_Sales)
            / Previous_Year_Sales,
            2
        )
    END AS YoY_Sales_Growth_Percentage

FROM SalesWithYoY

WHERE Sales_Rank <= 10

ORDER BY
    Order_Year DESC,
    Order_Region ASC,
    Sales_Rank ASC;


/* ------------------------------------------------------------
   5. Top Categories by Region with Overall Period Growth
   ------------------------------------------------------------ */

WITH RegionalCategorySales AS (

    SELECT
        dcat.Category_Name,
        dl.Order_Region,

        SUM(fs.Order_Item_Quantity) AS Total_Quantity_Ordered,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Lifetime_Total_Sales,

        ROUND(
            SUM(fs.Benefit_per_order),
            2
        ) AS Lifetime_Total_Profit,

        MIN(dd.Year) AS Start_Year,
        MAX(dd.Year) AS End_Year

    FROM FactSales AS fs

    JOIN DimDate AS dd
        ON fs.Order_Date_Key = dd.Date_Key

    JOIN DimCategory AS dcat
        ON fs.Category_Id = dcat.Category_Id

    JOIN DimLocation AS dl
        ON fs.Location_Id = dl.Location_Id

    GROUP BY
        dcat.Category_Name,
        dl.Order_Region
),

RegionalCategoryGrowth AS (

    SELECT
        rcs.*,

        (
            SELECT SUM(fs2.Sales)
            FROM FactSales AS fs2
            JOIN DimDate AS dd2
                ON fs2.Order_Date_Key = dd2.Date_Key
            JOIN DimCategory AS dc2
                ON fs2.Category_Id = dc2.Category_Id
            JOIN DimLocation AS dl2
                ON fs2.Location_Id = dl2.Location_Id
            WHERE dc2.Category_Name = rcs.Category_Name
              AND dl2.Order_Region = rcs.Order_Region
              AND dd2.Year = rcs.Start_Year
        ) AS Initial_Year_Sales,

        (
            SELECT SUM(fs3.Sales)
            FROM FactSales AS fs3
            JOIN DimDate AS dd3
                ON fs3.Order_Date_Key = dd3.Date_Key
            JOIN DimCategory AS dc3
                ON fs3.Category_Id = dc3.Category_Id
            JOIN DimLocation AS dl3
                ON fs3.Location_Id = dl3.Location_Id
            WHERE dc3.Category_Name = rcs.Category_Name
              AND dl3.Order_Region = rcs.Order_Region
              AND dd3.Year = rcs.End_Year
        ) AS Final_Year_Sales

    FROM RegionalCategorySales AS rcs
),

RankedRegionalCategories AS (

    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY Order_Region
            ORDER BY Lifetime_Total_Sales DESC
        ) AS Sales_Rank

    FROM RegionalCategoryGrowth
)

SELECT
    Sales_Rank,
    Category_Name,
    Order_Region,
    Total_Quantity_Ordered,
    Lifetime_Total_Sales,
    Lifetime_Total_Profit,

    CASE
        WHEN Initial_Year_Sales IS NULL
             OR Initial_Year_Sales = 0
        THEN NULL

        ELSE ROUND(
            100.0 *
            (Final_Year_Sales - Initial_Year_Sales)
            / Initial_Year_Sales,
            2
        )
    END AS Overall_Period_Growth_Percentage

FROM RankedRegionalCategories

WHERE Sales_Rank <= 10

ORDER BY
    Order_Region ASC,
    Sales_Rank ASC;


/* ------------------------------------------------------------
   6. Top 10 Global Categories with Overall Period Growth
   ------------------------------------------------------------ */

WITH CategorySales AS (

    SELECT
        dcat.Category_Name,

        SUM(fs.Order_Item_Quantity) AS Total_Quantity_Ordered,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Lifetime_Total_Sales,

        ROUND(
            SUM(fs.Benefit_per_order),
            2
        ) AS Lifetime_Total_Profit,

        MIN(dd.Year) AS Start_Year,
        MAX(dd.Year) AS End_Year

    FROM FactSales AS fs

    JOIN DimDate AS dd
        ON fs.Order_Date_Key = dd.Date_Key

    JOIN DimCategory AS dcat
        ON fs.Category_Id = dcat.Category_Id

    GROUP BY
        dcat.Category_Name
),

AnnualCategorySales AS (

    SELECT
        dcat.Category_Name,
        dd.Year,
        SUM(fs.Sales) AS Annual_Sales

    FROM FactSales AS fs

    JOIN DimDate AS dd
        ON fs.Order_Date_Key = dd.Date_Key

    JOIN DimCategory AS dcat
        ON fs.Category_Id = dcat.Category_Id

    GROUP BY
        dcat.Category_Name,
        dd.Year
),

CategoryGrowth AS (

    SELECT
        cs.*,

        start_sales.Annual_Sales AS Initial_Year_Sales,
        end_sales.Annual_Sales AS Final_Year_Sales

    FROM CategorySales AS cs

    LEFT JOIN AnnualCategorySales AS start_sales
        ON cs.Category_Name = start_sales.Category_Name
       AND cs.Start_Year = start_sales.Year

    LEFT JOIN AnnualCategorySales AS end_sales
        ON cs.Category_Name = end_sales.Category_Name
       AND cs.End_Year = end_sales.Year
),

RankedCategories AS (

    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY Lifetime_Total_Sales DESC
        ) AS Sales_Rank

    FROM CategoryGrowth
)

SELECT
    Sales_Rank,
    Category_Name,
    Total_Quantity_Ordered,
    Lifetime_Total_Sales,
    Lifetime_Total_Profit,

    CASE
        WHEN Initial_Year_Sales IS NULL
             OR Initial_Year_Sales = 0
        THEN NULL

        ELSE ROUND(
            100.0 *
            (Final_Year_Sales - Initial_Year_Sales)
            / Initial_Year_Sales,
            2
        )
    END AS Overall_Period_Growth_Percentage

FROM RankedCategories

WHERE Sales_Rank <= 10

ORDER BY
    Sales_Rank ASC;


/* ------------------------------------------------------------
   7. Revenue vs. Profitability Analysis
   Business Question:
   Are the highest-revenue regions and categories also the
   most profitable?
   ------------------------------------------------------------ */

SELECT
    dl.Market,
    dl.Order_Region AS Shipping_Region,
    dcat.Category_Name,

    SUM(fs.Order_Item_Quantity) AS Total_Units_Sold,

    ROUND(
        SUM(fs.Sales),
        2
    ) AS Total_Sales_Revenue,

    ROUND(
        SUM(fs.Order_Profit_Per_Order),
        2
    ) AS Net_Profit,

    ROUND(
        100.0 *
        SUM(fs.Order_Profit_Per_Order)
        / NULLIF(SUM(fs.Sales), 0),
        2
    ) AS Profit_Margin_Percentage,

    RANK() OVER (
        ORDER BY SUM(fs.Sales) DESC
    ) AS Revenue_Rank,

    RANK() OVER (
        ORDER BY SUM(fs.Order_Profit_Per_Order) DESC
    ) AS Profit_Rank

FROM FactSales AS fs

JOIN DimLocation AS dl
    ON fs.Location_Id = dl.Location_Id

JOIN DimCategory AS dcat
    ON fs.Category_Id = dcat.Category_Id

GROUP BY
    dl.Market,
    dl.Order_Region,
    dcat.Category_Name

ORDER BY
    Revenue_Rank ASC,
    Profit_Rank ASC,
    Market ASC,
    Total_Sales_Revenue DESC;


/* ------------------------------------------------------------
   8. Order Size & Purchase Behavior Analysis
   Business Question:
   Is sales volume driven by bulk orders or frequent
   individual purchases?
   ------------------------------------------------------------ */

WITH OrderTotals AS (

    SELECT
        fs.Order_Id,

        SUM(fs.Order_Item_Quantity) AS Total_Units_In_Order,

        SUM(fs.Sales) AS Total_Sales_Value

    FROM FactSales AS fs

    GROUP BY
        fs.Order_Id
),

OrderSegmentation AS (

    SELECT
        Order_Id,
        Total_Units_In_Order,
        Total_Sales_Value,

        CASE
            WHEN Total_Units_In_Order = 1
                THEN '1. Individual (1 Unit)'

            WHEN Total_Units_In_Order BETWEEN 2 AND 4
                THEN '2. Small Consumer (2–4 Units)'

            WHEN Total_Units_In_Order BETWEEN 5 AND 9
                THEN '3. Mid-Market / Multi-Buy (5–9 Units)'

            ELSE '4. Commercial / Bulk (10+ Units)'
        END AS Order_Size_Segment

    FROM OrderTotals
),

OrderSummary AS (

    SELECT
        Order_Size_Segment,

        COUNT(*) AS Total_Placed_Orders,

        SUM(Total_Units_In_Order) AS Aggregate_Units_Sold,

        SUM(Total_Sales_Value) AS Total_Revenue_Generated,

        AVG(Total_Sales_Value) AS Avg_Ticket_Value_Per_Order

    FROM OrderSegmentation

    GROUP BY
        Order_Size_Segment
),

OverallTotals AS (

    SELECT
        COUNT(*) AS Total_Orders,
        SUM(Total_Units_In_Order) AS Total_Units,
        SUM(Total_Sales_Value) AS Total_Revenue

    FROM OrderTotals
)

SELECT
    os.Order_Size_Segment,

    os.Total_Placed_Orders,

    ROUND(
        100.0 * os.Total_Placed_Orders
        / NULLIF(ot.Total_Orders, 0),
        2
    ) AS Order_Percentage_Total,

    os.Aggregate_Units_Sold,

    ROUND(
        100.0 * os.Aggregate_Units_Sold
        / NULLIF(ot.Total_Units, 0),
        2
    ) AS Units_Percentage_Total,

    ROUND(
        os.Total_Revenue_Generated,
        2
    ) AS Total_Revenue_Generated,

    ROUND(
        100.0 * os.Total_Revenue_Generated
        / NULLIF(ot.Total_Revenue, 0),
        2
    ) AS Total_Revenue_Percentage,

    ROUND(
        os.Avg_Ticket_Value_Per_Order,
        2
    ) AS Avg_Ticket_Value_Per_Order

FROM OrderSummary AS os
CROSS JOIN OverallTotals AS ot

ORDER BY
    os.Order_Size_Segment ASC;


/* ------------------------------------------------------------
   9. Payment Type Contribution
   Business Question:
   What payment methods are used and how much revenue does
   each method generate?
   ------------------------------------------------------------ */

SELECT
    od.Payment_Type,

    COUNT(DISTINCT fs.Order_Id) AS Total_Orders,

    ROUND(
        100.0 *
        COUNT(DISTINCT fs.Order_Id)
        / SUM(COUNT(DISTINCT fs.Order_Id)) OVER (),
        2
    ) AS Order_Volume_Share_Percentage,

    ROUND(
        SUM(fs.Sales),
        2
    ) AS Total_Sales_Revenue,

    ROUND(
        SUM(fs.Sales)
        / NULLIF(COUNT(DISTINCT fs.Order_Id), 0),
        2
    ) AS Avg_Order_Value

FROM FactSales AS fs

JOIN DimOrderDetails AS od
    ON fs.Order_Id = od.Order_Id

GROUP BY
    od.Payment_Type

ORDER BY
    Total_Sales_Revenue DESC;


/* ============================================================
   Task 4: Web Traffic & Conversion Analysis
   ============================================================ */


/* ------------------------------------------------------------
   10. Most Frequently Browsed Products by Year
   ------------------------------------------------------------ */

SELECT
    dd.Year AS Traffic_Year,
    dcat.Category_Name,
    ddept.Department_Name,
    dp.Product_Name,

    COUNT(*) AS Total_Page_Views,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY dd.Year
        ),
        2
    ) AS Product_Traffic_Share_Percentage,

    COUNT(DISTINCT fw.Log_Id) AS Unique_Visitors

FROM FactWebTraffic AS fw

JOIN DimProduct AS dp
    ON fw.Product_Card_Id = dp.Product_Card_Id

JOIN DimCategory AS dcat
    ON fw.Category_Id = dcat.Category_Id

JOIN DimDepartment AS ddept
    ON fw.Department_Id = ddept.Department_Id

JOIN DimDate AS dd
    ON DATE(fw.Timestamp) = dd.Date_Key

GROUP BY
    dd.Year,
    dcat.Category_Name,
    ddept.Department_Name,
    dp.Product_Name

ORDER BY
    Traffic_Year DESC,
    Total_Page_Views DESC;


/* ------------------------------------------------------------
   11. Web Sessions Linked to Orders
   Business Question:
   How many web traffic events are associated with an order?
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS Total_Web_Sessions,

    COUNT(
        CASE
            WHEN fw.Associated_Order_Id IS NOT NULL
            THEN 1
        END
    ) AS Sessions_With_Orders,

    ROUND(
        100.0 *
        COUNT(
            CASE
                WHEN fw.Associated_Order_Id IS NOT NULL
                THEN 1
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS Session_To_Order_Link_Rate_Percentage

FROM FactWebTraffic AS fw;


/* ------------------------------------------------------------
   12. Web Traffic & Conversion by Day of Week
   ------------------------------------------------------------ */

SELECT
    WEEKDAY(fw.Timestamp) AS Weekday_Index,
    DAYNAME(fw.Timestamp) AS Day_Of_Week,

    COUNT(*) AS Total_Web_Hits,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS Traffic_Share_Percentage,

    COUNT(
        CASE
            WHEN fw.Associated_Order_Id IS NOT NULL
            THEN 1
        END
    ) AS Orders_Placed,

    ROUND(
        100.0 *
        COUNT(
            CASE
                WHEN fw.Associated_Order_Id IS NOT NULL
                THEN 1
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS Web_Conversion_Rate_Percentage

FROM FactWebTraffic AS fw

GROUP BY
    WEEKDAY(fw.Timestamp),
    DAYNAME(fw.Timestamp)

ORDER BY
    Weekday_Index ASC;


/* ------------------------------------------------------------
   13. Top 5 Browsed & Highest-Converting Products by Day
   ------------------------------------------------------------ */

WITH DailyProductMetrics AS (

    SELECT
        WEEKDAY(fw.Timestamp) AS Weekday_Index,
        DAYNAME(fw.Timestamp) AS Day_Of_Week,
        dp.Product_Name,

        COUNT(*) AS Browsing_Events,

        COUNT(
            CASE
                WHEN fw.Associated_Order_Id IS NOT NULL
                THEN 1
            END
        ) AS Orders_Placed,

        ROUND(
            100.0 *
            COUNT(
                CASE
                    WHEN fw.Associated_Order_Id IS NOT NULL
                    THEN 1
                END
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS Web_Conversion_Rate_Percentage,

        ROW_NUMBER() OVER (
            PARTITION BY WEEKDAY(fw.Timestamp)
            ORDER BY COUNT(*) DESC
        ) AS Browsed_Volume_Rank,

        ROW_NUMBER() OVER (
            PARTITION BY WEEKDAY(fw.Timestamp)
            ORDER BY
                COUNT(
                    CASE
                        WHEN fw.Associated_Order_Id IS NOT NULL
                        THEN 1
                    END
                ) / NULLIF(COUNT(*), 0) DESC
        ) AS Conversion_Rate_Rank

    FROM FactWebTraffic AS fw

    JOIN DimProduct AS dp
        ON fw.Product_Card_Id = dp.Product_Card_Id

    GROUP BY
        WEEKDAY(fw.Timestamp),
        DAYNAME(fw.Timestamp),
        dp.Product_Name
)

SELECT
    Day_Of_Week,
    Product_Name,
    Browsing_Events,
    Orders_Placed,
    Web_Conversion_Rate_Percentage

FROM DailyProductMetrics

WHERE
    Browsed_Volume_Rank <= 5
    OR (
        Conversion_Rate_Rank <= 5
        AND Orders_Placed > 2
    )

ORDER BY
    Weekday_Index ASC,
    Browsed_Volume_Rank ASC;


/* ------------------------------------------------------------
   14. Product Conversion Rate by Year
   ------------------------------------------------------------ */

SELECT
    YEAR(fw.Timestamp) AS Traffic_Year,
    dp.Product_Name,
    dcat.Category_Name,
    ddept.Department_Name,

    COUNT(*) AS Total_Browsing_Events,

    COUNT(
        CASE
            WHEN fw.Associated_Order_Id IS NOT NULL
            THEN 1
        END
    ) AS Successful_Purchases,

    ROUND(
        100.0 *
        COUNT(
            CASE
                WHEN fw.Associated_Order_Id IS NOT NULL
                THEN 1
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS Web_Conversion_Rate_Percentage

FROM FactWebTraffic AS fw

JOIN DimProduct AS dp
    ON fw.Product_Card_Id = dp.Product_Card_Id

JOIN DimCategory AS dcat
    ON fw.Category_Id = dcat.Category_Id

JOIN DimDepartment AS ddept
    ON fw.Department_Id = ddept.Department_Id

GROUP BY
    YEAR(fw.Timestamp),
    ddept.Department_Name,
    dcat.Category_Name,
    dp.Product_Name

ORDER BY
    Traffic_Year DESC,
    Web_Conversion_Rate_Percentage DESC;


/* ============================================================
   Task 5: Analytical Master Tables
   ============================================================ */


/* ------------------------------------------------------------
   15. Create Master Sales Analytical Table
   ------------------------------------------------------------ */

DROP TABLE IF EXISTS master_sales_denormalized_view;

CREATE TABLE master_sales_denormalized_view AS

SELECT
    fs.Order_Item_Id,
    fs.Order_Id,

    dc.Customer_Id,
    fs.Product_Card_Id,
    fs.Category_Id,
    fs.Department_Id,
    fs.Location_Id,
    fs.Shipping_Id,

    /* Customer Attributes */
    dc.Customer_Name,
    dc.Customer_Segment,
    dc.Customer_City,
    dc.Customer_State,
    dc.Customer_Country,

    /* Product Attributes */
    dp.Product_Name,
    dp.Product_Price,
    dp.Product_Status,

    /* Product Classification */
    dcat.Category_Name,
    ddept.Department_Name,

    /* Geographic Attributes */
    dl.Order_City AS Shipping_City,
    dl.Order_Country AS Shipping_Country,
    dl.Order_Region AS Shipping_Region,
    dl.Order_State,
    dl.Market,

    /* Shipping Attributes */
    ds.Shipping_Mode,
    ds.Delivery_Status,
    ds.Late_delivery_risk,
    ds.Shipping_Date_Key,

    /* Order Attributes */
    od.Order_Status,
    od.Payment_Type,
    od.Order_Date_Key,

    /* Date Attributes */
    dd.Weekday AS Order_Weekday,

    /* Sales Metrics */
    fs.Sales,
    fs.Order_Item_Total,
    fs.Order_Profit_Per_Order,
    fs.Benefit_per_order,
    fs.Sales_per_customer,
    fs.Order_Item_Quantity,

    /* Discount Metrics */
    fs.Order_Item_Discount,
    fs.Order_Item_Discount_Rate,
    fs.Order_Item_Product_Price,

    /* Profitability */
    fs.Order_Item_Profit_Ratio,

    /* Fulfillment Metrics */
    fs.Days_for_shipping_real,
    fs.Days_for_shipment_scheduled,

    /* Geographic Coordinates */
    fs.Latitude,
    fs.Longitude

FROM FactSales AS fs

LEFT JOIN DimCustomer AS dc
    ON fs.Customer_Id = dc.Customer_Id

LEFT JOIN DimProduct AS dp
    ON fs.Product_Card_Id = dp.Product_Card_Id

LEFT JOIN DimCategory AS dcat
    ON fs.Category_Id = dcat.Category_Id

LEFT JOIN DimDepartment AS ddept
    ON fs.Department_Id = ddept.Department_Id

LEFT JOIN DimLocation AS dl
    ON fs.Location_Id = dl.Location_Id

LEFT JOIN DimShipping AS ds
    ON fs.Shipping_Id = ds.Shipping_Id

LEFT JOIN DimOrderDetails AS od
    ON fs.Order_Id = od.Order_Id

LEFT JOIN DimDate AS dd
    ON fs.Order_Date_Key = dd.Date_Key;


/* Validate master sales table */

SELECT
    COUNT(*) AS Stored_Sales_Rows
FROM master_sales_denormalized_view;


/* Export master sales dataset */

SELECT *
INTO OUTFILE
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\master_sales_export.csv'

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'

FROM master_sales_denormalized_view;


/* ============================================================
   Task 6: Customer Journey Analysis
   ============================================================ */


/* ------------------------------------------------------------
   16. Create Order-Level Sales Summary
   ------------------------------------------------------------ */

DROP TABLE IF EXISTS master_customer_journey_view;

CREATE TABLE master_customer_journey_view AS

WITH OrderSummary AS (

    SELECT
        fs.Order_Id,

        MAX(fs.Order_Date_Key) AS Order_Date_Key,
        MAX(fs.Customer_Id) AS Customer_Id,
        MAX(fs.Location_Id) AS Location_Id,
        MAX(fs.Shipping_Id) AS Shipping_Id,

        SUM(fs.Sales) AS Total_Sales_Value,
        SUM(fs.Order_Item_Total) AS Net_Order_Total,
        SUM(fs.Order_Profit_Per_Order) AS Total_Order_Profit,
        SUM(fs.Benefit_per_order) AS Total_Benefit,

        SUM(fs.Order_Item_Quantity) AS Total_Units_In_Order,
        SUM(fs.Order_Item_Discount) AS Total_Order_Discounts,

        AVG(fs.Order_Item_Discount_Rate) AS Avg_Order_Discount_Rate,
        AVG(fs.Order_Item_Product_Price) AS Avg_Product_Price,
        AVG(fs.Order_Item_Profit_Ratio) AS Avg_Profit_Ratio,

        MAX(fs.Days_for_shipping_real) AS Days_for_shipping_real,
        MAX(fs.Days_for_shipment_scheduled) AS Days_for_shipment_scheduled

    FROM FactSales AS fs

    GROUP BY
        fs.Order_Id
)

SELECT
    fw.Log_Id,
    fw.Timestamp AS Web_Access_Timestamp,
    fw.Associated_Order_Id,

    /* Customer / Order Keys */
    os.Order_Id,
    os.Customer_Id,
    os.Location_Id,
    os.Shipping_Id,
    os.Order_Date_Key,

    /* Customer Attributes */
    dc.Customer_Name,
    dc.Customer_Segment,
    dc.Customer_City,
    dc.Customer_State,
    dc.Customer_Country,

    /* Geographic Attributes */
    dl.Order_City AS Shipping_City,
    dl.Order_Country AS Shipping_Country,
    dl.Order_Region AS Shipping_Region,
    dl.Order_State,
    dl.Market,

    /* Shipping Attributes */
    ds.Shipping_Mode,
    ds.Delivery_Status,
    ds.Late_delivery_risk,
    ds.Shipping_Date_Key,

    /* Order Attributes */
    od.Order_Status,
    od.Payment_Type,

    /* Sales Metrics */
    os.Total_Sales_Value AS Sales,
    os.Net_Order_Total AS Order_Total,
    os.Total_Order_Profit AS Order_Profit,
    os.Total_Benefit AS Benefit_Per_Order,
    os.Total_Units_In_Order AS Units_In_Order,
    os.Total_Order_Discounts AS Total_Order_Discounts,

    /* Discount & Pricing Metrics */
    os.Avg_Order_Discount_Rate,
    os.Avg_Product_Price,
    os.Avg_Profit_Ratio,

    /* Fulfillment Metrics */
    os.Days_for_shipping_real,
    os.Days_for_shipment_scheduled,

    /* Web Attributes */
    fw.IP_Address,
    fw.URL

FROM FactWebTraffic AS fw

LEFT JOIN OrderSummary AS os
    ON fw.Associated_Order_Id = os.Order_Id

LEFT JOIN DimCustomer AS dc
    ON os.Customer_Id = dc.Customer_Id

LEFT JOIN DimLocation AS dl
    ON os.Location_Id = dl.Location_Id

LEFT JOIN DimShipping AS ds
    ON os.Shipping_Id = ds.Shipping_Id

LEFT JOIN DimOrderDetails AS od
    ON os.Order_Id = od.Order_Id;


/* ------------------------------------------------------------
   Customer Journey Validation
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS Total_Journey_Records,

    COUNT(
        CASE
            WHEN Associated_Order_Id IS NOT NULL
            THEN 1
        END
    ) AS Sessions_With_Orders,

    COUNT(
        CASE
            WHEN Associated_Order_Id IS NULL
            THEN 1
        END
    ) AS Sessions_Without_Orders

FROM master_customer_journey_view;


/* Calculate web-to-order linkage rate */

SELECT
    ROUND(
        100.0 *
        COUNT(
            CASE
                WHEN Associated_Order_Id IS NOT NULL
                THEN 1
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS Web_To_Order_Link_Rate_Percentage

FROM master_customer_journey_view;


/* Export customer journey dataset */

SELECT *
INTO OUTFILE
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\master_customer_journey.csv'

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'

FROM master_customer_journey_view;


/* Final validation */

SELECT COUNT(*) AS Final_Stored_Rows
FROM master_customer_journey_view;
```
