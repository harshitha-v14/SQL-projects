----Case study #1 - Dannys Diner-----
CREATE SCHEMA dannys_diner;
Use dannys_diner
CREATE TABLE sales (
   customer_id VARCHAR(1),
   order_date DATE,
   product_id INTEGER
 )

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
select * from members
select * from sales
select * from menu  
-- 1. What is the total amount each customer spent at the restaurant?
select S.customer_id, Sum(M.price)
From Menu m
join Sales s On m.product_id = s.product_id
group by S.customer_id
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) As days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
With ranking as
(
Select S.customer_id, 
       M.product_name, 
       S.order_date,
       DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date) as ranking
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id, M.product_name,S.order_date
)
Select Customer_id, product_name
From ranking
Where ranking = 1
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT M.product_name, COUNT(S.product_id) as purchased
FROM Menu M
JOIN Sales S ON M.product_id = S.product_id
GROUP BY M.product_name
ORDER BY COUNT(S.product_id) DESC
LIMIT 1;
-- 5. Which item was the most popular for each customer?
With ranked as
(
Select S.customer_ID ,
       M.product_name, 
       Count(S.product_id) as Count,
       Dense_rank()  Over (Partition by S.Customer_ID order by Count(S.product_id) DESC ) as Ranked
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id,S.product_id,M.product_name
)
Select Customer_id,Product_name,Count
From ranked
where ranked = 1

-- 6. Which item was purchased first by the customer after they became a member?
With Ranked as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Ranked
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)
Select *
From Ranked
Where Ranked = 1

-- 7. Which item was purchased just before the customer became a member?
With Ranked as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Ranked
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date  
)
Select customer_ID, Product_name
From Ranked
Where Ranked = 1

-- 8. What is the total items and amount spent for each member before they became a member?
Select S.customer_id,count(S.product_id ) as quantity ,Sum(M.price) as total_sales
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date
Group by S.customer_id
----If each $1 spent equates to 10 points and sushi has a 2x points multiplier -
 how many points would each customer have?
 With Points as
(
Select *, Case When product_id = 1 THEN price*20
               Else price*10
			   End as Points
From Menu
)
Select S.customer_id, Sum(P.points) as Points
From Sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id;
---- In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi — 
how many points do customer A and B have at the end of January?
WITH dates AS (
    SELECT *, 
           DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, 
           LAST_DAY('2021-01-31') AS last_date
    FROM members 
)
SELECT S.customer_id, 
       SUM(
           CASE 
               WHEN M.product_ID = 1 THEN M.price * 20
               WHEN S.order_date BETWEEN D.join_date AND D.valid_date THEN M.price * 20
               ELSE M.price * 10
           END
       ) AS Points
FROM dates D
JOIN sales S ON D.customer_id = S.customer_id
JOIN menu M ON M.product_id = S.product_id
WHERE S.order_date < D.last_date
GROUP BY S.customer_id;


 