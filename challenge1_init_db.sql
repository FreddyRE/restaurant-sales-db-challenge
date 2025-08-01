create database challenge1;
use challenge1;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  show tables;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_amount
FROM sales s
JOIN menu m ON m.product_id = s.product_id
GROUP BY s.customer_id
;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id , COUNT(DISTINCT order_date) as days_visited 
FROM sales
GROUP BY customer_id
;


-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
  SELECT
    s.customer_id,
    s.order_date,
    s.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY
        s.order_date   ASC,   
        s.product_id   ASC 
    ) AS rn
  FROM sales AS s
)
SELECT
  fp.customer_id,
  fp.order_date,        
  fp.product_id,       
  m.product_name,
  m.price        
FROM first_purchase AS fp
JOIN menu AS m
  ON m.product_id = fp.product_id
WHERE fp.rn = 1
ORDER BY fp.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  m.product_id,
  m.product_name,
  COUNT(*) AS total_purchases
FROM sales AS s
JOIN menu AS m
  ON m.product_id = s.product_id
GROUP BY
  m.product_id,
  m.product_name
ORDER BY
  total_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH customer_item_counts AS (
  SELECT
    s.customer_id,
    s.product_id,
    COUNT(*) AS purchase_count
  FROM sales AS s
  GROUP BY
    s.customer_id,
    s.product_id
),
ranked_items AS (
  SELECT
    cic.customer_id,
    cic.product_id,
    cic.purchase_count,
    ROW_NUMBER() OVER (
      PARTITION BY cic.customer_id
      ORDER BY cic.purchase_count DESC,
               cic.product_id    ASC
    ) AS rn
  FROM customer_item_counts AS cic
)
SELECT
  ri.customer_id,
  ri.product_id,
  m.product_name,
  ri.purchase_count
FROM ranked_items AS ri
JOIN menu AS m
  ON m.product_id = ri.product_id
WHERE ri.rn = 1
ORDER BY ri.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

WITH post_membership_sales AS (
  SELECT
    s.customer_id,
    s.order_date,
    s.product_id,
    m.join_date
  FROM sales AS s
  JOIN members AS m
    ON s.customer_id = m.customer_id
  WHERE s.order_date >= m.join_date
),
ranked AS (
  SELECT
    pms.customer_id,
    pms.order_date,
    pms.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY pms.customer_id
      ORDER BY
        pms.order_date ASC,
        pms.product_id ASC
    ) AS rn
  FROM post_membership_sales AS pms
)
SELECT
  r.customer_id,
  r.order_date,
  r.product_id,
  m.product_name,
  m.price
FROM ranked AS r
JOIN menu AS m
  ON m.product_id = r.product_id
WHERE r.rn = 1
ORDER BY r.customer_id;

-- 7. Which item was purchased just before the customer became a member?

WITH pre_membership_sales AS (
  SELECT
    s.customer_id,
    s.order_date,
    s.product_id,
    m.join_date
  FROM sales    AS s
  JOIN members  AS m
    ON s.customer_id = m.customer_id
  WHERE s.order_date < m.join_date
),
ranked_pre AS (
  SELECT
    pms.customer_id,
    pms.order_date,
    pms.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY pms.customer_id
      ORDER BY
        pms.order_date DESC,
        pms.product_id ASC
    ) AS rn
  FROM pre_membership_sales AS pms
)
SELECT
  rp.customer_id,
  rp.order_date,
  rp.product_id,
  m.product_name,
  m.price
FROM ranked_pre AS rp
JOIN menu       AS m
  ON m.product_id = rp.product_id
WHERE rp.rn = 1
ORDER BY rp.customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
  m.customer_id,
  COUNT(*) AS total_items_before_join,
  SUM(mu.price) AS total_amount_before_join
FROM sales AS s
JOIN members AS m
  ON s.customer_id = m.customer_id
JOIN menu AS mu
  ON s.product_id  = mu.product_id
WHERE s.order_date < m.join_date
GROUP BY m.customer_id
ORDER BY m.customer_id;

