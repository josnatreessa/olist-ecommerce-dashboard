----# customers---
USE olist;
CREATE TABLE customers ( customer_id varchar (50),
customer_unique_id varchar (50), customer_zip_code_prefix
varchar(5), customer_city varchar(100), customer_state
varchar(2));
TRUNCATE TABLE customers;
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/customers_clean.csv'
INTO TABLE customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT * FROM customers;
----#orders (dates loaded as text first, coverted later)----
CREATE TABLE orders_raw (
order_id VARCHAR(50),
customer_id VARCHAR(50),
order_status VARCHAR(20),
order_purchase_timestamp VARCHAR(30),
order_approved_at VARCHAR(30),
order_delivered_carrier_date VARCHAR(30),
order_delivered_customer_date VARCHAR(30),
order_estimated_delivery_date VARCHAR(30));
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/orders_clean.csv'
INTO TABLE orders_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM orders_raw;
select * from orders_raw;
CREATE TABLE orders (
  order_id VARCHAR(50),
  customer_id VARCHAR(50),
  order_status VARCHAR(20),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME);
INSERT INTO orders
SELECT order_id, customer_id, TRIM(order_status),
  STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''), '%d-%m-%Y %H:%i'),
  STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%d-%m-%Y %H:%i'),
  STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%d-%m-%Y %H:%i'),
  STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%d-%m-%Y %H:%i'),
  STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''), '%d-%m-%Y %H:%i')
FROM orders_raw;
SELECT
COUNT(*) - COUNT(order_purchase_timestamp) AS purchase_null,
COUNT(*) - COUNT(order_approved_at) AS approved_null,
COUNT(*) - COUNT(order_delivered_carrier_date) AS carrier_null,
COUNT(*) - COUNT(order_delivered_customer_date) AS delivered_null,
COUNT(*) - COUNT(order_estimated_delivery_date) AS estimated_null
FROM orders;
----#order_iems_raw----
CREATE TABLE order_items_raw (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date VARCHAR(30),
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2));
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/order_items_clean.csv'
INTO TABLE order_items_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM order_items_raw;
SELECT * FROM order_items_raw;
CREATE TABLE order_items (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date DATETIME,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2));
  INSERT INTO order_items
SELECT order_id, order_item_id, product_id, seller_id,
  STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''), '%d-%m-%Y %H:%i'),
  price, freight_value
FROM order_items_raw;
SELECT COUNT(*) AS total, COUNT(shipping_limit_date) AS valid_dates FROM order_items;
----#order_payments----
CREATE TABLE order_payments (
  order_id VARCHAR(50),
  payment_sequential INT,
  payment_type VARCHAR(20),
  payment_installments INT,
  payment_value DECIMAL(10,2));
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/order_payments_clean.csv'
INTO TABLE order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM order_payments;
SELECT payment_type, COUNT(*) FROM order_payments GROUP BY payment_type;
----# order_reviews----
CREATE TABLE order_reviews_raw (
  review_id VARCHAR(50),
  order_id VARCHAR(50),
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date VARCHAR(30),
  review_answer_timestamp VARCHAR(30)
) CHARACTER SET utf8mb4;
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/order_reviews_clean.csv'
INTO TABLE order_reviews_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM order_reviews_raw;
SELECT COUNT(*) AS bad_rows from order_reviews_raw
WHERE review_score IS NULL OR review_score NOT BETWEEN
1 AND 5 OR LENGTH(review_id) <> 32;
CREATE TABLE order_reviews (
  review_id VARCHAR(50),
  order_id VARCHAR(50),
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME
) CHARACTER SET utf8mb4;
INSERT INTO order_reviews
SELECT review_id, order_id, review_score,
  NULLIF(TRIM(review_comment_title), ''),
  NULLIF(TRIM(review_comment_message), ''),
  STR_TO_DATE(NULLIF(TRIM(review_creation_date), ''), '%d-%m-%Y %H:%i'),
  STR_TO_DATE(NULLIF(TRIM(review_answer_timestamp), ''), '%d-%m-%Y %H:%i')
FROM order_reviews_raw;
SELECT COUNT(*) AS total,
COUNT(review_creation_date) AS creation_ok,
COUNT(review_answer_timestamp) AS answer_ok
FROM order_reviews;
SELECT * FROM order_reviews;
----# products----
CREATE TABLE products (
  product_id VARCHAR(50),
  product_category_name VARCHAR(100),
  product_name_length INT,
  product_description_length INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
) CHARACTER SET utf8mb4;
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/products_clean.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(product_id, @cat, @nl, @dl, @ph, @w, @l, @h, @wd)
SET product_category_name = NULLIF(TRIM(@cat), ''),
    product_name_length = NULLIF(TRIM(@nl), ''),
    product_description_length = NULLIF(TRIM(@dl), ''),
    product_photos_qty = NULLIF(TRIM(@ph), ''),
    product_weight_g = NULLIF(TRIM(@w), ''),
    product_length_cm = NULLIF(TRIM(@l), ''),
    product_height_cm = NULLIF(TRIM(@h), ''),
    product_width_cm = NULLIF(TRIM(@wd), '');
SELECT COUNT(*) AS total,
COUNT(product_category_name) AS with_category,
COUNT(product_weight_g) AS with_weight
FROM products;
----# sellers----
CREATE TABLE sellers (
  seller_id VARCHAR(50),
  seller_zip_code_prefix VARCHAR(5),
  seller_city VARCHAR(100),
  seller_state VARCHAR(2)
) CHARACTER SET utf8mb4;
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/sellers_clean.csv'
INTO TABLE sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM sellers;
----# product_category_translation----
CREATE TABLE product_category_translation (
  product_category_name VARCHAR(100),
  product_category_name_english VARCHAR(100)
) CHARACTER SET utf8mb4;
LOAD DATA LOCAL INFILE 'C:/Users/GEO/Desktop/JOSNA/olist-project data/product_category_name_translation_clean.csv'
INTO TABLE product_category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM product_category_translation;
SELECT COUNT(*) AS orders_no_customer FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS items_no_order FROM order_items i
LEFT JOIN orders o ON o.order_id = i.order_id WHERE o.order_id IS NULL;
SELECT COUNT(*) AS items_no_product FROM order_items i
LEFT JOIN products p ON p.product_id = i.product_id WHERE p.product_id IS NULL;
SELECT COUNT(*) AS items_no_seller FROM order_items i
LEFT JOIN sellers s ON s.seller_id = i.seller_id WHERE s.seller_id IS NULL;
SELECT COUNT(*) AS payments_no_order FROM order_payments p
LEFT JOIN orders o ON o.order_id = p.order_id WHERE o.order_id IS NULL;
SELECT COUNT(*) AS reviews_no_order FROM order_reviews r
LEFT JOIN orders o ON o.order_id = r.order_id WHERE o.order_id IS NULL;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);
ALTER TABLE orders ADD PRIMARY KEY (order_id);
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE sellers ADD PRIMARY KEY (seller_id);
ALTER TABLE geolocation ADD PRIMARY KEY (zip_code_prefix);
ALTER TABLE order_items ADD PRIMARY KEY (order_id, order_item_id);
CREATE INDEX idx_items_product ON order_items (product_id);
CREATE INDEX idx_items_seller ON order_items (seller_id);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_customers_unique ON customers (customer_unique_id);
CREATE INDEX idx_payments_order ON order_payments (order_id);
CREATE INDEX idx_reviews_order ON order_reviews (order_id);
SELECT * FROM orders;
SELECT COUNT(order_id) from orders;
----# Total orders = 99441 ----
SELECT * FROM customers;
SELECT COUNT(DISTINCT customer_unique_id) from customers;
----# Total customers = 96096 ----
SELECT * FROM order_payments;
SELECT round(sum(p.payment_value),2) as revenue
from order_payments p join orders o on o.order_id = p.order_id
where o.order_status not in ( 'canceled', 'unavailable'); 
----# Total revenue = 15739137.01----
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') as month,
COUNT(DISTINCT o.order_id) as orders, round(sum(p.payment_value), 2) as revenue
from orders o join order_payments p on p.order_id=o.order_id
where o.order_status not in ( 'canceled', 'unavailable')
group by month order by revenue desc;
----#Orders and revenue by month (excl. canceled and unavailable orders) 
----# Peak month: Nov 2017 with 7,423 orders and R$ 1,172,639.23 revenue (Black Friday) 
----# Revenue grew from R$ 137,006.76 (Jan 2017) to R$ 764,785.28 (Oct 2017) 
---- #From Jan 2018 revenue stays level at about R$ 0.98M to R$ 1.16M a month 
----# Highest in 2018: Apr (R$ 1,156,303.91); lowest: Feb (R$ 979,966.23) 
---- #Partial months: 2016 has very few orders and Sep 2018 has only 1 order, because the data ends there ----
SELECT * from product_category_translation;
SELECT COALESCE(t.product_category_name_english ,p.product_category_name,'Unknown') as product_category,
COUNT(DISTINCT o.order_id) as orders, round(sum(i.price), 2) as revenue
from order_items i join orders o on o.order_id=i.order_id
join products p on p.product_id=i.product_id left join 
product_category_translation t on t.product_category_name = p.product_category_name
where o.order_status not in ( 'canceled', 'unavailable')
GROUP BY product_category ORDER BY revenue DESC LIMIT 10;
---- # Top 10 product categories by revenue (item price, excl. shipping; excl. canceled and unavailable orders) 
---- # 1 Health Beauty: R$ 1,255,695.13 from 8,800 orders 
---- # 2 Watches Gifts: R$ 1,198,185.21 from only 5,604 orders (high price per order, about R$ 214) 
---- # Bed Bath Table has the most orders (9,399) but ranks #3 (R$ 1,035,964.06): high volume, lower price 
---- # Next in the top 5: Sports Leisure (R$ 979,740.92) and Computers Accessories (R$ 904,322.02) 
---- # An order with items from 2 categories is counted in both, so category order counts should not be added up ----
SELECT * FROM customers;
SELECT c.customer_state as state, COUNT(DISTINCT o.order_id) AS orders,
round(sum(p.payment_value),2) as revenue from orders o join 
customers c on c.customer_id=o.customer_id join order_payments p 
on p.order_id=o.order_id where o.order_status not in 
( 'canceled', 'unavailable') group by state order by revenue desc ;
---- # Orders and revenue by customer state (payments; excl. canceled and unavailable orders) 
---- # SP leads with R$ 5,878,935.99 (about 37% of total revenue) from 41,126 orders 
---- # Next: RJ (R$ 2,115,994.28) and MG (R$ 1,843,460.37); the top 3 states are about 62% of revenue 
---- # Smallest: RR (R$ 9,948.97 from 45 orders), AP and AC
---- # Average order value is higher in remote northern states (about R$ 220 to 245 in RR, AC and AP) than in SP (about R$ 143) ----
SELECT p.payment_type,
COUNT(DISTINCT p.order_id) AS orders,
ROUND(SUM(p.payment_value), 2) AS revenue,
ROUND(100 * SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER (), 1) AS pct_revenue
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY p.payment_type
ORDER BY revenue DESC;
---- # Payment method share of revenue (excl. canceled and unavailable orders)
---- # Credit Card 78.5%, Boleto 18.0%, Voucher 2.2%, Debit Card 1.3% 
---- # Credit card dominates; boleto (bank slip) is the only other major method
---- # Orders can use more than one method (e.g. voucher plus card), so order counts by type overlap
SELECT COUNT(*) AS delivered_orders,
ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)), 1) AS avg_estimated_days,
SUM(DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)) AS late_orders,
ROUND(100 * SUM(DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)) / COUNT(*), 1) AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  ---- # Delivery performance (delivered orders only, dates compared by day) 
---- # 96,470 delivered orders; average delivery time 12.5 days vs 24.4 days estimated (about 12 days of buffer) 
---- # 6,534 orders (6.8%) arrived after the estimated delivery date ----
SELECT review_score,
COUNT(*) AS reviews,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;
SELECT ROUND(AVG(review_score), 2) AS avg_score FROM order_reviews;
---- # Review score distribution (99,222 reviews)
---- # 5 stars 57.8%, 4 stars 19.3%, 3 stars 8.2%, 2 stars 3.2%, 1 star 11.5% 
---- # 77% of reviews are 4 or 5 stars; average score about 4.09 
---- # Polarized: 1-star reviews (11.5%) outnumber 2-star and 3-star, so unhappy customers go straight to the lowest score ----
SELECT CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
            THEN 'Late' ELSE 'On time' END AS delivery_status,
       COUNT(*) AS reviews,
       ROUND(AVG(r.review_score), 2) AS avg_score,
       ROUND(100 * SUM(r.review_score <= 2) / COUNT(*), 1) AS pct_low_scores
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
---- # Impact of late delivery on review score (delivered orders with a review) 
---- # On time: 89,943 reviews, average score 4.29, 9.3% low scores (1 or 2 stars) 
---- # Late: 6,408 reviews, average score 2.27, 62.4% low scores (1 or 2 stars) 
---- # Late delivery lowers the average score by about 2 points and makes low scores about 6.7 times more likely 
---- # Late orders are only about 6.6% of reviews but about a third of all 1 and 2 star reviews (approximate) 
---- # Recommendation: reduce late deliveries, since they drive customer dissatisfaction; link, not proof of cause ----
SELECT COUNT(*) AS customers,
SUM(order_count = 1) AS one_time,
SUM(order_count > 1) AS repeat_customers,
ROUND(100 * SUM(order_count > 1) / COUNT(*), 1) AS pct_repeat
FROM (SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
 GROUP BY c.customer_unique_id) t;
 ---- # Repeat vs one-time customers (unique customers, excl. canceled and unavailable orders)
---- # 94,990 customers: 92,102 bought once, 2,888 (3.0%) bought more than once 
---- # 97% of customers never came back, so retention is the biggest growth opportunity 
---- # Caveat: the data covers about 2 years, so some one-time buyers may have returned after it ends ----
SELECT i.seller_id, s.seller_city, s.seller_state,
COUNT(DISTINCT i.order_id) AS orders,
ROUND(SUM(i.price), 2) AS revenue
FROM order_items i
JOIN orders o ON o.order_id = i.order_id
JOIN sellers s ON s.seller_id = i.seller_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY i.seller_id, s.seller_city, s.seller_state
ORDER BY revenue DESC LIMIT 10;
---- # Top 10 sellers by revenue (item price; excl. canceled and unavailable orders) 
---- # #1 Guariba (SP): R$ 229,237.63 from 1,131 orders; #2 Lauro De Freitas (BA): R$ 222,776.05 from only 358 orders 
---- # Lauro De Freitas earns about R$ 620 per order, versus about R$ 111 for #3 Ibitinga (SP), which has the most orders (1,804) 
---- # 9 of the top 10 sellers are in SP; together the top 10 earn about R$ 1.78M ----










