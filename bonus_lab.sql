--Task 1
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers(
  customer_id SERIAL PRIMARY KEY,
  iin VARCHAR(12) UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone VARCHAR(20),
  email TEXT,
  status VARCHAR(10) NOT NULL DEFAULT 'active', 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  daily_limit_kzt NUMERIC(18,2) DEFAULT 1000000 
);

CREATE TABLE accounts (
  account_id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  account_number VARCHAR(34) UNIQUE NOT NULL, 
  currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE exchange_rates (
  rate_id SERIAL PRIMARY KEY,
  from_currency VARCHAR(3) NOT NULL,
  to_currency VARCHAR(3) NOT NULL,
  rate NUMERIC(18,6) NOT NULL, 
  valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  valid_to TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT '9999-12-31'::timestamp with time zone
);

CREATE TABLE transactions (
  transaction_id SERIAL PRIMARY KEY,
  from_account_id INTEGER REFERENCES accounts(account_id),
  to_account_id   INTEGER REFERENCES accounts(account_id),
  amount  NUMERIC(18,2) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  exchange_rate NUMERIC(18,6),
  amount_kzt NUMERIC(18,2), 
  type VARCHAR(20) NOT NULL, 
  status VARCHAR(20) NOT NULL DEFAULT 'pending', 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  description TEXT
);

CREATE TABLE audit_log (
  log_id SERIAL PRIMARY KEY,
  table_name TEXT,
  record_id BIGINT,
  action VARCHAR(10),
  old_values JSONB,
  new_values JSONB,
  changed_by TEXT,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ip_address TEXT
);


INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('123456789012','Amanov A.','77001234567','aman@example.com','active', 5000000),
('223456789012','Bekturov B.','77007654321','bekt@example.com','active', 2000000),
('323456789012','Chingiz C.','77001112233','chig@example.com','blocked', 1000000),
('423456789012','Dina D.','77009998877','dina@example.com','active', 3000000),
('523456789012','Elena E.','77004455667','elena@example.com','active', 1500000),
('623456789012','Fedor F.','77003332211','fedor@example.com','frozen', 1000000),
('723456789012','Gulnara G.','77002223344','guln@example.com','active', 2500000),
('823456789012','Hamit H.','77005556677','hamit@example.com','active', 5000000),
('923456789012','Ilya I.','77006667788','ilya@example.com','active', 1000000),
('023456789012','Julia J.','77008889900','julia@example.com','active', 800000);


INSERT INTO accounts (customer_id, account_number, currency, balance, is_active)
VALUES
(1,'KZ01AMAN0000000001','KZT', 1000000, true),
(1,'KZ01AMAN0000000002','USD', 2000, true),
(2,'KZ01BEKT0000000001','KZT', 500000, true),
(2,'KZ01BEKT0000000002','EUR', 800, true),
(3,'KZ01CHNG0000000001','KZT', 10000, true),
(4,'KZ01DINA0000000001','KZT', 200000, true),
(5,'KZ01ELEN0000000001','USD', 50, true),
(6,'KZ01FEDO0000000001','KZT', 300000, true),
(7,'KZ01GULN0000000001','RUB', 100000, true),
(8,'KZ01HAMI0000000001','EUR', 500, true),
(9,'KZ01ILYA0000000001','KZT', 100000, true),
(10,'KZ01JULI0000000001','KZT', 70000, true);

INSERT INTO exchange_rates (from_currency,to_currency,rate, valid_from, valid_to) VALUES
('USD','KZT', 470.00, now() - interval '30 days', '9999-12-31'),
('EUR','KZT', 510.00, now() - interval '30 days', '9999-12-31'),
('RUB','KZT', 5.50, now() - interval '30 days', '9999-12-31'),
('KZT','KZT', 1.0, now() - interval '30 days', '9999-12-31'),
('KZT','USD', 1/470.00::numeric, now() - interval '30 days', '9999-12-31'),
('KZT','EUR', 1/510.00::numeric, now() - interval '30 days', '9999-12-31');

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description)
VALUES
(1,3,100000,'KZT',1.0,100000,'transfer','completed', now() - interval '6 hour', now() - interval '6 hour', 'test past transfer'),
(1,4,200,'USD',470.0,94000,'transfer','completed', now() - interval '2 hour', now() - interval '2 hour', 'another transfer');


CREATE OR REPLACE FUNCTION process_transfer(
  p_from_account_number TEXT,
  p_to_account_number   TEXT,
  p_amount              NUMERIC,
  p_currency            TEXT,
  p_description         TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  from_acc RECORD;
  to_acc   RECORD;
  cust     RECORD;
  rate_to_kzt NUMERIC := 1;
  amount_kzt NUMERIC;
  today_sum NUMERIC;
  tx_id INTEGER;
BEGIN

  SELECT * INTO from_acc FROM accounts WHERE account_number = p_from_account_number;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','code','E01','message','Source account not found');
  END IF;

  SELECT * INTO to_acc FROM accounts WHERE account_number = p_to_account_number;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status','error','code','E02','message','Target account not found');
  END IF;


  IF from_acc.is_active = false OR to_acc.is_active = false THEN
    RETURN jsonb_build_object('status','error','code','E03','message','Account inactive');
  END IF;


  SELECT * INTO cust FROM customers WHERE customer_id = from_acc.customer_id;
  IF cust.status <> 'active' THEN
    RETURN jsonb_build_object('status','error','code','E04','message','Customer not active');
  END IF;


  SELECT * FROM accounts WHERE account_id = from_acc.account_id FOR UPDATE;
  SELECT * FROM accounts WHERE account_id = to_acc.account_id FOR UPDATE;


  IF p_currency <> 'KZT' THEN
    SELECT rate INTO rate_to_kzt
    FROM exchange_rates
    WHERE from_currency = p_currency AND to_currency = 'KZT'
    LIMIT 1;
  END IF;

  amount_kzt := p_amount * rate_to_kzt;

  IF from_acc.balance < p_amount THEN
    RETURN jsonb_build_object('status','error','code','E05','message','Not enough money');
  END IF;


  SELECT COALESCE(SUM(amount_kzt),0) INTO today_sum
  FROM transactions
  WHERE from_account_id = from_acc.account_id
    AND status = 'completed'
    AND DATE(created_at) = CURRENT_DATE;

  IF today_sum + amount_kzt > cust.daily_limit_kzt THEN
    RETURN jsonb_build_object('status','error','code','E06','message','Daily limit exceeded');
  END IF;

  SAVEPOINT sp1;

  INSERT INTO transactions(
    from_account_id, to_account_id, amount, currency,
    exchange_rate, amount_kzt, type, status, description
  )
  VALUES (
    from_acc.account_id, to_acc.account_id, p_amount, p_currency,
    rate_to_kzt, amount_kzt, 'transfer', 'pending', p_description
  )
  RETURNING transaction_id INTO tx_id;


  UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = from_acc.account_id;

  UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = to_acc.account_id;

  UPDATE transactions
    SET status = 'completed', completed_at = now()
    WHERE transaction_id = tx_id;


  INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by)
  VALUES
  ('transactions', tx_id, 'INSERT',
   jsonb_build_object('from',from_acc.account_number,'to',to_acc.account_number,'amount',p_amount),
   'process_transfer');

  RETURN jsonb_build_object('status','ok','code','S00','message','Transfer completed','tx_id',tx_id);

EXCEPTION WHEN OTHERS THEN
  ROLLBACK TO SAVEPOINT sp1;

  IF tx_id IS NOT NULL THEN
    UPDATE transactions SET status='failed' WHERE transaction_id = tx_id;
  END IF;

  INSERT INTO audit_log(table_name, action, new_values, changed_by)
  VALUES ('transactions', 'ERROR', jsonb_build_object('error',SQLERRM), 'process_transfer');

  RETURN jsonb_build_object('status','error','code','E99','message','Unexpected error');
END;
$$;

--Task 2
--View 1
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
  c.customer_id,
  c.full_name,
  a.account_number,
  a.currency,
  a.balance,
  SUM(
    CASE 
      WHEN a.currency = 'KZT' THEN a.balance
      ELSE a.balance * er.rate
    END
  ) OVER (PARTITION BY c.customer_id) AS total_kzt,
  ROUND(
    (SUM(t.amount_kzt) OVER (PARTITION BY c.customer_id) / c.daily_limit_kzt) * 100, 2
  ) AS daily_usage_percent,
  RANK() OVER (
    ORDER BY SUM(
      CASE 
        WHEN a.currency = 'KZT' THEN a.balance
        ELSE a.balance * er.rate
      END
    ) OVER (PARTITION BY c.customer_id) DESC
  ) AS balance_rank
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN exchange_rates er 
  ON a.currency = er.from_currency AND er.to_currency = 'KZT';

--view 2
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
  DATE(created_at) AS tx_date,
  type,
  COUNT(*) AS tx_count,
  SUM(amount_kzt) AS total_volume,
  AVG(amount_kzt) AS avg_amount,
  SUM(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at)) AS running_total,
  ROUND(
    (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at))) /
    NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at)),0) * 100,2
  ) AS growth_percent
FROM transactions
WHERE status = 'completed'
GROUP BY DATE(created_at), type;

--view 3
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT *
FROM transactions
WHERE amount_kzt > 5000000
   OR transaction_id IN (
     SELECT transaction_id
     FROM transactions
     GROUP BY from_account_id, date_trunc('hour', created_at)
     HAVING COUNT(*) > 10
   );


--Task 3
CREATE INDEX idx_accounts_balance ON accounts(balance);
CREATE INDEX idx_accounts_active ON accounts(account_id)
WHERE is_active = true;
CREATE INDEX idx_customers_email_lower ON customers(LOWER(email));
CREATE INDEX idx_audit_json ON audit_log USING GIN(new_values);
CREATE INDEX idx_transactions_from_date ON transactions(from_account_id, created_at);
CREATE INDEX idx_transactions_status_hash ON transactions USING HASH(status);

--Task 4
CREATE OR REPLACE FUNCTION process_salary_batch(
  p_company_account TEXT,
  p_payments JSONB
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  company_acc RECORD;
  total_sum NUMERIC := 0;
  item JSONB;
  emp_acc RECORD;
  success_count INT := 0;
  fail_count INT := 0;
  fail_list JSONB := '[]';
BEGIN
  SELECT * INTO company_acc
  FROM accounts
  WHERE account_number = p_company_account
  FOR UPDATE;

  FOR item IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    total_sum := total_sum + (item->>'amount')::NUMERIC;
  END LOOP;

  IF company_acc.balance < total_sum THEN
    RETURN jsonb_build_object('status','error','message','Not enough balance');
  END IF;

  PERFORM pg_advisory_lock(company_acc.account_id);

  FOR item IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    BEGIN
      SELECT a.* INTO emp_acc
      FROM accounts a
      JOIN customers c ON a.customer_id = c.customer_id
      WHERE c.iin = item->>'iin'
      LIMIT 1;

      UPDATE accounts
        SET balance = balance - (item->>'amount')::NUMERIC
        WHERE account_id = company_acc.account_id;

      UPDATE accounts
        SET balance = balance + (item->>'amount')::NUMERIC
        WHERE account_id = emp_acc.account_id;

      INSERT INTO transactions(
        from_account_id, to_account_id, amount, currency,
        exchange_rate, amount_kzt, type, status
      )
      VALUES (
        company_acc.account_id, emp_acc.account_id,
        (item->>'amount')::NUMERIC, 'KZT',
        1, (item->>'amount')::NUMERIC,
        'transfer', 'completed'
      );

      success_count := success_count + 1;

    EXCEPTION WHEN OTHERS THEN
      fail_count := fail_count + 1;
      fail_list := fail_list || jsonb_build_object('iin', item->>'iin');
    END;
  END LOOP;

  PERFORM pg_advisory_unlock(company_acc.account_id);

  RETURN jsonb_build_object(
    'success', success_count,
    'failed', fail_count,
    'failed_list', fail_list
  );
END;
$$;

CREATE MATERIALIZED VIEW salary_batch_report AS
SELECT
  DATE(created_at) AS pay_date,
  COUNT(*) AS total_transfers,
  SUM(amount) AS total_paid
FROM transactions
WHERE description ILIKE '%salary%'
GROUP BY DATE(created_at);


--Test cases demonstrating each scenario (successful and failed operations)
--successful
SELECT process_transfer(
  'KZ01AMAN0000000001',
  'KZ01BEKT0000000001',
  50000,
  'KZT',
  'success test 1'
);

SELECT process_transfer(
  'KZ01AMAN0000000002',
  'KZ01BEKT0000000001',
  100,
  'USD',
  'success test 2'
);

--failed
--Sender do not found
SELECT process_transfer(
  'NO_ACCOUNT',
  'KZ01BEKT0000000001',
  1000,
  'KZT',
  'fail no sender'
);

--no money
SELECT process_transfer(
  'KZ01ELEN0000000001',
  'KZ01DINA0000000001',
  10000,
  'USD',
  'fail no money'
);

--limit
SELECT process_transfer(
  'KZ01JULI0000000001',
  'KZ01BEKT0000000001',
  9999999,
  'KZT',
  'fail daily limit'
);

--task 4
SELECT process_salary_batch(
  'KZ01AMAN0000000001',
  '[
     {"iin":"223456789012","amount":50000},
     {"iin":"423456789012","amount":30000},
     {"iin":"523456789012","amount":20000}
   ]'
);

--salary is not enough
SELECT process_salary_batch(
  'KZ01ELEN0000000001',
  '[
     {"iin":"223456789012","amount":50000000},
     {"iin":"423456789012","amount":30000000}
   ]'
);

--Explain analyze
EXPLAIN ANALYZE
SELECT * FROM accounts WHERE balance > 100000;

EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'aman@example.com';

EXPLAIN ANALYZE
SELECT * FROM audit_log WHERE new_values ? 'error';

EXPLAIN ANALYZE
SELECT * FROM transactions WHERE from_account_id = 1;

--brief documentation
--The database system was designed for a simplified banking transaction platform. The main goal was to implement secure money transfers, reporting views, performance optimization using indexes, and batch salary processing.
--For transaction processing, the process_transfer function was implemented. It checks account activity, customer status, available balance, and daily limits. Currency conversion is done using exchange rates. To prevent race conditions, row-level locking (FOR UPDATE) is used. A SAVEPOINT allows partial rollback in case of errors.
--For reporting, three views were created. The customer balance summary shows total balances converted to KZT and ranks customers. The daily transaction report aggregates daily statistics and calculates growth. The suspicious activity view detects large and frequent transactions using simple conditions and includes a security barrier.
--Indexes were created using different index types: B-tree for numeric searches, Hash for status filtering, GIN for JSONB fields, partial index for active accounts, and expression index for case-insensitive email search. Performance was verified using EXPLAIN ANALYZE.
--For batch salary processing, the process_salary_batch function accepts a JSONB list of payments. All payments are processed inside one transaction using advisory locks to avoid concurrent execution. Failed payments are collected into a JSON result. A materialized view was created to summarize salary payments by date.

--Demonstration of concurrent transaction handling (using two psql sessions)
--Terminal 1
BEGIN;
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;

--terminal 2
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;
--terminal 1
COMMIT;

