SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE status = 'Shipped';
