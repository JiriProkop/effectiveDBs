SELECT p.product_id, p.name, SUM(oi.quantity) AS sold_qty
FROM ordered_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
ORDER BY sold_qty DESC
LIMIT 10;
