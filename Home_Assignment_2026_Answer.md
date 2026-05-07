# Home Assignment 2026 - Answer

I loaded 525248.sql into PostgreSQL running in Docker (container pa152, DB pa152_db).

For runtime numbers, I followed the required method:

- one EXPLAIN (ANALYZE, BUFFERS) run for plan analysis,
- pgbench warm-up with 20 executions,
- pgbench measured run with 50 executions,
- one client and one thread.

I also did a second verification pass. The updated numbers below are from the verified full dataset state:

- customers: 10000
- orders: 100000
- ordered_items: 549941
- products: 500

## 1. Query Diagnostics Under Real Workload

### Query A - full explain plan
~~~text
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=2745.54..2745.59 rows=20 width=12) (actual time=30.244..30.247 rows=20.00 loops=1)
   Buffers: shared hit=882
   ->  Sort  (cost=2745.54..2770.57 rows=10012 width=12) (actual time=30.242..30.243 rows=20.00 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         Buffers: shared hit=882
         ->  HashAggregate  (cost=2379.00..2479.12 rows=10012 width=12) (actual time=28.453..29.340 rows=10000.00 loops=1)
               Group Key: customer_id
               Batches: 1  Memory Usage: 793kB
               Buffers: shared hit=879
               ->  Seq Scan on orders  (cost=0.00..1879.00 rows=100000 width=4) (actual time=0.021..7.730 rows=100000.00 loops=1)
                     Buffers: shared hit=879
 Planning:
   Buffers: shared hit=80
 Planning Time: 0.363 ms
 Execution Time: 30.699 ms
(16 rows)
~~~

### Query B - full explain plan
~~~text
                                                              QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=2129.01..4508.01 rows=2197 width=33) (actual time=15.341..22.904 rows=5704.00 loops=1)
   Filter: ((order_date >= (InitPlan 1).col1) AND ((status)::text = 'Pending'::text))
   Rows Removed by Filter: 94296
   Buffers: shared hit=1758
   InitPlan 1
     ->  Aggregate  (cost=2129.00..2129.01 rows=1 width=8) (actual time=15.327..15.328 rows=1.00 loops=1)
           Buffers: shared hit=879
           ->  Seq Scan on orders orders_1  (cost=0.00..1879.00 rows=100000 width=8) (actual time=0.004..7.788 rows=100000.00 loops=1)
                 Buffers: shared hit=879
 Planning:
   Buffers: shared hit=103
 Planning Time: 0.325 ms
 Execution Time: 23.145 ms
(13 rows)
~~~

### Query C - full explain plan
~~~text
                                                                                  QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=9293.98..9294.00 rows=10 width=18) (actual time=73.703..76.277 rows=10.00 loops=1)
   Buffers: shared hit=4079
   ->  Sort  (cost=9293.98..9295.23 rows=500 width=18) (actual time=73.701..76.274 rows=10.00 loops=1)
         Sort Key: (sum(oi.quantity)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         Buffers: shared hit=4079
         ->  Finalize GroupAggregate  (cost=9132.41..9283.17 rows=500 width=18) (actual time=73.114..76.173 rows=500.00 loops=1)
               Group Key: p.product_id
               Buffers: shared hit=4076
               ->  Gather Merge  (cost=9132.41..9272.17 rows=1200 width=18) (actual time=73.108..75.923 rows=1500.00 loops=1)
                     Workers Planned: 2
                     Workers Launched: 2
                     Buffers: shared hit=4076
                     ->  Sort  (cost=8132.39..8133.64 rows=500 width=18) (actual time=70.438..70.473 rows=500.00 loops=3)
                           Sort Key: p.product_id
                           Sort Method: quicksort  Memory: 44kB
                           Buffers: shared hit=4076
                           Worker 0:  Sort Method: quicksort  Memory: 44kB
                           Worker 1:  Sort Method: quicksort  Memory: 44kB
                           ->  Partial HashAggregate  (cost=8104.97..8109.97 rows=500 width=18) (actual time=70.211..70.290 rows=500.00 loops=3)
                                 Group Key: p.product_id
                                 Batches: 1  Memory Usage: 73kB
                                 Buffers: shared hit=4062
                                 Worker 0:  Batches: 1  Memory Usage: 73kB
                                 Worker 1:  Batches: 1  Memory Usage: 73kB
                                 ->  Hash Join  (cost=17.25..6959.26 rows=229142 width=14) (actual time=0.191..45.508 rows=183313.67 loops=3)
                                       Hash Cond: (oi.product_id = p.product_id)
                                       Buffers: shared hit=4062
                                       ->  Parallel Seq Scan on ordered_items oi  (cost=0.00..6335.42 rows=229142 width=8) (actual time=0.008..11.224 rows=183313.67 loops=3)
                                             Buffers: shared hit=4044
                                       ->  Hash  (cost=11.00..11.00 rows=500 width=10) (actual time=0.169..0.170 rows=500.00 loops=3)
                                             Buckets: 1024  Batches: 1  Memory Usage: 29kB
                                             Buffers: shared hit=18
                                             ->  Seq Scan on products p  (cost=0.00..11.00 rows=500 width=10) (actual time=0.011..0.075 rows=500.00 loops=3)
                                                   Buffers: shared hit=18
 Planning:
   Buffers: shared hit=129
 Planning Time: 0.504 ms
 Execution Time: 76.396 ms
(39 rows)
~~~

Which query had the longest execution time? (A/B/C)

C

Which query read the most shared buffers? (A/B/C)

C

Which query had the largest estimation error? (A/B/C)

B

Dominant expensive operator of the slowest query:

Hash Join (with parallel seq scan on ordered_items and aggregate/sort on top).

Explain in max. 60 words why the query was slow:

Query C touches a large part of ordered_items, joins it with products, then aggregates and sorts the result. Even with parallelism, this is a lot of data movement and CPU work. The expensive part is not one tiny lookup, but full-table style processing for join plus aggregation.

## 2. Index Budget Challenge

Average latency of Q1 before indexing (ms)

5.868

Average latency of Q2 before indexing (ms)

9.091

Average latency of Q3 before indexing (ms)

6.027

SQL commands creating your indexes:

~~~sql
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
CREATE INDEX idx_orders_status_order_date ON orders (status, order_date DESC);
~~~

Average latency of Q1 after indexing (ms)

0.115

Average latency of Q2 after indexing (ms)

3.256

Average latency of Q3 after indexing (ms)

0.125

Improvement percentage (before_sum - after_sum) / before_sum * 100

before_sum = 20.986 ms

after_sum = 3.496 ms

improvement = 83.34%

Explain in max. 80 words which query benefited most, which least, and why your chosen indexes are a compromise:

Q1 and Q3 improved the most because both are customer-focused filters and the (customer_id, status) index narrows rows quickly. Q2 improved less, but still significantly, because it filters by status and date range, which matches (status, order_date DESC). The pair is a compromise: one index for customer-driven lookups and one for status-plus-time filtering, minimizing total workload latency with only two indexes allowed.

## 3. A Plausible but Weak Index

Execution plan before indexing:

~~~text
                                                   QUERY PLAN
----------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..2129.00 rows=20017 width=24) (actual time=0.016..10.331 rows=20082.00 loops=1)
   Filter: ((status)::text = 'Shipped'::text)
   Rows Removed by Filter: 79918
   Buffers: shared hit=879
 Planning:
   Buffers: shared hit=72
 Planning Time: 0.214 ms
 Execution Time: 10.939 ms
(8 rows)
~~~

Average latency before indexing (ms)

15.769

SQL command creating the index:

~~~sql
CREATE INDEX idx_orders_customer_status_weak ON orders (customer_id, status);
~~~

Execution plan after indexing:

~~~text
                                                   QUERY PLAN
----------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..2129.00 rows=20017 width=24) (actual time=0.021..17.716 rows=20082.00 loops=1)
   Filter: ((status)::text = 'Shipped'::text)
   Rows Removed by Filter: 79918
   Buffers: shared hit=879
 Planning:
   Buffers: shared hit=95 read=1
 Planning Time: 0.334 ms
 Execution Time: 18.899 ms
(8 rows)
~~~

Average latency after indexing (ms)

14.723

Access method after indexing:

Seq Scan

Explain in max. 80 words why the index helped little:

The index looks reasonable at first glance because it includes status, but status is the second column, not the leading one. For WHERE status = 'Shipped', the planner still prefers sequential scan. Also, around one fifth of rows match this status, so filtering is not very selective. The result is only a small runtime gain in pgbench (about 6.63%).
