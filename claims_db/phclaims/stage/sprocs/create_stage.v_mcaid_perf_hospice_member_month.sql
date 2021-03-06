
USE PHClaims;
GO

IF OBJECT_ID('[stage].[v_mcaid_perf_hospice_member_month]', 'V') IS NOT NULL
DROP VIEW [stage].[v_mcaid_perf_hospice_member_month];
GO
CREATE VIEW [stage].[v_mcaid_perf_hospice_member_month]
AS
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] = 'Hospice'
GROUP BY [value_set_name], [code_system];

SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [ref].[hedis_code_system]
WHERE [value_set_name] = 'Hospice'
GROUP BY [value_set_name], [code_system];

SELECT [value_set_name]
      ,[code_system]
      ,[code]
FROM [archive].[hedis_code_system]
WHERE [value_set_name] = 'Hospice'
ORDER BY [value_set_name], [code_system], [code];

SELECT [value_set_name]
      ,[code_system]
      ,[code]
FROM [ref].[hedis_code_system]
WHERE [value_set_name] = 'Hospice'
ORDER BY [value_set_name], [code_system], [code];
*/
WITH CTE AS
(
SELECT 
 ym.[year_month]
,hd.[id_mcaid]
--,hd.[claim_header_id]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Hospice')
AND hed.[code_system] = 'UBTOB' 
AND hd.[type_of_bill_code] = hed.[code]
INNER JOIN [ref].[perf_year_month] AS ym
ON hd.[first_service_date] BETWEEN ym.[beg_month] AND ym.[end_month]

UNION

SELECT 
 ym.[year_month]
,ln.[id_mcaid]
--,ln.[claim_header_id]

FROM [final].[mcaid_claim_line] AS ln
INNER JOIN [archive].[hedis_code_system] AS hed
ON [value_set_name] IN 
('Hospice')
AND hed.[code_system] = 'UBREV'
AND ln.[rev_code] = hed.[code]
INNER JOIN [ref].[perf_year_month] AS ym
ON ln.[first_service_date] BETWEEN ym.[beg_month] AND ym.[end_month]

UNION 

SELECT
 ym.[year_month]
,pr.[id_mcaid]
--,pr.[claim_header_id]

FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [archive].[hedis_code_system] AS hed 
 ON [value_set_name] IN
('Hospice')
AND hed.[code_system] IN ('CPT', 'HCPCS')
AND pr.[procedure_code] = hed.[code]
INNER JOIN [ref].[perf_year_month] AS ym
ON pr.[first_service_date] BETWEEN ym.[beg_month] AND ym.[end_month]
)

SELECT
 [year_month]
,[id_mcaid]
,1 AS [hospice_flag]
FROM CTE;
GO

/*
SELECT 
 [year_month]
,COUNT(*)
FROM [stage].[v_mcaid_perf_hospice_member_month]
GROUP BY [year_month];
*/