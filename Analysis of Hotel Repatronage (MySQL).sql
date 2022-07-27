
/*
This is an analysis on the  “repatronage assignment database.sql” containing contains two tables:
“repatronage_review_assignment” and “repatronage_user_assignment”.
The database file includes all the reviews pertinent to TWO popular German hotels.
*/

SELECT *
FROM courseassignment.repatronage_review_assignment;

SELECT * 
FROM courseassignment.repatronage_user_assignment;

/*
1. Question 1: A user may visit the same hotel multiple times.
We want to know travelers from which country are more likely to revisit these hotels.
Thus, please compute the possibility that users from a specific country will revisit the same hotel.
*/

WITH repat AS(
-- Find the repatronage customers from each hotels
	SELECT
		hotel_id,
		user_id
	FROM repatronage_review_assignment
	GROUP BY 
		hotel_id,
		user_id
	HAVING COUNT(user_id)>1),

total AS(
-- Count all customers from each countries
    SELECT
	country,
	COUNT(DISTINCT user_id) AS total_user
	FROM repatronage_user_assignment
	GROUP BY country)

-- Calculate the likelihood of revisit of customers from each country
SELECT
	COUNT(DISTINCT repat.user_id)/total.total_user AS repat_ratio,
    user_table.country
FROM repat
JOIN repatronage_user_assignment AS user_table
	ON repat.user_id = user_table.user_id
JOIN total
	ON user_table.country = total.country
GROUP BY user_table.country
ORDER BY repat_ratio DESC;


/*
Question 2: Please compare the average hotel ratings given by re-patronage travelers
with regard to their first and second visits to the same hotel.
*/

WITH repat_rating AS(
	WITH repat AS(
	-- Find the repatronage customers from each hotels
		SELECT
			hotel_id,
			user_id
		FROM repatronage_review_assignment
		GROUP BY 
			hotel_id,
			user_id
		HAVING COUNT(user_id)>1)

	-- Find the ratings of repatronage
	SELECT
		review_table.hotel_id,
		review_table.user_id,
		review_date,
		overall_rating,
		rooms_rating,
		service_rating, 
		location_rating,
		value_rating,
	-- Sort by order of visit
	ROW_NUMBER() OVER (PARTITION BY
				review_table.hotel_id,
				review_table.user_id
				ORDER BY review_date) AS row_num
	FROM repatronage_review_assignment AS review_table
	JOIN repat 
		ON review_table.hotel_id = repat.hotel_id
		AND review_table.user_id = repat.user_id)

-- Calculate average ratings of first and second visits
SELECT
	row_num AS visit_order,
	AVG(overall_rating),
	AVG(rooms_rating),
	AVG(service_rating),
	AVG(location_rating),
	AVG(value_rating) 
FROM repat_rating
WHERE row_num < 3
GROUP BY row_num;


/*
Question 9.3. Compared the first lodging date and second lodging date of re-patronage travelers to the same hotel.
Which hotel tends to have the shortest average time between the first and second lodging dates of re-patronage travelers?
Please use review_date as lodging date.
*/

WITH repat_lodging AS(
	WITH repat AS(
	-- Find the repatronage customers from each hotels
		SELECT
			hotel_id,
			user_id
		FROM repatronage_review_assignment
		GROUP BY 
			hotel_id,
			user_id
		HAVING COUNT(user_id)>1)

	-- Sort by loging date
	SELECT
		review_table.hotel_id,
		review_table.user_id,
		review_date,
	ROW_NUMBER() OVER (PARTITION BY
				review_table.hotel_id,
			   	review_table.user_id
				ORDER BY review_date) AS row_num
	FROM repatronage_review_assignment AS review_table
	JOIN repat 
		ON review_table.hotel_id = repat.hotel_id
		AND review_table.user_id = repat.user_id)

-- Calculate the time interval between first and second lodging
SELECT
	t1.hotel_id,
    AVG(DATEDIFF(t2.review_date, t1.review_date)) AS avg_diff
FROM repat_lodging AS t1
JOIN repat_lodging AS t2
	ON t1.hotel_id = t2.hotel_id
    AND t1.user_id = t2.user_id
WHERE t1.row_num = 1
AND t2.row_num = 2
GROUP BY hotel_id
ORDER BY avg_diff;


