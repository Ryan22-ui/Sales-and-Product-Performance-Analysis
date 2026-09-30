DROP TABLE raw_data
CREATE TABLE raw_data (
    USER_ID TEXT,
    ORDER_ID VARCHAR(255),
    PURCHASE_TS TEXT,
    PURCHASE_Date DATE,
    PURCHASE_MONTH  DATE,
    SHIP_TS TEXT,
    PRODUCT_NAME TEXT,
    PRODUCT_ID TEXT,
    USD_PRICE TEXT,
    PURCHASE_PLATFORM TEXT,
    MARKETING_CHANNEL TEXT,
    ACCOUNT_CREATION_METHOD TEXT,
    COUNTRY_CODE TEXT,
    REGION VARCHAR(10)
);

COPY raw_data FROM 'D:\#syren_workspace\GamerGear_ecom2\data\gamergear_dataset.csv' WITH (FORMAT csv, HEADER true);

SELECT * FROM raw_data;


SELECT DISTINCT(product_name)
FROM raw_data;


SELECT product_name
FROM raw_data
WHERE product_name = '27in 4k gaming monitor';

UPDATE raw_data
SET product_name = '27in 4k gaming monitor'
WHERE product_name = '27in 4K gaming monitor';



SELECT
    order_id,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT user_id) AS unique_customers

FROM raw_data
GROUP BY order_id
HAVING COUNT(*) > 1;




-----------------------

SELECT *,
    COUNT(*) AS duplicate_value


--DIMENSIONS 


-- product dimension
CREATE TABLE dim_products (
    product_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id VARCHAR(50),
    product_name VARCHAR(150)
);
INSERT INTO dim_products(
    product_id,
    product_name
)
SELECT DISTINCT
    product_id,
    product_name
FROM raw_data
WHERE product_id IS NOT NULL;

SELECT *
FROM dim_products


-- geography dimension
DROP TABLE dim_geography
CREATE TABLE dim_geography (
    geo_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code VARCHAR(10),
    region VARCHAR(10)
);
INSERT INTO dim_geography(
    country_code,
    region
)
SELECT DISTINCT
    country_code,
    COALESCE(region, 'UNKNOWN')
FROM raw_data;
SELECT *
FROM dim_geography

--platform dimension
CREATE TABLE   dim_platform(
    platform_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PURCHASE_PLATFORM VARCHAR(120)
);
INSERT INTO dim_platform(
    PURCHASE_PLATFORM
)
SELECT DISTINCT
    PURCHASE_PLATFORM
FROM raw_data;

CREATE TABLE   dim_marketing(
    marketing_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    MARKETING_CHANNEL VARCHAR(120)
);
INSERT INTO dim_marketing(
    MARKETING_CHANNEL
)
SELECT DISTINCT
    MARKETING_CHANNEL
FROM raw_data;


-- user_dimension

CREATE TABLE dim_user(
    user_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id TEXT,
    ACCOUNT_CREATION_METHOD VARCHAR(120)
);
INSERT INTO dim_user(
    user_id,
    ACCOUNT_CREATION_METHOD
)
SELECT DISTINCT
    user_id,
    ACCOUNT_CREATION_METHOD
FROM raw_data;




CREATE TABLE dim_date (
    date_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PURCHASE_TS TEXT,
    PURCHASE_Date DATE,
    PURCHASE_MONTH DATE
);
INSERT INTO dim_date(
    PURCHASE_TS,
    PURCHASE_Date,
    PURCHASE_MONTH
)
SELECT DISTINCT
    PURCHASE_TS,
    PURCHASE_Date,
    PURCHASE_MONTH
FROM raw_data;


SELECT *
FROM dim_date;


--- STAGE TABLE


DROP TABLE IF EXISTS stg_tb;
CREATE TABLE stg_sales AS
SELECT DISTINCT
    user_id,
    order_id,
    purchase_ts,
    purchase_date,
    purchase_month,
    ship_ts,
    product_name,
    product_id,
    CAST(usd_price AS NUMERIC(12,2)) AS usd_price,
    PURCHASE_PLATFORM,
    MARKETING_CHANNEL,
    ACCOUNT_CREATION_METHOD,
    country_code,
    region
FROM raw_data;

SELECT COUNT(*) FROM raw_data;

SELECT COUNT(*) FROM stg_sales;

SELECT
    (SELECT COUNT(*) FROM raw_data)
    -
    (SELECT COUNT(*) FROM stg_sales)
    AS exact_duplicates_removed;


CREATE TABLE stg_orders AS
    SELECT
        order_id,
        
        CASE
            WHEN COUNT(DISTINCT user_id) = 1
                THEN MIN(user_id)
            ELSE 'UNknown_user'
        END AS user_id,

        product_id,
        product_name,
        purchase_date,
        purchase_month,
        usd_price,
        purchase_platform,
        marketing_channel,
        country_code,
        region
    
FROM stg_orders

WHERE order_id IS NOT NULL

GROUP BY
    order_id,
    product_id,
    product_name,
    purchase_date,
    purchase_month,
    usd_price,
    purchase_platform,
    marketing_channel,
    country_code,
    region;