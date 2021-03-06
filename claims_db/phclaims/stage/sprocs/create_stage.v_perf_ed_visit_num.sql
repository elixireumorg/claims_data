
USE PHClaims;
GO

IF OBJECT_ID('[stage].[v_perf_ed_visit_num]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_ed_visit_num];
GO
CREATE VIEW [stage].[v_perf_ed_visit_num]
AS
/*
DSRIP Guidance
All emergency department visits contribute to the metric 
(e.g. an individual may have multiple emergency department 
visits on the same day and each is counted as an event, as 
long as they are on separate claims).

Each ED visit appears to have a distinct claim_header_id

-- Both 1,358,867
SELECT COUNT(DISTINCT claim_header_id) FROM [stage].[v_perf_ed_visit_num];
SELECT COUNT(claim_header_id) FROM [stage].[v_perf_ed_visit_num];
*/

SELECT 
 ym.[year_month]
,hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [ed_visit_num]
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [ref].[date] AS ym
ON hd.[first_service_date] = ym.[date]
WHERE hd.[clm_type_mcaid_id] IN ('3', '26', '34')
  AND hd.[place_of_service_code] IN ('23')
  
UNION

SELECT 
 ym.[year_month]
,hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [ed_visit_num]
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [final].[mcaid_claim_line] AS ln
ON hd.[claim_header_id] = ln.[claim_header_id]
INNER JOIN [ref].[date] AS ym
ON hd.[first_service_date] = ym.[date]
WHERE hd.[clm_type_mcaid_id] IN ('3', '26', '34')
  AND ln.[rev_code] IN ('0450', '0451', '0452', '0456', '0459')
  
UNION

SELECT 
 ym.[year_month]
,hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
,hd.[last_service_date]
,1 AS [ed_visit_num]
FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [final].[mcaid_claim_procedure] AS pr
ON hd.[claim_header_id] = pr.[claim_header_id]
INNER JOIN [ref].[date] AS ym
ON hd.[first_service_date] = ym.[date]
WHERE hd.[clm_type_mcaid_id] IN ('3', '26', '34')
  AND pr.[procedure_code] IN ('99281', '99282', '99283', '99284', '99285', '99288');
GO

/*
-- 1,358,867
SELECT COUNT(*) FROM [stage].[v_perf_ed_visit_num];
-- 209,171
SELECT COUNT(*) FROM [stage].[v_perf_ed_visit_num] WHERE [year_month] BETWEEN 201701 AND 201712;
*/