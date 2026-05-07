EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE status = 'Pending'
  AND order_date >= (
      SELECT MAX(order_date) - INTERVAL '30 days'
      FROM orders
  );
