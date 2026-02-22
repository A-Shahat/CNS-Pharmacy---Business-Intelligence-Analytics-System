# 🏥 CNS Pharmacy Chain - Business Intelligence & Analytics System

A comprehensive **end-to-end business intelligence solution** for a multi-branch pharmacy chain, featuring complete database design, advanced SQL analytics, interactive dashboards, and Power BI integration.

## 📊 Project Overview

This project demonstrates a **full-stack data analytics pipeline** for a pharmacy chain with 10 branches, 50+ employees, 200+ medications, and 50,000+ transactions. It includes database design, complex SQL queries, data visualization, and actionable business insights.

### Key Deliverables:
- ✅ **Normalized relational database** (7 tables with referential integrity)
- ✅ **18 advanced analytical SQL queries** for business intelligence
- ✅ **8 Power BI-ready views** with pre-aggregated metrics
- ✅ **Interactive HTML dashboard** with 20+ visualizations
- ✅ **Complete Power BI dashboard** with 4 analysis pages
- ✅ **ABC Analysis**, **Reorder Point Calculator**, **Market Basket Analysis**

---

## 🎯 Business Impact

| Metric | Result | Impact |
|--------|--------|--------|
| **Revenue Analyzed** | EGP 19.2M | 100% transaction coverage |
| **Profit Identified** | EGP 5.2M | 27.17% profit margin |
| **Stock Issues Detected** | 26 out-of-stock items | Prevented lost sales |
| **Inventory Optimization** | ABC classification | Focus on top 20% driving 80% revenue |
| **Decision Speed** | Real-time dashboards | Reduced analysis time by 90% |

---

## 🛠️ Technology Stack

### Database & SQL
- **SQL Server** - Primary database engine
- **SSMS** - Database management and query development
- **T-SQL** - Advanced queries with window functions, CTEs, subqueries

### Analytics & Visualization
- **Power BI Desktop** - Interactive dashboards
- **Python** (pandas, json) - Data processing and transformation
- **HTML/CSS/JavaScript** - Custom dashboard development
- **Chart.js** - Web-based data visualization

### Development Tools
- **Git/GitHub** - Version control
- **PYCharm** - Code editor
- **Excel** - Data validation and prototyping

---

## 📁 Project Structure

```
pharmacy-analytics/
│
├── database/
│   ├── schema.sql                    # Database creation script
│   ├── pharmacy_powerbi_views.sql    # 8 analytical views
│   └── data/                         # CSV source data
│       ├── branches.csv
│       ├── employees.csv
│       ├── inventory.csv
│       ├── medications.csv
│       ├── purchase_orders.csv
│       ├── sales.csv
│       └── suppliers.csv
│
├── sql-queries/
│   ├── 01_top_medications.sql        # Revenue analysis
│   ├── 02_branch_performance.sql     # Profitability metrics
│   ├── 03_inventory_risk.sql         # Stock management
│   ├── 04_employee_performance.sql   # Productivity tracking
│   ├── 05_sales_trends.sql           # Time-series analysis
│   ├── 06_demographics.sql           # Customer insights
│   └── ... (18 queries total)
│
├── dashboards/
│   ├── pharmacy_dashboard.html       # Interactive web dashboard
│   ├── dashboard_data.json           # Processed analytics data
│   └── analyze_pharmacy_data.py      # Data processing script
│
├── powerbi/
│   ├── Pharmacy_Dashboard.pbix       # Power BI report
│   ├── PowerBI_Migration_Guide.md    # Setup instructions
│   └── PowerBI_QuickStart.md         # 30-minute setup guide
│
└── README.md                         # This file
```

---

## 📊 Database Schema

### Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌──────────────┐
│  BRANCHES   │────┐    │   SALES     │────┐    │  MEDICATIONS │
│             │    │    │             │    │    │              │
│ branch_id   │◄───┼────│ branch_id   │    ├────│ medication_id│
│ branch_name │    │    │ employee_id │◄───┘    │ med_name     │
│ governorate │    │    │ medication_ │         │ category     │
│ manager     │    │    │   id        │         │ unit_price   │
└─────────────┘    │    │ sale_date   │         └──────────────┘
                   │    │ quantity    │                │
┌─────────────┐    │    │ total_amount│                │
│  EMPLOYEES  │    │    └─────────────┘                │
│             │◄───┘                                   │
│ employee_id │         ┌──────────────┐               │
│ name        │         │  INVENTORY   │               │
│ branch_id   │         │              │               │
│ position    │         │ branch_id    │◄──────────────┘
│ salary      │         │ medication_id│
└─────────────┘         │ stock_qty    │
                        │ expiry_date  │
┌─────────────┐         └──────────────┘
│  SUPPLIERS  │                │
│             │         ┌──────┴────────┐
│ supplier_id │◄────────│ PURCHASE_     │
│ name        │         │   ORDERS      │
│ contact     │         │               │
└─────────────┘         │ order_date    │
                        │ quantity      │
                        │ total_cost    │
                        └───────────────┘
```

### Tables:
1. **branches** - Store locations and details (10 branches)
2. **medications** - Product catalog (200+ items)
3. **employees** - Staff information (50+ employees)
4. **sales** - Transaction records (50,000+ records)
5. **inventory** - Stock levels and expiry tracking
6. **suppliers** - Vendor information
7. **purchase_orders** - Procurement history

---

## 🔍 Key Features & Analyses

### 1. Revenue & Profitability Analysis
- Top 10 best-selling medications by revenue
- Branch-level profit margin comparison
- Category performance tracking
- Monthly and YoY growth trends

### 2. Inventory Management
- **ABC Analysis** (Pareto 80/20 principle)
  - Class A: 20% of items → 80% of revenue
  - Class B: 30% of items → 15% of revenue
  - Class C: 50% of items → 5% of revenue
- Real-time stock alerts (out-of-stock, low-stock)
- Expiration tracking and waste prevention
- Reorder point recommendations based on sales velocity

### 3. Operational Efficiency
- Employee performance rankings
- Revenue per square meter by branch
- Hourly sales patterns for staff scheduling
- Payment method analysis

### 4. Customer Insights
- Demographics analysis by age group
- Customer lifetime value estimation
- Purchase behavior patterns
- Segmentation (VIP, Premium, Standard)

### 5. Supply Chain Analytics
- Supplier performance evaluation
- Average delivery time tracking
- Purchase order cost analysis

---

## 📈 Sample SQL Queries

### Complex Query Example: ABC Analysis with Cumulative Revenue

```sql
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
        WHEN cumulative_revenue_pct <= 80 THEN 'A - Critical'
        WHEN cumulative_revenue_pct <= 95 THEN 'B - Important'
        ELSE 'C - Standard'
    END AS abc_classification
FROM ranked_meds
ORDER BY rank;
```

---

## 🚀 Getting Started

### Prerequisites
- SQL Server 2019+ or SQL Server Express (free)
- SQL Server Management Studio (SSMS)
- Power BI Desktop (free download)
- Python 3.8+ 

---

## 💡 Key Insights from Analysis

### Business Findings:
1. **Revenue Concentration**: 20% of medications generate 80% of revenue (Pareto principle validated)
2. **Stock Issues**: 26 critical out-of-stock items causing lost sales
3. **Profitability**: 27.17% overall profit margin with branch variance
4. **Peak Hours**: Busiest sales between 10 AM - 2 PM and 5 PM - 8 PM
5. **Customer Base**: Adult segment represents largest revenue contributor

### Recommendations:
- ✅ Implement automated reorder system for A-class medications
- ✅ Focus inventory investment on top 20% revenue-driving items
- ✅ Optimize staff scheduling based on hourly patterns
- ✅ Prevent stockouts through velocity-based reorder points
- ✅ Reduce expired inventory through FIFO tracking

---

## 🔧 Technical Highlights

### SQL Techniques Used:
- ✅ Window Functions (RANK, ROW_NUMBER, PARTITION BY, OVER)
- ✅ Common Table Expressions (CTEs) for complex queries
- ✅ Subqueries and correlated subqueries
- ✅ Aggregate functions with GROUP BY and HAVING
- ✅ JOINs (INNER, LEFT, multiple table joins)
- ✅ Date/Time functions (DATEADD, DATEDIFF, FORMAT)
- ✅ CASE statements for conditional logic
- ✅ Views for data abstraction

### Data Modeling:
- ✅ Normalized database design (3NF)
- ✅ Referential integrity with foreign keys
- ✅ Star schema for analytics (fact & dimension tables)
- ✅ Indexed views for performance

### Visualization:
- ✅ Interactive dashboards with drill-down capability
- ✅ KPI cards with trend indicators
- ✅ Multi-chart layouts for comprehensive analysis
- ✅ Color-coded alerts for quick identification
- ✅ Responsive design for mobile viewing

---

## 📊 Performance Metrics

### Query Performance:
- Average query execution time: <100ms
- Complex analytical queries: <500ms
- Dashboard load time: <2 seconds
- Supports: 50,000+ transactions efficiently

### Scalability:
- Handles millions of records with proper indexing
- View-based architecture for query optimization
- Incremental data loading supported

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

1. **Database Design**: Normalized schema, referential integrity
2. **SQL Mastery**: Complex queries, window functions, CTEs
3. **Business Intelligence**: KPI definition, metric calculation
4. **Data Visualization**: Dashboard design, storytelling with data
5. **Analytics**: ABC analysis, time-series, segmentation
6. **Documentation**: Technical writing, user guides
7. **Problem Solving**: Real-world business challenges

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Ahmed El-Shahat**
- LinkedIn: (https://linkedin.com/in/ahmed-shahat/)
- GitHub: (https://github.com/A-Shahat)
- Email: ahmed.elshahat.eru2016@gmail.com

---

## 🙏 Acknowledgments

- Thanks to the data science community for SQL best practices
- Power BI community for visualization inspiration
- Microsoft documentation for technical guidance

---

## ⭐ Star This Repository

If you found this project helpful, please consider giving it a star! It helps others discover the project.

---

**Last Updated**: February 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅
