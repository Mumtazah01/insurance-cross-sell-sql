-- Insurance Cross-Sell Analysis
-- Tool: Google BigQuery (Sandbox)
-- Table: insurance-analysis-512107.insurance.customers (381,109 rows)


-- Query 1: Total customers, duplicate check and overall interest rate
SELECT
  COUNT(*) AS jumlah_pelanggan,
  COUNT(DISTINCT id) AS id_unik,
  COUNTIF(Response = 1) AS berminat,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus
FROM `insurance-analysis-512107.insurance.customers`;
-- Result: 381,109 customers, all IDs unique, 46,710 interested (12.3%)


-- Query 2: Blank cells and value ranges
SELECT
  COUNTIF(Gender IS NULL) AS kosong_gender,
  COUNTIF(Age IS NULL) AS kosong_umur,
  COUNTIF(Vehicle_Age IS NULL) AS kosong_umur_kenderaan,
  COUNTIF(Vehicle_Damage IS NULL) AS kosong_kerosakan,
  COUNTIF(Annual_Premium IS NULL) AS kosong_premium,
  MIN(Age) AS umur_min,
  MAX(Age) AS umur_max,
  MIN(Annual_Premium) AS premium_min,
  MAX(Annual_Premium) AS premium_max,
  ROUND(AVG(Annual_Premium), 0) AS premium_purata
FROM `insurance-analysis-512107.insurance.customers`;
-- Result: no blank cells, age 20 to 85, premium 2,630 to 540,165 (mean 30,564)


-- Query 3: Premium distribution
SELECT
  COUNTIF(Annual_Premium = 2630) AS premium_2630,
  ROUND(COUNTIF(Annual_Premium = 2630) / COUNT(*) * 100, 1) AS peratus_2630,
  APPROX_QUANTILES(Annual_Premium, 100)[OFFSET(50)] AS premium_median,
  APPROX_QUANTILES(Annual_Premium, 100)[OFFSET(99)] AS premium_persentil_99,
  COUNTIF(Annual_Premium > 100000) AS premium_atas_100k
FROM `insurance-analysis-512107.insurance.customers`;
-- Result: 64,877 customers (17.0%) pay the minimum premium of 2,630.
-- Median 31,667. 99th percentile 72,987. Only 778 customers above 100,000. No rows removed.


-- Query 4: Interest rate by age group
SELECT
  CASE
    WHEN Age < 30 THEN '20-29'
    WHEN Age < 40 THEN '30-39'
    WHEN Age < 50 THEN '40-49'
    WHEN Age < 60 THEN '50-59'
    ELSE '60+'
  END AS kumpulan_umur,
  COUNT(*) AS pelanggan,
  COUNTIF(Response = 1) AS berminat,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus
FROM `insurance-analysis-512107.insurance.customers`
GROUP BY kumpulan_umur
ORDER BY kumpulan_umur;


-- Query 5: Interest rate by existing insurance and past vehicle damage
SELECT
  Previously_Insured AS sudah_ada_insurans,
  Vehicle_Damage AS pernah_rosak,
  COUNT(*) AS pelanggan,
  COUNTIF(Response = 1) AS berminat,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus
FROM `insurance-analysis-512107.insurance.customers`
GROUP BY sudah_ada_insurans, pernah_rosak
ORDER BY kadar_minat_peratus DESC;


-- Query 6: Why do young customers show low interest
SELECT
  CASE
    WHEN Age < 30 THEN '20-29'
    WHEN Age < 40 THEN '30-39'
    WHEN Age < 50 THEN '40-49'
    WHEN Age < 60 THEN '50-59'
    ELSE '60+'
  END AS kumpulan_umur,
  ROUND(AVG(Previously_Insured) * 100, 1) AS peratus_sudah_ada_insurans,
  ROUND(COUNTIF(Vehicle_Damage) / COUNT(*) * 100, 1) AS peratus_pernah_rosak,
  ROUND(AVG(CASE WHEN Previously_Insured = 0 THEN Response END) * 100, 1) AS kadar_minat_belum_insurans
FROM `insurance-analysis-512107.insurance.customers`
GROUP BY kumpulan_umur
ORDER BY kumpulan_umur;


-- Query 7: Top 10 sales channels by number of customers
SELECT
  CAST(Policy_Sales_Channel AS INT64) AS saluran,
  COUNT(*) AS pelanggan,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS peratus_pelanggan,
  COUNTIF(Response = 1) AS berminat,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus,
  ROUND(AVG(Age), 0) AS purata_umur
FROM `insurance-analysis-512107.insurance.customers`
GROUP BY saluran
ORDER BY pelanggan DESC
LIMIT 10;


-- Query 8: Fair channel comparison, target group only
SELECT
  CAST(Policy_Sales_Channel AS INT64) AS saluran,
  COUNT(*) AS pelanggan_sasaran,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus
FROM `insurance-analysis-512107.insurance.customers`
WHERE Previously_Insured = 0
  AND Vehicle_Damage = TRUE
  AND Age BETWEEN 30 AND 59
  AND Policy_Sales_Channel IN (152, 26, 124, 160, 156, 122, 157, 154, 151, 163)
GROUP BY saluran
ORDER BY kadar_minat_peratus DESC;


-- Query 9: Size and value of the target group
SELECT
  CASE
    WHEN Previously_Insured = 0 AND Vehicle_Damage = TRUE AND Age BETWEEN 30 AND 59
    THEN 'Sasaran'
    ELSE 'Lain-lain'
  END AS kumpulan,
  COUNT(*) AS pelanggan,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS peratus_pelanggan,
  COUNTIF(Response = 1) AS berminat,
  ROUND(COUNTIF(Response = 1) / SUM(COUNTIF(Response = 1)) OVER () * 100, 1) AS peratus_berminat,
  ROUND(AVG(Response) * 100, 1) AS kadar_minat_peratus,
  APPROX_QUANTILES(Annual_Premium, 100)[OFFSET(50)] AS premium_median
FROM `insurance-analysis-512107.insurance.customers`
GROUP BY kumpulan;
