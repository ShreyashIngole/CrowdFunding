create  database crowdfunding;

use crowdfunding;

SHOW VARIABLES LIKE 'secure_file_priv';
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_projects_1.csv'
INTO TABLE crowdfunding_projects
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@Project_id, @Project_Status, @Project_name, @country, @creator_id, @location_id, @category_id,
 @Created_date, @Deadline_date, @Update_Date, @state_changed_date, @successful_Date, @launched_Date,
 @goal, @pledged, @usd_pledged, @static_usd_rate, @backers_count)
SET
    Project_id = NULLIF(@Project_id,''),
    Project_Status = NULLIF(@Project_Status,''),
    Project_name = NULLIF(@Project_name,''),
    country = NULLIF(@country,''),
    creator_id = NULLIF(@creator_id,''),
    location_id = NULLIF(@location_id,''),
    category_id = NULLIF(@category_id,''),
    Created_date = NULLIF(@Created_date,''),
    Deadline_date = NULLIF(@Deadline_date,''),
    Update_Date = NULLIF(@Update_Date,''),
    state_changed_date = NULLIF(@state_changed_date,''),
    successful_Date = NULLIF(@successful_Date,''),
    launched_Date = NULLIF(@launched_Date,''),
    goal = NULLIF(@goal,''),
    pledged = NULLIF(@pledged,''),
    usd_pledged = NULLIF(@usd_pledged,''),
    static_usd_rate = NULLIF(@static_usd_rate,''),
    backers_count = NULLIF(@backers_count,'');
    
    
CREATE TABLE crowdfunding_projects (
    Project_id BIGINT,
    Project_Status VARCHAR(50),
    Project_name LONGTEXT,
    country VARCHAR(10),
    creator_id BIGINT,
    location_id BIGINT,
    category_id INT,
    Created_date BIGINT,
    Deadline_date BIGINT,
    Update_Date BIGINT,
    state_changed_date BIGINT,
    successful_Date BIGINT,
    launched_Date BIGINT,
    goal DECIMAL(20,2),
    pledged DECIMAL(20,2),
    usd_pledged DECIMAL(20,2),
    static_usd_rate DECIMAL(10,2),
    backers_count INT
);

CREATE TABLE location (
    id BIGINT,
    displayable_name VARCHAR(500),
    type VARCHAR(50),
    name VARCHAR(500),
    state VARCHAR(50),
    short_name VARCHAR(100),
    country VARCHAR(10)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_Location.csv'
INTO TABLE location
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, displayable_name, type, name, state, short_name, country);

CREATE TABLE category (
    id BIGINT,
    name VARCHAR(500),
    parent_id BIGINT,
    position INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_Category.csv'
INTO TABLE category
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, parent_id, position);

CREATE TABLE creator (
    id INT,
    name LONGTEXT
);
 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Crowdfunding_Creator.csv'
INTO TABLE creator
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, @dummy1, @dummy2, @dummy3);

ALTER TABLE project MODIFY COLUMN blurb VARCHAR(1000);
DESCRIBE crowdfunding_projects;
describe creator;
describe location;
describe category;
select * from crowdfunding_projects;
select * from calendar;


-- q1
ALTER TABLE crowdfunding_projects
ADD COLUMN created_date_natural DATETIME,
ADD COLUMN deadline_date_natural DATETIME,
ADD COLUMN updated_date_natural DATETIME,
ADD COLUMN statechange_date_natural DATETIME,
ADD COLUMN successful_date_natural DATETIME,
ADD COLUMN launched_date_natural DATETIME;

UPDATE crowdfunding_projects
SET
    created_date_natural = FROM_UNIXTIME(created_date),
    deadline_date_natural = FROM_UNIXTIME(deadline_date),
    updated_date_natural = FROM_UNIXTIME(update_date),
    statechange_date_natural = FROM_UNIXTIME(state_changed_date),
    successful_date_natural = FROM_UNIXTIME(successful_date),
    launched_date_natural = FROM_UNIXTIME(launched_date);

ALTER TABLE crowdfunding_projects
DROP COLUMN created_date,
DROP COLUMN deadline_date,
DROP COLUMN update_date,
DROP COLUMN state_changed_date,
DROP COLUMN successful_date,
DROP COLUMN launched_date;

ALTER TABLE crowdfunding_projects
MODIFY COLUMN created_date_natural DATETIME AFTER category_id,
MODIFY COLUMN deadline_date_natural DATETIME AFTER created_date_natural,
MODIFY COLUMN updated_date_natural DATETIME AFTER deadline_date_natural,
MODIFY COLUMN statechange_date_natural DATETIME AFTER updated_date_natural,
MODIFY COLUMN successful_date_natural DATETIME AFTER statechange_date_natural,
MODIFY COLUMN launched_date_natural DATETIME AFTER successful_date_natural;

ALTER TABLE creator
MODIFY id BIGINT UNSIGNED;

ALTER TABLE crowdfunding_projects
MODIFY creator_id BIGINT UNSIGNED;

ALTER TABLE location
MODIFY id BIGINT UNSIGNED;

ALTER TABLE crowdfunding_projects
MODIFY location_id BIGINT UNSIGNED;

ALTER TABLE category
MODIFY id BIGINT UNSIGNED;

ALTER TABLE crowdfunding_projects
MODIFY category_id BIGINT UNSIGNED;

CREATE TABLE creator_backup AS SELECT * FROM creator;

RENAME TABLE creator_backup TO creator;

-- q2

use crowdfunding;
CREATE TABLE calendar (
    calendar_date DATE PRIMARY KEY,
    year INT,
    month_no INT,
    month_fullname VARCHAR(20),
    quarter VARCHAR(10),
    `year_month` VARCHAR(10),
    weekday_no INT,
    weekday_name VARCHAR(20),
    financial_month VARCHAR(10),
    financial_quarter VARCHAR(10)
);

SET @@cte_max_recursion_depth = 10000;

WITH RECURSIVE date_series AS (
    SELECT (SELECT MIN(DATE(created_date_natural)) FROM crowdfunding_projects) AS calendar_date
    UNION ALL
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE calendar_date < (SELECT MAX(DATE(created_date_natural)) FROM crowdfunding_projects)
)
SELECT
    calendar_date,
    YEAR(calendar_date) AS year,
    MONTH(calendar_date) AS month_no,
    DATE_FORMAT(calendar_date, '%M') AS month_fullname,
    CONCAT('Q', QUARTER(calendar_date)) AS quarter,
    DATE_FORMAT(calendar_date, '%Y-%b') AS `year_month`,
    DAYOFWEEK(calendar_date) AS weekday_no,
    DATE_FORMAT(calendar_date, '%W') AS weekday_name,
    CONCAT('FM', 
        CASE WHEN MONTH(calendar_date) >= 4 THEN MONTH(calendar_date)-3 ELSE MONTH(calendar_date)+9 END
    ) AS financial_month,
    CONCAT('FQ-', 
        CASE 
            WHEN MONTH(calendar_date) BETWEEN 4 AND 6 THEN 1
            WHEN MONTH(calendar_date) BETWEEN 7 AND 9 THEN 2
            WHEN MONTH(calendar_date) BETWEEN 10 AND 12 THEN 3
            ELSE 4
        END
    ) AS financial_quarter
FROM date_series;
describe calendar;
commit;

SELECT COUNT(*) FROM calendar;
SELECT * FROM calendar LIMIT 5;


-- q3

use crowdfunding;

CREATE TABLE creator_backup AS SELECT * FROM creator;
CREATE TABLE location_backup AS SELECT * FROM location;
CREATE TABLE category_backup AS SELECT * FROM category;

-- Remove orphan projects where creator_id does not exist
DELETE FROM crowdfunding_projects
WHERE creator_id NOT IN (SELECT id FROM creator);

-- Remove orphan projects where location_id does not exist
DELETE FROM crowdfunding_projects
WHERE location_id NOT IN (SELECT id FROM location);

-- Remove orphan projects where category_id does not exist
DELETE FROM crowdfunding_projects
WHERE category_id NOT IN (SELECT id FROM category);

-- Set AUTO_INCREMENT primary key for creator
ALTER TABLE creator
MODIFY id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Set AUTO_INCREMENT primary key for location
ALTER TABLE location
MODIFY id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Set AUTO_INCREMENT primary key for category
ALTER TABLE category
MODIFY id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE crowdfunding_projects
ADD CONSTRAINT fk_creator FOREIGN KEY (creator_id) REFERENCES creator(id),
ADD CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES location(id),
ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES category(id);

-- q4

use crowdfunding;

ALTER TABLE crowdfunding_projects
ADD COLUMN usd_goal_amount DECIMAL(15,2);

UPDATE crowdfunding_projects
SET usd_goal_amount = goal * static_usd_rate;

-- q5

use crowdfunding;
-- q5(a)
SELECT
    Project_Status,
    COUNT(*) AS total_projects
FROM crowdfunding_projects
GROUP BY Project_Status;

-- q5 (b)
CREATE INDEX idx_location_id ON crowdfunding_projects(location_id);
CREATE INDEX idx_location_location_id ON location(id);

SELECT
    l.name,
    counts.total_projects
FROM location l
JOIN (
    SELECT location_id, COUNT(*) AS total_projects
    FROM crowdfunding_projects
    GROUP BY location_id
) counts ON l.id = counts.location_id
WHERE l.name IS NOT NULL AND l.name != ''
ORDER BY counts.total_projects DESC;






-- q5(c)
SELECT
    c.name,
    COUNT(*) AS total_projects
FROM crowdfunding_projects p
JOIN category c ON p.category_id = c.id
GROUP BY c.name
ORDER BY total_projects DESC;

-- q5 (d)

-- By Year
SELECT
    YEAR(created_date_natural) AS year,
    COUNT(*) AS total_projects
FROM crowdfunding_projects
GROUP BY YEAR(created_date_natural)
ORDER BY year;

-- By Quarter
SELECT
    YEAR(created_date_natural) AS year,
    QUARTER(created_date_natural) AS quarter,
    COUNT(*) AS total_projects
FROM crowdfunding_projects
GROUP BY YEAR(created_date_natural), QUARTER(created_date_natural)
ORDER BY year, quarter;

-- By Month
SELECT
    YEAR(created_date_natural) AS year,
    MONTH(created_date_natural) AS month,
    COUNT(*) AS total_projects
FROM crowdfunding_projects
GROUP BY YEAR(created_date_natural), MONTH(created_date_natural)
ORDER BY year, month;


-- q6

use crowdfunding;

SELECT
    SUM(usd_goal_amount) AS total_amount_raised_usd
FROM crowdfunding_projects
WHERE Project_Status = 'successful';


SELECT
    SUM(backers_count) AS total_backers
FROM crowdfunding_projects
WHERE Project_Status = 'successful';

SELECT
    AVG(DATEDIFF(successful_date_natural, launched_date_natural)) AS avg_days_to_success
FROM crowdfunding_projects
WHERE Project_Status = 'successful';

-- q7

SELECT
    project_id,
    project_name,
    backers_count,
    usd_goal_amount,
    creator_id,
    location_id,
    category_id
FROM crowdfunding_projects
WHERE Project_Status = 'successful'
ORDER BY backers_count DESC
LIMIT 10;  -- top 10 projects


SELECT
    project_id,
    project_name,
    backers_count,
    usd_goal_amount,
    creator_id,
    location_id,
    category_id
FROM crowdfunding_projects
WHERE Project_Status = 'successful'
ORDER BY usd_goal_amount DESC
LIMIT 10;  -- top 10 projects

-- q8

use crowdfunding;

SELECT
    ROUND(
        100 * SUM(CASE WHEN project_status = 'successful' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_successful
FROM crowdfunding_projects;

SELECT
    cat.name,
    COUNT(*) AS total_projects,
    SUM(CASE WHEN p.Project_Status = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    ROUND(
        100 * SUM(CASE WHEN p.project_status = 'successful' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_successful
FROM crowdfunding_projects p
JOIN category cat ON p.category_id = cat.id
GROUP BY cat.name
ORDER BY pct_successful DESC;


-- By Year
SELECT
    YEAR(created_date_natural) AS year,
    COUNT(*) AS total_projects,
    SUM(CASE WHEN Project_Status = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    ROUND(
        100 * SUM(CASE WHEN project_status = 'successful' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_successful
FROM crowdfunding_projects
GROUP BY YEAR(created_date_natural)
ORDER BY year;

-- By Month
SELECT
    YEAR(created_date_natural) AS year,
    MONTH(created_date_natural) AS month,
    COUNT(*) AS total_projects,
    SUM(CASE WHEN Project_Status = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    ROUND(
        100 * SUM(CASE WHEN project_status = 'successful' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_successful
FROM crowdfunding_projects
GROUP BY YEAR(created_date_natural), MONTH(created_date_natural)
ORDER BY year, month;


SELECT
    CASE
        WHEN goal <= 5000 THEN '<= $5K'
        WHEN goal <= 10000 THEN '$5K - $10K'
        WHEN goal <= 50000 THEN '$10K - $50K'
        ELSE '> $50K'
    END AS goal_range,
    COUNT(*) AS total_projects,
    SUM(CASE WHEN Project_Status = 'successful' THEN 1 ELSE 0 END) AS successful_projects,
    ROUND(
        100 * SUM(CASE WHEN project_status = 'successful' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS pct_successful
FROM crowdfunding_projects
GROUP BY goal_range
ORDER BY total_projects DESC;




