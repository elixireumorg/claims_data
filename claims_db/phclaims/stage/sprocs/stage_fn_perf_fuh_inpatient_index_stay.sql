
/*
This function gets inpatient stays as denominator events for the FUH (Follow-up After Hospitalization for Mental Illness)

LOGIC: Acute Inpatient Stays with a Mental Illness Principal Diagnosis
Principal diagnosis in Mental Illness Value Set
INTERSECT
(
Inpatient Stay Value Set
EXCEPT
Nonacute Inpatient Stay
)

Author: Philip Sylling
Created: 2019-04-25
Modified: 2019-08-09 | Point to new [final] analytic tables

Returns:
 [id_mcaid]
,[age]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag], = 1
*/

USE PHClaims;
GO

IF OBJECT_ID('[stage].[fn_perf_fuh_inpatient_index_stay]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fuh_inpatient_index_stay];
GO
CREATE FUNCTION [stage].[fn_perf_fuh_inpatient_index_stay]
(@measurement_start_date DATE
,@measurement_end_date DATE
,@age INT
,@dx_value_set_name VARCHAR(100))
RETURNS TABLE 
AS
RETURN
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('Mental Illness'
,'Inpatient Stay'
,'Nonacute Inpatient Stay')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [get_claims] AS
(
/*
Mental Illness Value Set does not include ICD9CM diagnosis codes
*/
SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
-- 2 Values: 'AOD Abuse and Dependence', 'Mental Illness'
ON [value_set_name] = @dx_value_set_name
--ON [value_set_name] IN ('Mental Illness')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date

INTERSECT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE ln.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

EXCEPT

(
SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE ln.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Nonacute Inpatient Stay')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]
WHERE hd.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-01'
))),

[age_x_year_old] AS
(
SELECT 
 cl.[id_mcaid]
,DATEDIFF(YEAR, elig.[dob], cl.[first_service_date]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dob], cl.[first_service_date]), elig.[dob]) > cl.[first_service_date] THEN 1 ELSE 0 END AS [age]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag]
FROM [get_claims] AS cl
INNER JOIN [final].[mcaid_elig_demo] AS elig
ON cl.[id_mcaid] = elig.[id_mcaid]
WHERE DATEDIFF(YEAR, elig.[dob], cl.[first_service_date]) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, elig.[dob], cl.[first_service_date]), elig.[dob]) > cl.[first_service_date] THEN 1 ELSE 0 END >= @age
)

SELECT *
FROM [age_x_year_old];
GO

/*
IF OBJECT_ID('tempdb..#temp', 'U') IS NOT NULL
DROP TABLE #temp;
SELECT * INTO #temp FROM [stage].[fn_perf_fuh_inpatient_index_stay]('2017-01-01', '2017-12-31', 6, 'Mental Illness');
*/