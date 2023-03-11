CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- WEEK ONE CHALLENGE

-- Question one: What is the total amount each customer spent at the restaurant?
--Method one
SELECT 	s.customer_id, 
		SUM(m.price) total_amount
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_amount DESC

/* Here I selected the customer_Id column from the salses table and the Sum of the price column from the menu table and then 
joined the two tables on a commom field, product_id. then grouped by the customer_id*/ 
--Method two
SELECT s.customer_id, 
	   SUM(CASE when s.product_id = m.product_id THEN m.price END) total_amount
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_amount DESC

/* Here, I used a case statement and an aggregate function, sum, to create a new field, total_amount.
This case statement converts the each product_id to its respective product price
and then the aggregate function takes the sum, then the group by clause grouped the sum by the customer_id.*/

-- Question two: How many days has each customer visited the restaurant?

SELECT customer_id, 
	   COUNT (DISTINCT (order_date)) as num_of_visits
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY num_of_visits DESC



-- Question three: What was the first item from the menu purchased by each customer?
-- The easiest approach to solving this question for me was using the windows function Rank(), 
--partition the window by customer_id and order it by the order_date
 
WITH cte1 AS 
(
	SELECT s.customer_id, 
		   m.product_name, 
		   s.order_date,
		   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales s
	JOIN dannys_diner.menu m
		ON s.product_id = m.product_id
)
SELECT *
FROM cte1
WHERE rank = 1

-- Question four: What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, 
	   COUNT(s.product_id) AS num_of_purchase
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY num_of_purchase DESC
LIMIT 1;


-- Question five: Which item was the most popular for each customer?
/* method one*/

WITH cte2 AS
(
	SELECT	s.customer_id,
		   	m.product_name,
			COUNT (s.product_id),
		  	RANK() OVER ( PARTITION BY s.customer_id ORDER BY COUNT(s.product_id)DESC) as rank
	FROM dannys_diner.sales s
	JOIN dannys_diner.menu m
		ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT *
FROM cte2
WHERE rank = 1

-- Question six: Which item was purchased first by the customer after they became a member?
	
WITH cte AS
(
	SELECT mb.customer_id, 
		   m.product_name, 
		   s.order_date, 
		   mb.join_date,
		   RANK() OVER (PARTITION BY mb.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales AS s
	JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	JOIN dannys_diner.members mb
		ON s.customer_id = mb.customer_id
	WHERE s.order_date >= mb.join_date
)
SELECT *
FROM cte
WHERE rank = 1

-- Question seven: Which item was purchased just before the customer became a member?

WITH cte as
(
	SELECT 	mb.customer_id, 
			m.product_name, 
			s.order_date, 
			mb.join_date,
		   	RANK() OVER (PARTITION BY mb.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales AS s
	JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	JOIN dannys_diner.members mb
		ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
)
SELECT *
FROM cte
WHERE rank = 1

-- Question eight: What is the total items and amount spent for each member before they became a member?

SELECT mb.customer_id as member, 
	   COUNT (s.product_id) as total_item,
	   SUM (m.price) as total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
JOIN dannys_diner.members mb
	ON s.customer_id =mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY member


--Question nine: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id as customer,
		SUM(CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price ELSE 10 * m.price END) AS total_point
FROM dannys_diner.sales s 
JOIN dannys_diner.menu M
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_point DESC
	
-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

WITH cte4 AS
(
	SELECT s.customer_id as customer, 
	       m.product_name,
	       m.price,
	       mb.join_date,
	       s.order_date
	FROM dannys_diner.sales S
	JOIN dannys_diner.menu m
		ON s.product_id = m.product_id
	JOIN dannys_diner.members mb
		ON s.customer_id = mb.customer_id
)		
SELECT customer,
	   SUM(CASE 
			WHEN order_date >= join_date AND order_date <= join_date + interval '1 week' THEN 2 * 10 * price
			WHEN (order_date < join_date AND order_date > join_date + interval '1 week') AND product_name = 'sushi' THEN 2 * 10 * price
 		    ELSE 10 * price 
		END) as total_point
FROM cte4
WHERE order_date <= '2021-01-31'
GROUP BY customer
ORDER BY total_point DESC

