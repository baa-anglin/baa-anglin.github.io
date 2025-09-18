-- Data Cleaning
SELECT *
FROM layoffs

/*  -- 1. Remove Duplicates
	-- 2. Standardize the data
	-- 3. Look at the NULL and blank values
	-- 4. Remove unnecessary columns or rows */

 /* Inserting the data into the newly created stage table as to not work on Raw data */
 
DROP TABLE IF EXISTS layoffs_staging;

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

 /* Finding dupliactes and double checking if they are correct */
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

 /* Creating a second stage table that will include the row number column that indicates if 
something is a duplicate by being >1, such that we will be able to delete the rows from this table
since you cannoy update a CTE */

DROP TABLE IF EXISTS layoffs_staging2; 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

/* Inserts the data from the original layoffs_staging as well as the additional row num row I created */
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

/* Deleting duplicate data from the layoffs_staging2 table where the row_num is greater than 1 */
SELECT *
FROM layoffs_staging2
where row_num>1;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;


/* Updating the company name to not have white space surrounding */
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET company = TRIM(company);

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

/* UPDATING the industry titles that are the same but have slightly different titles*/
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging2
SET industry= 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
From layoffs_staging2;

/* UPDATNG the United States to one correct version (there is a duplicate with a period) */
SELECT DISTINCT country
From layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country= 'United States'
WHERE country LIKE 'United States%';

/* ## update the date column from a string to a date */
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

/* LOOKING for NULL or empty columns and decide what our next steps should be */

SELECT DISTINCT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 t1
JOIN  layoffs_staging2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL; 

UPDATE layoffs_staging2
SET industry= NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN  layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

/* REMOVING the rows of data that do not have layoff metrics stated as they are not insightful*/

SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

/* REMOVING the row_num col as it serves no purpose now*/

ALTER TABLE layoffs_staging2
DROP COLUMN `row_num`;

SELECT *
FROM layoffs_staging2;
