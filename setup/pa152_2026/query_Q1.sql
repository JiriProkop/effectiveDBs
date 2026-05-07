SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE customer_id = 4832
  AND status = 'Pending'
ORDER BY order_date DESC
LIMIT 20;
