--Unsupported SubQuery Expression '2': Only 1 SubQuery expression is supported. (state=42000,code=10249)
SELECT
  cd_gender,
  cd_marital_status,
  cd_education_status,
  COUNT(*) AS cnt1,
  cd_purchase_estimate,
  COUNT(*) AS cnt2,
  cd_credit_rating,
  COUNT(*) AS cnt3
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cd_demo_sk = c.c_current_cdemo_sk

LEFT JOIN (
  SELECT ss_customer_sk
  FROM store_sales
  JOIN date_dim ON ss_sold_date_sk = d_date_sk
  WHERE d_year = 2003 AND d_moy BETWEEN 2 AND 4
  GROUP BY ss_customer_sk
) ss ON c.c_customer_sk = ss.ss_customer_sk

LEFT JOIN (
  SELECT ws_bill_customer_sk
  FROM web_sales
  JOIN date_dim ON ws_sold_date_sk = d_date_sk
  WHERE d_year = 2003 AND d_moy BETWEEN 2 AND 4
  GROUP BY ws_bill_customer_sk
) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
  SELECT cs_ship_customer_sk
  FROM catalog_sales
  JOIN date_dim ON cs_sold_date_sk = d_date_sk
  WHERE d_year = 2003 AND d_moy BETWEEN 2 AND 4
  GROUP BY cs_ship_customer_sk
) cs ON c.c_customer_sk = cs.cs_ship_customer_sk
WHERE
  ca_state IN ('MO', 'MN', 'AZ')
  AND ss.ss_customer_sk IS NOT NULL  -- 原 EXISTS 条件
  AND ws.ws_bill_customer_sk IS NULL -- 原 NOT EXISTS 条件
  AND cs.cs_ship_customer_sk IS NULL -- 原 NOT EXISTS 条件
GROUP BY
  cd_gender,
  cd_marital_status,
  cd_education_status,
  cd_purchase_estimate,
  cd_credit_rating
ORDER BY
  cd_gender,
  cd_marital_status,
  cd_education_status,
  cd_purchase_estimate,
  cd_credit_rating
LIMIT 100;

