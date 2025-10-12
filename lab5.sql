--Anuarova Nazerke  24B030982

--Part 1
--1.1
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);
--Valid
INSERT INTO employees VALUES (1, 'Alice', 'Brown', 30, 3000);
INSERT INTO employees VALUES (2, 'John', 'Smith', 45, 5000);

--Invalid
INSERT INTO employees VALUES (3, 'Tom', 'Young', 17, 2500);  --violates age 
INSERT INTO employees VALUES (4, 'Eva', 'Johnson', 25, -100); --violates salary 

--1.2
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

--Valid 
INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Phone', 600, 550);

--Invalid 
INSERT INTO products_catalog VALUES (3, 'Tablet', 0, 100);  --regular_price>0
INSERT INTO products_catalog VALUES (4, 'Mouse', 200, 250); --discount>=regular_price

--1.3
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

--Valid
INSERT INTO bookings VALUES (1, '2025-10-01', '2025-10-05', 3);
INSERT INTO bookings VALUES (2, '2025-10-10', '2025-10-12', 2);

--Invalid 
INSERT INTO bookings VALUES (3, '2025-10-01', '2025-09-30', 4); --check_out<check_in
INSERT INTO bookings VALUES (4, '2025-10-01', '2025-10-03', 15); --num_guests>10

--Part 2
--2.1
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

--Valid
INSERT INTO customers VALUES (1, 'user1@mail.com', '123456789', '2025-10-01');
INSERT INTO customers VALUES (2, 'user2@mail.com', NULL, '2025-10-05');

--Invalid 
INSERT INTO customers VALUES (NULL, 'user3@mail.com', '111111111', '2025-10-10'); --customer_id is NOT NULL
INSERT INTO customers VALUES (3, NULL, '111111111', '2025-10-10');                --email 
INSERT INTO customers VALUES (4, 'user4@mail.com', '222222222', NULL);            --registration_date 

--2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

--Valid
INSERT INTO inventory VALUES (1, 'Keyboard', 20, 30.00, CURRENT_TIMESTAMP);
INSERT INTO inventory VALUES (2, 'Mouse', 50, 15.00, CURRENT_TIMESTAMP);

--Invalid 
INSERT INTO inventory VALUES (3, 'Monitor', -5, 200.00, CURRENT_TIMESTAMP); --quantity>=0
INSERT INTO inventory VALUES (4, 'USB Cable', 10, -10.00, CURRENT_TIMESTAMP); --unit_price>0

--Part 3
--3.1
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

--Valid
INSERT INTO users VALUES (1, 'alex', 'alex@mail.com', CURRENT_TIMESTAMP);
INSERT INTO users VALUES (2, 'maria', 'maria@mail.com', CURRENT_TIMESTAMP);

--Invalid 
INSERT INTO users VALUES (3, 'alex', 'new@mail.com', CURRENT_TIMESTAMP);   --duplicate username
INSERT INTO users VALUES (4, 'newuser', 'maria@mail.com', CURRENT_TIMESTAMP); --email

--3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

--Valid
INSERT INTO course_enrollments VALUES (1, 1001, 'CS101', 'Fall 2025');
INSERT INTO course_enrollments VALUES (2, 1002, 'CS101', 'Fall 2025');

--Invalid
INSERT INTO course_enrollments VALUES (3, 1001, 'CS101', 'Fall 2025'); -- violates unique_enrollment

--3.3
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

--Test duplicate
INSERT INTO users VALUES (5, 'alex', 'another@mail.com', CURRENT_TIMESTAMP);  --violates unique_username
INSERT INTO users VALUES (6, 'susan', 'maria@mail.com', CURRENT_TIMESTAMP);   --unique_email

--Part 4
--4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

--Valid
INSERT INTO departments VALUES (1, 'HR', 'New York');
INSERT INTO departments VALUES (2, 'IT', 'Chicago');
INSERT INTO departments VALUES (3, 'Finance', 'Los Angeles');

--Invalid 
INSERT INTO departments VALUES (1, 'Marketing', 'Boston');  --duplicate dept_id
INSERT INTO departments VALUES (NULL, 'Legal', 'Miami');    --dept_id is PRIMARY KEY (NOT NULL)

--4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

--Valid
INSERT INTO student_courses VALUES (1001, 101, '2025-09-01', 'A');
INSERT INTO student_courses VALUES (1002, 101, '2025-09-01', 'B');

--Invalid
INSERT INTO student_courses VALUES (1001, 101, '2025-09-02', 'C'); --duplicate PK (student_id, course_id)

--4.3
--PRIMARY KEY uniquely identifies each row and implies NOT NULL.
--UNIQUE only ensures uniqueness but allows NULLs.
--Only one PRIMARY KEY per table, but multiple UNIQUE constraints allowed.
--Composite PKs are used when a single column cannot uniquely identify rows.

--Part 5
--5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

--Valid
INSERT INTO employees_dept VALUES (1, 'Alice', 1, '2025-01-01');
INSERT INTO employees_dept VALUES (2, 'Bob', 2, '2025-02-01');

--Invalid
INSERT INTO employees_dept VALUES (3, 'Charlie', 99, '2025-03-01'); --dept_id 99 does not exist

--5.2
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors VALUES (2, 'George R.R. Martin', 'USA');

INSERT INTO publishers VALUES (1, 'Bloomsbury', 'London');
INSERT INTO publishers VALUES (2, 'Bantam Books', 'New York');

INSERT INTO books VALUES (1, 'Harry Potter', 1, 1, 1997, '111111');
INSERT INTO books VALUES (2, 'Game of Thrones', 2, 2, 1996, '222222');

--5.3
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

--Test
DELETE FROM categories WHERE category_id = 1; --fails
DELETE FROM orders WHERE order_id = 1;        --deletes order

--Part 6
--6.1
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

--Valid
INSERT INTO customers (name, email, phone, registration_date) VALUES
('Alice Brown', 'alice@mail.com', '111111111', '2025-01-01'),
('Bob Smith', 'bob@mail.com', '222222222', '2025-02-01'),
('Carol White', 'carol@mail.com', '333333333', '2025-03-01'),
('David King', 'david@mail.com', '444444444', '2025-04-01'),
('Eve Black', 'eve@mail.com', '555555555', '2025-05-01');

INSERT INTO products (name, description, price, stock_quantity) VALUES
('Laptop', 'Gaming laptop', 1200, 10),
('Phone', 'Smartphone 5G', 800, 20),
('Headphones', 'Wireless headset', 150, 50),
('Keyboard', 'Mechanical keyboard', 100, 30),
('Mouse', 'Gaming mouse', 80, 40);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2025-06-01', 2000, 'pending'),
(2, '2025-06-02', 800, 'processing'),
(3, '2025-06-03', 150, 'shipped'),
(4, '2025-06-04', 100, 'delivered'),
(5, '2025-06-05', 1200, 'cancelled');

INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200),
(1, 2, 1, 800),
(2, 2, 1, 800),
(3, 3, 1, 150),
(4, 4, 1, 100);

--Invalid
INSERT INTO ecommerce_products (name, description, price, stock_quantity) VALUES ('Tablet', 'New tablet', -100, 10); --price<0
INSERT INTO ecommerce_order_details (order_id, product_id, quantity, unit_price) VALUES (1, 5, 0, 50); --quantity must be>0
INSERT INTO ecommerce_orders (customer_id, order_date, total_amount, status) VALUES (1, '2025-07-01', 500, 'returned'); --invalid status


