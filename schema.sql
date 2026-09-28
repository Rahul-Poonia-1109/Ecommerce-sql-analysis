-- ============================================================
-- E-Commerce Order Analysis | schema.sql
-- Creates the database and all four tables.
-- Run order: schema.sql -> data.sql -> queries.sql
-- Tested on: MySQL / MariaDB
-- ============================================================

CREATE DATABASE IF NOT EXISTS ecommerce_analysis;
USE ecommerce_analysis;

-- Customers who place orders
CREATE TABLE customers (
  cust_id      INT PRIMARY KEY,
  cust_name    VARCHAR(50) NOT NULL,
  city         VARCHAR(50),
  signup_date  DATE
);

-- Product catalog
CREATE TABLE products (
  product_id    INT PRIMARY KEY,
  product_name  VARCHAR(100) NOT NULL,
  category      VARCHAR(50),
  price         DECIMAL(10,2)
);

-- One row per order (header level)
CREATE TABLE orders (
  order_id    INT PRIMARY KEY,
  cust_id     INT,
  order_date  DATE,
  status      VARCHAR(20),          -- Delivered / Pending / Cancelled
  FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
);

-- One row per product line inside an order (line-item level)
CREATE TABLE order_items (
  order_item_id  INT PRIMARY KEY,
  order_id       INT,
  product_id     INT,
  quantity       INT,
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);
