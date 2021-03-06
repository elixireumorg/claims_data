
USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_ah_inpatient_exclusion]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_ah_inpatient_exclusion];
GO
CREATE VIEW [stage].[v_perf_ah_inpatient_exclusion]
AS


WITH [get_all_exclusions] AS
( 
SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('IPU Exclusions MS-DRG'
,'Maternity MS-DRG'
,'Newborns/Neonates MS-DRG')
AND hed.[code_system] = 'MSDRG' 
AND hd.[drvd_drg_code] = hed.[code]

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Maternity')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]

UNION

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Deliveries Infant Record'
,'Maternity Diagnosis'
,'Mental and Behavioral Disorders')
AND hed.[code_system] = 'ICD9CM'
AND dx.[icdcm_version] = 9 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]

UNION

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Deliveries Infant Record'
,'Maternity Diagnosis'
,'Mental and Behavioral Disorders')
AND hed.[code_system] = 'ICD10CM'
AND dx.[icdcm_version] = 10 
-- Principal Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = hed.[code]

UNION

SELECT 
 ln.[id_mcaid]
,ln.[claim_header_id]
,hed.[value_set_name]
,1 AS [flag]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Maternity')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
)

SELECT 
 [id_mcaid]
,[claim_header_id]
,[Deliveries Infant Record]
,[IPU Exclusions MS-DRG]
,[Maternity]
,[Maternity Diagnosis]
,[Maternity MS-DRG]
,[Mental and Behavioral Disorders]
,[Newborns/Neonates MS-DRG]
FROM [get_all_exclusions]
PIVOT(MAX([flag]) FOR [value_set_name] IN
(
 [Deliveries Infant Record]
,[IPU Exclusions MS-DRG]
,[Maternity]
,[Maternity Diagnosis]
,[Maternity MS-DRG]
,[Mental and Behavioral Disorders]
,[Newborns/Neonates MS-DRG]
)) AS P;
GO

/*
SELECT COUNT(*) FROM [stage].[v_perf_ah_inpatient_exclusion];
*/