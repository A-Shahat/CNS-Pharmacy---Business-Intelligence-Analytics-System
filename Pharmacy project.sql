-- =====================================================================
-- EGYPTIAN PHARMACY CHAIN — SQL DATABASE PROJECT
-- =====================================================================
-- Author: Ahmed El-Shahat
-- Purpose: Complete database schema + analytical queries for Power BI
-- =====================================================================

-- =====================================================================
-- STEP 1: CREATE DATABASE
-- =====================================================================

DROP DATABASE IF EXISTS pharmacy_db;
CREATE DATABASE pharmacy_db;
USE pharmacy_db;

-- =====================================================================
-- STEP 2: CREATE TABLES
-- =====================================================================

-- TABLE 1: BRANCHES
CREATE TABLE branches (
    branch_id       INT PRIMARY KEY,
    branch_name     VARCHAR(100) NOT NULL,
    governorate     VARCHAR(50),
    city            VARCHAR(50),
    manager_name    VARCHAR(100),
    opening_date    DATE,
    square_meters   INT
);

-- TABLE 2: MEDICATIONS
CREATE TABLE medications (
    medication_id   INT PRIMARY KEY,
    medication_name VARCHAR(200) NOT NULL,
    category        VARCHAR(50),
    manufacturer    VARCHAR(100),
    unit_cost       DECIMAL(10,2),
    unit_price      DECIMAL(10,2),
    requires_rx     BIT,
    expiry_months   INT
);

-- TABLE 3: EMPLOYEES
CREATE TABLE employees (
    employee_id     INT PRIMARY KEY,
    employee_name   VARCHAR(100) NOT NULL,
    branch_id       INT,
    position        VARCHAR(50),
    hire_date       DATE,
    salary          DECIMAL(10,2),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- TABLE 4: SALES
CREATE TABLE sales (
    sale_id         INT PRIMARY KEY,
    branch_id       INT,
    employee_id     INT,
    medication_id   INT,
    sale_date       DATE,
    sale_time       TIME,
    quantity        INT,
    unit_price      DECIMAL(10,2),
    total_amount    DECIMAL(10,2),
    payment_method  VARCHAR(20),
    customer_age_group VARCHAR(20),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
);

-- TABLE 5: INVENTORY
CREATE TABLE inventory (
    inventory_id    INT PRIMARY KEY,
    branch_id       INT,
    medication_id   INT,
    stock_quantity  INT,
    last_restock    DATE,
    expiry_date     DATE,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
);

-- TABLE 6: SUPPLIERS
CREATE TABLE suppliers (
    supplier_id     INT PRIMARY KEY,
    supplier_name   VARCHAR(100) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    city            VARCHAR(50)
);

-- TABLE 7: PURCHASE_ORDERS
CREATE TABLE purchase_orders (
    order_id        INT PRIMARY KEY,
    branch_id       INT,
    supplier_id     INT,
    medication_id   INT,
    order_date      DATE,
    quantity        INT,
    unit_cost       DECIMAL(10,2),
    total_cost      DECIMAL(10,2),
    delivery_date   DATE,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
);

-- =====================================================================
-- STEP 3: LOADING DATA
-- =====================================================================

BULK INSERT dbo.branches
FROM 'D:\Work\Data Science\Databases\Pharmacy database\branches.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.employees
FROM 'D:\Work\Data Science\Databases\Pharmacy database\employees.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.inventory
FROM 'D:\Work\Data Science\Databases\Pharmacy database\inventory.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.medications
FROM 'D:\Work\Data Science\Databases\Pharmacy database\medications.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.purchase_orders
FROM 'D:\Work\Data Science\Databases\Pharmacy database\purchase_orders.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.sales
FROM 'D:\Work\Data Science\Databases\Pharmacy database\sales.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT dbo.suppliers
FROM 'D:\Work\Data Science\Databases\Pharmacy database\suppliers.csv'
WITH (
    Format= 'csv',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- =====================================================================
-- STEP 4: ANALYTICAL QUERIES
-- =====================================================================

-- QUERY 1: Top 10 Best-Selling Medications by Revenue
-- Purpose: Identify high-revenue products for inventory prioritization

SELECT top 10
    m.medication_name,
    m.category,
    m.manufacturer,
    COUNT(s.sale_id) AS total_transactions,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.total_amount) AS total_revenue,
    ROUND(AVG(s.total_amount), 2) AS avg_transaction_value
FROM sales s
JOIN medications m ON s.medication_id = m.medication_id
GROUP BY m.medication_id, m.medication_name, m.category, m.manufacturer
ORDER BY total_revenue DESC
;

-- QUERY 2: Branch Performance Comparison (Profit Analysis)
-- Purpose: Compare profitability across branches for expansion decisions

SELECT TOP 5
    b.governorate,
    b.city,
    b.branch_name,
    COUNT(s.sale_id) AS total_sales,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.total_amount - m.unit_cost * s.quantity) AS profit,
    ROUND(SUM(s.total_amount - m.unit_cost * s.quantity) / SUM(s.total_amount) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(s.total_amount) / COUNT(DISTINCT s.sale_date), 2) AS avg_daily_revenue
FROM sales s
JOIN branches b ON s.branch_id=b.branch_id
JOIN medications m ON s.medication_id = m.medication_id
GROUP BY b.branch_id, b.branch_name, b.governorate, b.city
ORDER BY profit DESC
;

-- QUERY 3: Inventory Risk Analysis (Expiring Soon + Low Stock)
-- Purpose: Identify urgent inventory issues requiring immediate action

SELECT 
    b.branch_name,
    m.medication_name,
    m.category,
    i.stock_quantity,
    i.expiry_date,
    DATEDIFF(day, GETDATE(), i.expiry_date) AS days_until_expiry,
    CASE 
        WHEN i.stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN i.stock_quantity < 20 THEN 'LOW STOCK'
        WHEN DATEDIFF(day, GETDATE(), i.expiry_date) < 30 THEN 'EXPIRING SOON'
        WHEN DATEDIFF(day, GETDATE(), i.expiry_date) = 0 THEN 'EXPIRED'
        ELSE 'OK'
    END AS status,
    ROUND(i.stock_quantity * m.unit_cost, 2) AS inventory_value_at_risk
FROM inventory i
JOIN branches b ON i.branch_id = b.branch_id
JOIN medications m ON i.medication_id = m.medication_id
WHERE i.stock_quantity < 20 OR DATEDIFF(day, GETDATE(), i.expiry_date) < 60
ORDER BY days_until_expiry, i.stock_quantity
;

-- QUERY 4: Employee Sales Performance with Rankings
-- Purpose: Evaluate and compare employee productivity

SELECT 
    e.employee_name,
    e.position,
    b.branch_name,
    COUNT(s.sale_id) AS total_sales,
    SUM(s.total_amount) AS revenue_generated,
    ROUND(AVG(s.total_amount), 2) AS avg_sale_value,
    RANK() OVER (
        PARTITION BY e.branch_id 
        ORDER BY SUM(s.total_amount) DESC
    ) AS branch_rank,
    RANK() OVER (
        ORDER BY SUM(s.total_amount) DESC
    ) AS overall_rank
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN branches b ON e.branch_id = b.branch_id
GROUP BY e.employee_id, e.employee_name, e.position, b.branch_name, e.branch_id
ORDER BY revenue_generated DESC
;

-- QUERY 5: Monthly Sales Trends by Category
-- Purpose: Identify seasonal patterns for inventory planning

SELECT 
    m.category,
    FORMAT(s.sale_date, 'yyyy-MM') AS year_month,
    SUM(s.total_amount) AS monthly_revenue,
    SUM(s.quantity) AS units_sold,
    COUNT(DISTINCT s.sale_id) AS transaction_count,
    ROUND(AVG(s.total_amount), 2) AS avg_transaction
FROM sales s
JOIN medications m ON s.medication_id = m.medication_id
GROUP BY 
    m.category, 
    FORMAT(s.sale_date, 'yyyy-MM')
ORDER BY 
    m.category, 
    year_month
;

-- QUERY 6: Medication revenue Analysis per governorate
-- Purpose: Knowing highly demanded medications to adjust it's inventory

SELECT 
    b.city,
    b.governorate,
    m.category,
    m.medication_name,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue,
    RANK() OVER (
        PARTITION BY b.city, b.governorate
        ORDER BY SUM(s.total_amount) DESC
    ) AS ranking_demographics
FROM sales s
JOIN branches b ON s.branch_id = b.branch_id
JOIN medications m ON m.medication_id = s.medication_id
GROUP BY
    b.city,
    b.governorate,
    m.category,
    m.medication_name
;

-- QUERY 7: Customer Demographics Analysis
-- Purpose: Understand customer base for targeted marketing

SELECT 
    customer_age_group,
    COUNT(sale_id) AS total_transactions,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_transaction,
    ROUND(
        SUM(total_amount) / (SELECT SUM(total_amount) FROM sales) * 100, 
        2
    ) AS revenue_share_pct
FROM sales
GROUP BY customer_age_group
ORDER BY total_revenue DESC
;

-- QUERY 8: Payment Method Analysis
-- Purpose: Optimize payment processing and cash flow management

SELECT 
    payment_method,
    COUNT(sale_id) AS transaction_count,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_transaction_value,
    ROUND(
        COUNT(sale_id) * 100.0 / (SELECT COUNT(*) FROM sales), 
        2
    ) AS transaction_share_pct
FROM sales
GROUP BY payment_method
ORDER BY total_revenue DESC
;

-- QUERY 9: Hourly Sales Pattern
-- Purpose: Identify peak hours for staff scheduling

SELECT 
    DATEPART(HOUR, sale_time) AS hour_of_day,
    COUNT(sale_id) AS transaction_count,
    SUM(total_amount) AS hourly_revenue,
    ROUND(AVG(total_amount), 2) AS avg_transaction
FROM sales
GROUP BY DATEPART(HOUR, sale_time)
ORDER BY hour_of_day
;

-- QUERY 10: Supplier Performance Evaluation
-- Purpose: Assess supplier reliability and costs

SELECT 
    s.supplier_name,
    s.city,
    COUNT(po.order_id) AS total_orders,
    SUM(po.quantity) AS total_units_ordered,
    SUM(po.total_cost) AS total_spent,
    ROUND(AVG(po.unit_cost), 2) AS avg_unit_cost,
    ROUND(
        AVG(DATEDIFF(day, po.order_date, po.delivery_date)), 
        1
    ) AS avg_delivery_days
FROM purchase_orders po
JOIN suppliers s 
    ON po.supplier_id = s.supplier_id
GROUP BY 
    s.supplier_id,
    s.supplier_name,
    s.city
ORDER BY total_spent DESC
;

-- QUERY 11: Medication Profitability Analysis
-- Purpose: Identify most and least profitable products

SELECT TOP 20
    m.medication_name,
    m.category,
    m.unit_cost,
    m.unit_price,
    m.unit_price - m.unit_cost AS profit_per_unit,
    ROUND((m.unit_price - m.unit_cost) / m.unit_cost * 100, 2) AS profit_margin_pct,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.total_amount - m.unit_cost * s.quantity) AS total_profit
FROM medications m
LEFT JOIN sales s ON m.medication_id = s.medication_id
GROUP BY m.medication_id, m.medication_name, m.category, m.unit_cost, m.unit_price
HAVING SUM(s.quantity) > 0 
ORDER BY total_profit DESC
;

-- QUERY 12: Branch Inventory Health Score
-- Purpose: Overall inventory health assessment per branch

SELECT 
    b.branch_name,
    COUNT(i.inventory_id) AS total_items,
    SUM(CASE WHEN i.stock_quantity = 0 THEN 1 ELSE 0 END) AS out_of_stock_count,
    SUM(CASE WHEN i.stock_quantity < 20 THEN 1 ELSE 0 END) AS low_stock_count,
    SUM(CASE WHEN DATEDIFF(day, GETDATE(), i.expiry_date) < 30 THEN 1 ELSE 0 END) AS expiring_soon_count,
    SUM(i.stock_quantity * m.unit_cost) AS total_inventory_value,
    ROUND(
        (1 - (SUM(CASE WHEN i.stock_quantity = 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(i.inventory_id))) * 100,
        2
    ) AS availability_score
FROM inventory i
JOIN branches b ON i.branch_id = b.branch_id
JOIN medications m ON i.medication_id = m.medication_id
GROUP BY b.branch_id, b.branch_name
ORDER BY availability_score DESC
;

-- QUERY 13: Category Performance Comparison (Year-over-Year)
-- Purpose: Identify growing vs declining categories

SELECT 
    m.category,
    YEAR(s.sale_date) AS year,
    SUM(s.total_amount) AS annual_revenue,
    COUNT(s.sale_id) AS transaction_count,
    LAG(SUM(s.total_amount)) OVER (
        PARTITION BY m.category 
        ORDER BY YEAR(s.sale_date)
    ) AS prev_year_revenue,
    ROUND(
        (SUM(s.total_amount) - LAG(SUM(s.total_amount)) OVER (
            PARTITION BY m.category 
            ORDER BY YEAR(s.sale_date)
        )) / LAG(SUM(s.total_amount)) OVER (
            PARTITION BY m.category 
            ORDER BY YEAR(s.sale_date)
        ) * 100,
        2
    ) AS yoy_growth_pct
FROM sales s
JOIN medications m ON s.medication_id = m.medication_id
GROUP BY m.category, YEAR(s.sale_date)
ORDER BY m.category, year
;

-- QUERY 14: ABC Analysis - Medication Classification by Revenue Contribution
-- Purpose: Identify which medications drive 80% of revenue (Pareto principle)

WITH medication_revenue AS (
    SELECT 
        m.medication_id,
        m.medication_name,
        m.category,
        SUM(s.total_amount) AS total_revenue,
        SUM(SUM(s.total_amount)) OVER () AS grand_total
    FROM sales s
    JOIN medications m ON s.medication_id = m.medication_id
    GROUP BY m.medication_id, m.medication_name, m.category
),
ranked_meds AS (
    SELECT 
        *,
        total_revenue / grand_total * 100 AS revenue_pct,
        SUM(total_revenue / grand_total * 100) OVER (
            ORDER BY total_revenue DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue_pct,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
    FROM medication_revenue
)
SELECT 
    medication_name,
    category,
    total_revenue,
    ROUND(revenue_pct, 2) AS revenue_contribution_pct,
    ROUND(cumulative_revenue_pct, 2) AS cumulative_pct,
    rank,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'A - Critical (80% revenue)'
        WHEN cumulative_revenue_pct <= 95 THEN 'B - Important (15% revenue)'
        ELSE 'C - Standard (5% revenue)'
    END AS abc_classification
FROM ranked_meds
ORDER BY rank;


-- QUERY 15: Reorder Point Calculator with Sales Velocity
-- Purpose: Calculate when to restock based on actual sales patterns

WITH sales_velocity AS (
    SELECT 
        s.medication_id,
        s.branch_id,
        COUNT(DISTINCT s.sale_date) AS days_with_sales,
        SUM(s.quantity) AS total_sold,
        ROUND(SUM(s.quantity) * 1.0 / NULLIF(COUNT(DISTINCT s.sale_date), 0), 2) AS avg_daily_sales,
        MAX(s.quantity) AS max_daily_sales
    FROM sales s
    WHERE s.sale_date >= DATEADD(MONTH, -3, GETDATE()) -- Last 3 months
    GROUP BY s.medication_id, s.branch_id
)
SELECT 
    b.branch_name,
    m.medication_name,
    m.category,
    i.stock_quantity AS current_stock,
    sv.avg_daily_sales,
    sv.max_daily_sales,
    ROUND(i.stock_quantity / NULLIF(sv.avg_daily_sales, 0), 1) AS days_of_stock_remaining,
    ROUND(sv.avg_daily_sales * 14, 0) AS recommended_reorder_point, -- 2 weeks safety stock
    ROUND((sv.avg_daily_sales * 30) - i.stock_quantity, 0) AS recommended_order_quantity, -- 1 month supply
    CASE 
        WHEN i.stock_quantity <= sv.avg_daily_sales * 7 THEN 'ORDER NOW - Critical'
        WHEN i.stock_quantity <= sv.avg_daily_sales * 14 THEN 'ORDER SOON - Low'
        WHEN i.stock_quantity >= sv.avg_daily_sales * 60 THEN 'OVERSTOCK - Reduce'
        ELSE 'OK - Normal'
    END AS reorder_status,
    i.stock_quantity * m.unit_cost AS current_inventory_value
FROM inventory i
JOIN branches b ON i.branch_id = b.branch_id
JOIN medications m ON i.medication_id = m.medication_id
LEFT JOIN sales_velocity sv ON i.medication_id = sv.medication_id AND i.branch_id = sv.branch_id
WHERE sv.avg_daily_sales IS NOT NULL -- Only items with recent sales
ORDER BY 
    CASE 
        WHEN i.stock_quantity <= sv.avg_daily_sales * 7 THEN 1
        WHEN i.stock_quantity <= sv.avg_daily_sales * 14 THEN 2
        ELSE 3
    END,
    sv.avg_daily_sales DESC;


-- QUERY 16: Market Basket Analysis - Frequently Bought Together
-- Purpose: Identify medication combinations purchased in same transaction

WITH transaction_pairs AS (
    SELECT 
        s1.sale_date,
        s1.sale_time,
        s1.branch_id,
        m1.medication_name AS medication_1,
        m1.category AS category_1,
        m2.medication_name AS medication_2,
        m2.category AS category_2,
        COUNT(*) AS co_purchase_count
    FROM sales s1
    JOIN sales s2 
        ON s1.sale_date = s2.sale_date 
        AND s1.sale_time = s2.sale_time 
        AND s1.branch_id = s2.branch_id
        AND s1.medication_id < s2.medication_id 
    JOIN medications m1 ON s1.medication_id = m1.medication_id
    JOIN medications m2 ON s2.medication_id = m2.medication_id
    GROUP BY 
        s1.sale_date,
        s1.sale_time,
        s1.branch_id,
        m1.medication_name,
        m1.category,
        m2.medication_name,
        m2.category
)
SELECT TOP 50
    medication_1,
    category_1,
    medication_2,
    category_2,
    COUNT(*) AS times_bought_together,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT CONCAT(sale_date, sale_time, branch_id)) 
        FROM sales
    ), 2) AS basket_frequency_pct
FROM transaction_pairs
GROUP BY 
    medication_1,
    category_1,
    medication_2,
    category_2
HAVING COUNT(*) >= 5
ORDER BY times_bought_together DESC;


-- QUERY 17: Branch Efficiency Scorecard - Multi-Metric Performance

WITH branch_metrics AS (
    SELECT 
        b.branch_id,
        b.branch_name,
        b.governorate,
        b.square_meters,
        
        -- Revenue Metrics
        SUM(s.total_amount) AS total_revenue,
        SUM(s.total_amount - m.unit_cost * s.quantity) AS total_profit,
        ROUND(SUM(s.total_amount - m.unit_cost * s.quantity) / NULLIF(SUM(s.total_amount), 0) * 100, 2) AS profit_margin,
        
        -- Efficiency Metrics
        COUNT(DISTINCT s.employee_id) AS employee_count,
        ROUND(SUM(s.total_amount) / NULLIF(b.square_meters, 0), 2) AS revenue_per_sqm,
        ROUND(SUM(s.total_amount) / NULLIF(COUNT(DISTINCT s.employee_id), 0), 2) AS revenue_per_employee,
        
        -- Customer Metrics
        COUNT(s.sale_id) AS total_transactions,
        ROUND(AVG(s.total_amount), 2) AS avg_transaction_value,
        
        -- Inventory Health
        (SELECT AVG(CASE WHEN stock_quantity > 0 THEN 1.0 ELSE 0.0 END) * 100
         FROM inventory 
         WHERE branch_id = b.branch_id) AS stock_availability_pct
         
    FROM branches b
    LEFT JOIN sales s ON b.branch_id = s.branch_id
    LEFT JOIN medications m ON s.medication_id = m.medication_id
    GROUP BY b.branch_id, b.branch_name, b.governorate, b.square_meters
)
SELECT 
    branch_name,
    governorate,
    total_revenue,
    profit_margin,
    
    -- Efficiency Scores (normalized to 0-100)
    ROUND(PERCENT_RANK() OVER (ORDER BY revenue_per_sqm) * 100, 1) AS space_efficiency_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY revenue_per_employee) * 100, 1) AS staff_efficiency_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY avg_transaction_value) * 100, 1) AS transaction_quality_score,
    ROUND(stock_availability_pct, 1) AS inventory_health_score,
    
    -- Overall Performance Score (weighted average)
    ROUND(
        (PERCENT_RANK() OVER (ORDER BY total_revenue) * 30 +
         PERCENT_RANK() OVER (ORDER BY profit_margin) * 25 +
         PERCENT_RANK() OVER (ORDER BY revenue_per_employee) * 20 +
         PERCENT_RANK() OVER (ORDER BY avg_transaction_value) * 15 +
         stock_availability_pct / 100 * 10) * 100 / 100,
    1) AS overall_performance_score,
    
    -- Raw Metrics
    revenue_per_sqm,
    revenue_per_employee,
    avg_transaction_value,
    total_transactions
    
FROM branch_metrics
ORDER BY overall_performance_score DESC;


-- QUERY 18: Customer Lifetime Value & Repeat Purchase Behavior
-- Purpose: Analyze customer loyalty patterns and identify high-value segments

WITH customer_transactions AS (
    SELECT 
        customer_age_group,
        sale_date,
        total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_age_group, 
            CAST(sale_date AS DATE), 
            DATEPART(HOUR, sale_time)
            ORDER BY sale_id
        ) AS transaction_sequence
    FROM sales
),
customer_metrics AS (
    SELECT 
        customer_age_group,
        COUNT(DISTINCT sale_date) AS visit_frequency,
        AVG(total_amount) AS avg_purchase_value,
        SUM(total_amount) AS total_lifetime_value,
        MIN(sale_date) AS first_purchase_date,
        MAX(sale_date) AS last_purchase_date,
        DATEDIFF(DAY, MIN(sale_date), MAX(sale_date)) AS customer_lifespan_days,
        COUNT(*) AS total_transactions
    FROM customer_transactions
    GROUP BY customer_age_group
)
SELECT 
    customer_age_group,
    total_transactions,
    visit_frequency,
    ROUND(avg_purchase_value, 2) AS avg_purchase_value,
    ROUND(total_lifetime_value, 2) AS estimated_lifetime_value,
    ROUND(total_lifetime_value / NULLIF(visit_frequency, 0), 2) AS avg_spend_per_visit,
    ROUND(customer_lifespan_days / NULLIF(visit_frequency, 0), 1) AS avg_days_between_visits,
    first_purchase_date,
    last_purchase_date,
    CASE 
        WHEN DATEDIFF(DAY, last_purchase_date, GETDATE()) > 90 THEN 'At Risk - Churned'
        WHEN DATEDIFF(DAY, last_purchase_date, GETDATE()) > 30 THEN 'At Risk - Inactive'
        WHEN visit_frequency >= 10 THEN 'Loyal - High Value'
        WHEN visit_frequency >= 5 THEN 'Regular - Medium Value'
        ELSE 'New - Low Value'
    END AS customer_segment,
    ROUND(total_lifetime_value * 100.0 / (SELECT SUM(total_amount) FROM sales), 2) AS revenue_contribution_pct
FROM customer_metrics
ORDER BY total_lifetime_value DESC;
