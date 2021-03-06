
/*
This function gets follow-up visits that meet the requirements for the 
HEDIS FUA (Follow-Up After Emergency Department Visit for Alcohol and 
Other Drug Abuse or Dependence) measure.

Author: Philip Sylling
Created: 2019-04-24
Modified: 2019-07-25 | Point to new [final] analytic tables

Returns:
 [id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[last_service_date], [TO_SRVC_DATE]
,[flag], 1 for claim meeting follow-up visit criteria
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[fn_perf_fua_follow_up_visit]', 'IF') IS NOT NULL
DROP FUNCTION [stage].[fn_perf_fua_follow_up_visit];
GO
CREATE FUNCTION [stage].[fn_perf_fua_follow_up_visit](@measurement_start_date DATE, @measurement_end_date DATE)
RETURNS TABLE 
AS
RETURN
/*
SELECT [measure_id]
      ,[value_set_name]
      ,[value_set_oid]
FROM [archive].[hedis_value_set]
WHERE [measure_id] = 'FUA';

SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] IN
('AOD Abuse and Dependence'
,'IET POS Group 1'
,'IET POS Group 2'
,'IET Stand Alone Visits'
,'IET Visits Group 1'
,'IET Visits Group 2'
,'Online Assessments'
,'Telehealth Modifier' 
,'Telephone Visits')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [get_claims] AS
(
/*
Condition 1:
IET Stand Alone Visits Value Set with a principal diagnosis of AOD abuse or 
dependence (AOD Abuse and Dependence Value Set), with or without a telehealth 
modifier (Telehealth Modifier Value Set).
*/
((
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Stand Alone Visits')
AND hed.[code_system] IN ('CPT', 'HCPCS')
AND pr.[procedure_code] = hed.[code]
WHERE pr.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE pr.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

UNION

SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,ln.[first_service_date]
,ln.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Stand Alone Visits')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
WHERE ln.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE ln.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE dx.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 2:
IET Visits Group 1 Value Set with IET POS Group 1 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Visits Group 1')
AND hed.[code_system] = 'CPT'
AND pr.[procedure_code] = hed.[code]
WHERE pr.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE pr.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET POS Group 1')
AND hed.[code_system] = 'POS' 
AND hd.[place_of_service_code] = hed.[code]
WHERE hd.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE dx.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 3:
IET Visits Group 2 Value Set with IET POS Group 2 Value Set and a principal 
diagnosis of AOD abuse or dependence (AOD Abuse and Dependence Value Set), with
or without a telehealth modifier (Telehealth Modifier Value Set).
*/
(
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET Visits Group 2')
AND hed.[code_system] = 'CPT'
AND pr.[procedure_code] = hed.[code]
WHERE pr.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE pr.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IET POS Group 2')
AND hed.[code_system] = 'POS' 
AND hd.[place_of_service_code] = hed.[code]
WHERE hd.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE hd.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE dx.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 4:
A telephone visit (Telephone Visits Value Set) with a principal diagnosis of 
AOD abuse or dependence (AOD Abuse and Dependence Value Set). 
*/
(
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Telephone Visits')
AND hed.[code_system] = 'CPT'
AND pr.[procedure_code] = hed.[code]
WHERE pr.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE pr.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE dx.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)

UNION

/*
Condition 5:
An online assessment (Online Assessments Value Set) with a principal diagnosis 
of AOD abuse or dependence (AOD Abuse and Dependence Value Set).
*/
(
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
,pr.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Online Assessments')
AND hed.[code_system] = 'CPT'
AND pr.[procedure_code] = hed.[code]
WHERE pr.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE pr.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'

INTERSECT

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
,dx.[last_service_date]
--,hed.[value_set_name]
,1 AS [flag]

--SELECT COUNT(*)
FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('AOD Abuse and Dependence')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]
WHERE dx.[first_service_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE dx.[first_service_date] BETWEEN '2017-01-01' AND '2017-12-31'
)
)
SELECT 
 [id_mcaid]
,[claim_header_id]
,[first_service_date]
,[last_service_date]
,[flag]
FROM [get_claims]
--WHERE [from_date] BETWEEN @measurement_start_date AND @measurement_end_date
--WHERE [from_date] BETWEEN '2017-01-01' AND '2017-12-31'
GO
/*
IF OBJECT_ID('tempdb..#temp') IS NOT NULL
DROP TABLE #temp;
SELECT * 
INTO #temp
FROM [stage].[fn_perf_fua_follow_up_visit]('2017-01-01', '2017-12-31');
*/