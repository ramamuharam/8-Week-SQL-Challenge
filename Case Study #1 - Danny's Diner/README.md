# 🍜 Case Study #1 - Danny's Diner
<p align="center">
<img src="dannys_diner.png" width=40% height=40%>

## Table Of Contents
* [Introduction](#introduction)
* [Problem Statement](#problem-statement)
* [Dataset](#dataset)
* [Case Study Questions](#case-study-questions)
* [Solutions](#solutions)
* [Limitations](#limitations)
  
---

## Introduction

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

---

## Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program.

---

## Dataset

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

### **sales**

<details>
<summary>
View table
</summary>

The sales table captures all ```customer_id``` level purchases with an corresponding ```order_date``` and ```product_id``` information for when and what menu items were ordered.

|customer_id|order_date|product_id|
|-----------|----------|----------|
|A          |2021-01-01|1         |
|A          |2021-01-01|2         |
|A          |2021-01-07|2         |
|A          |2021-01-10|3         |
|A          |2021-01-11|3         |
|A          |2021-01-11|3         |
|B          |2021-01-01|2         |
|B          |2021-01-02|2         |
|B          |2021-01-04|1         |
|B          |2021-01-11|1         |
|B          |2021-01-16|3         |
|B          |2021-02-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-07|3         |

 </details>

### **menu**

<details>
<summary>
View table
</summary>

The menu table maps the ```product_id``` to the actual ```product_name``` and price of each menu item.

|product_id |product_name|price     |
|-----------|------------|----------|
|1          |sushi       |10        |
|2          |curry       |15        |
|3          |ramen       |12        |

</details>

### **members**

<details>
<summary>
View table
</summary>

The final members table captures the ```join_date``` when a ```customer_id``` joined the beta version of the Danny’s Diner loyalty program.

|customer_id|join_date |
|-----------|----------|
|A          |1/7/2021  |
|B          |1/9/2021  |

 </details>

---

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

---

## Solutions

### **Q1. What is the total amount each customer spent at the restaurant?**
```sql
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
```

| customer_id | total_spent |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

---

### **Q2. How many days has each customer visited the restaurant?**
```sql
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS visited_days
FROM
    sales
GROUP BY
    customer_id;
```

|customer_id|visited_days|
|-----------|------------|
|A          |4           |
|B          |6           |
|C          |2           |

---

### **Q3. What was the first item from the menu purchased by each customer?**
```sql
WITH order_info AS (
	SELECT
		customer_id,
		order_date,
		product_name,
		rank() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_order
	FROM
		sales
		JOIN menu ON sales.product_id = menu.product_id
)
SELECT DISTINCT
	customer_id,
	product_name
FROM
	order_info
WHERE
	item_order = 1;
```

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        | 
| C           | ramen        | 

---

### **Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```sql
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
```

|product_name|order_count|
|------------|-----------|
|ramen       |8          |

---

### **Q5. Which item was the most popular for each customer?**
```sql
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
```

|customer_id|product_name|order_count|
|-----------|------------|-----------|
|A          |ramen       |3          |
|B          |sushi       |2          |
|B          |curry       |2          |
|B          |ramen       |2          |
|B          |ramen       |3          |

---

### **Q6. Which item was purchased first by the customer after they became a member?**
```sql
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
```

| customer_id | product_name | order_date |
| ----------- | ------------ | ---------- |
| A           | curry        | 2021-01-07 |
| B           | sushi        | 2021-01-11 |

---

### **Q7. Which item was purchased just before the customer became a member?**
```sql
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
```

| customer_id | product_name | order_date |
| ----------- | ------------ | ---------- |
| A           | sushi        | 2021-01-01 |
| A           | curry        | 2021-01-01 |
| B           | sushi        | 2021-01-04 |

---

### **Q8. What is the total items and amount spent for each member before they became a member?**
```sql
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
```

| customer_id | total_items | amount_spent |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |


---

### **Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
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
```

| customer_id | customer_points |
| ----------- | --------------- |
| A           | 510             |
| B           | 440             |

---

### **Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
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
```

| customer_id | SUM          |
| ----------- | ------------ |
| A           | 1370         |
| B           | 820          |

 