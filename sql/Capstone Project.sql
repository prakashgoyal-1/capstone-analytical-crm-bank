/*
					Capstone Project (Analytical CRM Development for a Bank)
                    By: Kumar Prakash
*/


-- Create Database
CREATE DATABASE BANKCRM;
SHOW DATABASES;
USE BANKCRM;
SHOW TABLES;

-- Import data from csv into respective table by "table data import wizard" features on mysql
SELECT * FROM ActiveCustomer;
SELECT * FROM BankChurn;
SELECT * FROM CreditCard;
SELECT * FROM Gender;
SELECT * FROM ExitCustomer;
SELECT * FROM Geography;
SELECT * FROM CustomerInfo;
-- Check columns of the tables
SHOW COLUMNS FROM ActiveCustomer;
SHOW COLUMNS FROM BankChurn;
SHOW COLUMNS FROM CreditCard;
SHOW COLUMNS FROM Gender;
SHOW COLUMNS FROM ExitCustomer;
SHOW COLUMNS FROM Geography;
SHOW COLUMNS FROM CustomerInfo;

-- SQL Data Cleaning steps
-- step 1: Change type and format
UPDATE CustomerInfo 
SET `Bank DOJ` = STR_TO_DATE(`Bank DOJ`, '%Y/%m/%d') 
WHERE CustomerId IS NOT NULL; 
ALTER TABLE CustomerInfo MODIFY COLUMN `Bank DOJ` DATE;

-- step 2: Trim Whitespaces from text column of the table
UPDATE ActiveCustomer SET ActiveCategory = TRIM(ActiveCategory);
UPDATE CreditCard SET Category = TRIM(Category);
UPDATE Gender SET GenderCategory = TRIM(GenderCategory);
UPDATE ExitCustomer SET ExitCategory = TRIM(ExitCategory);
UPDATE Geography SET GeographyLocation = TRIM(GeographyLocation);
UPDATE CustomerInfo SET Surname = TRIM(Surname);

-- step 3: Check null values, Only doubts in BankChurn and customerInfo table, because it has 10,000 entries
SELECT
  COUNT(CASE WHEN CustomerId IS NULL THEN 1 END) AS CustomerId,
  COUNT(CASE WHEN CreditScore IS NULL THEN 1 END) AS CreditScore,
  COUNT(CASE WHEN Tenure IS NULL THEN 1 END) AS Tenure,
  COUNT(CASE WHEN Balance IS NULL THEN 1 END) AS Balance,
  COUNT(CASE WHEN NumOfProducts IS NULL THEN 1 END) AS NumOfProducts,
  COUNT(CASE WHEN HasCrCard IS NULL THEN 1 END) AS HasCrCard,
  COUNT(CASE WHEN IsActiveMember IS NULL THEN 1 END) AS IsActiveMember,
  COUNT(CASE WHEN Exited IS NULL THEN 1 END) AS Exited
FROM BankChurn;

SELECT
  COUNT(CASE WHEN CustomerId IS NULL THEN 1 END) AS CustomerId,
  COUNT(CASE WHEN Surname IS NULL THEN 1 END) AS Surname,
  COUNT(CASE WHEN Age IS NULL THEN 1 END) AS Age,
  COUNT(CASE WHEN GenderId IS NULL THEN 1 END) AS GenderId,
  COUNT(CASE WHEN EstimatedSalary IS NULL THEN 1 END) AS EstimatedSalary,
  COUNT(CASE WHEN GeographyID IS NULL THEN 1 END) AS GeographyID,
  COUNT(CASE WHEN `Bank DOJ` IS NULL THEN 1 END) AS `Bank DOJ`
FROM CustomerInfo;

-- Note: As I ran above query. It was clear that there is no null value.




/* ----------------------------------------   Objective   QUESTION   ANSWER  --------------------------------------- */
-- Question 1. What is the distribution of account balance across different regions?
SELECT 
	g.GeographyLocation AS Region,
	ROUND(AVG(b.Balance), 2) AS `AvgBalance`,
	ROUND(MIN(b.Balance), 2) AS MinBalance, 
	ROUND(MAX(b.Balance), 2) AS MaxBalance
FROM Geography g
JOIN CustomerInfo c ON g.GeographyID = c.GeographyID
JOIN BankChurn b ON c.CustomerId = b.CustomerId
GROUP BY g.GeographyLocation;

-- Question 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
SELECT CustomerID, EstimatedSalary
FROM CustomerInfo
WHERE MONTH(`Bank DOJ`) IN (10, 11, 12)
ORDER BY EstimatedSalary DESC
LIMIT 5;

-- Question 3. Calculate the average number of products used by customers who have a credit card. (SQL)
SELECT ROUND(AVG(NumOfProducts)) AS AvgNumberOfProducts
FROM BankChurn
WHERE Has_creditcard = 1;

-- Question 4. Determine the churn rate by Gender for the most recent year in the dataset.
SELECT g.GenderCategory,
       Round(((COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) * 100.0)/ COUNT(*)), 2) AS `ChurnRate (in %)`
FROM BankChurn bc
JOIN CustomerInfo ci ON bc.CustomerId = ci.CustomerId
JOIN Gender g ON ci.GenderID = g.GenderID
WHERE YEAR(`Bank DOJ`) = (SELECT MAX(YEAR(`Bank DOJ`)) FROM CustomerInfo)
GROUP BY g.GenderCategory;
-- Insight: ChurnRate of Female is higher than Male in the most recent year.


-- Question 5. Compare the average credit score of customers who have exited and those who remain.
SELECT ec.ExitCategory as Exited, ROUND(AVG(bc.CreditScore)) AS AvgCreditScore
FROM ExitCustomer ec
JOIN BankChurn bc ON bc.Exited = ec.ExitID
GROUP BY ec.ExitCategory;
-- Note: AvgCreditScore of exited customers are low as compare to Retain customers.


-- Question 6. Which Gender has a higher average estimated salary, and how does it relate to the number of active accounts?
SELECT g.GenderCategory,
       ROUND(AVG(ci.EstimatedSalary), 2) AS AvgSalary,
       COUNT(CASE WHEN bc.IsActiveMember = 1 THEN 1 END) AS ActiveAccounts
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
JOIN Gender g ON ci.GenderID = g.GenderID
GROUP BY g.GenderCategory;
-- Note: Male has highest number of active accounts as compare to Female but lower the Average Salary.

-- Question 7. Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
SELECT 
  CASE 
    WHEN CreditScore >= 800 THEN 'Excellent'
    WHEN CreditScore >= 740 THEN 'Very Good'
    WHEN CreditScore >= 670 THEN 'Good'
    WHEN CreditScore >= 580 THEN 'Fair'
    ELSE 'Poor'
  END AS CreditSegment,
  ROUND((COUNT(CASE WHEN Exited = 1 THEN 1 END) * 100.0 / COUNT(*)), 2) AS `ExitRate (in %)`
FROM BankChurn
GROUP BY CreditSegment
ORDER BY `ExitRate (in %)` desc;
-- Note: Poor (i.e. credit score < 580) has highest ExitRate as 22.02% among all.

-- Question 8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.
SELECT g.GeographyLocation, COUNT(*) AS NumberOfActiveCustomers
FROM BankChurn bc
JOIN CustomerInfo ci ON bc.CustomerId = ci.CustomerId
JOIN Geography g ON ci.GeographyID = g.GeographyID
WHERE bc.Tenure > 5 AND bc.IsActiveMember = 1
GROUP BY g.GeographyLocation
ORDER BY NumberOfActiveCustomers DESC
LIMIT 1;
-- Note: France has highest NumberOfActiveCustomers as 797 among others.


-- Question 9.	What is the impact of having a credit card on customer churn, based on the available data?
SELECT Has_creditcard  as HasCrCard,
       Round((COUNT(CASE WHEN Exited = 1 THEN 1 END) * 100.0 / COUNT(*)), 2) AS ChurnRate
FROM BankChurn
GROUP BY Has_creditcard ;
-- Note: There are no major impact of HasCreditCard on Churn Rate.


-- Question 10.	For customers who have exited, what is the most common number of products they had used?
SELECT NumOfProducts, COUNT(*) AS Frequency
FROM BankChurn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY Frequency DESC
LIMIT 1;
-- Note: Most common number of products among all are 1 with frequency: 1409.

-- Question 11.	Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT YEAR(`Bank DOJ`) AS Year, MONTH(`Bank DOJ`) AS Month, COUNT(*) AS NewCustomers
FROM CustomerInfo
GROUP BY YEAR(`Bank DOJ`), MONTH(`Bank DOJ`)
ORDER BY Year, Month;


-- Question 12.	Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT NumOfProducts, Round(AVG(Balance), 2) AS AvgBalance
FROM BankChurn
WHERE Exited = 1
GROUP BY NumOfProducts;
-- Note: AvgBalance of NumOfProducts as 4 has higher and NumOfProducts as 3 has lower.


-- Question 13.	Identify any potential outliers in terms of balance among customers who have remained with the bank.
/* 
	To Identify outliers we have to calculate ZScore. For customer whose ZScore > 3 treated as a outlier. 
    So, I calculated outlier by ABS(ZScore) > 3. 
    Where ZScore = (Balance - AVG(Balance) / STDDEV(Balance)
*/
 
SELECT CustomerId, Balance
FROM (
  SELECT CustomerId, Balance,
         (Balance - AVG(Balance) OVER()) / STDDEV(Balance) OVER() AS ZScore
  FROM BankChurn
  WHERE Exited = 0
) AS sub
WHERE ABS(ZScore) > 3;

-- Question 14. How many different tables are given in the dataset, out of these tables which table only consists of categorical variables? 
/*  Solution:
	Total Tables = 7,
    There are no such table that contains only categorical variables.
    But, we have some column in the following table which contain only categorical value.
    like: Gender(GenderCategory), Geography(GeographyLocation), ExitCustomer(ExitCategory), ActiveCustomer(ActiveCategory), CreditCard(Category).
*/


-- Question 15. Using SQL, write a query to find out the Gender-wise average income of males and females in each Geography id. Also, rank the Gender according to the average value.
SELECT ci.GeographyID, g.GenderCategory, Round(AVG(ci.EstimatedSalary), 2) AS AvgIncome,
       RANK() OVER (PARTITION BY ci.GeographyID ORDER BY AVG(ci.EstimatedSalary) DESC) AS IncomeRank
FROM CustomerInfo ci
JOIN Gender g ON ci.GenderID = g.GenderID
GROUP BY ci.GeographyID, g.GenderCategory;
-- Note: We got for GeographyID as 1 Male has highest AvgIncome but for others GeographyID (like 2, 3) Female has highest AvgIncome.


-- Question 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+). 
SELECT 
  CASE 
    WHEN Age BETWEEN 18 AND 30 THEN '18-30'
    WHEN Age BETWEEN 31 AND 50 THEN '31-50'
    ELSE '50+'
  END AS AgeBracket,
  Round(AVG(bc.Tenure), 2) AS AvgTenure
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
WHERE bc.Exited = 1
GROUP BY AgeBracket;
-- Note: AvgTenure for 18-30 is 4.78, for 31-50 is 4.89 and for 50+ is 4.83.


-- Question 17. Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not? 
SELECT bc.Exited, CORR(ci.EstimatedSalary, bc.Balance) AS Correlation
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
GROUP BY bc.Exited;
-- Since for my laptop CORR function not supported. So, I used basic method to find correlation.
SELECT
  bc.Exited,
  Round((
    SUM((ci.EstimatedSalary - avg_salary) * (bc.Balance - avg_balance)) /
    (SQRT(SUM(POWER(ci.EstimatedSalary - avg_salary, 2))) *
     SQRT(SUM(POWER(bc.Balance - avg_balance, 2))))
  ), 2) AS Correlation
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
JOIN (
  SELECT Exited, AVG(EstimatedSalary) AS avg_salary, AVG(Balance) AS avg_balance
  FROM CustomerInfo ci2
  JOIN BankChurn bc2 ON ci2.CustomerId = bc2.CustomerId
  GROUP BY Exited
) avgs ON bc.Exited = avgs.Exited
GROUP BY bc.Exited;
-- Since Correlation for Exited = 1 is -0.01 and for exited=0 is 0.02. In both the case absolute value towards zero. It means both are not correlated.


-- Question 18. Is there any correlation between the salary and the Credit score of customers? 
SELECT
  Round((
    SUM((ci.EstimatedSalary - avg_salary) * (bc.CreditScore - avg_credit)) /
    (SQRT(SUM(POWER(ci.EstimatedSalary - avg_salary, 2))) *
     SQRT(SUM(POWER(bc.CreditScore - avg_credit, 2))))
  ), 2) AS SalaryCreditScoreCorrelation
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
JOIN (
  SELECT 
    AVG(EstimatedSalary) AS avg_salary, 
    AVG(CreditScore) AS avg_credit
  FROM CustomerInfo ci2
  JOIN BankChurn bc2 ON ci2.CustomerId = bc2.CustomerId
) avgs ON 1=1;
-- I got the SalaryCreditScoreCorrelation value as -0. means no correlation.


-- Question 19. Rank each bucket of credit score as per the number of customers who have churned the bank. 
SELECT 
  CASE 
    WHEN CreditScore >= 800 THEN 'Excellent'
    WHEN CreditScore >= 740 THEN 'Very Good'
    WHEN CreditScore >= 670 THEN 'Good'
    WHEN CreditScore >= 580 THEN 'Fair'
    ELSE 'Poor'
  END AS CreditBucket,
  COUNT(*) AS ChurnCount,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS ChurnRank
FROM BankChurn
WHERE Exited = 1
GROUP BY CreditBucket;
-- We got Fair as a rank 1 and Excellent as rank 5.


-- Question 20. According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket. 
WITH AgeCredit AS (
  SELECT 
    CASE 
      WHEN Age BETWEEN 18 AND 30 THEN '18-30'
      WHEN Age BETWEEN 31 AND 50 THEN '31-50'
      ELSE '50+'
    END AS AgeBucket,
    COUNT(CASE WHEN bc.Has_creditcard = 1 THEN 1 END) AS CreditCardCount
  FROM CustomerInfo ci
  JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
  GROUP BY AgeBucket
),
AvgCredit AS (
  SELECT AVG(CreditCardCount) AS AvgCards FROM AgeCredit
)
SELECT AgeBucket, CreditCardCount
FROM AgeCredit, AvgCredit
WHERE CreditCardCount < AvgCards;
-- We got AgeBucket as 18-30 has 1400 CreditCardCount and 50+ has 874 count.


-- Question 21. Rank the Locations as per the number of people who have churned the bank and average balance of the customers. 
SELECT g.GeographyLocation,
       COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) AS ChurnCount,
       Round(AVG(bc.Balance), 2) AS AvgBalance,
       RANK() OVER (ORDER BY COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) DESC) AS ChurnRank
FROM BankChurn bc
JOIN CustomerInfo ci ON bc.CustomerId = ci.CustomerId
JOIN Geography g ON ci.GeographyID = g.GeographyID
GROUP BY g.GeographyLocation;
-- From above query we got, Rank 1 for Germany and 3 for Span.


-- Question 22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”. 
SELECT CONCAT(CustomerId, '_', Surname) AS `CustomerKey(primary key)`, Surname
FROM CustomerInfo;


-- Question 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL. 
/* 
	Yes, by below query.
*/
SELECT CustomerId,
       (SELECT ExitCategory FROM ExitCustomer ec WHERE ec.ExitID = bc.Exited) AS ExitCategory
FROM BankChurn bc;


-- Question 24. Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them? 
/* 
	No,
	Tool Used: 
		Power BI or Python (Pandas), 
    Methods:
		Imputation (mean/median/mode),
		Domain-specific replacement,
		Deletion (if sparse),
*/

-- Question 25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”. 
SELECT ci.CustomerId, ci.Surname, bc.IsActiveMember
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
WHERE ci.Surname LIKE '%on';


-- Question 26. Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. One more point to consider is that the data in the Exited Column is absolutely correct and accurate.
/*
	A customer cannot be both exited and active at the same time.
	To detect the Discrepancy: use below query
*/
SELECT bc.CustomerId, bc.IsActiveMember, bc.Exited
FROM BankChurn bc
WHERE bc.IsActiveMember = 1 AND bc.Exited = 1;
/* 
Note:
	We got 735 records, means there are data quality issues.
    These rows represent customers who are incorrectly labeled as active despite having exited.
	Since the Exited column is confirmed to be accurate, the issue lies in the IsActiveMember flag.
    
    To fix this we can create a new column as CorrectedIsActiveMember or we can update the value in same column (IsActiveMember).
    Below, I am adding new column as CorrectedIsActiveMember. Along with CustomerId, IsActiveMember and Exited column. Also I update the flag (IsActiveMember) to 0 when Exited = 1 and IsActiveMember = 1.
*/
SELECT 
	bc.CustomerId, 
	bc.IsActiveMember, 
    bc.Exited, 
    CASE 
	  WHEN Exited = 1 THEN 0 
	  ELSE IsActiveMember 
	END AS CorrectedIsActive
FROM BankChurn bc
WHERE bc.IsActiveMember = 1 AND bc.Exited = 1;




/* ----------------------------------------   SUBJECTIVE   QUESTION   ANSWER  --------------------------------------- */

-- Question 1. Customer Behavior Analysis: What patterns can be observed in the spending habits of long-term customers compared to new customers, and what might these patterns suggest about customer loyalty? 
SELECT 
  CASE WHEN Tenure > 5 THEN 'Long-Term' ELSE 'New' END AS CustomerType,
  Round(AVG(Balance), 2) AS AvgBalance,
  Round(AVG(NumOfProducts), 2) AS AvgProducts
FROM BankChurn
GROUP BY CustomerType;
/*
Insights: 
	The data shows that long-term customers maintain a slightly higher average balance than new customers, suggesting stronger financial engagement over time. 
    However, new customers use a marginally greater number of products, indicating initial experimentation with offerings. 
	This suggests that loyal customers tend to focus on fewer, more substantial products, reflecting trust and satisfaction with the bank. 
	Overall, loyalty appears linked more to quality of engagement rather than sheer quantity of product usage.
*/


-- Question 2. Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies? 
SELECT NumOfProducts, Has_creditcard as HasCrCard, COUNT(*) AS Frequency
FROM BankChurn
GROUP BY NumOfProducts, Has_creditcard
ORDER BY Frequency DESC;
/*
Insights: 
	The results show that customers with 1 or 2 products and a credit card (HasCrCard = 1) are the most common groups, with 3,578 and 3,246 customers respectively. 
	This indicates a strong affinity between holding a credit card and having multiple products, suggesting cross-selling opportunities around credit card holders. 
	Lower frequencies for customers without credit cards imply banks can focus on promoting credit cards alongside other products to increase engagement. 
	These patterns can guide targeted marketing and bundled offers to boost product adoption and deepen customer relationships.
*/


-- Question 3. Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates? 
SELECT g.GeographyLocation,
       COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) AS ChurnCount,
       COUNT(CASE WHEN bc.IsActiveMember = 1 THEN 1 END) AS ActiveCount
FROM BankChurn bc
JOIN CustomerInfo ci ON bc.CustomerId = ci.CustomerId
JOIN Geography g ON ci.GeographyID = g.GeographyID
GROUP BY g.GeographyLocation;
/*
Insight:
	The data shows that France has the highest number of active customers (2,591) with a churn count of 810, indicating a relatively stable but significant churn. 
	Germany has a nearly equal churn count (814) but a much lower active customer base (1,248), suggesting a higher churn rate and weaker customer retention. 
	Spain has the lowest churn (413) and active customers (1,312), reflecting moderate customer stability. 
	These variations imply that geographic regions have different levels of customer loyalty, which banks should consider when tailoring retention and marketing strategies.
*/

-- Question 4. Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why? 
SELECT 
  CASE 
    WHEN Age < 30 THEN 'Young(<30)'
    WHEN Age BETWEEN 30 AND 50 THEN 'Mid-Age(30-50)'
    ELSE 'Senior(50+)'
  END AS AgeGroup,
  Round(AVG(CreditScore), 2) AS AvgCreditScore,
  COUNT(CASE WHEN Exited = 1 THEN 1 END) AS ChurnCount
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
GROUP BY AgeGroup;
/*
Insight:
	The data shows that the Mid-Age group (30–50) has the highest churn count at 1,350, indicating a higher risk of customers leaving the bank. 
	Despite the churn, the average credit scores are similar across all age groups, around 650, so creditworthiness is comparable. 
	The Young group (<30) has the lowest churn count, suggesting lower risk in terms of customer attrition. 
	Therefore, the Mid-Age segment poses the highest financial risk mainly due to higher churn, which can impact the bank’s stable revenue and growth.
*/


-- Question 5. Customer Tenure Value Forecast: How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments?
SELECT Age, GeographyID, Has_creditcard as HasCrCard, IsActiveMember, 
       AVG(Tenure) AS AvgTenure,
       Round(AVG(Balance), 2) AS AvgBalance,
       AVG(CreditScore) AS AvgCreditScore,
       Round(AVG(EstimatedSalary), 2) AS AvgSalary,
       AVG(NumOfProducts) AS AvgProducts
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
GROUP BY Age, GeographyID, Has_creditcard, IsActiveMember;
/*
Insight: 
	To model and predict lifetime (tenure) value for customer segments, the query groups customers by age, geography, credit card ownership, and activity status, then calculates average tenure within each segment. 
	These results reveal which combinations (e.g., active credit card holders in specific regions and age brackets) tend to stay longer with the bank. 
	By identifying segments with higher average tenure, the bank can target retention strategies and prioritize valuable customer groups. 
	These insights provide evidence-based guidance for resource allocation and personalized service offers to maximize long-term customer relationships.
*/


-- Question 6. Marketing Campaign Effectiveness: How could you assess the impact of marketing campaigns on customer retention and acquisition within the dataset? What extra information would you need to solve this? 
/*
1. Evaluate how marketing campaigns influence:
	Customer retention (preventing churn)
	Customer acquisition (bringing in new customers)

2. We need to define these key metrics: 
	Retention Rate, Acqusition Rate, Conversion Rate and Churn Rate Change
    
3. Required Data: In current dataset includes customer profiles and churn status, but does not include campaign data. To perform this analysis, you’d need:
	CampaignID, CampaignDate, TargetSegment, AcquisitionDate, and RetentionStatus

4. Once Data is Avaliable we use Visualization chart like Funnel, Line or Bar chart to show insights.
*/


-- Question 7. Customer Exit Reasons Exploration: Can you identify common characteristics or trends among customers who have exited that could explain their reasons for leaving? 
SELECT AVG(CreditScore), Round(AVG(Balance), 2), AVG(NumOfProducts)
FROM BankChurn
WHERE Exited = 1;
/*
Insight:
	The average credit score of customers who exited is relatively low at around 645, indicating potentially higher credit risk. 
	Their average balance is moderately high (about ₹91,108), suggesting they had significant funds, which might make their churn impactful. 
	The average number of products held (1.475) shows they were engaged but not deeply diversified in bank offerings. 
	These trends suggest that customers leaving may be financially valuable but perhaps dissatisfied or seeking better options, emphasizing the need for proactive retention strategies focused on service quality and personalized offers.
*/


-- Question 8. Are 'Tenure', 'NumOfProducts', 'IsActiveMember', and 'EstimatedSalary' important for predicting if a customer will leave the bank? 
/*
	To find importance of these feature, we have to evaluate some matrics. Below query help to evaluate metrics...
*/
SELECT 
  AVG(CASE WHEN Exited = 1 THEN Tenure ELSE NULL END) AS AvgTenure_Exited,
  AVG(CASE WHEN Exited = 0 THEN Tenure ELSE NULL END) AS AvgTenure_Retained,
  AVG(CASE WHEN Exited = 1 THEN NumOfProducts ELSE NULL END) AS AvgProducts_Exited,
  AVG(CASE WHEN Exited = 0 THEN NumOfProducts ELSE NULL END) AS AvgProducts_Retained,
  AVG(CASE WHEN Exited = 1 THEN EstimatedSalary ELSE NULL END) AS AvgSalary_Exited,
  AVG(CASE WHEN Exited = 0 THEN EstimatedSalary ELSE NULL END) AS AvgSalary_Retained,
  COUNT(CASE WHEN Exited = 1 AND IsActiveMember = 1 THEN 1 END) AS ActiveExited,
  COUNT(CASE WHEN Exited = 1 AND IsActiveMember = 0 THEN 1 END) AS InactiveExited
FROM BankChurn bc
JOIN CustomerInfo ci ON ci.CustomerID = bc.CustomerID;
/*
Based on the analysis, we found that...
	IsActiveMember: is the most influential feature for predicting customer churn—customers who are inactive are nearly twice as likely to exit the bank. 
	NumOfProducts: also shows a meaningful impact, with lower product usage correlating with higher churn, suggesting that deeper engagement reduces attrition. 
	While EstimatedSalary and Tenure: show only marginal differences between exited and retained customers, they may still contribute when combined with other variables. 

Overall, focusing on reactivating inactive users and promoting multi-product adoption could significantly improve retention outcomes.
*/


-- Question 9. Utilize SQL queries to segment customers based on demographics and account details. 
SELECT 
  g.GenderCategory,
  CASE 
    WHEN Age < 30 THEN 'Young(<30)'
    WHEN Age BETWEEN 30 AND 50 THEN 'Mid-Age(30-50)'
    ELSE 'Senior(50+)'
  END AS AgeGroup,
  bc.NumOfProducts,
  bc.Balance
FROM CustomerInfo ci
JOIN BankChurn bc ON ci.CustomerId = bc.CustomerId
JOIN Gender g ON ci.GenderID = g.GenderID;
/*
Insight: 
	This segmentation query groups customers by gender, age group, number of products, and account balance, providing a detailed profile of customer diversity.
	The output allows the bank to identify patterns, such as which demographic is associated with higher product usage or larger balances. 
	For example: 
		both male and female customers in the 'Mid-Age(30-50)' group show variation in balance and product holdings, while younger customers may sometimes hold more products but with varied balances. 
	
    Such insights enable targeted marketing, product recommendations, and risk assessment for specific customer segments.
*/


-- Question 10. How can we create a conditional formatting setup to visually highlight customers at risk of churn and to evaluate the impact of credit card rewards on customer retention? 
/*
Use the following indicators from your dataset:
	Exited = 1 -> Confirmed churn
	IsActiveMember = 0 -> Inactive
	NumOfProducts < 2 ->  Low engagement
	CreditScore < 600 -> Financial risk
	Balance = 0 -> Dormant account
    
Then use conditional formating facility in Excel or Power BI and Charts to visually highlight customers at risk of churn.
*/


-- Question 11. What is the current churn rate per year and overall as well in the bank? Can you suggest some insights to the bank about which kind of customers are more likely to churn and what different strategies can be used to decrease the churn rate? 
SELECT YEAR(`Bank DOJ`) AS Year,
       ROUND(COUNT(CASE WHEN bc.Exited = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS `ChurnRate(in %)`
FROM BankChurn bc
JOIN CustomerInfo ci ON bc.CustomerId = ci.CustomerId
GROUP BY YEAR(`Bank DOJ`);

-- Overall Churn:
SELECT ROUND(COUNT(CASE WHEN Exited = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS `OverallChurnRate(in %)`
FROM BankChurn;
/* 
Insights:
	The overall churn rate at the bank is approximately 20.37%, which is higher than the typical benchmark of 5–10% for banks and may indicate underlying customer retention challenges. 
	Customers most likely to churn often have lower product usage, lower activity levels (inactive members), and sometimes lower engagement or satisfaction based on previous analysis. 
	Strategies to decrease churn include increasing customer engagement through personalized communications, regularly seeking feedback to address pain points, and offering more relevant or flexible products and services. 
	The bank should use data segmentation to identify at-risk groups and prioritize proactive retention initiatives and customer satisfaction improvements.
*/


-- Question 12. Create a dashboard incorporating all the KPIs and visualization-related metrics. Use a slicer in order to assist in selection in the dashboard. 
/*
We will create a dashbord with the help of PowerBI in PowerBI and focus on these things...
	KPIs: Churn Rate, Avg Balance, Product Usage, Tenure.
	Visuals: Bar charts, line graphs, heatmaps.
	Slicers: Geography, Age Group, Gender, Credit Score Bucket.
	Tool: Power BI or Tableau.
*/


-- Question 13. How would you approach this problem, if the objective and subjective questions weren't given? 
/*
We approach this problem like:
	1. Explore data schema and relationships.
	2. Identify key business goals (e.g., retention, risk).
	3. Perform EDA (Exploratory Data Analysis).
	4. Build hypotheses (e.g., “Does tenure affect churn?”).
	5. Use SQL + visual tools to validate insights.
	6. Present findings in a structured report.
*/


-- Question 14. In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”? 
ALTER TABLE BankChurn
RENAME COLUMN HasCrCard TO Has_creditcard;



-- By Kumar Prakash
/* ----------------------------------- Thanks --------------------------------------------*/



















