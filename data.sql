-- ============================================================
-- E-Commerce Order Analysis | data.sql
-- Synthetic sample data (6 customers, 6 products, 10 orders, 14 order lines).
-- Run after schema.sql.
--
-- Note: customer 6 (Singh Traders) intentionally has NO orders,
-- so LEFT JOIN / NOT EXISTS queries have an edge case to catch.
-- ============================================================

USE ecommerce_analysis;

INSERT INTO customers VALUES
(1,'Rahul Traders','Faridabad','2022-01-10'),
(2,'Delhi Mart','Delhi','2022-03-22'),
(3,'Gupta Stores','Noida','2021-11-05'),
(4,'Sharma & Co','Gurgaon','2023-02-18'),
(5,'Verma Enterprises','Faridabad','2022-07-30'),
(6,'Singh Traders','Delhi','2023-01-01');

INSERT INTO products VALUES
(1,'Wireless Mouse','Electronics',799.00),
(2,'Office Chair','Furniture',5200.00),
(3,'Notebook Pack','Stationery',150.00),
(4,'LED Desk Lamp','Furniture',1200.00),
(5,'Bluetooth Speaker','Electronics',2500.00),
(6,'Whiteboard Marker Set','Stationery',300.00);

INSERT INTO orders VALUES
(101,1,'2023-01-05','Delivered'),
(102,1,'2023-02-14','Delivered'),
(103,2,'2023-01-20','Cancelled'),
(104,3,'2023-03-01','Delivered'),
(105,2,'2023-03-15','Pending'),
(106,4,'2023-04-02','Delivered'),
(107,1,'2023-04-10','Delivered'),
(108,5,'2023-04-22','Pending'),
(109,3,'2023-05-01','Cancelled'),
(110,4,'2023-05-12','Delivered');

INSERT INTO order_items VALUES
(1,101,1,2),
(2,101,3,5),
(3,102,2,1),
(4,103,5,1),
(5,104,2,2),
(6,104,4,1),
(7,105,1,3),
(8,106,3,10),
(9,107,5,1),
(10,107,6,4),
(11,108,4,2),
(12,109,1,1),
(13,110,2,1),
(14,110,5,2);
