-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

/* Taking a look at the date ranges within the data set
	- finding out that it's within a 3 year range
    - beginning roughly around the beginning of COVID and ending in spring 2023*/

SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

/* Finding out what industry was hit with the most layoffs
	- The consumer and retail industries were hit the hardest by layoffs
    - intuituvely makes sense giving some of the things that were going on during COVID*/

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

/* Finding out what country was hit with the most layoffs
	- The USA had the most total layoffs during this time duration*/

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC
LIMIT 1;

/* Finding out what year had the most layoffs total
	- The year 2022
    - The dataset is inclusive of only 3 months of 2023, so this also shows that I can confidently
    predict that the amount of people laid off in 2023 will be higher than the prior years by the
    end of that year*/
    
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 DESC; 

/* Finding out what country was hit with the most layoffs
	- The USA had the most total layoffs during this time duration*/
    
SELECT SUBSTRING(date, 1, 7) AS MONTH, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

/* What's the monthly rolling total of layoffs around the world?
	- 2021 was a better year as far as layoffs than 2020, with 2020 ending with about 81k layoffs
    in total and 2021 having roughly around 15k layoffs */
    
WITH Rolling_Total AS (
SELECT SUBSTRING(date, 1, 7) AS MONTH, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC)

SELECT MONTH , total_off, SUM(total_off) OVER(ORDER BY MONTH) AS rolling_total
FROM Rolling_Total;

/* What are the top 5 companies that laid people off per each year?
	- 2020: Uber, Booking.com, , Groupon, Swiggy, Airbnb
    - 2021: Bytedance, Katerra, Zillow, Instacart, WhiteHat Jr
    - 2022: Meta, Amazon, Cisco, Peloton, Carvana, Philips
    - 2023: Google, Microsoft, Ericsson, Amazon, Salesforce, Dell*/
    
SELECT company, YEAR(date), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(date)
    ORDER BY 3 DESC;
    
WITH Company_Year (company, years, total_laid_off) AS
(SELECT company, YEAR(date), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(date)), Company_Year_Rank AS
    
   ( SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM Company_Year
    WHERE years IS NOT NULL)
    
SELECT *
FROM Company_Year_Rank
WHERE ranking <=5 AND years = '2023'; 