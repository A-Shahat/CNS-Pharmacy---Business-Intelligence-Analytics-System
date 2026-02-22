-- =====================================================================
-- POWER BI VIEWS - EGYPTIAN PHARMACY CHAIN
-- =====================================================================
-- Author: Ahmed El-Shahat
-- Purpose: Create views for new analytical queries for Power BI consumption
-- =====================================================================

USE pharmacy_db;
GO

-- VIEW 1: Sales Summary (for Power BI main dashboard)

CREATE OR ALTER VIEW vw_sales_summary AS
SELECT 
    s.sale_id,
    s.sale_date,
    s.sale_time,
    b.branch_name,
    b.governorate,
    b.city,
    e.employee_name,
    e.position,
    m.medication_name,
    m.category,
    m.manufacturer,
    s.quantity,
    s.unit_price,
    s.total_amount,
    m.unit_cost,
    s.total_amount - (m.unit_cost * s.quantity) AS profit,
    s.payment_method,
    s.customer_age_group,
    YEAR(s.sale_date) AS sale_year,
    MONTH(s.sale_date) AS sale_month,
    DATEPART(WEEKDAY, s.sale_date) AS day_of_week,
    DATEPART(HOUR, s.sale_time) AS hour_of_day
FROM sales s
JOIN branches b ON s.branch_id = b.branch_id
JOIN employees e ON s.employee_id = e.employee_id
JOIN medications m ON s.medication_id = m.medication_id;


-- VIEW 2: Inventory Status (for Power BI inventory dashboard)

CREATE OR ALTER VIEW vw_inventory_status AS
SELECT 
    i.inventory_id,
    b.branch_name,
    b.governorate,
    m.medication_name,
    m.category,
    m.manufacturer,
    i.stock_quantity,
    i.last_restock,
    i.expiry_date,
    DATEDIFF(DAY, GETDATE(), i.expiry_date) AS days_until_expiry,
    m.unit_cost,
    i.stock_quantity * m.unit_cost AS inventory_value,
    CASE 
        WHEN i.stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN i.stock_quantity < 20 THEN 'LOW STOCK'
        WHEN DATEDIFF(DAY, GETDATE(), i.expiry_date) < 0 THEN 'EXPIRED'
        WHEN DATEDIFF(DAY, GETDATE(), i.expiry_date) < 30 THEN 'EXPIRING SOON'
        ELSE 'OK'
    END AS status
FROM inventory i
JOIN branches b ON i.branch_id = b.branch_id
JOIN medications m ON i.medication_id = m.medication_id;


-- VIEW 3: ABC Analysis - Medication Classification

CREATE OR ALTER VIEW vw_abc_analysis AS
WITH medication_revenue AS (
    SELECT 
        m.medication_id,
        m.medication_name,
        m.category,
        m.manufacturer,
        SUM(s.total_amount) AS total_revenue,
        SUM(s.quantity) AS total_units_sold,
        SUM(SUM(s.total_amount)) OVER () AS grand_total
    FROM sales s
    JOIN medications m ON s.medication_id = m.medication_id
    GROUP BY m.medication_id, m.medication_name, m.category, m.manufacturer
),
ranked_meds AS (
    SELECT 
        *,
        total_revenue / grand_total * 100 AS revenue_pct,
        SUM(total_revenue / grand_total * 100) OVER (
            ORDER BY total_revenue DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue_pct,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM medication_revenue
)
SELECT 
    medication_id,
    medication_name,
    category,
    manufacturer,
    total_revenue,
    total_units_sold,
    ROUND(revenue_pct, 2) AS revenue_contribution_pct,
    ROUND(cumulative_revenue_pct, 2) AS cumulative_revenue_pct,
    revenue_rank,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'A - Critical (80% revenue)'
        WHEN cumulative_revenue_pct <= 95 THEN 'B - Important (15% revenue)'
        ELSE 'C - Standard (5% revenue)'
    END AS abc_classification,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 1
        WHEN cumulative_revenue_pct <= 95 THEN 2
        ELSE 3
    END AS abc_priority
FROM ranked_meds;
GO


-- VIEW 4: Reorder Point Calculator

CREATE OR ALTER VIEW vw_reorder_recommendations AS
WITH sales_velocity AS (
    SELECT 
        s.medication_id,
        s.branch_id,
        COUNT(DISTINCT s.sale_date) AS days_with_sales,
        SUM(s.quantity) AS total_sold_3months,
        ROUND(SUM(s.quantity) * 1.0 / NULLIF(COUNT(DISTINCT s.sale_date), 0), 2) AS avg_daily_sales,
        MAX(s.quantity) AS max_daily_sales,
        MIN(s.sale_date) AS first_sale_date,
        MAX(s.sale_date) AS last_sale_date
    FROM sales s
    WHERE s.sale_date >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY s.medication_id, s.branch_id
)
SELECT 
    i.inventory_id,
    b.branch_id,
    b.branch_name,
    b.governorate,
    b.city,
    m.medication_id,
    m.medication_name,
    m.category,
    m.manufacturer,
    i.stock_quantity AS current_stock,
    i.last_restock,
    i.expiry_date,
    sv.avg_daily_sales,
    sv.max_daily_sales,
    sv.total_sold_3months,
    ROUND(i.stock_quantity / NULLIF(sv.avg_daily_sales, 0), 1) AS days_of_stock_remaining,
    ROUND(sv.avg_daily_sales * 14, 0) AS recommended_reorder_point,
    ROUND((sv.avg_daily_sales * 30) - i.stock_quantity, 0) AS recommended_order_quantity,
    ROUND(i.stock_quantity * m.unit_cost, 2) AS current_inventory_value,
    ROUND(sv.avg_daily_sales * 30 * m.unit_cost, 2) AS target_inventory_value,
    CASE 
        WHEN sv.avg_daily_sales IS NULL THEN 'NO RECENT SALES'
        WHEN i.stock_quantity = 0 THEN 'OUT OF STOCK - Critical'
        WHEN i.stock_quantity <= sv.avg_daily_sales * 7 THEN 'ORDER NOW - Critical'
        WHEN i.stock_quantity <= sv.avg_daily_sales * 14 THEN 'ORDER SOON - Low'
        WHEN i.stock_quantity >= sv.avg_daily_sales * 60 THEN 'OVERSTOCK - Reduce'
        ELSE 'OK - Normal'
    END AS reorder_status,
    CASE 
        WHEN sv.avg_daily_sales IS NULL THEN 0
        WHEN i.stock_quantity = 0 THEN 5
        WHEN i.stock_quantity <= sv.avg_daily_sales * 7 THEN 4
        WHEN i.stock_quantity <= sv.avg_daily_sales * 14 THEN 3
        WHEN i.stock_quantity >= sv.avg_daily_sales * 60 THEN 2
        ELSE 1
    END AS priority_level
FROM inventory i
JOIN branches b ON i.branch_id = b.branch_id
JOIN medications m ON i.medication_id = m.medication_id
LEFT JOIN sales_velocity sv ON i.medication_id = sv.medication_id AND i.branch_id = sv.branch_id;
GO


-- VIEW 5: Market Basket Analysis

CREATE OR ALTER VIEW vw_market_basket AS
WITH transaction_pairs AS (
    SELECT 
        s1.sale_date,
        s1.sale_time,
        s1.branch_id,
        s1.medication_id AS med_id_1,
        s2.medication_id AS med_id_2
    FROM sales s1
    JOIN sales s2 
        ON s1.sale_date = s2.sale_date 
        AND s1.sale_time = s2.sale_time 
        AND s1.branch_id = s2.branch_id
        AND s1.medication_id < s2.medication_id
),
aggregated_pairs AS (
    SELECT 
        tp.med_id_1,
        tp.med_id_2,
        COUNT(*) AS co_purchase_count
    FROM transaction_pairs tp
    GROUP BY tp.med_id_1, tp.med_id_2
    HAVING COUNT(*) >= 5
)
SELECT 
    ap.med_id_1,
    m1.medication_name AS medication_1,
    m1.category AS category_1,
    ap.med_id_2,
    m2.medication_name AS medication_2,
    m2.category AS category_2,
    ap.co_purchase_count AS times_bought_together,
    ROUND(ap.co_purchase_count * 100.0 / (
        SELECT COUNT(DISTINCT CONCAT(sale_date, '-', sale_time, '-', branch_id)) 
        FROM sales
    ), 2) AS basket_frequency_pct,
    CASE 
        WHEN ap.co_purchase_count >= 50 THEN 'Very Strong'
        WHEN ap.co_purchase_count >= 20 THEN 'Strong'
        WHEN ap.co_purchase_count >= 10 THEN 'Moderate'
        ELSE 'Weak'
    END AS association_strength
FROM aggregated_pairs ap
JOIN medications m1 ON ap.med_id_1 = m1.medication_id
JOIN medications m2 ON ap.med_id_2 = m2.medication_id;
GO


-- VIEW 6: Branch Performance Scorecard

CREATE OR ALTER VIEW vw_branch_scorecard AS
WITH branch_metrics AS (
    SELECT 
        b.branch_id,
        b.branch_name,
        b.governorate,
        b.city,
        b.manager_name,
        b.square_meters,
        b.opening_date,
        
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
        COUNT(DISTINCT s.sale_date) AS operating_days,
        ROUND(SUM(s.total_amount) / NULLIF(COUNT(DISTINCT s.sale_date), 0), 2) AS avg_daily_revenue,
        
        -- Inventory Health
        (SELECT ROUND(AVG(CASE WHEN stock_quantity > 0 THEN 100.0 ELSE 0.0 END), 1)
         FROM inventory 
         WHERE branch_id = b.branch_id) AS stock_availability_pct
         
    FROM branches b
    LEFT JOIN sales s ON b.branch_id = s.branch_id
    LEFT JOIN medications m ON s.medication_id = m.medication_id
    GROUP BY b.branch_id, b.branch_name, b.governorate, b.city, b.manager_name, b.square_meters, b.opening_date
)
SELECT 
    branch_id,
    branch_name,
    governorate,
    city,
    manager_name,
    square_meters,
    opening_date,
    DATEDIFF(MONTH, opening_date, GETDATE()) AS months_in_operation,
    
    -- Financial Metrics
    total_revenue,
    total_profit,
    profit_margin,
    avg_daily_revenue,
    
    -- Efficiency Metrics
    revenue_per_sqm,
    revenue_per_employee,
    avg_transaction_value,
    total_transactions,
    employee_count,
    
    -- Performance Scores (0-100 normalized)
    ROUND(PERCENT_RANK() OVER (ORDER BY revenue_per_sqm) * 100, 1) AS space_efficiency_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY revenue_per_employee) * 100, 1) AS staff_efficiency_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY avg_transaction_value) * 100, 1) AS transaction_quality_score,
    ROUND(ISNULL(stock_availability_pct, 0), 1) AS inventory_health_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_revenue) * 100, 1) AS revenue_score,
    
    -- Overall Performance Score (weighted composite)
    ROUND(
        (PERCENT_RANK() OVER (ORDER BY total_revenue) * 30 +
         PERCENT_RANK() OVER (ORDER BY profit_margin) * 25 +
         PERCENT_RANK() OVER (ORDER BY revenue_per_employee) * 20 +
         PERCENT_RANK() OVER (ORDER BY avg_transaction_value) * 15 +
         ISNULL(stock_availability_pct, 0) / 100 * 10) * 100 / 100,
    1) AS overall_performance_score,
    
    -- Performance Rating
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY total_revenue) >= 0.8 THEN 'Excellent'
        WHEN PERCENT_RANK() OVER (ORDER BY total_revenue) >= 0.6 THEN 'Good'
        WHEN PERCENT_RANK() OVER (ORDER BY total_revenue) >= 0.4 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS performance_rating
    
FROM branch_metrics;
GO


-- VIEW 7: Customer Lifetime Value & Segmentation

CREATE OR ALTER VIEW vw_customer_segments AS
WITH customer_metrics AS (
    SELECT 
        customer_age_group,
        COUNT(DISTINCT CONCAT(sale_date, '-', DATEPART(HOUR, sale_time))) AS estimated_unique_customers,
        AVG(total_amount) AS avg_purchase_value,
        SUM(total_amount) AS total_lifetime_value,
        MIN(sale_date) AS first_purchase_date,
        MAX(sale_date) AS last_purchase_date,
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT sale_date) AS visit_frequency
    FROM sales
    WHERE customer_age_group IS NOT NULL
    GROUP BY customer_age_group
)
SELECT 
    customer_age_group,
    total_transactions,
    estimated_unique_customers,
    visit_frequency AS total_visit_days,
    ROUND(avg_purchase_value, 2) AS avg_purchase_value,
    ROUND(total_lifetime_value, 2) AS total_segment_revenue,
    ROUND(total_lifetime_value / NULLIF(estimated_unique_customers, 0), 2) AS estimated_customer_ltv,
    ROUND(total_lifetime_value / NULLIF(visit_frequency, 0), 2) AS avg_spend_per_visit,
    DATEDIFF(DAY, first_purchase_date, last_purchase_date) AS segment_lifespan_days,
    first_purchase_date,
    last_purchase_date,
    DATEDIFF(DAY, last_purchase_date, GETDATE()) AS days_since_last_purchase,
    
    -- Segment Classification
    CASE 
        WHEN DATEDIFF(DAY, last_purchase_date, GETDATE()) > 90 THEN 'At Risk - Churned'
        WHEN DATEDIFF(DAY, last_purchase_date, GETDATE()) > 30 THEN 'At Risk - Inactive'
        WHEN visit_frequency >= 100 THEN 'Loyal - High Value'
        WHEN visit_frequency >= 50 THEN 'Regular - Medium Value'
        ELSE 'New - Low Value'
    END AS customer_segment,
    
    -- Revenue Contribution
    ROUND(total_lifetime_value * 100.0 / (SELECT SUM(total_amount) FROM sales), 2) AS revenue_contribution_pct,
    
    -- Segment Priority
    CASE 
        WHEN total_lifetime_value > (SELECT AVG(total_amount) * 1000 FROM sales) THEN 'VIP'
        WHEN total_lifetime_value > (SELECT AVG(total_amount) * 500 FROM sales) THEN 'Premium'
        ELSE 'Standard'
    END AS segment_tier
    
FROM customer_metrics;
GO


-- VIEW 8 : Unified Analytics Dashboard

CREATE OR ALTER VIEW vw_executive_summary AS
SELECT 
    -- Time Period
    CAST(GETDATE() AS DATE) AS report_date,
    
    -- Revenue Metrics
    (SELECT SUM(total_amount) FROM sales) AS total_revenue_alltime,
    (SELECT SUM(total_amount) FROM sales WHERE sale_date >= DATEADD(MONTH, -1, GETDATE())) AS revenue_last_month,
    (SELECT SUM(total_amount) FROM sales WHERE sale_date >= DATEADD(DAY, -7, GETDATE())) AS revenue_last_week,
    (SELECT SUM(total_amount) FROM sales WHERE CAST(sale_date AS DATE) = CAST(GETDATE() AS DATE)) AS revenue_today,
    
    -- Profit Metrics
    (SELECT SUM(s.total_amount - m.unit_cost * s.quantity) 
     FROM sales s JOIN medications m ON s.medication_id = m.medication_id) AS total_profit_alltime,
    
    -- Transaction Metrics
    (SELECT COUNT(*) FROM sales) AS total_transactions_alltime,
    (SELECT ROUND(AVG(total_amount), 2) FROM sales) AS avg_transaction_value,
    
    -- Inventory Metrics
    (SELECT COUNT(*) FROM inventory WHERE stock_quantity = 0) AS out_of_stock_items,
    (SELECT COUNT(*) FROM inventory WHERE stock_quantity < 20) AS low_stock_items,
    (SELECT COUNT(*) FROM inventory WHERE DATEDIFF(DAY, GETDATE(), expiry_date) < 30) AS expiring_soon_items,
    (SELECT SUM(i.stock_quantity * m.unit_cost) 
     FROM inventory i JOIN medications m ON i.medication_id = m.medication_id) AS total_inventory_value,
    
    -- Branch Metrics
    (SELECT COUNT(*) FROM branches) AS total_branches,
    (SELECT COUNT(DISTINCT branch_id) FROM sales WHERE sale_date >= DATEADD(MONTH, -1, GETDATE())) AS active_branches_last_month,
    
    -- Employee Metrics
    (SELECT COUNT(*) FROM employees) AS total_employees,
    (SELECT COUNT(DISTINCT employee_id) FROM sales WHERE sale_date >= DATEADD(MONTH, -1, GETDATE())) AS active_employees_last_month,
    
    -- Product Metrics
    (SELECT COUNT(*) FROM medications) AS total_medications,
    (SELECT COUNT(DISTINCT medication_id) FROM sales WHERE sale_date >= DATEADD(MONTH, -1, GETDATE())) AS active_medications_last_month,
    
    -- Top Performers
    (SELECT TOP 1 branch_name FROM vw_branch_scorecard ORDER BY total_revenue DESC) AS top_branch_by_revenue,
    (SELECT TOP 1 medication_name FROM vw_abc_analysis ORDER BY total_revenue DESC) AS top_medication_by_revenue,
    
    -- Growth Indicators
    (SELECT ROUND(
        (SUM(CASE WHEN sale_date >= DATEADD(MONTH, -1, GETDATE()) THEN total_amount ELSE 0 END) - 
         SUM(CASE WHEN sale_date >= DATEADD(MONTH, -2, GETDATE()) AND sale_date < DATEADD(MONTH, -1, GETDATE()) THEN total_amount ELSE 0 END)) /
        NULLIF(SUM(CASE WHEN sale_date >= DATEADD(MONTH, -2, GETDATE()) AND sale_date < DATEADD(MONTH, -1, GETDATE()) THEN total_amount ELSE 0 END), 0) * 100
    , 2) FROM sales) AS mom_revenue_growth_pct;
GO


-- =====================================================================
-- VERIFICATION QUERIES
-- =====================================================================
-- Run these to verify all views are working correctly

SELECT 'vw_sales_summary' AS view_name, COUNT(*) AS row_count FROM vw_sales_summary
UNION ALL
SELECT 'vw_inventory_status', COUNT(*) FROM vw_inventory_status
UNION ALL
SELECT 'vw_abc_analysis', COUNT(*) FROM vw_abc_analysis
UNION ALL
SELECT 'vw_reorder_recommendations', COUNT(*) FROM vw_reorder_recommendations
UNION ALL
SELECT 'vw_market_basket', COUNT(*) FROM vw_market_basket
UNION ALL
SELECT 'vw_branch_scorecard', COUNT(*) FROM vw_branch_scorecard
UNION ALL
SELECT 'vw_customer_segments', COUNT(*) FROM vw_customer_segments
UNION ALL
SELECT 'vw_executive_summary', COUNT(*) FROM vw_executive_summary;

-- =====================================================================
-- POWER BI CONNECTION STRING
-- =====================================================================
/*
Server: localhost (or your SQL Server instance)
Database: pharmacy_db
Authentication: Windows Authentication / SQL Server Authentication

VIEWS AVAILABLE FOR POWER BI:
1. vw_sales_summary          - Main sales data with all dimensions
2. vw_inventory_status        - Current inventory with health indicators
3. vw_abc_analysis            - Medication classification by importance
4. vw_reorder_recommendations - Smart reordering suggestions
5. vw_market_basket           - Product associations for cross-selling
6. vw_branch_scorecard        - Comprehensive branch performance
7. vw_customer_segments       - Customer behavior and value analysis
8. vw_executive_summary       - Key metrics for dashboard KPIs
*/
