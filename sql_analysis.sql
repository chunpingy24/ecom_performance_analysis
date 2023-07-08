/* Sales */
-- APAC tend to lead the growth on the total sales and average order value averaging 1.47% and 1.06% growth rate respectively across years 2020 to 2022. 
WITH sales_2019 AS (
  SELECT 
    date_trunc(orders.purchase_ts,year) AS years,
    geo.region,
    COUNT(orders.id) AS order_count,
    ROUND(SUM(usd_price),2) AS total_sales,
    ROUND(AVG(usd_price),2) AS average_order_value
  FROM elist.customers customers
  LEFT JOIN elist.geo_lookup geo 
    ON customers.country_code = geo.country
  LEFT JOIN elist.orders orders 
    ON customers.id = orders.customer_id
  WHERE geo.region IS NOT NULL AND date_trunc(orders.purchase_ts,year) = '2019-01-01'
  GROUP BY 1, 2
  ORDER BY 1 ASC, 2
), 
sales_2020 AS (
    SELECT 
    date_trunc(orders.purchase_ts,year) AS years,
    geo.region,
    COUNT(orders.id) AS order_count,
    ROUND(SUM(usd_price),2) AS total_sales,
    ROUND(AVG(usd_price),2) AS average_order_value
  FROM elist.customers customers
  LEFT JOIN elist.geo_lookup geo 
    ON customers.country_code = geo.country
  LEFT JOIN elist.orders orders 
    ON customers.id = orders.customer_id
  WHERE geo.region IS NOT NULL AND date_trunc(orders.purchase_ts,year) = '2020-01-01'
  GROUP BY 1, 2
  ORDER BY 1 ASC, 2
), 
sales_2021 AS (
    SELECT 
    date_trunc(orders.purchase_ts,year) AS years,
    geo.region,
    COUNT(orders.id) AS order_count,
    ROUND(SUM(usd_price),2) AS total_sales,
    ROUND(AVG(usd_price),2) AS average_order_value
  FROM elist.customers customers
  LEFT JOIN elist.geo_lookup geo 
    ON customers.country_code = geo.country
  LEFT JOIN elist.orders orders 
    ON customers.id = orders.customer_id
  WHERE geo.region IS NOT NULL AND date_trunc(orders.purchase_ts,year) = '2021-01-01'
  GROUP BY 1, 2
  ORDER BY 1 ASC, 2
),
sales_2022 AS (
    SELECT 
    date_trunc(orders.purchase_ts,year) AS years,
    geo.region,
    COUNT(orders.id) AS order_count,
    ROUND(SUM(usd_price),2) AS total_sales,
    ROUND(AVG(usd_price),2) AS average_order_value
  FROM elist.customers customers
  LEFT JOIN elist.geo_lookup geo 
    ON customers.country_code = geo.country
  LEFT JOIN elist.orders orders 
    ON customers.id = orders.customer_id
  WHERE geo.region IS NOT NULL AND date_trunc(orders.purchase_ts,year) = '2022-01-01'
  GROUP BY 1, 2
  ORDER BY 1 ASC, 2
)
SELECT 
  sales_2019.region,
  ROUND(sales_2020.order_count/sales_2019.order_count,2) AS order_count_growth_2020,
  ROUND(sales_2021.order_count/sales_2020.order_count,2) AS order_count_growth_2021,
  ROUND(sales_2022.order_count/sales_2021.order_count,2) AS order_count_growth_2022,
  ROUND(sales_2020.total_sales/sales_2019.total_sales,2) AS total_sales_growth_2020,
  ROUND(sales_2021.total_sales/sales_2020.total_sales,2) AS total_sales_growth_2021,
  ROUND(sales_2022.total_sales/sales_2021.total_sales,2) AS total_sales_growth_2022,
  ROUND(sales_2020.average_order_value/sales_2019.average_order_value,2) AS average_order_value_2020,
  ROUND(sales_2021.average_order_value/sales_2020.average_order_value,2) AS average_order_value_2021,
  ROUND(sales_2022.average_order_value/sales_2021.average_order_value,2) AS average_order_value_2022
FROM sales_2019
INNER JOIN sales_2020
  ON sales_2019.region = sales_2020.region
INNER JOIN sales_2021
  ON sales_2019.region = sales_2021.region
  INNER JOIN sales_2022
  ON sales_2019.region = sales_2022.region
;


/* Operations */
-- Macbook Air Laptops have the highest return rate of 4.17% compared to other products. More analysis should be taken to identify the root cause so as to reduce the operational cost required to carry out these refunds. 
SELECT 
  CASE WHEN orders.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE orders.product_name END AS product_name_cleaned,
  SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refunds,
  ROUND(SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END)/(COUNT (DISTINCT orders.id))*100,2) AS refund_rate
FROM elist.orders orders
LEFT JOIN elist.order_status order_status
  ON orders.id = order_status.id
GROUP BY 1
ORDER BY 3 DESC;

-- While Apple has the highest number of refunds from 2019-2021 with 2020 having highest number of refunds (446), it does not have the highest refund rate. 
WITH order_refunds AS (
  SELECT
    EXTRACT(YEAR FROM orders.purchase_ts) AS year,
    CASE 
      WHEN LOWER(orders.product_name) LIKE '%thinkpad%' THEN 'ThinkPad'
      WHEN LOWER(orders.product_name) LIKE '%apple%' THEN 'Apple'
      WHEN LOWER(orders.product_name) LIKE '%macbook%' THEN 'Apple'
      WHEN LOWER(orders.product_name) LIKE '%samsung%' THEN 'Samsung'
      WHEN LOWER(orders.product_name) LIKE '%bose%' THEN 'Bose'
      ELSE 'Others'
      END AS brand,
    SUM(CASE WHEN order_status.refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refund_count,
    ROUND(SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END)/COUNT(DISTINCT orders.id)*100,2) AS refund_rate
  FROM elist.orders orders
  LEFT JOIN elist.order_status order_status 
    ON orders.id = order_status.id
  GROUP BY 1, 2
  ORDER BY 1,3 DESC
) 
SELECT 
  *,
  ROW_NUMBER() OVER (
    PARTITION BY year
    ORDER BY refund_count DESC) AS refund_ranking,
    ROW_NUMBER() OVER (
    PARTITION BY year
    ORDER BY refund_rate DESC) AS refund_rate_ranking
FROM order_refunds
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY year
    ORDER BY refund_count DESC) =1 
ORDER BY year;

/* Marketing */
-- Looking to identify the best performin marketing channel, there is a need to define what "best" means.It could be by highest average order value, total_sales or number of orders. 
-- In this case, we define best as highest average order value. The best performing marketing channels by region differs but across the board, affiliate and direct marketing channels generate higher average order value than other marketing channels. 

WITH orders_by_region AS (
  SELECT 
    geo.region,
    customers.marketing_channel,
    ROUND(SUM(orders.usd_price),2) AS total_sales,
    ROUND(AVG(orders.usd_price),2) AS average_order_value,
    COUNT(orders.id) AS num_of_orders
  FROM elist.customers customers
  LEFT JOIN elist.geo_lookup geo
    ON customers.country_code = geo.country
  LEFT JOIN elist.orders orders
    ON customers.id = orders.customer_id
  GROUP BY 1,2
)

SELECT
  region,
  marketing_channel,
  average_order_value,
  RANK() OVER (
    PARTITION BY region
    ORDER BY average_order_value DESC) AS ranking
FROM orders_by_region
WHERE region IS NOT NULL AND marketing_channel IS NOT NULL AND marketing_channel != "unknown"
ORDER BY ranking asc;
