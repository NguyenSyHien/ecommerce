-- Percentage of orders that have been delivered
SELECT order_status,
(COUNT(order_id)*100 / (SELECT COUNT(order_id) FROM olist_orders_dataset)) AS Order_Pct
FROM olist_orders_dataset
WHERE order_status IN ('approved', 'delivered', 'created', 'invoiced', 'processing', 'unavailable', 'canceled', 'shipped')
GROUP BY order_status

-- Delivered before estimated time
SELECT (COUNT(order_id)*100 / (SELECT COUNT(order_id) FROM olist_orders_dataset)) AS Delivery_BeforeEstdate
FROM olist_orders_dataset
WHERE order_delivered_customer_date < order_estimated_delivery_date

-- Customer's payment types
SELECT payment_type, 
(COUNT(order_id)*100 / (SELECT COUNT(order_id) FROM olist_order_payments_dataset)) AS Payment_types_Pct
FROM olist_order_payments_dataset
WHERE payment_type IN ( 'credit_card', 'debit_card', 'boleto', 'voucher')
GROUP BY payment_type;

-- Top 3 Products with the most 1 and 5 review scores 
WITH Ranked_Categories AS (
    SELECT 
        t.column2 AS product_category_name_english,
        p.product_category_name,
        r.review_score,
        COUNT(r.review_score) AS score_count,
        ROW_NUMBER() OVER (PARTITION BY r.review_score ORDER BY COUNT(r.review_score) DESC) AS rank
		-- Use ROW_NUMBER to choose top 3 of each 1 and 5 score
    FROM 
        olist_order_reviews_dataset AS r
    LEFT JOIN 
        olist_order_items_dataset AS i ON r.order_id = i.order_id
    LEFT JOIN 
        olist_products_dataset AS p ON i.product_id = p.product_id
    LEFT JOIN 
        product_category_name_translation AS t ON p.product_category_name = t.column1
    WHERE 
        r.review_score IN (1, 5)
    GROUP BY 
        t.column2, p.product_category_name, r.review_score
)
SELECT 
    product_category_name_english, 
    product_category_name, 
    review_score, 
    score_count
FROM 
    Ranked_Categories
WHERE 
    rank <= 3
ORDER BY 
    review_score, score_count DESC;

-- Number of customers across cities
SELECT COUNT(customer_id) AS Nocustomer, customer_city
FROM olist_customers_dataset
GROUP BY customer_city
HAVING COUNT(customer_id) > 500
ORDER BY Nocustomer DESC;

---Number of sellers across cities
SELECT COUNT(seller_id) AS Noseller, seller_city
FROM olist_sellers_dataset
GROUP BY seller_city
ORDER BY Noseller DESC

-- Number of products sold
SELECT 
    t.column2 AS product_category_name_english, 
    p.product_category_name, 
    COUNT(p.product_photos_qty) AS No_product_sold
	--> We found that beds, baths, and tables are the best sellers, however, they also received the most 1 review scores of 1.6k
FROM 
    olist_products_dataset AS p
LEFT JOIN 
    product_category_name_translation AS t 
ON 
    p.product_category_name = t.column1
GROUP BY 
    t.column2, p.product_category_name
ORDER BY 
    No_product_sold DESC;

-- The average price of products 
DELETE TOP(1)
FROM product_category_name_translation;
-- The first row of table is not showing the correct title thus we need to delete it

WITH correct AS
(SELECT column1 AS product_category_name, column2 AS product_category_name_english
FROM product_category_name_translation)
-- Change to the correct title

SELECT AVG(e.price) AS average_price, e.product_category_name, j.product_category_name_english
FROM 
(SELECT i.price, p.product_category_name
FROM olist_order_items_dataset AS i
LEFT JOIN olist_products_dataset AS p
ON i.product_id = p.product_id
) AS e
LEFT JOIN correct AS j
ON j.product_category_name = e.product_category_name
GROUP BY e.product_category_name, j.product_category_name_english
ORDER BY AVG(e.price) DESC
