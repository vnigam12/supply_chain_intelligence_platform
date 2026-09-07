## Project Overview

This project demonstrates an end-to-end Business Intelligence pipeline for DataCo Global, a simulated multinational retail organization. The solution covers the complete data lifecycle—from raw data ingestion and transformation using Python, through structured data warehousing and modeling in SQL Server, to executive-level business intelligence dashboards built in Power BI.

By transforming more than 180,000 denormalized records into a scalable Fact Constellation/Galaxy Schema, the project delivers actionable insights into logistics performance, profitability leakage, customer conversion, and overall business operations.


# DataCo: End-to-End Data Analytics & Business Intelligence Solution
<img width="1858" height="1038" alt="image" src="https://github.com/user-attachments/assets/59e0cbb8-2402-48b7-a02a-39a37aff6190" />


## Business Performance Dashboard Summary

| Dashboard | Focus | Business Value |
| :--- | :--- | :--- |
| **Overview** | Provides a high-level view of business performance across core financial metrics—including Sales, Costs, and Profit—along with order volumes, category and market distribution, customer segmentation, and monthly sales trends. | Enables executive-level visibility into overall financial health, key revenue drivers by category and market, customer purchasing patterns, payment preferences, and seasonal demand trends to support budgeting and commercial planning. |
| **Discounts** | Analyzes promotional discount depth, discount elasticity, margin erosion per 1% discount, and order-level discount rates across product price segments and categories. | Identifies margin leakage and discount-sensitive areas, enabling targeted discount controls and promotional strategies that protect profitability while maintaining effective price incentives. |
| **Web Traffic** | Evaluates digital channel performance through web conversion rates by day, category-level conversion trends, and web versus non-web sales by product. | Identifies digital conversion bottlenecks, highlights high-performing sales periods such as the Thursday conversion peak, and supports targeted UX/UI improvements for underperforming product pages. |
| **Shipping** | Monitors fulfillment performance through late and canceled order trends, scheduled versus actual delivery variance, and profitability across shipping statuses and modes. | Identifies logistics inefficiencies and SLA risks, enabling optimization of shipping modes and fulfillment processes to improve delivery reliability, customer satisfaction, and unit profitability. |
| **Recommendation** | Prioritizes strategic initiatives using an Impact vs. Effort framework across Discount Optimization, SLA Performance & Risk, Checkout & Traffic Optimization, and Post-Purchase & Return Reduction. | Converts complex analytical findings into prioritized, actionable initiatives, helping leadership focus on high-impact quick wins while establishing a roadmap for longer-term operational and strategic investments. |


## Datasource
- **Description:** Contains structured enterprise supply chain data spanning transactional sales, customer interactions, web traffic activity, and shipping and logistics metrics across global business units.
- **Source:** DataCo Smart Supply Chain for Big Data Analysis
- **Access Link:** [Mendeley Data Dataset (Version 5)](https://data.mendeley.com/datasets/8gx2fvg2k6/5)


## Key Business Challenges
- **Severe Logistics & Fulfillment Bottlenecks:** Between 2015 and 2017, DataCo fulfilled 65,752 orders, yet delivery reliability remained a significant operational challenge. Approximately 54.8% of shipments were delivered late, while only 17.8% arrived on time. Late shipments required an average of 4.09 days to reach customers, exceeding the expected transit window of 2–4 days. Persistent delivery delays were also associated with lower order profitability due to additional fulfillment costs, expedited shipping, penalties, and customer service recovery. The consistency of these delays despite relatively stable order volumes suggests systemic fulfillment inefficiencies rather than demand-driven capacity constraints.

- **Digital Channel Underperformance & Conversion Gap:** Despite generating more than 443K monthly page views, DataCo's e-commerce channel contributed only 3.04% of total sales, while traditional non-web channels generated more than 97% of revenue across leading product lines. This significant gap between website traffic and sales suggests that the digital channel functions primarily as a product discovery or browsing platform rather than an effective revenue-generating channel. The findings point to opportunities across digital acquisition, customer engagement, and checkout conversion rather than a fundamental lack of product demand.

- **Seasonal Margin Erosion & Q4 Product-Mix Shift:** Despite relatively stable order volumes during November and December, DataCo experienced a notable decline in revenue during the fourth quarter. The decline was driven by a shift in purchasing behavior toward lower-value, medium-volume products and away from higher-margin premium items. This unfavorable product-mix shift reduces average order value and compresses margins during the peak holiday period, suggesting that existing promotional strategies may be driving sales volume at the expense of profitability.


## Business Questions & Project Objectives
This project was designed to answer a series of strategic business questions across sales performance, digital commerce, pricing strategy, and supply chain operations. The objective was not only to build an end-to-end Business Intelligence pipeline, but also to transform enterprise data into actionable insights that support executive decision-making. Specifically, the analysis seeks to answer these key questions:

**Strategic Decision Support**
- Which operational and commercial improvements offer the greatest potential business impact?
- How can improvement opportunities be prioritized based on expected business value, cost, and implementation effort?

**Revenue & Commercial Performance**
- Which products, departments, customer segments, and geographic markets drive the highest revenue and profitability?
- How has revenue and overall business performance evolved over time?
- What seasonal patterns or trends are influencing sales performance?

**Pricing & Profitability**
- How do discounting strategies impact sales, revenue, and profit margins?
- Which products or categories experience the greatest margin erosion due to discounting?
- Which products demonstrate the highest price sensitivity?
- Where can promotional spending and discount strategies be optimized without compromising profitability?

**Digital Commerce & Customer Conversion**
- How effectively does website traffic translate into completed purchases?
- Which product categories, customer segments, and days of the week generate the highest conversion rates?
- Where are the largest opportunities to improve the customer conversion funnel?

**Logistics & Fulfillment Performance**
- Which shipping modes, regions, and fulfillment processes experience the greatest operational inefficiencies?
- How do delivery reliability and shipping performance impact customer experience and profitability?
- Which areas of the supply chain present the greatest opportunities for operational improvement?


## Key Business Insights
- **Strong Global Market Penetration:** Europe and LATAM emerged as the company’s strongest geographic markets, each generating more than $10 million in sales, followed by Pacific Asia with approximately $8 million. This demonstrates a diversified global footprint and sustained international demand across key regions.

- **High Revenue Concentration Across Core Departments:** Fan Shop and Apparel served as DataCo’s primary commercial engines, collectively accounting for approximately 70% of total sales. While this concentration reflects strong product demand, it also creates a potential business risk, as disruptions in inventory availability, supply chain operations, or customer demand within these departments could materially impact overall revenue.

- **Significant Digital Conversion Opportunity:** Customer conversion reached 22.94% on Thursdays, compared with an average of approximately 9.5% on other weekdays, representing nearly a 2.5× uplift. Thursday therefore presents a high-potential window for targeted promotions, product launches, and digital marketing campaigns.

- **High-Value Customer Segments:** Corporate and Consumer customers generated the highest average order values, despite predominantly placing single-item orders. This presents opportunities to increase customer lifetime value through premium product offerings, personalized marketing, cross-selling, and targeted retention initiatives.

- **Delivery Delays Indicate Process Inefficiencies:** Delivery performance remained relatively consistent despite fluctuations in order volumes throughout the year, suggesting that delays are more likely attributable to fulfillment and delivery process inefficiencies than insufficient logistics capacity.

- **Complex Shipments Face Greater Delivery Risk:** Late deliveries were more prevalent among higher-volume and more complex shipments, while moderate-sized orders were more likely to arrive on time. This indicates that fulfillment efficiency deteriorates as shipment complexity increases, highlighting the need for proactive monitoring, capacity planning, and priority handling of complex orders.

- **Delivery Reliability Is a Key Profitability Driver:** On-time deliveries consistently generated stronger profit margins, while cancelled orders produced the weakest financial returns. Although late orders remained profitable, recurring delivery issues reduced overall margins and customer value. Improving delivery reliability could therefore increase profitability without requiring additional sales volume or price increases.

- **Operational Execution Matters More Than Product Price:** Profitability was driven more strongly by fulfillment performance and discounting strategy than by product price alone. Products delivered on time with well-controlled discounts consistently achieved stronger margins, indicating that optimizing operations and promotional strategies may provide greater profit improvement than simply increasing the sale of higher-priced products.


## Executive Performance Summary
- Between 2015 and 2018, DataCo generated approximately $36.78 million in revenue while maintaining an average net profit margin of 10.8%, indicating strong overall financial performance and sustained customer demand. 
- Revenue was primarily driven by the Apparel and Fan Shop departments, which accounted for a significant share of total sales. From a geographic perspective, Europe and LATAM represented the company’s strongest markets, contributing the largest portions of overall revenue.
- Customer demand was concentrated primarily within the Consumer (~52%) and Corporate (~30%) segments. Orders were predominantly single-item purchases, suggesting a high-frequency, lower-volume purchasing model rather than bulk ordering. This behavior has important implications for inventory planning, fulfillment capacity, customer segmentation, and targeted marketing strategies.


## Data-Driven Strategic Recommendations

- **Optimize Discounting for Immediate Margin Impact:** Eliminate promotional code stacking and establish managerial approval thresholds for highly inelastic product categories, such as Fitness Accessories. This can reduce unnecessary discounting and protect promotional margins.

- **Capitalize on the Thursday Conversion Peak:** Launch digital-only flash sales, targeted promotions, and time-sensitive incentives on Thursdays, when conversion reaches 22.94%. Converting this high-intent traffic into completed purchases can increase e-commerce revenue and reduce reliance on traditional distribution channels.

- **Improve Checkout & Digital Conversion:** Simplify the checkout journey and redesign product landing pages for low-converting categories, such as Trade-In and Women’s Golf Clubs. Improving the digital purchase funnel can increase conversion by an estimated 2–5 percentage points without requiring additional customer acquisition spend.

- **Reduce Post-Purchase & Return Costs:** Introduce automated in-transit tracking notifications and perform root-cause analysis on high-cancellation categories, including Kids’ Golf Clubs and Pet Supplies. Addressing the primary causes of cancellations and returns can reduce reverse-logistics overhead and improve customer experience.

- **Strengthen SLA Monitoring & Fulfillment Risk Management:** Implement automated shipment checkpoint monitoring with early exception alerts for high-risk shipping modes, including First Class and Same Day, as well as volatile regions. Proactive intervention can improve delivery reliability, protect customer SLAs, and reduce the profitability impact of late shipments.


## The End-to-End Pipeline

The project architecture is divided into three distinct phases, ensuring a seamless flow from raw data to business decisions.

### Phase 1: Python ETL & Data Engineering
The raw DataCo dataset was initially provided as a highly denormalized flat file. Using Python with Pandas, NumPy, and SQLAlchemy, I developed a structured ETL (Extract, Transform, Load) workflow to clean, transform, normalize, and prepare the data for downstream analytics and business intelligence.

- **Data Cleaning:** Addressed missing and inconsistent values, standardized naming conventions, validated data types, and converted Unix timestamps into standardized DateTime formats for reliable temporal analysis.

- **Data Normalization:** Decomposed the denormalized source dataset into a relational data model consisting of 8 Dimension tables and 2 Fact tables, reducing data redundancy, improving data integrity, and establishing a scalable foundation for analytical workloads.

- **Feature Engineering & Surrogate Keys:** Designed and generated surrogate identifiers—including `Shipping_ID`, `Location_ID`, `Log_ID`, and other entity-specific keys—to uniquely identify business entities across the supply chain. These engineered keys supported the decomposition of the source dataset into normalized fact and dimension structures while maintaining referential integrity and enabling efficient relational querying, ERD development, and Power BI semantic modeling.

- **Data Export & SQL Readiness:** Programmatically exported the transformed DataFrames into structured CSV files using Pandas `to_csv()`, preserving schema consistency and preparing the curated datasets for SQL database ingestion, analytical querying, and executive dashboard development.


### Phase 2: SQL Server Data Warehousing & Schema Enforcement
The transition from Python-based transformation to SQL was a critical step in establishing a structured, production-ready analytical database. Using a dedicated SQL deployment script (`Import_DataCo.sql`), I implemented the following workflow:

- **Database Provisioning:** Created the `dataco_supply_chain` database to serve as the centralized repository for the normalized analytical data model.

- **Schema Definition:** Translated the Python-generated data structures into a formal relational schema using `CREATE TABLE` statements. Each dimension and fact table was defined with appropriate data types, including `DECIMAL(15,10)` for financial precision, `DATETIME` for temporal attributes, and `VARCHAR` for categorical fields, ensuring consistent and reliable data storage.

- **Data Ingestion:** Leveraged `LOAD DATA LOCAL INFILE` to efficiently bulk-load the Python-generated CSV files into their corresponding SQL tables, providing an efficient and scalable ingestion mechanism for the large dataset.

- **Primary Key Definition:** Assigned unique `PRIMARY KEY` constraints to dimension and fact tables, including `DimCustomer`, `DimProduct`, `FactSales`, and `FactWebTraffic`, to enforce record uniqueness and provide efficient row-level identification.

- **Foreign Key Relationships:** Established relationships between fact and dimension tables—for example, linking `FactSales.Customer_Id` to `DimCustomer.Customer_Id` — to enforce referential integrity, support reliable joins, and enable efficient cross-dimensional analytical queries.

- **ERD Development & Validation:** Built and validated the Entity Relationship Diagram (ERD) in MySQL Workbench to visually verify table relationships, cardinality, and data-model integrity, establishing efficient query paths for downstream analytics and Power BI reporting.



### Phase 3: Power BI Intelligence & Visualization
The SQL database served as the centralized data source for the Power BI dashboard suite, providing a structured foundation for semantic modeling, advanced analytics, and executive reporting.

- **Data Connectivity:** Connected Power BI directly to the MySQL database server, importing the curated dimension and fact tables into the Power BI semantic model for downstream analysis and reporting.

- **Semantic Modeling:** Recreated and validated the relational relationships established in SQL within Power BI, ensuring consistent filtering, cross-filtering, and cross-highlighting behavior across dashboards and analytical views.

- **DAX & Analytical Measures:** Developed advanced DAX measures for time-intelligence analysis, including Month-over-Month (MoM) growth, profitability metrics, KPI calculations, and conditional formatting logic to enhance analytical depth and business interpretation.

- **Dashboard & UI/UX Design:** Designed a 5-page executive dashboard suite covering Sales, Web Traffic, Operations, and Inventory performance. The dashboards incorporated intuitive navigation, interactive visualizations, KPI-driven layouts, and clear visual storytelling to communicate actionable insights to business stakeholders.


## Entity Relationship Diagram
The architecture leverages a Galaxy Schema to enable comprehensive analysis across sales, logistics, and web engagement by utilizing shared, conformed dimensions.
<img width="2209" height="1124" alt="ERD (DataCo)" src="https://github.com/user-attachments/assets/3c356d89-98f9-4c03-a18c-2e7e3caf3a3b" />


## Data Modeling
| Table Name | Strategic Role | Business Value |
| :--- | :--- | :--- |
| `FactSales` | Sales & Order Transactions | Captures transactional sales data, including revenue, quantity, discounts, and market attributes, supporting comprehensive sales, profitability, and operational analysis. |
| `FactWebTraffic` | Web Traffic & Customer Activity | Captures website activity and customer interactions associated with completed orders, enabling analysis of digital engagement, conversion behavior, and the relationship between web activity and sales outcomes. |
| `DimCustomer` | Customer Information | Stores customer demographic and geographic attributes, supporting customer segmentation, geographic analysis, and purchasing behavior insights. |
| `DimProduct` | Product Information | Contains product attributes, pricing, and category details, enabling analysis of product performance, pricing effectiveness, and portfolio composition. |
| `DimCategory` | Product Classification | Organizes products into business categories, supporting category-level sales, product mix, and performance analysis. |
| `DimDepartment` | Department Classification | Groups products by department, enabling evaluation of departmental sales performance and operational trends. |
| `DimLocation` | Geographic Information | Stores regional and market attributes, supporting geographic performance analysis, regional comparisons, and market-level insights. |
| `DimShipping` | Shipping & Delivery Information | Captures shipping methods and delivery attributes, enabling analysis of fulfillment efficiency, delivery performance, delays, and logistics operations. |
| `DimOrderDetails` | Order Information | Stores order-level attributes such as payment method, order status, and order date, supporting transaction lifecycle and order behavior analysis. |
| `DimDate` | Time Dimension | Provides a standardized date hierarchy across days, months, quarters, and years, enabling consistent trend, period-over-period, and seasonality analysis. |


## Technical Stack
- **ETL & Data Engineering:** Python (`Pandas`, `NumPy`, `SQLAlchemy`)
- **Database & Data Warehousing:** MySQL Workbench — Schema Design, Primary/Foreign Key Constraints, Indexing
- **Business Intelligence & Analytics:** Microsoft Power BI — DAX, Power Query, Data Modeling, SVG Custom Visuals


## Reference

- **Portfolio / Projects:** [Link to Github Portfolio](https://github.com/Danny-NG-9999/Academic-and-Personal-Projects)
