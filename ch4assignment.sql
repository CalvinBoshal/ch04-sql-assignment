select current_database ();

select current_schema ();

set search_path to my_schema; 


select * from customer_info;

select * from products;

select * from sales;

-- Section 1 – Core SQL Concepts 

--Q1: Write a SQL query to list all customers located in Nairobi. Show only full_name and location.
select ci.full_name, ci.location
from customer_info ci
where location = 'Nairobi';

--Q2: Write a SQL query to display each customer along with the products they purchased. Include full_name, product_name, and price.
select ci.full_name, p.product_name, p.price
from customer_info ci
join products p on p.customer_id = ci.customer_id;

-- Q3: Write a SQL query to find the total sales amount for each customer. Display full_name and the total amount spent, sorted in descending order.
select ci.full_name, sum(s.total_sales) as total_amount_spent
from customer_info ci
join sales s on ci.customer_id = s.customer_id 
group by ci.full_name
order by total_amount_spent desc;

-- Q4: Write a SQL query to find all customers who have purchased products priced above 10,000.
select ci.full_name
from customer_info ci
join products p on ci.customer_id = p.customer_id
where p.price > 10000;

-- Q5: Write a SQL query to find the top 3 customers with the highest total sales.
select ci.full_name, sum(s.total_sales) as total_sales
from customer_info ci
join sales s on ci.customer_id = s.customer_id
group by ci.full_name
order by total_sales desc
limit 3;


-- Section 2 – Advanced SQL Techniques


-- Q6: Write a CTE that calculates the average sales per customer and then returns customers whose total sales are above that average.
with total_sales_cte as (
--Calculating total sales per customer
select ci.full_name, sum(s.total_sales) as totalsalespercustomer
from customer_info ci
join sales s on ci.customer_id = s.customer_id
group by ci.full_name
)
-- This final query selects from the CTE
select full_name, totalsalespercustomer
from total_sales_cte 
where totalsalespercustomer > (select avg(totalsalespercustomer) from total_sales_cte);

-- Q7: Write a Window Function query that ranks products by their total sales in descending order. Display product_name, total_sales, and rank.
with product_sales as( 
-- Get total sales first
select p.product_name, sum(s.total_sales) as totalsales
from products p 
join sales s on p.product_id = s.product_id
group by p.product_name
)
-- The rank the result
select product_name, totalsales,
rank () over (order by totalsales desc) as salesrank
from product_sales 
;

-- Q8: Create a View called high_value_customers that lists all customers with total sales greater than 15,000.
create view high_value_customers as
-- Get total sales per customer
select ci.full_name, sum(s.total_sales) as totalsales
from customer_info ci
join sales s on ci.customer_id = s.customer_id
group by ci.full_name
having sum(s.total_sales) > 15000;

-- Q9: Create a Stored Procedure that accepts a location as input and returns all customers and their total spending from that location.
create function get_customers_by_location(location_name varchar)
returns table(full_name varchar, total_spent float) as $$
begin
    return query
    select ci.full_name, sum(s.total_sales) as total_amount_spent
    from customer_info ci
    join sales s on ci.customer_id = s.customer_id
    where ci.location = location_name
    group by ci.full_name;
end;
$$ language plpgsql;


-- Q10: Write a recursive query to display all sales transactions in order by sales_id, along with a running total of sales.
with recursive running_total_cte as (
-- Anchor Member: Get first sale
select sales_id, total_sales, total_sales as running_total
from sales 
where sales_id = (select min(sales_id)
from sales )

union all

--Recursive Member: Join next sale and add running total
select s.sales_id, s.total_sales, r.running_total + s.total_sales
from sales s
join running_total_cte r on s.sales_id = r.sales_id + 1)

-- Final Select: Retrieve all calculated rows
select sales_id, total_sales, running_total
from running_total_cte
order by sales_id;


-- Section 3 – Query Optimization & Execution Plans


-- Q11: The following query is running slowly: SELECT * FROM sales WHERE total_sales > 5000; Explain two changes you would make to improve its performance and then write the optimized SQL query.
-- Answer - The two most effective changes to improve the query's performance are to add an index to the total_sales column and avoid using SELECT * 

-- Create index
create index idx_sales_total_sales on sales(total_sales);

-- Avoid select all
select sales_id, total_sales
from sales s
where total_sales > 5000;

-- Q12: Create an index on a column that would improve queries filtering by customer location, then write a query to test the improvement.
create index idx_customer_info_location on customer_info(location);

select ci.location
from customer_info ci;


-- Section 4 – Data Modeling 


-- Q13: Redesign the given schema into 3rd Normal Form (3NF) and provide the new CREATE TABLE statements.
-- Remove location from customer_info table and create it's own table.
-- Locations table will store each unique location to avoid repetition.
create table locations (
location_id int primary key, 
location_name varchar (90) unique not null
);

-- Customer_info should now reference the locations table using a foreign key (location_id)

drop table customer_info cascade;
drop table products cascade;
drop table sales cascade;


create table customer_info (
customer_id int primary key,
full_name varchar (120),
location_id int, 
foreign key (location_id) references locations(location_id)
);

-- The products catalog should not have customer_id which belongs to a trasaction table.
-- We will remove the customer_id from products table
create table products (
product_id int primary key, 
product_name varchar (120),
price float
);

-- The sales table remains as is and is the connector between a customers and a product for a specific transaction tables.
create table sales (
sales_id int primary key,
total_sales float,
product_id int,
customer_id int,
foreign key (product_id) references products(product_id),
foreign key (customer_id) references customer_info(customer_id)
);

-- Q14: Create a Star Schema design for analyzing sales by product and customer location. Include the fact table and dimension tables with their fields.
-- Create fact table with links to 3 dimension tables
create table FactSales (
sales_key int primary key,
customer_key int,
product_key int,
location_key int
total_sales float,
quantity int,
foreign key (customer_key) references Dimcustomer(customer_key),
foreign key (product_key) references DimProduct(product_key),
foreign key (location_key) references DimLocation(location_key)
);

-- Create Dimension tables - Dimcustomer, Dimproduct and Dimlocation
create table DimCustomer (
    customer_key int primary key,
    customer_id int,
    full_name varchar(120)
);

create table DimProduct (
    product_key int primary key,
    product_id int,
    product_name varchar (120),
    price float
);

create table DimLocation (
    location_key int primary key,
    location_name varchar(90)
);


-- Q15: Explain a scenario where denormalization would improve performance for reporting queries, and demonstrate the SQL table creation for that denormalized structure.

-- Answer: Imagine a business analyst needs to run a report every morning that shows the total sales for each product, broken down by customer location. The report needs to show the product_name, the customer's location, and the sum of total_sales.
-- With a normalized schema, this query would require joining three tables (sales, products, customer_info). If the sales table has millions of rows, these joins could be very slow and resource-intensive, making the report take several minutes or even hours to run.

-- To speed this up, we can create a single, denormalized table specifically for this report. This table, reporting_sales_summary, will pre-join all the necessary information. We'll add the product_name and location directly into the sales records, creating data redundancy.

--Denormalized Table
create table reporting_sales_summary (
    summary_id int primary key,
    sales_id int,
    total_sales float,
    product_name varchar(120),
    customer_location varchar(90)
);





















































