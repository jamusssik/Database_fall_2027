COPY products TO '/tmp/products.csv' WITH CSV HEADER;
SELECT pg_read_file('/tmp/products.csv');

CREATE TABLE products_import (LIKE products INCLUDING ALL);
COPY products_import FROM '/tmp/products.csv' WITH CSV HEADER;
SELECT COUNT(*) FROM products_import;

COPY (SELECT * FROM clients ORDER BY client_id) TO '/tmp/clients.txt'
    WITH DELIMITER '|' NULL 'N/A' CSV HEADER;
SELECT pg_read_file('/tmp/clients.txt');

COPY (SELECT name, age FROM clients ORDER BY client_id) TO '/tmp/new_clients.csv' WITH CSV HEADER;
CREATE TABLE clients_import (id SERIAL PRIMARY KEY, name VARCHAR(100), age INT);
COPY clients_import(name, age) FROM '/tmp/new_clients.csv' WITH CSV HEADER;
SELECT * FROM clients_import;

COPY (SELECT * FROM products WHERE price > 20000) TO '/tmp/expensive_products.csv' WITH CSV HEADER;
SELECT pg_read_file('/tmp/expensive_products.csv');

COPY branch TO '/tmp/branch.csv' WITH CSV HEADER DELIMITER ';' QUOTE '"';
SELECT pg_read_file('/tmp/branch.csv');

COPY history TO '/tmp/history.csv' WITH CSV HEADER FORCE_QUOTE (date);
SELECT pg_read_file('/tmp/history.csv');

TRUNCATE products_import;
COPY products_import FROM '/tmp/products.csv' WITH CSV HEADER;

COPY (SELECT * FROM (VALUES ('20', 'Charger', '900'), ('abc', 'Broken row', '100'), ('21', 'Tripod', '2000'))
      AS v(product_id, product_name, price))
    TO '/tmp/products_with_errors.csv' WITH CSV HEADER;
COPY products_import FROM '/tmp/products_with_errors.csv' WITH (FORMAT csv, HEADER true, ON_ERROR ignore);
SELECT * FROM products_import WHERE product_id >= 20;

TRUNCATE products_import;
COPY products_import FROM '/tmp/products.csv' WITH CSV HEADER ENCODING 'UTF8';

COPY (SELECT 1 AS id, 'Great laptop, fast "and" quiet' AS comment)
    TO '/tmp/feedback.csv' WITH CSV HEADER DELIMITER ',' QUOTE '"' ESCAPE '"';
SELECT pg_read_file('/tmp/feedback.csv');

COPY (SELECT client_id, name, age FROM clients ORDER BY client_id)
    TO '/tmp/clients_null.csv' WITH CSV HEADER NULL 'NULL';
CREATE TABLE clients_null_test (client_id INT, name VARCHAR(100), age INT);
COPY clients_null_test FROM '/tmp/clients_null.csv' WITH CSV HEADER NULL 'NULL';
SELECT * FROM clients_null_test WHERE age IS NULL;

SHOW wal_level;
SHOW archive_mode;
SELECT pg_current_wal_lsn();

SELECT pg_switch_wal();
SELECT pg_current_wal_lsn();

SELECT pg_create_restore_point('before_data_migration');

CREATE PUBLICATION migration_pub FOR ALL TABLES;
SELECT pubname, puballtables FROM pg_publication;
DROP PUBLICATION migration_pub;

CREATE TABLE staging_clients AS SELECT * FROM clients WHERE 1 = 0;
COPY (SELECT * FROM clients ORDER BY client_id LIMIT 3 OFFSET 0)
    TO '/tmp/clients_batch_1.csv' WITH CSV HEADER;
COPY staging_clients FROM '/tmp/clients_batch_1.csv' WITH CSV HEADER;
UPDATE staging_clients SET name = UPPER(name);

CREATE TABLE clients_target (LIKE clients INCLUDING ALL);
INSERT INTO clients_target (client_id, name, age, balance) VALUES (1, 'Aidana', 15, 0);
INSERT INTO clients_target
SELECT * FROM staging_clients
ON CONFLICT (client_id) DO UPDATE
    SET name = EXCLUDED.name, balance = EXCLUDED.balance;
SELECT client_id, name, balance FROM clients_target ORDER BY client_id;

SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM products_import;

SELECT pid, usename, application_name, client_addr, state
FROM pg_stat_activity
WHERE application_name = 'pg_dump';

CREATE TABLE history_partitioned (client_id INT, product_id INT, date DATE) PARTITION BY RANGE (date);
CREATE TABLE history_2026_q3 PARTITION OF history_partitioned FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');
CREATE TABLE history_2026_q4 PARTITION OF history_partitioned FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');
INSERT INTO history_partitioned SELECT * FROM history;
SELECT tableoid::regclass AS partition, COUNT(*) FROM history_partitioned GROUP BY tableoid;
