CREATE TABLE accounts (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
id SERIAL PRIMARY KEY,
shop VARCHAR(100) NOT NULL,
product VARCHAR(100) NOT NULL,
price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);

--Task 1
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;
--Alice = 900, Bob = 600.
--To ensure atomicity—both updates succeed or none do.
--Balances would become inconsistent: Alice loses money, Bob doesn’t receive it.

--Task 2
BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';

ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
--500.00
--1000.00 (original balance)
--When you detect an error and need to undo temporary changes.

--Task 3
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Wally';
COMMIT;
--Alice = 900, Bob = 500, Wally = 850.
--Yes, temporarily — but rolled back to savepoint, so final state has no credit.
--SAVEPOINT allows partial rollback without restarting the whole transaction.

--Task 4
--Scenario A
--Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

--Scenario B
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--First: original rows; second: updated rows from T2.
--Only original rows.
--READ COMMITTED allows seeing new committed data; SERIALIZABLE blocks phantom changes.

--Task 5
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
--No, Terminal 1 does NOT see the new row.
--Phantom read = new rows appear on repeated queries in the same transaction.
--SERIALIZABLE prevents phantom reads.

--Task 6
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

--Yes, T1 sees 99.99 — this is unsafe because the change never committed.
--Dirty read = reading uncommitted data from another transaction.
--Because it may produce invalid or inconsistent results.

--Ex 1
BEGIN;

DO $$
DECLARE
    bob_balance DECIMAL;
BEGIN
    SELECT balance INTO bob_balance FROM accounts WHERE name='Bob';

    IF bob_balance < 200 THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
END $$;

UPDATE accounts 
    SET balance = balance - 200
    WHERE name='Bob';

UPDATE accounts 
    SET balance = balance + 200
    WHERE name='Wally';

COMMIT;

--Ex 2
BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('TestShop', 'Tea', 5.00);

SAVEPOINT s1;

UPDATE products SET price = 7.00 
WHERE product='Tea';

SAVEPOINT s2;

DELETE FROM products 
WHERE product='Tea';

ROLLBACK TO s1;

COMMIT;

--Ex 3
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 100 WHERE name='Alice';
COMMIT;
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 100 WHERE name='Alice';
COMMIT;

--Ex 4
T1: SELECT MAX(price) → 10
T2: UPDATE price=20
T1: SELECT MIN(price) → 30

BEGIN;
SELECT MAX(price), MIN(price);
COMMIT;
