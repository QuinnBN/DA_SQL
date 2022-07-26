/*

The dataset used for the analysis was extracted from Wolt’s customer purchase process in the period between March 2020 and October 2020, divided into two data files.
  The “first_purchases” file includes details about users’ first ever purchases and
  the “purchases” file contain details about all purchases (excluding the first purchase) of these users from Wolt.
Both data files contain information about the user ID, purchase date, purchase ID, venue ID, and the product line of the purchase.

The analysis was performed in BigQuery with standard SQL. The SQL script is shared below and can also be accessed using these following links:
  Retention analysis for restaurant line: https://console.cloud.google.com/bigquery?sq=777797998756:72527506e4c5429db64b769615025bf4
  Retention analysis for retail line: https://console.cloud.google.com/bigquery?sq=777797998756:e0d8cadf4eeb458883f01b8b9c5e1223

*/


WITH res_first_total AS(
--Count monthly fisrt purchases
    SELECT
        COUNT(user_id) AS cohort_size,
        FORMAT_DATE("%m%Y", PARSE_DATE("%d.%m.%y", first_purchase_date)) AS cohort_month
    FROM `wolt-339715.Wolt_assignment.first_purchases`
    WHERE product_line = 'Restaurant'
    GROUP BY cohort_month
),

res_all_purchases AS(
--Combine first purchases and repurchases
    SELECT 
        FORMAT_DATE("%m%Y", PARSE_DATE("%d.%m.%y", t1.first_purchase_date)) AS cohort_month,
        FORMAT_DATE("%m%Y", PARSE_DATE("%d.%m.%y", t2.purchase_date)) AS purchase_month,
        DATE_DIFF(PARSE_DATE("%d.%m.%y", purchase_date), PARSE_DATE("%d.%m.%y", first_purchase_date), MONTH) AS month_diff,
        t1.user_id
    FROM `wolt-339715.Wolt_assignment.first_purchases` AS t1
    FULL JOIN `wolt-339715.Wolt_assignment.purchases` AS t2
        USING(user_id)
    WHERE t1.product_line = 'Restaurant'
)
--Count monthly retained users and calculate retention rate
SELECT 
    cohort_month,
    month_diff,
    cohort_size,
    COUNT(DISTINCT res_all_purchases.user_id) AS num_repurchasers,
    ROUND(COUNT(DISTINCT res_all_purchases.user_id)/cohort_size, 4) AS retention_rate
FROM res_all_purchases
FULL JOIN res_first_total USING(cohort_month)
WHERE month_diff !=0
GROUP BY
    cohort_month,
    cohort_size,
    month_diff
ORDER BY
    cohort_month,
    month_diff;
