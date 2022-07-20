
--An Ecommerce Customer Analysis using google_analytics_sample dataset from Google BigQuery public data. The analysis was performed on Google BigQuery with standardSQL.

#standardSQL

-- 1. Total visit, pageview, transaction and revenue for Jan, Feb and March 2017
SELECT
    FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month,
    COUNT(fullVisitorId) AS visits,
    SUM(totals.pageviews) AS views,
    SUM(totals.transactions) AS transactions,
    SUM(totals.totalTransactionRevenue)/POWER(10, 6) AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _table_suffix BETWEEN '20170101' AND '20170331'
GROUP BY month
ORDER BY month;

#month	visits	views	transactions	revenue
201701	64694	257708	713	106248.15
201702	62192	233373	733	116111.6
201703	69931	259522	993	150224.7



-- 2. Bounce rate per traffic source in July 2017
SELECT
    trafficSource.source AS source,
    SUM(totals.visits) AS total_visits,
    SUM(totals.bounces) AS total_no_of_bounces,
    (SUM(totals.bounces)/SUM(totals.visits)) AS bounce_rate
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;

#source	total_visits	total_no_of_bounces	bounce_rate
google	38400	19798	0.51557291666666671
(direct)	19891	8606	0.43265798602382988
youtube.com	6351	4238	0.66729648874193037
analytics.google.com	1972	1064	0.539553752535497
Partners	1788	936	0.52348993288590606
m.facebook.com	669	430	0.64275037369207777
google.com	368	183	0.49728260869565216
...



-- 3. Revenue by traffic source by week, by month in June 2017
WITH revenue_by_month AS(
    SELECT
        'Month' AS time_type,
        FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS time,
        trafficSource.source AS source,
        (SUM(totals.totalTransactionRevenue)/POWER(10, 6)) AS revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
    GROUP BY source, time
    ),

revenue_by_week AS(
    SELECT
        'Week' AS time_type,
        FORMAT_DATE("%Y%W",PARSE_DATE("%Y%m%d",date)) AS time,
        trafficSource.source AS source,
        (SUM(totals.totalTransactionRevenue)/POWER(10, 6)) AS revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
    GROUP BY source, time
    )

SELECT *
FROM revenue_by_month 
UNION ALL
SELECT *
FROM revenue_by_week
ORDER BY revenue DESC;

#time_type	time	source	revenue
Month	201706	(direct)	97231.62
Week	201724	(direct)	30883.91
Week	201725	(direct)	27254.32
Month	201706	google	18757.18
Week	201723	(direct)	17302.68
Week	201726	(direct)	14905.81
Week	201724	google	9217.17
Month	201706	dfa	8841.23
Week	201722	(direct)	6884.9
Week	201726	google	5330.57
...



-- 4. Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
WITH purchaser_data AS(
    SELECT
        FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month,
        (SUM(totals.pageviews)/COUNT(DISTINCT fullvisitorid)) AS avg_pageviews_purchase,
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    WHERE _table_suffix BETWEEN '0601' and '0731'
    AND totals.transactions>=1
    GROUP BY month
    ),

non_purchaser_data AS(
    SELECT 
        FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month,
        SUM(totals.pageviews)/COUNT(DISTINCT fullvisitorid) AS avg_pageviews_non_purchase,
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    GROUP BY month
    )

SELECT 
    *
FROM purchaser_data
LEFT JOIN non_purchaser_data
    ON purchaser_data.month = non_purchaser_data.month
ORDER BY purchaser_data.month;

#month	avg_pageviews_purchase	month_1	avg_pageviews_non_purchase
201706	25.735763097949885	201706	4.0745598761849484
201707	27.720954356846473	201707	4.1918408747077427



-- 5.  Average number of transactions per user that made a purchase in July 2017
SELECT
    FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month,
    (SUM(totals.transactions)/COUNT(DISTINCT fullvisitorid)) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
WHERE  totals.transactions>=1
GROUP BY month;

#month	Avg_total_transactions_per_user
201707	1.1120331950207469



-- 6. Average amount of money spent per session
SELECT
    FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month,
    ((SUM(totals.totalTransactionRevenue)
    /SUM(totals.visits))/POWER(10,6)) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
WHERE  totals.transactions IS NOT NULL
GROUP BY month;

#month	avg_revenue_by_user_per_visit
201707	155.90675072744909



-- 7. Products purchased by customers who purchased product A - YouTube Men's Vintage Henley
SELECT 
    product.v2productname AS other_purchased_product,
    SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE fullvisitorid IN (SELECT DISTINCT fullvisitorid
                        FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
                        UNNEST(hits) AS h,
                        UNNEST(h.product) AS p
                        WHERE p.v2productname = "YouTube Men's Vintage Henley"
                        AND h.eCommerceAction.action_type = '6')
AND product.v2productname != "YouTube Men's Vintage Henley"
AND product.productRevenue IS NOT NULL
GROUP BY other_purchased_product
ORDER BY quantity DESC;

#other_purchased_product	quantity
Google Sunglasses	20
Google Women's Vintage Hero Tee Black	7
SPF-15 Slim & Slender Lip Balm	6
Google Women's Short Sleeve Hero Tee Red Heather	4
YouTube Men's Fleece Hoodie Black	3
Google Men's Short Sleeve Badge Tee Charcoal	3
Android Wool Heather Cap Heather/Black	2
Crunch Noise Dog Toy	2
22 oz YouTube Bottle Infuser	2
Android Men's Vintage Henley	2
...



-- 8. Calculate Cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
WITH view_table AS(
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(*) AS num_product_view
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits
    WHERE hits.eCommerceAction.action_type = '2'
    AND _table_suffix BETWEEN '20170101' AND '20170331'
    GROUP BY month
),

addtocard_table AS(
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(*) AS num_addtocard
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits
    WHERE hits.eCommerceAction.action_type = '3'
    AND _table_suffix BETWEEN '20170101' AND '20170331'
    GROUP BY month
),

purchase_table AS(
    SELECT 
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d',date)) AS month,
        COUNT(*) AS num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
    WHERE hits.eCommerceAction.action_type = '6'
    AND _table_suffix BETWEEN '20170101' AND '20170331'
    GROUP BY month
)

SELECT 
    *,
    (a.num_addtocard/v.num_product_view)*100 AS addtocard_rate,
    (p.num_purchase/v.num_product_view)*100 AS purchase_rate
FROM view_table AS v
LEFT JOIN addtocard_table AS a USING(month)
LEFT JOIN purchase_table AS p USING(month)
ORDER BY v.month;

#month	num_product_view	num_addtocard	num_purchase	addtocard_rate	purchase_rate
201701	25787	7342	4328	28.471710551828437	16.783650676697562
201702	21489	7360	4141	34.250081437014288	19.270324351994045
201703	23549	8782	6018	37.292454032018348	25.555225274958598

