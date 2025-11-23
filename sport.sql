--DROP SCHEMA IF EXISTS sport CASCADE;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------- Creating Roles -------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Очистити старі ролі/користувачів
DROP ROLE IF EXISTS sport_admin;
DROP ROLE IF EXISTS sport_trainer;
DROP ROLE IF EXISTS sport_client;

DROP USER IF EXISTS sport_admin;
DROP USER IF EXISTS sport_trainer;
DROP USER IF EXISTS sport_client;

-- 2. Створення користувачів та призначення ролей. 
-- Створення користувачів
CREATE USER sport_admin WITH PASSWORD 'AdminPass123!';
CREATE USER sport_trainer WITH PASSWORD 'TrainerPass456!';
CREATE USER sport_client WITH PASSWORD 'ClientPass789!';

-- 3. Надати sport_admin право створювати об'єкти в базі.
GRANT CREATE ON DATABASE postgres TO sport_admin;

-- Перевірити права адміністратора на створення схеми.
SELECT has_database_privilege('sport_admin', current_database(), 'CREATE') AS can_create;


-- 4. Переключення на роль sport_admin
-- ВАЖЛИВО: Виконати створення об'єктів від імені sport_admin (оскільки скрипт виконується суперюзером).
SET ROLE sport_admin;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Перевіремо, що схема sport існує та ми підключені як суперкористувач або власник цієї схеми.
-- Подивитися, хто суперюзер:
SELECT usename, usesuper FROM pg_user;

SELECT rolname FROM pg_roles;

-- Крок 1: Перевірити, чи існує схема sport
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'sport';

-- Крок 2: Перевірити, хто є власником схеми sport
SELECT nspname AS schema_name, pg_roles.rolname AS owner    
FROM pg_namespace 										 	
JOIN pg_roles ON pg_roles.oid = pg_namespace.nspowner
WHERE nspname = 'sport';

-- Крок 3: Перевірити, чи я суперкористувач
SELECT rolsuper FROM pg_roles WHERE rolname = current_user;
-- дізнатися, під яким користувачем бази даних зараз підключені
SELECT current_user, session_user;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------- Creating Scheme ------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Створюємо схему та всі таблиці. Вони будуть належати sport_admin.
CREATE SCHEMA IF NOT exists sport;

SET search_path TO sport;

-- 1. Country
CREATE TABLE IF NOT exists sport.country (
    country_name TEXT PRIMARY KEY,
    phone_code TEXT NOT NULL UNIQUE
);

-- 2. Trainer
CREATE TABLE IF NOT exists sport.trainer (
    trainer_id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    presentation TEXT
);

-- 3. News
CREATE TABLE IF NOT exists sport.news (
    news_id SERIAL PRIMARY KEY,
    trainer_id INT REFERENCES trainer(trainer_id),  
    title TEXT,
    text_news TEXT,
    date_news TIMESTAMP,
    source TEXT,
    CONSTRAINT unique_trainer_title_date UNIQUE (trainer_id, title, date_news)
);

-- 4. Client
CREATE TABLE IF NOT exists sport.client (
    phone TEXT PRIMARY KEY,
    trainer_id INT REFERENCES trainer(trainer_id) ON DELETE SET NULL,
    country_name TEXT REFERENCES country(country_name),
    first_name_client TEXT,
    last_name_client TEXT,
    age SMALLINT NOT NULL,
    gender TEXT,
    notes_client TEXT,
    goal TEXT
);

-- 5. Review
CREATE TABLE IF NOT exists sport.review (
    client_phone TEXT PRIMARY KEY REFERENCES client(phone),
    rating NUMERIC,
    text_review TEXT,
    photo_review TEXT,
    created_at TIMESTAMP
);

-- 6. Progress
CREATE TABLE IF NOT exists sport.progress (
    progress_id SERIAL PRIMARY KEY,
    client_phone TEXT REFERENCES client(phone),
    date_progress TIMESTAMP,
    weight_client NUMERIC,
    measurements_client TEXT
);

-- 7. Schedule Trainer
CREATE TABLE IF NOT exists sport.schedule_trainer (
    schedule_id SERIAL PRIMARY KEY,
    trainer_id INT NOT NULL REFERENCES trainer(trainer_id),
    day DATE NOT NULL,
    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,
    location TEXT,
    is_available BOOLEAN DEFAULT TRUE
);

-- 8. Schedule Client
CREATE TABLE IF NOT exists sport.schedule_client (
    slot_id SERIAL PRIMARY KEY,
    schedule_id INT REFERENCES schedule_trainer(schedule_id) ON DELETE CASCADE,
    client_phone TEXT REFERENCES client(phone),
    status TEXT DEFAULT 'Pending'
);

-- 9. Package
CREATE TABLE IF NOT exists sport.package (
    package_id SERIAL PRIMARY KEY,
    client_phone TEXT REFERENCES client(phone),
    number_sessions INTEGER,
    price_package NUMERIC,
    valid DATE
);

-- 10. Session
CREATE TABLE IF NOT exists sport.session (
    session_id SERIAL PRIMARY KEY,
    slot_id INT REFERENCES schedule_client(slot_id),
    schedule_id INT REFERENCES schedule_trainer(schedule_id),
    package_id INT REFERENCES package(package_id),
    duration NUMERIC,
    type_session TEXT,
    status TEXT DEFAULT 'Planned'
);

-- 11. Discount
CREATE TABLE IF NOT exists sport.discount (
    discount_id SERIAL PRIMARY KEY,
    discount_type TEXT,
    discount_value NUMERIC,
    valid_from DATE,
    valid_to DATE
);

-- 12. Payment
CREATE TABLE IF NOT exists sport.payment (
    payment_id SERIAL PRIMARY KEY,
    client_phone TEXT REFERENCES client(phone),
    package_id INT REFERENCES package(package_id),
    discount_id INT REFERENCES discount(discount_id),
    date_payment TIMESTAMP,
    method TEXT,
    status TEXT
);

/*
Індекси для Foreign Keys: in case f they would not be created at the time of making the table. 
Since FK were made already, we do not use this part of the code. 
CREATE INDEX idx_schedule_trainer_trainer_id ON sport.schedule_trainer(trainer_id);
CREATE INDEX idx_schedule_client_schedule_id ON sport.schedule_client(schedule_id);
CREATE INDEX idx_client_trainer_id ON sport.client(trainer_id);
CREATE INDEX idx_client_country_name ON sport.client(country_name);
CREATE INDEX idx_review_client_phone ON sport.review(client_phone);
CREATE INDEX idx_package_client_phone ON sport.package(client_phone);
CREATE INDEX idx_session_slot_id ON sport.session(slot_id);
CREATE INDEX idx_session_package_id ON sport.session(package_id);
CREATE INDEX idx_payment_client_phone ON sport.payment(client_phone);
CREATE INDEX idx_payment_package_id ON sport.payment(package_id);
CREATE INDEX idx_payment_discount_id ON sport.payment(discount_id);
CREATE INDEX idx_progress_client_phone ON sport.progress(client_phone);
CREATE INDEX idx_news_trainer_id ON sport.news(trainer_id);
 */

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------- Inserting Data Into Tables -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Table: country
INSERT INTO sport.country(country_name, phone_code)
VALUES
  ('Norway', '+47'),
  ('Sweden', '+46'),
  ('Denmark', '+45'),
  ('Germany', '+49'),
  ('Poland', '+48');


-- Table: trainer
INSERT INTO trainer (first_name, last_name, presentation)
VALUES 
('Alex', 'Bond', 'Fitness, None');


-- Table: client
INSERT INTO sport.client(phone, trainer_id, country_name, first_name_client, last_name_client, age, gender, notes_client, goal)
SELECT
  '+47' || (10000000 + floor(random()*90000000))::text AS phone,
  (SELECT trainer_id FROM sport.trainer ORDER BY random() LIMIT 1) AS trainer_id,
  (ARRAY['Norway','Sweden','Denmark','Germany','Poland'])[floor(random()*5)+1] AS country_name,
  (ARRAY['Anna','Mark','Eva','Fred','Ingrid','Oliver'])[floor(random()*6)+1] AS first_name_client,
  (ARRAY['Hansen','Lund','Berg','Kroll','Schmidt','Kovalski'])[floor(random()*6)+1] AS last_name_client,
  (18 + floor(random()*50))::smallint AS age,
  (ARRAY['M','F'])[floor(random()*2)+1] AS gender,
  'Notes ' || floor(random()*100) AS notes_client,
  (ARRAY['Lose weight','Build muscle','Maintain fitness'])[floor(random()*3)+1] AS goal
FROM generate_series(1,100);


-- Table: progress
INSERT INTO sport.progress(client_phone, date_progress, weight_client, measurements_client)
SELECT
  c.phone AS client_phone,
  (current_date - (floor(random()*365) || ' days')::interval + (floor(random()*86400) || ' seconds')::interval) AS date_progress,
  (50 + random()*50)::numeric(5,2) AS weight_client,
  'Measurements: ' || (floor(random()*100)+10)::int || ' cm' AS measurements_client
FROM sport.client c
ORDER BY random()
LIMIT 200;


-- Table: schedule_trainer
INSERT INTO sport.schedule_trainer(trainer_id, day, start_at, finish_at, location, is_available)
SELECT
  (SELECT trainer_id FROM sport.trainer ORDER BY random() LIMIT 1), -- випадковий тренер
  (current_date + (gs || ' days')::interval)::date,
  (current_timestamp + (gs * interval '1 day') + (floor(random()*10) || ' hours')::interval),
  (current_timestamp + (gs * interval '1 day') + (floor(random()*10 + 1) || ' hours')::interval),
  (ARRAY['Gym A','Gym B','Outdoor Park','Home Visit'])[floor(random()*4)::int + 1],
  TRUE
FROM generate_series(1, 30) AS gs;


-- Table: schedule_client
INSERT INTO sport.schedule_client(schedule_id, client_phone, status)
SELECT
  s.schedule_id,
  (SELECT phone FROM sport.client ORDER BY random() LIMIT 1) AS client_phone,
  (ARRAY['Pending','Confirmed','Cancelled'])[floor(random()*3)+1] AS status
FROM sport.schedule_trainer s
WHERE s.is_available = TRUE
ORDER BY random()
LIMIT 80;

-- Заполним schedule_client с уникальными client_phone
INSERT INTO sport.schedule_client(schedule_id, client_phone, status)
SELECT
  s.schedule_id,
  c.phone,
  (ARRAY['Pending','Confirmed','Cancelled'])[floor(random()*3)+1]
FROM sport.schedule_trainer s
JOIN sport.client c ON TRUE
WHERE s.is_available = TRUE
ORDER BY random()
LIMIT 50;


-- Table: package
INSERT INTO sport.package(client_phone, number_sessions, price_package, valid)
SELECT
  c.phone,
  (5 + floor(random()*10))::int AS number_sessions,
  (100 + random()*400)::numeric(7,2) AS price_package,
  (current_date + (floor(random()*365))::int) AS valid
FROM sport.client c
ORDER BY random()
LIMIT 50;

-- Добавим package только тем клиентам, у кого его нет.
INSERT INTO sport.package(client_phone, number_sessions, price_package, valid)
SELECT
  DISTINCT sc.client_phone,
  (5 + floor(random()*10))::int,
  (100 + random()*400)::numeric(7,2),
  (current_date + (floor(random()*365) || ' days')::interval)::date
FROM sport.schedule_client sc
LEFT JOIN sport.package p ON sc.client_phone = p.client_phone
WHERE p.client_phone IS NULL;


-- Table: session
INSERT INTO sport.session(slot_id, schedule_id, package_id, duration, type_session, status)
SELECT
  sc.slot_id,
  sc.schedule_id,
  p.package_id,
  (30 + floor(random()*90))::numeric(5,0),
  (ARRAY['Strength','Cardio','Yoga','Pilates'])[floor(random()*4)+1],
  (ARRAY['Planned','Completed','Cancelled'])[floor(random()*3)+1]
FROM sport.schedule_client sc
JOIN sport.package p ON p.client_phone = sc.client_phone
ORDER BY random()
LIMIT 50;


-- Table: news (with CROSS JOIN and UNNEST)
INSERT INTO sport.news (trainer_id, title, text_news, date_news, source)
SELECT
  t.trainer_id,
  title,
  'News about ' || title || ' - ' || floor(random()*100)::text || ' details' AS text_news,
  current_date - (gs || ' days')::interval + (floor(random()*86400) || ' seconds')::interval AS date_news,
  source
FROM sport.trainer t
CROSS JOIN UNNEST(ARRAY[
  'Training Tips',
  'Nutrition Advice',
  'Workout Plan',
  'Client Success',
  'New Program'
]) AS titles(title)
CROSS JOIN UNNEST(ARRAY[
  'Website',
  'Instagram',
  'YouTube',
  'Newsletter'
]) AS sources(source)
CROSS JOIN generate_series(1, 2) AS gs
ORDER BY random()
LIMIT 20;


-- Table: review (згенерувати і вставити 20 записів з випадковими, але перемішаними рейтингами).
WITH ratings AS (
  SELECT unnest(ARRAY[
    1,2,3,4,5,
    1,2,3,4,5,
    1,2,3,4,5,
    1,2,3,4,5
  ]) AS rating
),
shuffled_ratings AS (
  SELECT rating, row_number() OVER () AS rn
  FROM ratings
  ORDER BY random()
  LIMIT 20
),
clients AS (
  SELECT phone, row_number() OVER () AS rn
  FROM (
    SELECT phone
    FROM sport.client
    ORDER BY random()
    LIMIT 20
  ) sub
)
INSERT INTO sport.review(client_phone, rating, text_review, photo_review, created_at)
SELECT
  c.phone,
  r.rating,
  'Great experience! Review #' || r.rn,
  'review_photo_' || floor(random()*1000)::text || '.jpg',
  current_timestamp - (floor(random()*365) || ' days')::interval
FROM clients c
JOIN shuffled_ratings r ON c.rn = r.rn;


-- Table: discount (вставка 5 стандартних знижок).
INSERT INTO sport.discount(discount_type, discount_value, valid_from, valid_to)
VALUES
  ('Welcome Bonus', 10, current_date, current_date + interval '30 days'),
  ('Seasonal Offer', 15, current_date - interval '10 days', current_date + interval '20 days'),
  ('Black Friday', 25, '2025-11-29', '2025-12-01'),
  ('Old Client', 20, NULL, NULL), -- одноразова, без термінів
  ('Referral', 5, current_date, current_date + interval '60 days');


-- Table: payment 
INSERT INTO sport.payment(client_phone, package_id, discount_id, date_payment, method, status)
SELECT
  c.phone,
  p.package_id,
  d.discount_id,
  current_timestamp - (floor(random()*200) || ' days')::interval,
  (ARRAY['Card', 'Cash', 'Bank Transfer'])[floor(random()*3 + 1)],
  (ARRAY['Completed', 'Pending', 'Failed'])[floor(random()*3 + 1)]
FROM sport.client c
JOIN sport.package p ON p.client_phone = c.phone
JOIN sport.discount d ON TRUE
ORDER BY random()
LIMIT 50;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------- Establishing Roles and Rights, Limitations  -----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Повертаємо роль після створення об’єктів.
RESET ROLE;

-- Обмежений доступ для sport_trainer
-- Можна читати дані про клієнтів, свій графік, додавати новини
GRANT USAGE ON SCHEMA sport TO sport_trainer;
GRANT SELECT, INSERT, UPDATE ON sport.client TO sport_trainer;
GRANT SELECT, INSERT, UPDATE ON sport.news TO sport_trainer;
GRANT SELECT, INSERT, UPDATE ON sport.schedule_trainer TO sport_trainer;
GRANT SELECT ON sport.review TO sport_trainer;
GRANT SELECT ON sport.progress TO sport_trainer;


-- Обмежений доступ для sport_client
-- Можна бачити лише свої записи, додавати/переглядати прогрес, писати рев'ю, записуватись на сесії
GRANT USAGE ON SCHEMA sport TO sport_client;
GRANT SELECT, INSERT, UPDATE ON sport.progress TO sport_client;
GRANT SELECT, INSERT, UPDATE ON sport.schedule_client TO sport_client;
GRANT SELECT, INSERT, UPDATE ON sport.payment TO sport_client;

GRANT SELECT, INSERT ON sport.review TO sport_client;							-- для доступу тільки до своїх записів потрібно додавати Row-Level Security, але це вже пізніше. Поки що так. 
REVOKE UPDATE, DELETE ON sport.review FROM sport_client;

GRANT SELECT ON sport.package TO sport_client;
GRANT SELECT ON sport.session TO sport_client;


--- 3.4. Безпека за замовчуванням (заборона доступ до схеми sport всім іншим, хто не має ролі).
REVOKE ALL ON SCHEMA sport FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA sport FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA sport FROM PUBLIC;


-------------------------- Перевірка ролей та прав, обмежень --------------------------------------------------------------------------------------

-- Подивитися всіх користувачів (ролі)
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles;

-- Перевірити права доступу до таблиць (GRANT)
-- Для конкретної таблиці:
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'client';

-- До всіх таблиць схеми:
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'sport';

-- Хто є власником таблиць:
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'sport';

-- Всі ролі, їх типи та чи мають пароль:
SELECT rolname,
       rolcanlogin AS can_login,
       rolsuper AS is_superuser,
       rolcreatedb AS can_create_db,
       rolcreaterole AS can_grant_roles,
       rolvaliduntil AS password_expiry
FROM pg_roles;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------ Statistics, Analytics ------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Вплив знижок — загальна сума знижок і частка «втраченого» доходу.
WITH pn AS (
  SELECT
    p.payment_id,
    ROUND(pk.price_package,2) AS gross_amount,
    ROUND(pk.price_package * (COALESCE(d.discount_value,0)::numeric / 100.0),2) AS discount_amount,
    ROUND(pk.price_package * (1 - COALESCE(d.discount_value,0)::numeric / 100.0),2) AS net_amount
  FROM sport.payment p
  JOIN sport.package pk ON pk.package_id = p.package_id
  LEFT JOIN sport.discount d ON d.discount_id = p.discount_id
  WHERE p.status = 'Completed'
)
SELECT
  SUM(gross_amount) AS gross_revenue,
  SUM(discount_amount) AS total_discounts,
  SUM(net_amount) AS net_revenue,
  ROUND( CASE WHEN SUM(gross_amount)=0 THEN 0 ELSE SUM(discount_amount)/SUM(gross_amount)*100 END, 2) AS discount_share_pct
FROM pn;


-------------------------------------------------------------------------------------------------------------------------
-- Доходи за країнами (топ країн) — приєднання через client.
WITH pn AS (
  SELECT
    p.payment_id,
    p.client_phone,
    ROUND(pk.price_package * (1 - COALESCE(d.discount_value,0)::numeric / 100.0), 2) AS net_amount
  FROM sport.payment p
  JOIN sport.package pk ON pk.package_id = p.package_id
  LEFT JOIN sport.discount d ON d.discount_id = p.discount_id
  WHERE p.status = 'Completed'
)
SELECT
  c.country_name,
  COUNT(DISTINCT pn.client_phone) AS unique_payers,
  COUNT(pn.payment_id) AS payments_count,
  SUM(pn.net_amount) AS total_revenue,
  ROUND( SUM(pn.net_amount) / NULLIF(COUNT(DISTINCT pn.client_phone),0)::numeric, 2) AS revenue_per_payer
FROM pn
JOIN sport.client c ON c.phone = pn.client_phone
GROUP BY c.country_name
ORDER BY total_revenue DESC;


-------------------------------------------------------------------------------------------------------------------------
/*  Загальний фінансово-аналітичний звіт по тренуваннях:
- підрахунок кількості занять за типом (Strength, Yoga, тощо);
- середня тривалість, середня ціна за сесію та дохід по сесіях;
- дохід тільки за завершені тренування (status='Completed').
*/

WITH session_info AS (
  SELECT
    s.session_id,
    s.type_session,
    s.status,
    s.duration,
    st.trainer_id,
    sc.client_phone,
    p.price_package,
    p.number_sessions,
    ROUND(p.price_package / NULLIF(p.number_sessions,0), 2) AS price_per_session
  FROM sport.session s
  JOIN sport.schedule_trainer st ON st.schedule_id = s.schedule_id
  JOIN sport.schedule_client sc ON sc.slot_id = s.slot_id
  JOIN sport.package p ON p.package_id = s.package_id
)
SELECT
  type_session,
  COUNT(*) AS total_sessions,
  SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_sessions,
  ROUND(AVG(duration),2) AS avg_duration_min,
  ROUND(AVG(price_per_session),2) AS avg_price_per_session,
  ROUND(SUM(CASE WHEN status='Completed' THEN price_per_session ELSE 0 END),2) AS total_realized_revenue
FROM session_info
GROUP BY type_session
ORDER BY total_realized_revenue DESC;


-------------------------------------------------------------------------------------------------------------------------
-- Базовий розподіл занять за типом локації.
WITH session_location AS (
  SELECT
    s.session_id,
    st.location,
    s.status,
    date_trunc('month', st.day)::date AS month,
    CASE
      WHEN LOWER(st.location) LIKE '%gym%' THEN 'Gym'
      WHEN LOWER(st.location) LIKE '%online%' OR LOWER(st.location) LIKE '%home%' THEN 'Online'
      WHEN LOWER(st.location) LIKE '%outdoor%' THEN 'Outdoor'
      ELSE 'Other'
    END AS place_type
  FROM sport.session s
  JOIN sport.schedule_trainer st ON st.schedule_id = s.schedule_id
  WHERE s.status IN ('Planned', 'Completed')
)
SELECT
  place_type,
  COUNT(*) AS total_sessions,
  ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percent_sessions
FROM session_location
GROUP BY place_type
ORDER BY percent_sessions DESC;


-------------------------------------------------------------------------------------------------------------------------
/* З використанням LAG.
Динаміка платежів клієнтів (payment): порівняємо поточний платіж із попереднім за сумою або датою.
- days_since_prev_payment — показник частоти оплати або затримок.
*/

SELECT
    client_phone,
    date_payment,
    package_id,
    status,
    LAG(date_payment) OVER (PARTITION BY client_phone ORDER BY date_payment) AS prev_payment_date,
    date_payment - LAG(date_payment) OVER (PARTITION BY client_phone ORDER BY date_payment) AS days_since_prev_payment,
    LAG(package_id) OVER (PARTITION BY client_phone ORDER BY date_payment) AS prev_package_id
FROM sport.payment
ORDER BY client_phone, date_payment;


-------------------------------------------------------------------------------------------------------------------------
/* З використанням LEAD.
Наступна тренувальна сесія клієнта (session): можна використати для створення нагадувань або аналітики активності.
LEAD(st.day) показує дату наступного тренування.
 */

SELECT 
    c.phone AS client_phone,
    st.day AS current_session_date,
    LEAD(st.day) OVER (PARTITION BY c.phone ORDER BY st.day) AS next_session_date,
    LEAD(st.day) OVER (PARTITION BY c.phone ORDER BY st.day) - st.day AS days_until_next_session,
    s.type_session,
    s.status
FROM sport.session s
JOIN sport.schedule_client sc ON s.slot_id = sc.slot_id
JOIN sport.client c ON sc.client_phone = c.phone
JOIN sport.schedule_trainer st ON s.schedule_id = st.schedule_id
ORDER BY c.phone, st.day;

