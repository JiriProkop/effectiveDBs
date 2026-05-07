SELECT customer_id, COUNT(*) AS orders_count
FROM orders
GROUP BY customer_id
ORDER BY orders_count DESC
LIMIT 20;
