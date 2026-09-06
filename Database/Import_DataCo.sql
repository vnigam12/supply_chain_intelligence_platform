# Drop the existing database if it already exists and create a new one
DROP DATABASE IF EXISTS DataCo_supply_chain;
CREATE DATABASE DataCo_supply_chain;

# Display the list of all databases to confirm the new one has been created
SHOW DATABASES;

# Select the database to work with
USE DataCo_supply_chain;

# Enable importing CSVs from your local computer
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

# Create the customer dimension table
CREATE TABLE DimCustomer (
    Customer_Id INT PRIMARY KEY,
    Customer_Segment VARCHAR(50),
    Customer_Email VARCHAR(50), 
    Customer_Password VARCHAR(50),
    Customer_Street VARCHAR(50),
    Customer_City VARCHAR(50),
    Customer_State VARCHAR(50),
    Customer_Country VARCHAR(50),
    Customer_Zipcode VARCHAR(50),
    Customer_Name VARCHAR(50)
);

# Import data from a local CSV file into the DimCustomer table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_customer.csv'
INTO TABLE DimCustomer
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Customer_Id FROM DimCustomer;

# Create the product dimension table
CREATE TABLE DimProduct (
    Product_Card_Id INT PRIMARY KEY,
    Product_Name VARCHAR(300),
    Product_Category_Id INT,
    Product_Description VARCHAR (300),
    Product_Image VARCHAR(300),
    Product_Price DECIMAL(15, 10),
    Product_Status VARCHAR(50)
);

# Import data from a local CSV file into the DimProduct table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_product.csv'
INTO TABLE DimProduct
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Product_Card_Id FROM DimProduct;

# Create the category dimension table
CREATE TABLE DimCategory (
    Category_Id INT PRIMARY KEY,
    Category_Name VARCHAR(100)
);

# Import data from a local CSV file into the DimCategory table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_category.csv'
INTO TABLE DimCategory
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Create the department dimension table
CREATE TABLE DimDepartment (
    Department_Id INT PRIMARY KEY,
    Department_Name VARCHAR(100)
);

# Import data from a local CSV file into the DimDepartment table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_department.csv'
INTO TABLE DimDepartment
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Create the location dimension table
CREATE TABLE DimLocation (
    Order_City VARCHAR(100),
    Order_Country VARCHAR(100),
    Order_Region VARCHAR(100),
    Order_State VARCHAR(100),
    Market VARCHAR(100),
	Location_Id INT PRIMARY KEY
);

# Import data from a local CSV file into the DimLocation table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_location.csv'
INTO TABLE DimLocation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Location_Id FROM DimLocation;

# Create the shipping dimension table
CREATE TABLE DimShipping (
    Shipping_Mode VARCHAR(50),
    Delivery_Status VARCHAR(50),
    Late_delivery_risk BOOLEAN,
    Days_for_shipping_real INT,
    Days_for_shipment_scheduled INT,
    shipping_date_DateOrders DATETIME, 
    Shipping_Date_Key INT,
    Shipping_Id INT PRIMARY KEY
);

# Import data from a local CSV file into the DimShipping table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_shipping.csv'
INTO TABLE DimShipping
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Shipping_Id FROM DimShipping;

# Create the order details dimension table
CREATE TABLE DimOrderDetails (
    Order_Id INT PRIMARY KEY,
    Order_Customer_Id VARCHAR(50),
    Order_Status VARCHAR(50),
    Payment_Type VARCHAR(50),
    Order_Item_Cardprod_Id INT,
    order_date_DateOrders DATETIME, 
    Order_Date_Key INT
);

# Import data from a local CSV file into the DimOrderDetails table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_order_details.csv'
INTO TABLE DimOrderDetails
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Order_Id FROM DimOrderDetails;

CREATE TABLE DimDate (
    Full_Date DATETIME,
    Date_Key INT PRIMARY KEY,
    Year INT,
    Month INT,
    Day INT,
    Quarter INT,
    Weekday VARCHAR(20)
);
ALTER TABLE DimDate MODIFY Full_Date DATETIME;

# Import data from a local CSV file into the DimDate table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_date.csv'
INTO TABLE DimDate
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Date_Key FROM DimDate;

-- Fact Tables --
# Fact Sales table
CREATE TABLE FactSales (
    Order_Item_Id INT PRIMARY KEY,
    Order_Id INT,
    Customer_Id INT,
    Customer_Segment VARCHAR(100),
    Product_Card_Id INT, 
    Category_Id INT,
    Department_Id INT,
    Location_Id INT,
    Shipping_Id INT,
    Order_Date_Key INT,
    Shipping_Date_Key INT,
    Sales DECIMAL(15, 10),
    Order_Item_Total DECIMAL(15, 10),
    Order_Profit_Per_Order DECIMAL(15, 10),
    Benefit_per_order DECIMAL(15, 10),
    Sales_per_customer DECIMAL(15, 10),
    Order_Item_Quantity INT,
    Order_Item_Discount DECIMAL(15, 10),
    Order_Weekday VARCHAR(20), 
    Order_Item_Discount_Rate DECIMAL(15, 10), 
    Order_Item_Product_Price DECIMAL(15, 10), 
    Order_Item_Profit_Ratio DECIMAL(15, 10), 
    Days_for_shipping_real INT, 
    Days_for_shipment_scheduled INT,
    Order_Status VARCHAR(50),
	Latitude DECIMAL(15, 10),
    Longitude DECIMAL(15, 10),
    Order_Region VARCHAR(100), 
    Order_Country VARCHAR(100), 
    Customer_Country VARCHAR(100),
    FOREIGN KEY (Order_Id) REFERENCES DimOrderDetails(Order_Id),
    FOREIGN KEY (Customer_Id) REFERENCES DimCustomer(Customer_Id),
    FOREIGN KEY (Product_Card_Id) REFERENCES DimProduct(Product_Card_Id),
    FOREIGN KEY (Category_Id) REFERENCES DimCategory(Category_Id),
    FOREIGN KEY (Department_Id) REFERENCES DimDepartment(Department_Id),
    FOREIGN KEY (Location_Id) REFERENCES DimLocation(Location_Id),
    FOREIGN KEY (Shipping_Id) REFERENCES DimShipping(Shipping_Id),
    FOREIGN KEY (Order_Date_Key) REFERENCES DimDate(Date_Key)
);

# Import data from a local CSV file into the FactSales table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\fact_sales.csv'
INTO TABLE FactSales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Order_Item_Id FROM FactSales;

# Fact Web Traffic table
CREATE TABLE FactWebTraffic (
    Product_Card_Id INT,
    Category_Id INT,
    Department_Id INT,
    Date_Key INT,
    IP_Address VARCHAR(50),
    URL TEXT,
    Timestamp DATETIME,
    Associated_Order_Id INT, 
    Log_Id INT PRIMARY KEY,
    FOREIGN KEY (Product_Card_Id) REFERENCES DimProduct(Product_Card_Id),
    FOREIGN KEY (Category_Id) REFERENCES DimCategory(Category_Id),
    FOREIGN KEY (Department_Id) REFERENCES DimDepartment(Department_Id),
    FOREIGN KEY (Date_Key) REFERENCES DimDate(Date_Key),
    FOREIGN KEY (Associated_Order_Id) REFERENCES DimOrderDetails(Order_Id)
);

# TRUNCATE TABLE FactWebTraffic;
# Import data from a local CSV file into the FactWebTraffic table
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\fact_web_traffic.csv'
INTO TABLE FactWebTraffic
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

-- Evaluate the variable: if it's empty, blank, or the string 'NULL', force it to a database NULL
(Product_Card_Id, Category_Id, Department_Id, Date_Key, IP_Address, URL, Timestamp, @v_order_id, Log_Id)
SET 
  Associated_Order_Id = IF(@v_order_id = '' OR @v_order_id = 'NULL' OR TRIM(@v_order_id) = '' OR (@v_order_id) = 0, NULL, @v_order_id);

# Verify the import and inspect the import and display any warnings generated during the import
SHOW WARNINGS;
SELECT Log_Id FROM FactWebTraffic;