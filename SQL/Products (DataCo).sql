# Select the database to work with
USE DataCo_supply_chain;

SHOW VARIABLES LIKE '%timeout%';
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SHOW VARIABLES LIKE 'wait_timeout';
SHOW VARIABLES LIKE 'interactive_timeout';

# Task 2: Product, Category and Department Analysis (2015–2018)
## What is the current price of each product and which specific department assigned to oversee each respective product?
SELECT DISTINCT DP.Product_Name, ROUND(DP.Product_Price, 2) AS Product_Price, DC.Category_Name, DD.Department_Name
FROM dimproduct AS DP
INNER JOIN dimcategory AS DC ON DC.Category_Id = DP.Product_Category_Id
INNER JOIN factsales AS FS ON FS.Product_Card_Id = DP.Product_Card_Id
INNER JOIN dimdepartment AS DD ON DD.Department_Id = FS.Department_Id
ORDER BY Product_Price DESC;

## What is the highest price and lowest price product?
SELECT DISTINCT DP.Product_Name, ROUND(DP.Product_Price, 2) AS Product_Price, DC.Category_Name, DD.Department_Name
FROM dimproduct AS DP
INNER JOIN dimcategory AS DC ON DC.Category_Id = DP.Product_Category_Id
INNER JOIN factsales AS FS ON FS.Product_Card_Id = DP.Product_Card_Id
INNER JOIN dimdepartment AS DD ON DD.Department_Id = FS.Department_Id
WHERE ROUND(DP.Product_Price, 2) = (SELECT ROUND(MAX(Product_Price), 2) FROM dimproduct)
   OR ROUND(DP.Product_Price, 2) = (SELECT ROUND(MIN(Product_Price), 2) FROM dimproduct)
ORDER BY Product_Price DESC;

## What is the total number of items within each product category and what category had most items?
WITH GroupedProducts AS (
    SELECT DP.Product_Name, ROUND(DP.Product_Price, 2) AS Product_Price, DC.Category_Name, DD.Department_Name
    FROM dimproduct AS DP
    INNER JOIN dimcategory AS DC ON DC.Category_Id = DP.Product_Category_Id
    INNER JOIN factsales AS FS ON FS.Product_Card_Id = DP.Product_Card_Id
    INNER JOIN dimdepartment AS DD ON DD.Department_Id = FS.Department_Id
    GROUP BY DP.Product_Name, DP.Product_Price, DC.Category_Name, DD.Department_Name
),
RankedCategories AS (
    SELECT Product_Name, Product_Price, Category_Name, Department_Name,
        COUNT(*) OVER(PARTITION BY Category_Name) AS Number_of_products
    FROM GroupedProducts
)
SELECT 
    DENSE_RANK() OVER (ORDER BY Number_of_products DESC) AS Category_Rank,
     Product_Name, Product_Price, Number_of_products, Category_Name, Department_Name
FROM RankedCategories
ORDER BY Category_Rank ASC, Product_Price DESC;

## What is the status of each product?
SELECT DISTINCT DP.Product_Name, ROUND(DP.Product_Price, 2) AS Product_Price, DC.Category_Name, DD.Department_Name,
    CASE 
        WHEN DP.Product_Status = 1 THEN 'Not Available'
        WHEN DP.Product_Status = 0 THEN 'Available'
        ELSE 'Unknown Status'
    END AS Product_Stock_Status
FROM dimproduct AS DP
INNER JOIN dimcategory AS DC ON DC.Category_Id = DP.Product_Category_Id
INNER JOIN factsales AS FS ON FS.Product_Card_Id = DP.Product_Card_Id
INNER JOIN dimdepartment AS DD ON DD.Department_Id = FS.Department_Id
ORDER BY Product_Price DESC;

## What is the best selling and worst selling product by Customer_Country each year?
WITH ProductSalesPerYear AS (
    SELECT 
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')) AS Sales_Year,
        C.Customer_Country, DD.Department_Name, DP.Product_Name, DC.Category_Name, 
        ROUND(DP.Product_Price, 2) AS Product_Price, SUM(FS.Order_Item_Quantity) AS Total_Quantity_Sold,

        ROW_NUMBER() OVER (
            PARTITION BY YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')), C.Customer_Country 
            ORDER BY SUM(FS.Order_Item_Quantity) DESC
        ) AS Best_Selling_Rank,
        
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')), C.Customer_Country 
            ORDER BY SUM(FS.Order_Item_Quantity) ASC
        ) AS Worst_Selling_Rank

    FROM factsales AS FS
    JOIN dimproduct AS DP ON FS.Product_Card_Id = DP.Product_Card_Id
    JOIN dimcategory AS DC ON DP.Product_Category_Id = DC.Category_Id
    JOIN dimcustomer AS C ON FS.Customer_Id = C.Customer_Id   
    JOIN dimdepartment AS DD ON DD.Department_Id = FS.Department_Id -- Added department join
    GROUP BY 
        YEAR(STR_TO_DATE(CAST(FS.Order_Date_Key AS CHAR), '%Y%m%d')), 
        C.Customer_Country, DD.Department_Name, DP.Product_Name, DC.Category_Name, DP.Product_Price
)
SELECT Sales_Year, Customer_Country, Department_Name, Product_Name, Category_Name, 
    Product_Price, Total_Quantity_Sold,
    CASE 
        WHEN Best_Selling_Rank = 1 THEN 'Best Selling'
        WHEN Worst_Selling_Rank = 1 THEN 'Worst Selling'
    END AS Performance_Type
FROM ProductSalesPerYear
WHERE Best_Selling_Rank = 1 OR Worst_Selling_Rank = 1
ORDER BY Sales_Year ASC, Customer_Country ASC, Total_Quantity_Sold DESC;
