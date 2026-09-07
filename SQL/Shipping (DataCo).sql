/* ============================================================
   Database Configuration
   ============================================================ */

USE DataCo_supply_chain;

-- Review connection timeout settings
SHOW VARIABLES LIKE '%timeout%';

-- Increase session timeout limits for long-running analytical queries
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

-- Validate updated settings
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';


/* ============================================================
   Task 3: Shipping & Location Analysis (2015–2018)
   ============================================================ */


/* ------------------------------------------------------------
   1. Where are DataCo's orders being shipped?
      Breakdown by year, region, and market
   ------------------------------------------------------------ */

SELECT
    YEAR(STR_TO_DATE(CAST(fs.Shipping_Date_Key AS CHAR), '%Y%m%d')) AS Year,
    dl.Order_Region,
    dl.Market,
    COUNT(*) AS Total_Shipped
FROM FactSales AS fs
JOIN DimShipping AS ds
    ON fs.Shipping_Id = ds.Shipping_Id
JOIN DimLocation AS dl
    ON fs.Location_Id = dl.Location_Id
GROUP BY
    YEAR(STR_TO_DATE(CAST(fs.Shipping_Date_Key AS CHAR), '%Y%m%d')),
    dl.Order_Region,
    dl.Market
ORDER BY
    Year ASC,
    dl.Market ASC,
    Total_Shipped DESC;


/* ------------------------------------------------------------
   2. Which shipping modes are available by market?
   ------------------------------------------------------------ */

SELECT DISTINCT
    dl.Order_Region,
    dl.Market,
    ds.Shipping_Mode
FROM FactSales AS fs
JOIN DimShipping AS ds
    ON fs.Shipping_Id = ds.Shipping_Id
JOIN DimLocation AS dl
    ON fs.Location_Id = dl.Location_Id
ORDER BY
    dl.Market ASC,
    ds.Shipping_Mode ASC;


/* ------------------------------------------------------------
   3. Which shipping modes and regions have the highest
      late-delivery rates?
   ------------------------------------------------------------ */

SELECT
    ds.Shipping_Mode,
    dl.Order_Region,
    COUNT(*) AS Total_Shipped,
    SUM(
        CASE
            WHEN ds.Delivery_Status = 'Late delivery' THEN 1
            ELSE 0
        END
    ) AS Late_Orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN ds.Delivery_Status = 'Late delivery' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS Late_Delivery_Rate_Percentage
FROM FactSales AS fs
JOIN DimShipping AS ds
    ON fs.Shipping_Id = ds.Shipping_Id
JOIN DimLocation AS dl
    ON fs.Location_Id = dl.Location_Id
GROUP BY
    ds.Shipping_Mode,
    dl.Order_Region
ORDER BY
    ds.Shipping_Mode ASC,
    Late_Delivery_Rate_Percentage DESC,
    dl.Order_Region ASC;


/* ------------------------------------------------------------
   4. How does shipping performance vary by market and mode?
   ------------------------------------------------------------ */

WITH ShippingPerformance AS (
    SELECT
        dl.Market,
        ds.Shipping_Mode,
        COUNT(*) AS Total_Shipments,

        ROUND(
            AVG(ds.Days_for_shipment_scheduled),
            2
        ) AS Avg_Scheduled_Shipping_Days,

        ROUND(
            AVG(ds.Days_for_shipping_real),
            2
        ) AS Avg_Actual_Shipping_Days,

        ROUND(
            100.0 * AVG(
                CASE
                    WHEN ds.Late_delivery_risk = 1 THEN 1
                    ELSE 0
                END
            ),
            2
        ) AS Late_Delivery_Risk_Percentage

    FROM FactSales AS fs
    JOIN DimShipping AS ds
        ON fs.Shipping_Id = ds.Shipping_Id
    JOIN DimLocation AS dl
        ON fs.Location_Id = dl.Location_Id
    GROUP BY
        dl.Market,
        ds.Shipping_Mode
)

SELECT
    Market,
    Shipping_Mode,
    Total_Shipments,
    Avg_Scheduled_Shipping_Days,
    Avg_Actual_Shipping_Days,

    ROUND(
        Avg_Actual_Shipping_Days -
        Avg_Scheduled_Shipping_Days,
        2
    ) AS Scheduled_vs_Actual_Gap_Days,

    Late_Delivery_Risk_Percentage

FROM ShippingPerformance
ORDER BY
    Market ASC,
    Shipping_Mode ASC;


/* ------------------------------------------------------------
   5. Shipping performance by delivery status
   ------------------------------------------------------------ */

WITH ShippingPerformance AS (
    SELECT
        dl.Market,
        ds.Shipping_Mode,
        ds.Delivery_Status,
        COUNT(*) AS Total_Shipments,

        ROUND(
            AVG(ds.Days_for_shipment_scheduled),
            2
        ) AS Avg_Scheduled_Shipping_Days,

        ROUND(
            AVG(ds.Days_for_shipping_real),
            2
        ) AS Avg_Actual_Shipping_Days,

        ROUND(
            100.0 * AVG(
                CASE
                    WHEN ds.Late_delivery_risk = 1 THEN 1
                    ELSE 0
                END
            ),
            2
        ) AS Late_Delivery_Risk_Percentage

    FROM FactSales AS fs
    JOIN DimShipping AS ds
        ON fs.Shipping_Id = ds.Shipping_Id
    JOIN DimLocation AS dl
        ON fs.Location_Id = dl.Location_Id
    GROUP BY
        dl.Market,
        ds.Shipping_Mode,
        ds.Delivery_Status
)

SELECT
    Market,
    Shipping_Mode,
    Delivery_Status,
    Total_Shipments,
    Avg_Scheduled_Shipping_Days,
    Avg_Actual_Shipping_Days,

    ROUND(
        Avg_Actual_Shipping_Days -
        Avg_Scheduled_Shipping_Days,
        2
    ) AS Scheduled_vs_Actual_Gap_Days,

    Late_Delivery_Risk_Percentage

FROM ShippingPerformance
ORDER BY
    Market ASC,
    Shipping_Mode ASC,
    CASE
        WHEN Delivery_Status = 'Late delivery' THEN 1
        WHEN Delivery_Status = 'Shipping on time' THEN 2
        WHEN Delivery_Status = 'Advance shipping' THEN 3
        WHEN Delivery_Status = 'Shipping canceled' THEN 4
        ELSE 5
    END ASC;


/* ============================================================
   Task 4: Sales Volume & Seasonality Analysis
   ============================================================ */


/* ------------------------------------------------------------
   6. When does DataCo experience peaks or spikes in
      monthly order volume?
   ------------------------------------------------------------ */

WITH MonthlySales AS (
    SELECT
        YEAR(
            STR_TO_DATE(
                CAST(fs.Order_Date_Key AS CHAR),
                '%Y%m%d'
            )
        ) AS Year,

        MONTH(
            STR_TO_DATE(
                CAST(fs.Order_Date_Key AS CHAR),
                '%Y%m%d'
            )
        ) AS Month,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Total_Sales,

        SUM(
            fs.Order_Item_Quantity
        ) AS Total_Quantity

    FROM FactSales AS fs
    GROUP BY
        Year,
        Month
)

SELECT
    Year,
    Month,
    Total_Sales,
    Total_Quantity,

    RANK() OVER (
        PARTITION BY Year
        ORDER BY Total_Quantity DESC
    ) AS Quantity_Rank

FROM MonthlySales
ORDER BY
    Year ASC,
    Month ASC;


/* ------------------------------------------------------------
   7. Which days of the week have the highest order volume
      by year?
   ------------------------------------------------------------ */

WITH RankedWeeklySales AS (
    SELECT
        YEAR(
            STR_TO_DATE(
                CAST(fs.Order_Date_Key AS CHAR),
                '%Y%m%d'
            )
        ) AS Year,

        fs.Order_Weekday,

        ROUND(
            SUM(fs.Sales),
            2
        ) AS Total_Sales,

        SUM(
            fs.Order_Item_Quantity
        ) AS Total_Quantity,

        DENSE_RANK() OVER (
            PARTITION BY YEAR(
                STR_TO_DATE(
                    CAST(fs.Order_Date_Key AS CHAR),
                    '%Y%m%d'
                )
            )
            ORDER BY
                SUM(fs.Order_Item_Quantity) DESC
        ) AS Weekday_Volume_Rank

    FROM FactSales AS fs
    GROUP BY
        Year,
        fs.Order_Weekday
)

SELECT
    Year,
    Order_Weekday,
    Total_Quantity,
    Total_Sales,
    Weekday_Volume_Rank

FROM RankedWeeklySales
ORDER BY
    Year DESC,
    Weekday_Volume_Rank ASC;
