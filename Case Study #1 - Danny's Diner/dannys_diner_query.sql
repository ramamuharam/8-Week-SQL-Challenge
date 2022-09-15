/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	customer_id,
	SUM(price) AS total_spent
FROM
	sales
	JOIN menu ON sales.product_id = menu.product_id
GROUP BY
	customer_id
ORDER BY
	customer_id;
    
    
-- 2. How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS visited_days
FROM
    sales
GROUP BY
    customer_id;
    
    
-- 3. What was the first item from the menu purchased by each customer?
WITH order_info AS (
	SELECT
		customer_id,
		order_date,
		product_name,
		RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_order
	FROM
		sales
		JOIN menu ON sales.product_id = menu.product_id
)
SELECT
	customer_id,
	product_name
FROM
	order_info
WHERE
	item_order = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    product_name,
    COUNT(*) AS order_count
FROM
    sales
    JOIN menu ON sales.product_id = menu.product_id
GROUP BY
    product_name
ORDER BY
    order_count DESC
LIMIT 1;
    
  
-- 5. Which item was the most popular for each customer?
WITH customer_order_count AS (
    SELECT
        customer_id,
        product_name,
        COUNT(*) AS order_count,
        RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rank_by_order_count
    FROM
        sales
        JOIN menu ON sales.product_id = menu.product_id
    GROUP BY
        customer_id,
        product_name
)
SELECT
    customer_id,
    product_name,
    order_count
FROM
    customer_order_count
WHERE
    rank_by_order_count = 1;
    
    
-- 6. Which item was purchased first by the customer after they became a member?
WITH order_after_member AS (
    SELECT
        members.customer_id,
        product_name,
        order_date,
        RANK() OVER (PARTITION BY members.customer_id ORDER BY order_date) AS purchase_order
    FROM
        sales
        JOIN members ON sales.customer_id = members.customer_id
        JOIN menu ON sales.product_id = menu.product_id
    WHERE
        order_date >= join_date
)
SELECT
    customer_id,
    product_name,
    order_date
FROM
    order_after_member
WHERE
    purchase_order = 1;
    
  
-- 7. Which item was purchased just before the customer became a member?
WITH last_order_before_member AS (
    SELECT
        members.customer_id,
        product_name,
        order_date,
        RANK() OVER (PARTITION BY members.customer_id ORDER BY order_date DESC) AS purchase_order
    FROM
        sales
        JOIN members ON sales.customer_id = members.customer_id
        JOIN menu ON sales.product_id = menu.product_id
    WHERE
        order_date < join_date
)
SELECT
    customer_id,
    product_name,
    order_date
FROM
    last_order_before_member
WHERE
    purchase_order = 1;

    
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    members.customer_id,
    COUNT(*) AS total_items,
    SUM(price) AS amount_spent
FROM
    sales
    JOIN members ON sales.customer_id = members.customer_id
    JOIN menu ON sales.product_id = menu.product_id
WHERE
    order_date < join_date
GROUP BY
    members.customer_id
ORDER BY
    members.customer_id;
    
  
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?	
SELECT
	sales.customer_id,
	SUM(
		CASE WHEN product_name = 'sushi' THEN
			price * 20
		ELSE
			price * 10
		END) AS customer_points
FROM
	menu
	JOIN sales ON menu.product_id = sales.product_id
	JOIN members ON sales.customer_id = members.customer_id
WHERE
	order_date >= join_date
GROUP BY
	sales.customer_id
ORDER BY
	sales.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
	sales.customer_id,
	SUM(
		CASE WHEN order_date BETWEEN join_date AND join_date + 6 THEN
			price * 20
		ELSE
			CASE WHEN product_name = 'sushi' THEN
				price * 20
			ELSE
				price * 10
			END
		END) AS customer_points
FROM
	menu
	JOIN sales ON menu.product_id = sales.product_id
	JOIN members ON sales.customer_id = members.customer_id
WHERE
	order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY
	sales.customer_id
ORDER BY
	sales.customer_id;

select 
    adasld