# ch04-sql-assignment
Project assignment for CH04 SQL Essentials


--Q1: Write a SQL query to list all customers located in Nairobi. Show only full_name and location.

SELECT full_name, location: This specifies that you only want to see the full_name and location columns.

FROM customer_info: This tells the database to get the data from the customer_info table.

WHERE location = 'Nairobi': This is the filter. It returns only the rows where the value in the location column is exactly 'Nairobi'.


--Q2: Write a SQL query to display each customer along with the products they purchased. Include full_name, product_name, and price.

SELECT ci.full_name, p.product_name, p.price: This selects the three columns you want to see. We use aliases ci (for customer_info) and p (for products) to make the code shorter and easier to read.

FROM customer_info ci: This specifies that we're starting with the customer_info table.

JOIN products p ON ci.customer_id = p.customer_id: This is the key part. It links the customer_info table to the products table. The ON clause tells the database how to match the rows: it connects a customer to a product only when the customer_id is the same in both tables.


-- Q3: Write a SQL query to find the total sales amount for each customer. Display full_name and the total amount spent, sorted in descending order.

SELECT ci.full_name, SUM(s.total_sales) AS total_amount_spent: This selects the customer's name and calculates the sum of all their sales. SUM() is an aggregate function that adds up the values. AS total_amount_spent gives the new calculated column a readable name.

FROM customer_info ci JOIN sales s ON ci.customer_id = s.customer_id: This joins the customer_info table with the sales table, linking rows where the customer_id matches. This is how we connect a sale to a specific customer's name.

GROUP BY ci.full_name: This is the crucial step. It groups all the sales rows by the customer's name, so the SUM() function calculates the total for each customer individually.

ORDER BY total_amount_spent DESC: This sorts the final result, showing the customers who spent the most at the top.


-- Q4: Write a SQL query to find all customers who have purchased products priced above 10,000.


SELECT DISTINCT ci.full_name: This selects the name of each customer. DISTINCT is used to ensure that if a customer bought multiple expensive items, their name only appears once in the result.

FROM customer_info ci JOIN products p ON ci.customer_id = p.customer_id: This joins the customer and product tables together based on their shared customer_id.

WHERE p.price > 10000: This filters the joined table, keeping only the rows where a product's price is greater than 10,000.


-- Q5: Write a SQL query to find the top 3 customers with the highest total sales.


JOIN: It first links the customer_info and sales tables to connect customers with their sales records.

GROUP BY: It groups all sales by full_name so that SUM() can calculate the total for each individual customer.

SUM(...): This calculates the total sales for each customer group.

ORDER BY ... DESC: It sorts the results from the highest total sales to the lowest.

LIMIT 3: This is the final step, which restricts the output to only the top 3 rows from the sorted result.


-- Section 2 – Advanced SQL Techniques


-- Q6: Write a CTE that calculates the average sales per customer and then returns customers whose total sales are above that average.

WITH customer_sales AS (...): This defines a Common Table Expression (CTE), which is a temporary, named result set. We've named it customer_sales.

Inside the CTE: The first SELECT statement runs and calculates the total amount spent for each customer. This temporary table contains two columns: full_name and total_spent.

Final SELECT Statement: The main query then treats customer_sales like a real table.

WHERE total_spent > (SELECT AVG(total_spent) FROM customer_sales): This is the filter. It calculates the overall average of the total_spent column from our CTE and then returns only the rows where a customer's individual total_spent is greater than that average.


-- Q7: Write a Window Function query that ranks products by their total sales in descending order. Display product_name, total_sales, and rank.

WITH product_sales AS (...): We first create a Common Table Expression (CTE) named product_sales. Its job is to calculate the total sales for each unique product name. It does this by joining the products and sales tables and then using SUM() with a GROUP BY clause.

SELECT ... RANK() OVER (...): The final SELECT statement queries the results from our CTE.

RANK(): This is the window function that assigns a rank.

OVER (ORDER BY total_sales_amount DESC): This tells the RANK() function how to operate. It sorts the products by their total_sales_amount from highest to lowest and then assigns a rank to each one. If two products have the same total sales, they will receive the same rank, and the next rank will be skipped.


-- Q8: Create a View called high_value_customers that lists all customers with total sales greater than 15,000.

CREATE VIEW high_value_customers AS: This command tells the database to create a new view named high_value_customers. The view stores the SELECT query that follows.

SELECT ... JOIN ...: This joins the customer_info and sales tables to link customers to their sales.

GROUP BY ...: This groups all the sales records for each unique customer together so we can sum them up.

HAVING SUM(s.total_sales) > 15000: After calculating the total sales for each customer, the HAVING clause filters those groups, keeping only the ones where the total is greater than 15,000.


-- Q9: Create a Stored Procedure that accepts a location as input and returns all customers and their total spending from that location.
CREATE OR REPLACE FUNCTION...: This creates a new function or replaces an existing one with the same name.

get_customers_by_location(location_name VARCHAR): This defines the function's name and specifies that it accepts one input parameter, location_name, which is a text string (VARCHAR).

RETURNS TABLE(...): This specifies that the function will return a table with two columns: full_name and total_spent.

$$ LANGUAGE plpgsql;: This is the standard syntax for defining the body of a function in PostgreSQL's procedural language, plpgsql.

RETURN QUERY SELECT ...: This is the core logic. It executes the SELECT statement and returns its results in the format defined by RETURNS TABLE.

WHERE ci.location = location_name: This is the crucial filter. It ensures that only customers from the location provided as input are included in the calculation.

-- Q10: Write a recursive query to display all sales transactions in order by sales_id, along with a running total of sales.
Anchor Member: The first SELECT statement runs only once. It finds the sale with the lowest sales_id and establishes it as the starting point. The running_total for this first row is simply its own total_sales.

Recursive Member: The second SELECT statement runs repeatedly. It takes the result from the previous step (r) and joins it to the next row in the sales table (s), based on the condition that the next sales_id is one greater than the previous one. It then calculates the new running_total by adding the current sale's amount to the previous running total.

Final Select: This query pulls all the rows generated by the anchor and recursive steps and displays them.

-- Section 3 – Query Optimization & Execution Plans


-- Q11: The following query is running slowly: SELECT * FROM sales WHERE total_sales > 5000; Explain two changes you would make to improve its performance and then write the optimized SQL query.
-- Answer - The two most effective changes to improve the query's performance are to add an index to the total_sales column and avoid using SELECT * 


-- Q12: Create an index on a column that would improve queries filtering by customer location, then write a query to test the improvement.

Change 1: Add an Index
The main reason the query is slow is likely because the database has to perform a full table scan. This means it reads every single row in the sales table to check if total_sales is greater than 5000.

Change 2: Avoid SELECT
Using SELECT * is inefficient because it forces the database to retrieve data from every column in the table, even if you don't need them. This increases the amount of data that needs to be read from the disk and sent over the network.

You should always specify only the columns you actually need. This reduces the I/O load and makes the query faster.

-- Section 4 – Data Modeling 


-- Q13: Redesign the given schema into 3rd Normal Form (3NF) and provide the new CREATE TABLE statements.
-- The original schema is poorly designed, primarily because the products table mixes product catalog data with transactional data (customer_id). The most significant improvement is to separate these concerns.

A schema is in 3rd Normal Form (3NF) if it's in 2NF and has no transitive dependencies. This means every non-key attribute must depend directly on the primary key, and not on another non-key attribute. The redesign below fixes the structural issues to better align with 3NF and good database design.

The main changes are:

Normalize Locations: The location is a repeated string. We'll move it to its own locations table to reduce redundancy and prevent update anomalies (e.g., misspelling 'Nairobi' in one entry).

Fix the Products Table: A product catalog (products) should not contain a customer_id. This information belongs in a transaction table. We will remove this column.

Refine the Sales Table: The existing sales table acts as a link between a customer and a single product for a transaction, which is correct.


-- Q14: Create a Star Schema design for analyzing sales by product and customer location. Include the fact table and dimension tables with their fields.

A star schema is a data modeling approach used in data warehousing and business intelligence. It consists of a central fact table that contains quantitative data (the "facts" or measurements) and is linked to several smaller dimension tables that contain descriptive, categorical data. It's called a "star" schema because the diagram looks like a star, with the fact table at the center. 

Star Schema Design
Fact Table: 
This is the central table containing the core metrics of our analysis. Each row represents a specific sales event.
-- Create Dimension table. FactSales

Dimension Tables
These tables provide the descriptive context for the facts.

-- Create Dimension tables - Dimcustomer, Dimproduct and Dimlocation

-- Q15: Explain a scenario where denormalization would improve performance for reporting queries, and demonstrate the SQL table creation for that denormalized structure.

-- Answer: Imagine a business analyst needs to run a report every morning that shows the total sales for each product, broken down by customer location. The report needs to show the product_name, the customer's location, and the sum of total_sales.
-- With a normalized schema, this query would require joining three tables (sales, products, customer_info). If the sales table has millions of rows, these joins could be very slow and resource-intensive, making the report take several minutes or even hours to run.

-- To speed this up, we can create a single, denormalized table specifically for this report. This table, reporting_sales_summary, will pre-join all the necessary information. We'll add the product_name and location directly into the sales records, creating data redundancy.
