SELECT order_id, customer_id, order_date
FROM orders
WHERE status = 'Pending'
  AND order_date >= '2026-04-01';
