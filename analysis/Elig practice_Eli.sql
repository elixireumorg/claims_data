/****** Learn what Alastair's code is doing ******/
SELECT
dt_2.MEDICAID_RECIPIENT_ID, dt_2.SOCIAL_SECURITY_NMBR,
dt_2.startdate, dt_2.enddate,
DATEDIFF(mm, startdate, enddate) + 1 AS cov_time_mth
FROM (
SELECT
dt_1.MEDICAID_RECIPIENT_ID, dt_1.SOCIAL_SECURITY_NMBR,
MIN(calmonth) AS startdate, MAX(calmonth) AS enddate,
dt_1.group_num
FROM (
SELECT
DISTINCT CONVERT(datetime, CAL_YEAR_MONTH + '01', 112) AS calmonth,
x.MEDICAID_RECIPIENT_ID, x.SOCIAL_SECURITY_NMBR, 
DATEDIFF(MONTH, 0, CONVERT(datetime, CAL_YEAR_MONTH + '01', 112)) - ROW_NUMBER() 
OVER(PARTITION BY x.MEDICAID_RECIPIENT_ID, x.SOCIAL_SECURITY_NMBR
ORDER BY CONVERT(datetime, CAL_YEAR_MONTH + '01', 112)) AS 'group_num'
FROM (
SELECT DISTINCT y.MEDICAID_RECIPIENT_ID, y.SOCIAL_SECURITY_NMBR, y.CAL_YEAR_MONTH
FROM [PHClaims].[dbo].[NewEligibility] y
) AS x
) AS dt_1
GROUP BY MEDICAID_RECIPIENT_ID, SOCIAL_SECURITY_NMBR, group_num
) AS dt_2
ORDER BY  MEDICAID_RECIPIENT_ID, SOCIAL_SECURITY_NMBR, startdate, enddate

/****** Alastair's y ******/
SELECT DISTINCT TOP (1000) y.MEDICAID_RECIPIENT_ID, y.SOCIAL_SECURITY_NMBR, y.CAL_YEAR_MONTH
FROM [PHClaims].[dbo].[NewEligibility] y
WHERE y.MEDICAID_RECIPIENT_ID = '200383049WA'

SELECT TOP (1000) y.MEDICAID_RECIPIENT_ID, y.SOCIAL_SECURITY_NMBR, y.CAL_YEAR_MONTH, y.RAC_NAME
FROM [PHClaims].[dbo].[NewEligibility] y
WHERE y.MEDICAID_RECIPIENT_ID = '200383049WA'

/****** Server permissions  ******/
USE PH_APDEStore;
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');  
GO

USE PHClaims;
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');  
GO

/****** Understanding claims for dual eligibles ******/
SELECT COUNT(DISTINCT CLM_LINE_TCN)
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE (PAID_AMT_H = '.00' OR PAID_AMT_H is null) AND 
	(MEDICARE_COST_AVOIDANCE_AMT != '.00'OR MEDICARE_COST_AVOIDANCE_AMT is not null
	OR TPL_COST_AVOIDANCE_AMT != '.00' OR TPL_COST_AVOIDANCE_AMT is not null)

SELECT COUNT(DISTINCT CLM_LINE_TCN)
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE (PAID_AMT_H = MEDICARE_COST_AVOIDANCE_AMT) OR (PAID_AMT_H = TPL_COST_AVOIDANCE_AMT)

/****** RAC codes ******/
SELECT DISTINCT (RAC_CODE), RAC_NAME, SUBSTRING(CAL_YEAR_MONTH,1,4) 
  FROM [PHClaims].[dbo].[NewEligibility]

/****** Revenue code counts in 2016  ******/
SELECT COUNT(DISTINCT CLM_LINE_TCN), REVENUE_CODE,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY REVENUE_CODE

/****** Revenue code counts in 2015  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), REVENUE_CODE,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2015-01-01' AND '2015-12-31'
  GROUP BY REVENUE_CODE

/****** Claim types in 2016  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), CLM_TYPE_CID,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY CLM_TYPE_CID
 
/****** Claim types in 2015  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), CLM_TYPE_CID,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2015-01-01' AND '2015-12-31'
  GROUP BY CLM_TYPE_CID

/****** Procedure codes in 2016  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), PRCDR_CODE_1,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY [PRCDR_CODE_1]

 /****** Procedure codes in 2015  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), PRCDR_CODE_1,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE FROM_SRVC_DATE BETWEEN '2015-01-01' AND '2015-12-31'
  GROUP BY [PRCDR_CODE_1]

/****** Look at all Place of Stay codes  ******/
 SELECT COUNT(DISTINCT CLM_LINE_TCN), PLACE_OF_SERVICE,
  SUM(ISNULL(CAST(PAID_AMT_H as float),0)) AS 'cost'
  FROM [PHClaims].[dbo].[NewClaims]
  GROUP BY PLACE_OF_SERVICE

  SELECT DISTINCT MEDICAID_RECIPIENT_ID AS 'id',
	  CLM_LINE_TCN as 'clm_line_tcn',
	  FROM_SRVC_DATE as 'from_srvc_date',
	  TO_SRVC_DATE as 'to_srvc_date',
	  CLM_TYPE_CID as 'cid',
	  REVENUE_CODE as 'rev',
	  PLACE_OF_SERVICE as 'pos',
	  PAID_AMT_H as 'paid_amt',
	  PRIMARY_DIAGNOSIS_CODE as 'diag1',
	  DIAGNOSIS_CODE_2 as 'diag2',
	  DIAGNOSIS_CODE_3 as 'diag3',
	  DIAGNOSIS_CODE_4 as 'diag4',
	  DIAGNOSIS_CODE_5 as 'diag5',
	  PRCDR_CODE_1 as 'proc1',
	  PRCDR_CODE_2 as 'proc2',
	  PRCDR_CODE_3 as 'proc3',
	  PRCDR_CODE_4 as 'proc4',
	  PRCDR_CODE_5 as 'proc5'

	  FROM [PHClaims].[dbo].[NewClaims]

	  WHERE (FROM_SRVC_DATE BETWEEN '2016-01-01' AND '2016-12-31') AND 
	  (REVENUE_CODE LIKE '045[01269]' OR REVENUE_CODE LIKE '0981' OR PRCDR_CODE_1 LIKE '9928[1-5]'
	  OR PRCDR_CODE_2 LIKE '9928[1-5]' OR PRCDR_CODE_3 LIKE '9928[1-5]' OR PRCDR_CODE_4 LIKE '9928[1-5]' OR PRCDR_CODE_5 LIKE '9928[1-5]'
	  OR PLACE_OF_SERVICE LIKE '%23%')
	  --AND MEDICAID_RECIPIENT_ID = '201476386WA'
	  AND CLM_LINE_TCN = '101608200000735008'

	  ORDER BY CLM_LINE_TCN

/****** Understanding modifier codes  ******/
SELECT * 
  FROM [PHClaims].[dbo].[NewClaims]
  WHERE MEDICAID_RECIPIENT_ID IN ('201401231WA')
  AND FROM_SRVC_DATE BETWEEN '2016-12-01' AND '2016-12-04'

/****** Comparing new and old claims data extracts (pre and post August 2017 extracts)  ******/
--50 server (77 million rows in claims)
SELECT clm_type_name, count(clm_type_name)
  FROM [PHClaims].[dbo].[NewClaims]
  --WHERE MEDICAID_RECIPIENT_ID IN ('100128250WA')
  GROUP BY CLM_TYPE_NAME
--old data - 65 claims for this particular Medicaid ID

--51 server (22 million rows in claims)
SELECT clm_type_name, count(clm_type_name)
  FROM [PHClaims].[dbo].[NewClaims]
  --WHERE MEDICAID_RECIPIENT_ID IN ('100128250WA')
  GROUP BY CLM_TYPE_NAME
--new data - 65 claims for this particular Medicaid ID

