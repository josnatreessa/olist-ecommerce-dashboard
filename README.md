# Olist E-Commerce Analysis: SQL + Power BI

End-to-end analysis of the Olist Brazilian e-commerce dataset. Data was cleaned in Excel Power Query, analysed in MySQL, and visualised in a two-page Power BI dashboard.

**Author:** Josna Treessa PG | [LinkedIn](https://www.linkedin.com/in/josnatreessa) | [GitHub](https://github.com/josnatreessa)

---

## Dashboard Preview

**Page 1**


![Dashboard page 1](dashboard%20page%201.png)



**Page 2**


![Dashboard page 2](dashboard%20page%202.png)



---

## Business Problem

Olist connects small sellers to large marketplaces across Brazil. Leadership wants to understand:

1. How is revenue trending, and which product categories and sellers drive it?
2. Where are customers and sellers concentrated geographically?
3. How do customers pay (payment type, installments)?
4. How well does delivery perform, and do late deliveries hurt customer satisfaction?
5. How many customers come back for a repeat purchase?

---

## Dataset

Olist Brazilian E-Commerce public dataset (Kaggle), around 100k orders from 2016 to 2018.

| Table | Description |
|---|---|
| customers | Customer ID, unique ID, city, state |
| orders | Order status and purchase, delivery and estimated delivery dates |
| order_items | Products, sellers, price and freight value per order |
| order_payments | Payment type, installments and value |
| order_reviews | Review score and creation date |
| products | Product ID and category |
| product_category_translation | Portuguese to English category names |
| sellers | Seller ID, city, state |
| geolocation | Zip code coordinates (used in SQL only; dropped from Power BI to reduce file size) |

---

## Tools Used

- **Excel Power Query**: cleaning the 8 smaller files
- **MySQL Workbench**: geolocation cleaning, validation checks and analysis
- **Power BI**: data model, DAX measures and dashboard

---

## Data Preparation

- Cleaned the 8 smaller files in Excel Power Query (one worksheet per table).
- Cleaned the geolocation file in SQL, reducing it to one row per zip code prefix.
- Converted date columns from DD-MM-YYYY HH:MM text to proper date/time types.
- Loaded all 9 tables into the MySQL database `olist` and ran validation checks.

### Key definitions
- **Revenue** = customer payments, excluding canceled and unavailable orders.
- **Category and seller revenue** = item price (freight excluded).

---

## Key SQL Queries

The complete set of queries is in [`olist_all_analyzed_queries.sql`](olist_all_analyzed_queries.sql). Highlights:

### 1. Monthly revenue trend
```sql
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;
```

### 2. Top 10 product categories by revenue
```sql
SELECT
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN product_category_translation t ON pr.product_category_name = t.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
```

### 3. Late deliveries vs review score
```sql
SELECT
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late' ELSE 'On time' END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(*) AS orders
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery_status;
```

### 4. Repeat customers
```sql
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers
FROM (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) t;
```

---

## Results

> Replace the bracketed values with your actual numbers.

- **Revenue:** total revenue of [X] with a [growth/trend] from [month] to [month].
- **Top categories:** [category 1], [category 2] and [category 3] lead revenue.
- **Geography:** [state] has the most customers and sellers, at [X]% of orders.
- **Payments:** [payment type] is the most used method at [X]%.
- **Delivery:** [X]% of delivered orders arrived late.
- **Customer satisfaction:** late orders average [X] vs [Y] for on-time orders, so late delivery clearly lowers review scores.
- **Repeat customers:** only [X]% of customers purchased more than once.

---

## Recommendations

1. Improve delivery reliability in the states with the highest late-delivery rates.
2. Set more realistic delivery estimates to protect review scores.
3. Launch retention campaigns (discounts, loyalty offers), since repeat purchase is low.
4. Focus seller support on the top-revenue categories.

---

## Limitations

- The dataset covers 2016 to 2018, so patterns may not reflect today's market.
- Revenue counts customer payments, so vouchers and installments can differ from item price totals.
- Review score is the only satisfaction measure, and not every order has a review.
- Delivered dates are missing for undelivered orders, so delivery analysis covers delivered orders only.
- The geolocation table was removed from the Power BI model to meet GitHub's file size limit, so map visuals use state-level data.
- Analysis is descriptive. It shows relationships (for example late delivery and low scores) but does not prove causation.

---

## How I Used AI

I used Claude (Anthropic) as a learning and productivity partner throughout this project. I made the analysis decisions, ran every query myself, and checked the results against the data.

| Stage | How AI helped |
|---|---|
| **Data cleaning** | Guided me on cleaning the raw files in Excel Power Query and on reducing the geolocation file to one row per zip code in SQL. |
| **Table design** | Helped structure clean tables and relationships, and loading all 9 tables into MySQL with the right data types (for example, converting DD-MM-YYYY text dates to proper dates). |
| **SQL troubleshooting** | Helped me understand and fix query errors, such as join problems, wrong aggregations and date-handling issues, and explained why each fix worked. |
| **Validation** | Suggested checks such as row counts, duplicate keys and null values, to confirm the data was reliable before analysis. |
| **Power BI optimisation** | Helped identify unused tables and columns to remove (geolocation, ID and timestamp columns) so the .pbix file fit within GitHub's upload limit. |
| **Dashboard fixes** | Helped rebuild a visual after removing a column, replacing a review ID count with an order-based measure. |
| **Documentation** | Helped structure and draft this README. |

**What I did myself:** chose the dataset and business questions, defined revenue and the other metrics, wrote and ran the analysis in MySQL, designed the dashboard, and verified all results.

---

## Repository Contents

| File | Description |
|---|---|
| `olist_dashboard.pbix` | Power BI dashboard file |
| `olist_all_analyzed_queries.sql` | All SQL queries used in the analysis |
| `dashboard page 1.png` / `dashboard page 2.png` | Dashboard screenshots |
| `README.md` | Project documentation |
