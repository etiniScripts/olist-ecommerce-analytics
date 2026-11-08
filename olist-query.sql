
USE olist_database;

-- To confirm the tables
SHOW TABLES;

-- The total number of sellers
SELECT COUNT(seller_id) Sellers FROM sellers;
-- There are 3095 sellers

-- The total number of products
SELECT COUNT(product_id) FROM products;
-- There are 32,951 products

-- The total category of products
SELECT COUNT(product_category_translation) FROM product_category;
-- There are 71 category of products

-- The total number of customers
SELECT COUNT(DISTINCT customer_unique_id) FROM customers;
-- There are 96,096 customers

-- The total number of orders
SELECT COUNT(order_id) FROM orders;
-- There have been 99,441 orders

-- The total number of items bought
SELECT COUNT(order_item_id) FROM order_items;
-- There have been 112,650 items bought

-- The total number of payments received
SELECT COUNT(order_id) FROM order_payments;
-- There have been 103,886 received payments

-- The total number of reviews
SELECT COUNT(review_id) FROM reviews;
-- There are 99,223 reviews

-- The total geolocation of buyers
SELECT COUNT(geolocation_zip_code_prefix) FROM geolocation;
-- There are 1,000,163 geolocations of buyers


-- ----------------------------
-- ANSWERING BUSINESS QUESTIONS
-- ----------------------------

-- What are the earliest and latest order ?
SELECT 	
		min(order_purchase_timestamp) AS 'Earliest Order',
		max(order_purchase_timestamp) AS 'Latest Order'
FROM orders;
-- The earliest order was on '2016-09-04 21:15' and the latest order was on '2018-10-17 17:30:18'

-- How many orders are there for each order status ?
SELECT 	
		order_status AS 'Status',
		COUNT(order_status) AS 'Total Orders'
FROM orders
GROUP BY order_status;
-- The query results show 96,478 delivered, 609 unavailable, 1,107 shipped, 
-- 625 canceled, 314 invoiced, 301 processing, 2 approved, and 5 created orders.


-- Which status is the most common ?
SELECT 	
		order_status AS 'Status',
		COUNT(order_status) AS 'Total Orders'
FROM orders
GROUP BY order_status 
ORDER BY COUNT(order_status) DESC
LIMIT 1;
-- The delivered status with 96,478 orders


-- How many delivered orders have a blank delivery date ?
SELECT 	
		COUNT(order_id) AS 'Blank_Dates'
FROM orders
WHERE order_delivered_customer_date IS NULL
AND order_status ='delivered';
-- 8 delivered orders have  blank delivery dates


-- Is every order ID in the table of ordered items also in the table of orders? 
-- Is every order_id in order_items also in orders?

SELECT order_items.order_id AS 'Unrecorded IDs'
FROM order_items
LEFT JOIN orders
	ON orders.order_id = order_items.order_id
WHERE orders.order_id IS NULL ;
-- The answer is YES


-- How many orders and how much revenue does Olist make each month? 

SELECT
    DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS Month,
    COUNT(DISTINCT o.order_id) AS Orders,
    CONCAT('R$ ',ROUND(SUM(oi.price),2)) AS Revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month
ORDER BY Month;

-- Revenue peaked in November 2017 at R$987,765.37, 
-- followed by May 2018 at R$977,544.69 and 
-- April 2018 at R$9732,534.09.

-- The most orders were placed in November 2017 (7,289), 
-- followed by January 2018 (7,069) and March 2018 (7,003).


-- What is the average order value?
SELECT CONCAT('R$',ROUND(
    SUM(oi.price) / COUNT(DISTINCT o.order_id),
    2)
) AS average_order_value
FROM orders AS o
JOIN order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';
-- The average order value is R$137.04


-- Which day of the week and hour do customers buy most?
-- DAY OF THE WEEK
SELECT
    DATE_FORMAT(order_purchase_timestamp,'%a') AS Day, 
    COUNT(order_id) AS Orders 
FROM orders
GROUP BY Day
ORDER BY Orders DESC;
-- Customers by mostly on Mondays at 16,196, followed 
-- by Tuesday at 15963 and Wednesday at 15552

-- HOUR OF THE DAY
SELECT
    DATE_FORMAT(order_purchase_timestamp,'%H') AS Hour,
    COUNT(*) AS Orders
FROM orders
-- WHERE DATE_FORMAT(order_purchase_timestamp,'%a') = 'Mon'
GROUP BY Hour
ORDER BY Orders DESC;
-- Customers buy more at 4pm, followed by 11am and 2pm.


-- What are the top 10 categories by revenue? Are they the same as the top 10 by number of orders?

-- TOP 10 CATEGORIES BY REVENUE
SELECT 
	pc.product_category_translation AS 'Category',
	CONCAT('R$ ',ROUND(SUM(oi.price),2)) AS 'Revenue'
FROM order_items oi
JOIN products p
	ON oi.product_id = p.product_id
JOIN product_category AS pc
	ON pc.product_category_name= p.product_category_name
GROUP BY Category
ORDER BY ROUND(SUM(oi.price),2) DESC
LIMIT 10;
-- The top 10 categories by revenue are led by Health & Beauty (R$1.26 million),
-- Watches & Gifts (R$1.2 million), and Bed, Bath & Table (R$1.03 million),
-- followed by Sports & Leisure, Computers & Accessories, Furniture & Decor, 
-- Cool Stuff, Housewares, Auto, and Garden Tools rounding out the list at R$485,000.

-- TOP 10 CATEGORIES BY ORDERS
SELECT 
	pc.product_category_translation AS 'Category',
	COUNT(DISTINCT oi.order_id) AS 'Orders'
FROM order_items AS oi
JOIN products AS p
	ON oi.product_id = p.product_id
JOIN product_category AS pc
	ON pc.product_category_name= p.product_category_name
GROUP BY Category 
ORDER BY Orders DESC
LIMIT 10;
-- The top 10 categories by orders are slightly different from the revenue list, 
-- led by Bed, Bath & Table (9,417 orders), Health & Beauty (8,836), and Sports & Leisure (7,720).
-- Telephony and Toys make the top 10 for orders. Cool Stuff and Garden Tools,
-- and Watches & Gifts drops to seventh place in volume despite being second in total revenue.

-- CHECKING IF THEY ARE THE SAME
WITH	
	revenue_top10 AS (
		SELECT 
            pc.product_category_translation AS 'Category',
			ROUND(SUM(oi.price),2) AS 'Revenue'
		FROM order_items oi
			JOIN products p
				ON oi.product_id = p.product_id
			JOIN product_category AS pc
				ON pc.product_category_name= p.product_category_name
		GROUP BY Category
		ORDER BY Revenue DESC
		LIMIT 10),
    
	orders_top10 AS (
		SELECT 
				pc.product_category_translation AS 'Category',
				COUNT(DISTINCT oi.order_id) AS 'Orders'
		FROM order_items AS oi
		JOIN products AS p
				ON oi.product_id = p.product_id
		JOIN product_category AS pc
				ON pc.product_category_name= p.product_category_name
		GROUP BY Category
		ORDER BY Orders DESC
		LIMIT 10)

	SELECT r.Category,
			CASE
				WHEN o.Category IS NOT NULL THEN 'In both'
				ELSE 'Revenue top 10 only'
			END AS result
	FROM revenue_top10 AS r
	LEFT JOIN orders_top10 AS o ON o.Category = r.Category
    
	UNION ALL
    
	SELECT
		o.Category,
		'Orders top 10 only' AS result
	FROM orders_top10 AS o
	LEFT JOIN revenue_top10 AS r ON r.Category = o.Category
	WHERE r.Category IS NULL;
    
-- health & beauty, watches & gifts, bed & bath, sports & leisure, computers accessories,
-- furniture & decor,housewares , auto appear in the top 10 for both revenue and orders,
-- whereas garden tools and cool stuff are top 10 for REVENUE ONLY 
-- and telephony and toys are top 10 for ORDERS ONLY.
    
    
-- WHAT PERCENT OF TOTAL MONEY DOES EACH TOP CATEGORY BRING IN?
-- THE TOTAL REVENUE
-- Total revenue
SELECT CONCAT('R$',ROUND(SUM(oi.price), 2)) AS Total_Revenue
FROM order_items oi
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';
-- The total revenue is R$13,221,498.11


-- Percentage
SELECT 
	pc.product_category_translation AS 'Category',
	CONCAT('R$ ',SUM(oi.price)) AS 'Revenue',
    CONCAT_WS(' ',ROUND((SUM(oi.price) * 100) / (SELECT SUM(price) FROM order_items),2),'%')AS 'Percentage'
FROM order_items AS oi
JOIN products AS p
	ON oi.product_id = p.product_id
JOIN product_category AS pc
	ON pc.product_category_name= p.product_category_name
GROUP BY Category
ORDER BY Percentage DESC
LIMIT 10;
-- Of the categories provided, the largest contributors to the R$13.2 million total revenue are
--  Sports & Leisure (7.27%), Computers & Accessories (6.71%), and Furniture & Decor (5.37%). 
--  The remaining categories shown, such as Home Construction and Home Appliances, 
--  each account for less than 1% of total sales.


-- WHICH CATEGORIES HAVE THE HIGHEST PRICE OF ITEMS AND THE LOWEST PRICE OF ITEMS?
-- HIGHEST
SELECT  pc.product_category_translation 'Category', 
		CONCAT('R$ ',ROUND(AVG(oi.price),2)) AS Average
FROM order_items oi
JOIN products p
	ON oi.product_id = p.product_id
JOIN product_category AS pc
    ON pc.product_category_name= p.product_category_name
GROUP BY Category
HAVING COUNT(*) >= 100
ORDER BY ROUND(AVG(oi.price),2) DESC; 

-- Highest Priced Categories are Computers: R$ 1,098.34, Home Appliances: R$ 476.12
-- and Agro Industry & Commerce: R$ 342.12
-- Lowest Priced Categories are Food & Drink: R$ 54.60 (the absolute lowest) and Christmas Supplies: R$ 57.52


-- WHICH STATES AND CITIES GENERATE THE MOST ORDERS AND REVENUE?
-- WHICH STATES AND CITIES GENERATE THE MOST ORDERS?
-- STATE
SELECT 
		c.customer_state State,
        COUNT(o.order_id) Orders
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
GROUP BY State
ORDER BY Orders DESC;
-- SP generated the most orders

-- CITY
SELECT
    c.customer_state AS state,
    c.customer_city AS city,
    COUNT(DISTINCT o.order_id) AS orders
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state, c.customer_city
ORDER BY orders DESC;
-- Sao Paulo generated the most orders
    
-- WHICH STATES AND CITIES GENERATE THE MOST REVENUE?
-- State
SELECT 
        c.customer_state State,
        CONCAT('R$ ', ROUND(SUM(oi.price),2)) Revenue
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY State
ORDER BY ROUND(SUM(oi.price),2) DESC;
-- SP generated the most revenue
    
-- City
SELECT 
    c.customer_state AS state,
    c.customer_city AS city,
    CONCAT('R$ ', ROUND(SUM(oi.price),2)) Revenue
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY State,City
ORDER BY ROUND(SUM(oi.price),2) DESC;

-- São Paulo (SP) leads overall with 41,746 orders and R$5.06M in revenue,
-- anchored by São Paulo city which alone accounts for 15,540 orders 
-- and R$1.85M in revenue.

-- Rio de Janeiro (RJ) ranks second, generating 12,852 orders and R$1.75M in revenue statewide,
-- driven primarily by its capital with 6,882 orders and R$955.5K in revenue

-- Minas Gerais (MG) holds third place, contributing 11,635 orders and R$1.55M in revenue across the state,
-- with Belo Horizonte accounting for 2,773 orders and R$346.6K in revenue.


-- WHICH STATES ARE THE SELLERS COMPARED TO CUSTOMERS?
-- STATES OF SELLERS
SELECT 	seller_state State,
		COUNT(DISTINCT seller_id) Total_Sellers
FROM sellers 
GROUP BY State
ORDER BY Total_Sellers DESC;

-- STATES OF Customers
SELECT 	customer_state State,
		COUNT(DISTINCT customer_unique_id) Total_Customers
FROM customers 
GROUP BY State
ORDER BY Total_Customers DESC;

-- COMPARISON
SELECT 	s.State,
		s.Total_Sellers,
        COALESCE(c.T_Customers, 0) AS Total_Customers       
FROM (
	SELECT seller_state State,
	COUNT(DISTINCT seller_id) Total_Sellers
	FROM sellers 
	GROUP BY State
) AS s

LEFT JOIN (
	SELECT 	customer_state State,
			COUNT(DISTINCT customer_unique_id) T_Customers
	FROM customers 
	GROUP BY State
)AS c
		ON s.State = c.State
ORDER BY s.Total_Sellers DESC;
-- SP (São Paulo) completely dominates the platform, acting as the primary hub for both groups 
-- with 1,849 sellers and 40,302 customers.


-- HOW MUCH DO CUSTOMERS PAY FOR FRIEGHT BY STATE 
    
SELECT 	c.customer_state State,
        CONCAT('R$', ROUND(SUM(oi.freight_value),2)) Freight
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
JOIN order_items oi
	ON o.order_id = oi.order_id
GROUP BY State
ORDER BY  ROUND(SUM(oi.freight_value),2) DESC;

-- Customers in São Paulo (SP) incurred the highest total freight costs at R$718.7K, 
-- followed by Rio de Janeiro (R$305.6K) and Minas Gerais (R$270.9K), 
-- while remote northern states like Roraima (RR at R$2.2K) 
-- and Amapá (AP at R$2.8K) recorded the lowest total freight expenditures.

-- THE FREIGHT PERCENTAGE OF THE ITEM PRICE
SELECT 	c.customer_state State,
        CONCAT('R$ ', ROUND(SUM(oi.freight_value),2)) Freight,
        CONCAT_WS(' ', ROUND((SUM(oi.freight_value)) * 100 / (SUM(oi.price)),2),'%') Percentage
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY State
ORDER BY Percentage;

-- While São Paulo (SP) pays the lowest freight relative to item cost at 13.85% (R$702K total).
-- WHEREAS Roraima (RR) at 28.08% (R$1.9K total) and Maranhão (MA) at 26.32% (R$30.7K total)
-- face significantly higher logistics overheads.


-- WHAT IS THE AVERAGE DELIVERY TIME (PURCHASE TO DELIVERY), OVERALL AND BY STATE?

-- THE AVERAGE DELIVERY TIME (PURCHASE TO DELIVERY)
-- DIFFERENCE 
SELECT 
		c.customer_state State,
        DATEDIFF(o.order_delivered_customer_date,o.order_purchase_timestamp) AS Difference,
        o.order_purchase_timestamp Purchase_date,
        o.order_delivered_customer_date Delivery
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
WHERE order_status = 'delivered';

-- OVERALL AVERAGE DELIVERY TIME
SELECT 	ROUND(AVG(
			DATEDIFF(o.order_delivered_customer_date,o.order_purchase_timestamp)
			),2) Average
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
WHERE order_status = 'delivered';
-- THE OVERALL AVERAGE DELIVERY TIME IS 12.50 days

-- AVERAGE DELIVERY TIME BY STATE
SELECT 	c.customer_state States,
		ROUND(AVG(
			DATEDIFF(o.order_delivered_customer_date,o.order_purchase_timestamp)
			),2) Average
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
WHERE order_status = 'delivered'
GROUP BY States
ORDER BY Average ASC;

-- São Paulo (SP) boasts the fastest average delivery time at 8.70 days,
-- with Roraima (RR) and Amapá (AP) suffering the slowest average delivery times 
-- at 29.34 days and 27.18 days, respectively.


-- HOW DOES ACTUAL DELIVERY COMPARE TO ESTIMATED DELIVERY? WHAT PERCENTAGE OF ORDERS ARRIVE LATE?

-- ACTUAL DELIVERY COMPARE TO ESTIMATED DELIVERY
SELECT 
		order_purchase_timestamp Purchase_date,
        order_estimated_delivery_date Expected,
        order_delivered_customer_date Delivery,
        DATEDIFF(order_estimated_delivery_date,order_purchase_timestamp) AS Expected_Duration,
        DATEDIFF(order_delivered_customer_date,order_purchase_timestamp) AS Days_Taken,
        DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date) AS Days_Late,
		CASE
			WHEN DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date) > 0 THEN 1
            ELSE 0
		END AS Punctuality
FROM orders 
WHERE order_status = 'delivered';

-- AVERAGE DELIVERY Margin
SELECT 
		ROUND(AVG(
			DATEDIFF(o.order_estimated_delivery_date,o.order_delivered_customer_date)
			),2) Average
FROM orders o
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- The delivery data shows that fulfillment performance outperforms expectations, 
-- with actual delivery times beating estimated delivery dates by an average margin of 11.88 days.

-- PERCENTAGE OF ORDERS ARRIVE LATE
-- DELIVERY RATE
	SELECT 
			CASE
				WHEN DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date) > 0 THEN 'Late'
				ELSE 'Early'
			END AS Punctuality,
			COUNT(order_id) AS Delivery_Rate
	FROM orders 
	WHERE order_status = 'delivered'
	GROUP BY Punctuality;

-- PERCENTAGE 
SELECT ROUND((SUM(	CASE
				WHEN DATEDIFF(order_delivered_customer_date,order_estimated_delivery_date) > 0 THEN 1
				ELSE 0
			END) * 100) 
		/ COUNT(*),2) Late_Percentage
FROM orders o
WHERE order_status = 'delivered'
	AND o.order_delivered_customer_date IS NOT NULL
	AND o.order_estimated_delivery_date IS NOT NULL;

-- Only 6.77% of total shipments (6,534 orders) arrived past their estimated delivery date, 
-- with 93.23% (89,944 orders) successfully reaching customers on time.

-- WHICH STATES HAVE THE WORST LATE RATE?

-- LATE
SELECT 
        c.customer_state States,
        ROUND(100 *
        SUM( CASE
				WHEN DATEDIFF( o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0
                THEN 1 ELSE 0 END) / COUNT(*),1) AS LRate
FROM orders AS o
JOIN customers AS c
	ON o.customer_id = c.customer_id
WHERE order_status = 'delivered' 
GROUP BY States
ORDER BY LRate DESC;

-- AL and MA record the worst late rate with 21.4 and 17.4 respectively% 


-- WHAT IS THE DISTRUBUTION OF REVIEW SCORES (HOW MANY 1S, 2S, ... 5S)?
SELECT 	review_score Score,
		COUNT(*) Distrubution
FROM reviews
GROUP BY review_score
ORDER BY review_score ASC;

-- 5-star reviews domineate at 57,327 and 4-star reviews accounting for 19,142,
-- while 1-star reviews at 11,414, followed by 3-star at 8,179 and 2-star 3,151 ratings.


-- DO LATE DELIVERIES GET LOWER REVIEW SCORES THAN ON-TIME ONES? 
SELECT 
		ROUND(AVG(r.review_score),2) Score,
		CASE
			WHEN DATEDIFF(o.order_delivered_customer_date,o.order_estimated_delivery_date) > 0 THEN 'Late'
            ELSE 'On Time'
		END AS Punctuality
FROM orders o
JOIN reviews r
	ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY Punctuality;
-- YES, with On time deliveries getting an Average of 4.29
-- AND LATE deliveries getting an Average of 2.27

-- WHICH PRODUCT CATEGORIES HAVE THE LOWEST AVERAGE REVIEW SCORES?
SELECT 	pc.product_category_translation Category,
		ROUND(AVG(r.review_score),2) Score
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN reviews r
	ON oi.order_id = r.order_id
JOIN product_category AS pc
    ON pc.product_category_name= p.product_category_name
GROUP BY Category
HAVING COUNT(*) >= 100
ORDER BY Score ASC;
-- The categories with the lowest scores are office_furniture,fashion_male_clothing,
-- fixed_telephony and home_comfort.


-- WHAT PAYMENT METHODS ARE USED, AND HOW MANY INSTALLMENTS DO CUSTOMERS TYPICALLY CHOOSE?

-- WHAT PAYMENT METHODS AREUSED?
SELECT	payment_type,
		COUNT(*) AS Payments
FROM order_payments
GROUP BY payment_type;
-- People pay using credit cards, boletto, vouchers and debit cards. Mostly Credit Cards

-- HOW MANY INSTALLMENTS DO CUSTOMERS TYPICALLY CHOOSE?
SELECT 	payment_installments Installments,
		COUNT(*) AS Payments
FROM order_payments
GROUP BY payment_installments
ORDER BY Payments DESC;
-- Customers usually choose to pay on 1 installment.

    
        
		


