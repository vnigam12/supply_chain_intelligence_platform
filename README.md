## Project Overview

This project demonstrates a complete End-to-End BI Pipeline for DataCo Global, a simulated multinational retail corporation. The solution spans the entire data lifecycle: from raw data ingestion and transformation using Python, to structured data warehousing in SQL Server, and finally to executive-level business intelligence dashboard in Power BI.

By transforming over 180,000 denormalized records into a robust Fact Constellation (Galaxy) Schema, this project provides actionable insights into logistics efficiency, profitability leakage, and customer conversion.

---

## Table of Contents
- [Datasource](#datasource)
- [Repository Architecture](#repository-architecture)
- [Business Questions & Project Objectives](#business-questions--project-objectives)
- [Executive Performance Summary](#executive-performance-summary)
  - [Strategic Insights](#strategic-insights)
  - [Key Business Challenges](#key-business-challenges)
  - [Data-Driven Recommendations](#data-driven-recommendations)
- [The End-to-End Pipeline](#the-end-to-end-pipeline)
  - [Phase 1: Python ETL & Data Engineering](#phase-1-python-etl--data-engineering)
  - [Phase 2: SQL Server Data Warehousing & Schema Enforcement](#phase-2-sql-server-data-warehousing--schema-enforcement)
  - [Phase 3: Power BI Intelligence & Visualization](#phase-3-power-bi-intelligence--visualization)
- [Data Modeling (Fact Constellation Schema)](#data-modeling-fact-constellation-schema)
- [Entity Relationship Diagram (ERD)](#entity-relationship-diagram-erd)
- [Business Performance Dashboard Summary](#business-performance-dashboard-summary)
- [Technical Stack](#technical-stack)
- [Author & Professional Contact](#author--professional-contact)

---

## Datasource
- **Source:** DataCo Smart Supply Chain for Big Data Analysis
- **Access Link:** [Mendeley Data Dataset (Version 5)](https://data.mendeley.com/datasets/8gx2fvg2k6/5)
- **Description:** Contains structured enterprise supply chain data, covering transactional sales, customer activity, web traffic logs, and shipping logistics metrics across global business units.

## Repository Architecture
```text
├── Database             # Database scripts, schemas, or relational data files
├── Dataset              # Raw datasets used across analysis and reporting
├── PowerBI Dashboard    # Power BI dashboard files (.pbix) and visual assets
├── Process Files        # Data transformation, prep, and pipeline processing scripts
├── SQL                  # SQL queries, procedures, and data extraction scripts
└── README.md            # Project documentation and executive summary
```

---

# DataCo: An End-to-End Data Analysis & Business Intelligence Pipeline
<img width="1858" height="1038" alt="image" src="https://github.com/user-attachments/assets/59e0cbb8-2402-48b7-a02a-39a37aff6190" />

---
## Business Questions & Project Objectives
This project was designed to answer a series of strategic business questions across sales performance, digital commerce, pricing strategy, and supply chain operations. The objective was not only to build an end-to-end Business Intelligence pipeline, but also to transform enterprise data into actionable insights that support executive decision-making. Specifically, the analysis seeks to answer the these key questions:

**💰 Revenue & Commercial Performance**
- Which products, departments, customer segments, and geographic markets generate the highest revenue and profitability?
- How has business performance evolved over time, and what seasonal trends influence sales?

**🏷️ Pricing & Profitability**
- How do discount strategies influence sales performance and profit margins?
- Which product categories experience the greatest margin erosion from excessive discounting?
- Which products are highly price-sensitive, and where can promotional spending be optimized without sacrificing profitability?

**🌐 Digital Commerce & Customer Conversion**
- How effectively does website traffic convert into completed purchases?
- Which days of the week, product categories, and customer segments achieve the highest conversion rates?

**🚚 Logistics & Fulfillment Performance**
- Which shipping modes, regions, and fulfillment processes experience the greatest operational inefficiencies?
- How do delivery reliability and shipping performance affect profitability?

**📊 Strategic Decision Support**
- Which operational improvements provide the highest business impact relative to implementation effort?

---

## Executive Performance Summary
Between 2015 and 2018, DataCo generated approximately $36.78 million in total revenue while maintaining an average net profit margin of 10.8%, reflecting strong financial performance and sustained market demand. The company's revenue was largely driven by the Apparel and Fan Shop departments, which generated the majority of total revenue and demonstrated strong product demand. From a regional perspective, Europe and LATAM emerged as the company's most significant markets, contributing the largest share of sales. Customer demand was primarily concentrated within the Consumer (≈52%) and Corporate (≈30%) segments, with single-item orders representing the dominant purchasing behaviour. This purchasing pattern suggests a business characterised by frequent, lower-volume orders rather than bulk purchases, providing valuable context for inventory planning, fulfilment operations, and targeted marketing strategies.

### Strategic Insights
- **Good Global Market Penetration:** Europe and LATAM serve as the dominant revenue pillars, each generating over $10 million in sales. Pacific Asia follows closely with $8 million, confirming a strong, diversified global footprint with significant international demand.
- **Core Departmental Revenue Concentration:** The Fan Shop and Apparel departments function as the company's primary commercial engines, collectively contributing approximately 70% of total sales. While this reflects strong customer demand and product performance, it also indicates a high revenue concentration, meaning that disruptions to product availability, supply chain operations, or changes in customer demand within these two departments could have a significant impact on overall business performance.
- **Digital Conversion Performance:** Customer conversion reached 22.94% on Thursdays, compared with an average of approximately 9.5% on other weekdays. This near 2.5x uplift identifies Thursday as the most effective day for targeted promotions, product launches, and digital marketing campaigns.
- **High-Value Customer Segments:** Corporate and Consumer customers consistently recorded the highest average order values through predominantly single-item purchases, presenting opportunities for premium product offerings, personalised marketing campaigns, and customer retention initiatives.
- **Delivery Delays Are Operational Rather Than Capacity-Driven:** Although order volumes vary throughout the year, delivery performance remains largely unchanged. This indicates that delays are more likely caused by inefficiencies in fulfillment and delivery operations than by insufficient logistics capacity.
- **High-Volume Shipments Are More Susceptible to Delays:** Late deliveries are concentrated among high-volume shipments, while on-time deliveries are more common for moderate-sized orders. This patterns suggest that fulfillment processes become less efficient as shipment complexity increases, highlighting the need for proactive monitoring and priority handling of large orders.
- **Delivery Reliability Drives Profitability:** On-time deliveries consistently generate the highest profit margins, while cancelled orders deliver the weakest financial returns. Although late deliveries remain profitable, recurring delivery delays gradually reduce overall margins and customer value. This highlights delivery reliability as a key driver of financial performance, where improving fulfillment efficiency can increase profitability without requiring additional sales or price increases.
- **Product Price Is Not the Primary Driver of Profitability:** Profitability is influenced more by operational execution and discounting strategy than by product price. Products delivered on time with well-managed discounts consistently achieve stronger margins, indicating that improving fulfillment performance and optimizing promotional strategies can generate greater profit gains than focusing solely on selling higher-priced products.

### Key Business Challenges
- **Digital Channel Underperformance & Conversion Failure:** Despite generating over 443K monthly page views, the e-commerce platform operates as a passive "window shopping" catalog rather than a revenue driver. The web channel contributes only 3.04% of total sales, and traditional non-web channels capture over 97% of revenue across all top-selling product lines. This indicates a severe deficiency in digital acquisition and checkout conversion, rather than a lack of market demand for the products themselves.
- **Severe Logistics & Fulfillment Bottlenecks:** Between 2015 and 2017, DataCo fulfilled 65,752 orders, yet delivery performance remained a critical operational weakness. Approximately 54.8% of all shipments were delivered late, while only 17.8% arrived on time, indicating a persistent failure to meet customer delivery expectations. Delayed orders required an average of 4.09 days to arrive compared with the promised 2.0 to 4.0 days transit time. The analysis further shows that late deliveries are directly associated with lower profitability, as additional fulfillment costs, expedited shipping, penalty fees and service recovery efforts erode order margins. Since delivery delays remained consistently high despite stable order volumes, the root cause lies in systemic fulfillment inefficiencies rather than demand fluctuations.
- **Seasonal Margin Erosion (Q4 Unit-Mix Shift):** While gross order volumes remain stable during November and December, total revenue declines significantly. This is driven by a dangerous shift in product composition: customers are substituting high-margin, premium items for low-value, medium-volume goods. This unit-mix compression actively erodes Q4 profitability, signaling that the current holiday promotional strategy is cannibalizing the bottom line.

### Data-Driven Recommendations
- **Discount Optimization (Immediate ROI):** Eliminate promotional code stacking and enforce managerial approval thresholds for inelastic product categories (e.g., Fitness Accessories) to stop margin erosion and maximize promotional profitability.
- **SLA Performance & Risk Dashboard (Strategic Investment):** Implement automated checkpoint monitoring and early exception escalation across high-risk shipping modes (First Class, Same Day) and volatile regions to eliminate late delivery delays and protect customer SLAs.
- **Checkout & Traffic Optimization (Strategic Investment):** Streamline checkout steps and redesign product landing pages for low-converting categories (e.g., Trade-In, Women's Golf Clubs) to boost web conversion rates by 2–5 percentage points without increasing acquisition costs.
- **Post-Purchase & Return Rate Reduction (Tactical Optimization):** Deploy automated in-transit tracking notifications and conduct return root-cause analytics for high-cancellation categories (e.g., Kids' Golf Clubs, Pet Supplies) to cut return logistics overhead by 10–15%.
- **Capitalize on the Thursday Peak:** Deploy exclusive, digital-only flash sales and time-sensitive incentives on Thursdays. Channeling the 22.94% high-intent traffic into finalized web sales will reduce reliance on traditional distribution networks and expand overall e-commerce profitability.

---

## The End-to-End Pipeline

The project architecture is divided into three distinct phases, ensuring a seamless flow from raw data to business decisions.

### Phase 1: Python ETL & Data Engineering
The raw DataCo dataset was initially a denormalized flat file. Using Python (Pandas, NumPy, SQLAlchemy), I implemented a comprehensive ETL (Extract, Transform, Load) workflow:
- **Data Cleaning:** Handled missing values, standardized naming conventions, and corrected data types (e.g., converting Unix timestamps to DateTime).
- **Normalization:** Deconstructed the flat file into a relational model, creating 8 Dimension tables and 2 Fact tables to eliminate redundancy and improve data integrity.
- **Feature Engineering:** Designed and generated surrogate key columns (e.g., Shipping_ID, Location_ID, Log_ID, and other entity identifiers) to uniquely represent business entities across the supply chain. These engineered identifiers served as the foundation for decomposing the original denormalized dataset into normalized dimension and fact tables, ensuring referential integrity, minimizing data redundancy, and supporting efficient SQL database development, Entity Relationship Diagram (ERD) construction, analytical querying, and Power BI semantic modelling for executive dashboard reporting.
- **Exporting Tables:** The cleaned and normalized DataFrames were programmatically exported as structured CSV files using Pandas' `to_csv()` method, ensuring data integrity and readiness for SQL ingestion.

### Phase 2: SQL Server Data Warehousing & Schema Enforcement
The transition from Python to SQL was a critical step in establishing a production-grade analytical database. Using a dedicated SQL script (`Import_DataCo.sql`), I implemented the following workflow:
- **Database Provisioning:** The script initiated by creating the `dataco_supply_chain` database to host the analytical model.
- **Schema Definition (Python to SQL):** For each dimension and fact table, `CREATE TABLE` statements were executed, explicitly defining columns with precise data types (e.g., `DECIMAL(15, 10)` for financial precision, `DATETIME` for temporal accuracy, `VARCHAR` for categorical data). This step ensured that the Python-generated data conformed to a strict relational schema.
- **Data Ingestion:** High-speed `LOAD DATA LOCAL INFILE` commands were utilized to efficiently import the Python-generated CSVs into their respective SQL tables, ensuring scalability for large datasets.
- **Defining Primary Keys:** Each dimension table (e.g., `DimCustomer`, `DimProduct`) and fact table (`FactSales`, `FactWebTraffic`) had its unique identifier explicitly defined as a `PRIMARY KEY` during table creation, guaranteeing data uniqueness and supporting efficient data retrieval.
- **Defining Foreign Keys & Relationships:** Established foreign key relationships between fact and dimension tables (e.g., `FactSales.Customer_Id` referencing `DimCustomer.Customer_Id`) to maintain referential integrity, enable accurate table joins, and support efficient analytical querying within the relational database.
- **Building the ERD:** The Entity Relationship Diagram (ERD) was subsequently built and validated within the SQL environment (MySQL Workbench), visually confirming the integrity of the data model and ensuring efficient query paths for downstream BI tools.

### Phase 3: Power BI Intelligence & Visualization
The SQL Server database served as the live source for the Power BI dashboard suite:
- **Data Connectivity:** Power BI was connected directly to the MySQL Workbench Server instance, importing the structured tables into the Power BI semantic model.
- **Semantic Modeling:** The relationships defined in SQL were replicated and validated within Power BI's data model, ensuring consistent filtering and cross-highlighting behavior across all reports.
- **DAX Implementation:** Advanced DAX measures were developed for time-intelligence (MoM growth), profitability ratios, and conditional formatting logic, enriching the analytical capabilities of the dashboard.
- **UI/UX Design:** A 5-page executive dashboard was designed, focusing on Sales, Web Traffic, Operations, and Inventory, providing intuitive navigation and clear communication of insights.

---

## Data Modeling (Fact Constellation Schema)
The architecture utilizes a Galaxy Schema to support complex analysis across sales, logistics, and web engagement through shared dimensions.

| Table Name | Strategic Role | Business Value |
| :--- | :--- | :--- |
| `FactSales` | Sales & Order Transactions | Stores transactional sales data, including revenue, quantity, discounts, and market information, enabling comprehensive sales, profitability, and operational analysis. |
| `FactWebTraffic` | Web Traffic & Customer Activity | Records website activity and links customer interactions to completed orders, enabling analysis of customer engagement, conversion behaviour, and the relationship between online activity and sales outcomes. |
| `DimCustomer` | Customer Information | Contains customer demographic and location attributes, enabling customer segmentation, geographic analysis, and purchasing behaviour analysis. |
| `DimProduct` | Product Information | Stores product details, pricing, and category information, supporting product performance, pricing, and product portfolio analysis. |
| `DimCategory` | Product Classification | Organises products into business categories, enabling category-level sales and product mix analysis. |
| `DimDepartment` | Department Classification | Groups products by department to evaluate departmental sales and operational performance. |
| `DimLocation` | Geographic Information | Stores regional and market information, supporting geographic sales analysis, regional performance monitoring, and market comparisons. |
| `DimShipping` | Shipping & Delivery Information | Captures shipping methods and delivery performance, enabling analysis of shipping efficiency, delivery delays, and logistics operations. |
| `DimOrderDetails` | Order Information | Stores order-level attributes such as payment type, order status, and order date, supporting order lifecycle and transaction analysis. |
| `DimDate` | Time Dimension | Provides a standardized date hierarchy for analysing business performance across days, months, quarters, and years, enabling trend and seasonality analysis. |

## Entity Relationship Diagram (ERD)
<img width="2209" height="1124" alt="ERD (DataCo)" src="https://github.com/user-attachments/assets/3c356d89-98f9-4c03-a18c-2e7e3caf3a3b" />

---

## Business Performance Dashboard Summary

| Dashboard Page | Strategic Focus | Business Value |
| :--- | :--- | :--- |
| **Overview** | High-level business health monitoring across core financial metrics (Sales, Costs, Profit), volume indicators, category/market distribution, customer segmentation, and monthly sales seasonality. | Provides executive visibility into top-line revenue performance, identifying top sales drivers by category/market, payment preferences, and seasonal demand fluctuations to guide annual budgeting and commercial planning. |
| **Discounts** | Evaluation of promotional discount depth, discount elasticity, margin erosion per 1% discount, and order discount rates across price segments and categories. | Prevents margin leakage by identifying inelastic or high-erosion product categories, enabling targeted discount capping to preserve overall profitability while maintaining strategic promotional depth. |
| **Web Traffic** | Digital channel effectiveness, web conversion rates by day of week, category-level conversion performance, and web vs. non-web sales channel breakdown by product. | Pinpoints conversion bottlenecks on digital platforms, optimizes marketing spend across high-performing sales days (e.g., Thursday peak), and guides targeted UX/UI improvements on low-converting product landing pages. |
| **Shipping** | Fulfillment performance analysis tracking late vs. canceled order trends, variance between scheduled and actual delivery days, and profitability by shipping status and mode. | Minimizes logistics inefficiencies and SLA breach risks by identifying carrier/mode delays (e.g., *Late Delivery* average variance of +1.5 days), optimizing shipping choices to protect customer satisfaction and unit margins. |
| **Recommendation** | Strategic prioritization via an Impact vs. Effort matrix covering key initiatives: Discount Optimization, SLA Performance & Risk, Checkout/Traffic, and Post-Purchase/Return Reduction. | Translates complex operational data into actionable, prioritized business initiatives—enabling leadership to execute immediate high-ROI quick wins while structuring long-term strategic investments. |

---

## Technical Stack
* **ETL & Data Engineering:** Python (`pandas`, `numpy`, `sqlalchemy`)
* **Database & Warehousing:** MySQL Workbench (Schema Design, PK/FK Constraints, Indexing)
* **Business Intelligence & Analytics:** Microsoft Power BI (DAX, SVG Custom Visuals, Power Query, Data Modeling)

---

## Author & Professional Contact

**Daniel (Viet) Nguyen**  
*BI Consultant*  
- **Date:** July 2026
- **Portfolio / Projects:** [Link to Github Portfolio](https://github.com/Danny-NG-9999/Academic-and-Personal-Projects)
- **Email:** daniel.h.nguyen24@gmail.com

*If you find this repository helpful or relevant to your enterprise BI architecture, feel free to give it a ⭐️!*

---
