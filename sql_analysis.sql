-- Which marketing channels perform the best in each region? Does the top channel differ across regions?

-- "Best" has different definitions, could be by highest average order value, total_sales or number of orders. 
-- For this case, we define best as highest average order value. The region's average_order_value is ranked and order by ascending order to find the top marketing channel by region.

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
WHERE region IS NOT NULL AND marketing_channel IS NOT NULL
ORDER BY ranking asc;
