EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, total_amount, order_date
FROM orders
WHERE customer_id = 4832
  AND order_date >= '2026-04-01'
ORDER BY order_date DESC
LIMIT 50;
