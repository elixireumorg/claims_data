
/*
This view gets non-acute inpatient stays as denominator exclusions for the 
FUH (Follow-up After Hospitalization for Mental Illness).

From DSRIP Guide:
(1)
Exclude discharges (acute discharges with principal diagnosis of mental 
illness) followed by readmission or direct transfer to a non-acute inpatient 
care setting within the 30-day follow-up period, regardless of principal 
diagnosis for the readmission.

To identify readmissions and direct transfers to a non-acute inpatient care 
setting:
-Identify all acute and non-acute inpatient stays (Inpatient Stay Value Set).
-Confirm the stay was for non-acute care based on the presence of a non-acute 
code (Non-acute Inpatient Stay Value Set) on the claim.
-Identify the admission date for the stay.

(2)
Exclude discharges followed by readmission or direct transfer to an acute 
inpatient care setting within the 30-day follow-up period if the principal 
diagnosis was for non-mental health (any principal diagnosis code other than 
those included in the Mental Health Diagnosis Value Set). To identify 
readmissions and direct transfers to an acute inpatient care setting:
-Identify all acute and non-acute inpatient stays (Inpatient Stay Value Set).
-Exclude non-acute inpatient stays (Non-acute Inpatient Stay Value Set).
-Identify the admission date for the stay.

LOGIC:
(
Inpatient Stay
INTERSECT
Nonacute Inpatient Stay
)
UNION
((
Inpatient Stay
EXCEPT
Nonacute Inpatient Stay
)
EXCEPT
Mental Health Diagnosis
)

Author: Philip Sylling
Created: 2019-04-25
Modified: 2019-08-09 | Point to new [final] analytic tables
Modified: 2019-09-20 | Use admit/discharge dates instead of first/last service dates

Returns:
 [id_mcaid]
,[age]
,[claim_header_id]
,[admit_date]
,[discharge_date]
,[flag] = 1
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_fuh_inpatient_index_stay_readmit]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_fuh_inpatient_index_stay_readmit];
GO
CREATE VIEW [stage].[v_perf_fuh_inpatient_index_stay_readmit]
AS
/*
SELECT [value_set_name]
      ,[code_system]
      ,COUNT([code])
FROM [archive].[hedis_code_system]
WHERE [value_set_name] IN
('Mental Illness'
,'Mental Health Diagnosis'
,'Inpatient Stay'
,'Nonacute Inpatient Stay')
GROUP BY [value_set_name], [code_system]
ORDER BY [value_set_name], [code_system];
*/

WITH [non_acute] AS
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,'Nonacute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Inpatient Stay')
AND [code_set] = 'UBREV'

INTERSECT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,'Nonacute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBREV'

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,'Nonacute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBTOB'
)),

[acute] AS
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,'Acute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Inpatient Stay')
AND [code_set] = 'UBREV'

EXCEPT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,'Acute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBREV'

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,'Acute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN 
('Nonacute Inpatient Stay')
AND [code_set] = 'UBTOB'
)

EXCEPT

(
SELECT 
 [id_mcaid]
,[claim_header_id]
,'Acute' AS [acuity]
,1 AS [flag]

--SELECT COUNT(*)
FROM [stage].[mcaid_claim_value_set]
WHERE 1 = 1
AND [value_set_group] = 'HEDIS'
AND [value_set_name] IN ('Mental Health Diagnosis')
AND [code_set] = 'ICD10CM'
-- Principal Diagnosis
AND [primary_dx_only] = 'Y'
)),

[readmit] AS
(
SELECT 
 [id_mcaid]
,[claim_header_id]
,[flag]
,[acuity]
FROM [non_acute]

UNION

SELECT 
 [id_mcaid]
,[claim_header_id]
,[flag]
,[acuity]
FROM [acute]
)

SELECT 
 re.[id_mcaid]
,re.[claim_header_id]
,hd.[admsn_date] AS [admit_date]
,hd.[dschrg_date] AS [discharge_date]
,hd.[first_service_date]
,hd.[last_service_date]
,[acuity]
,[flag]
FROM [readmit] AS re
INNER JOIN [final].[mcaid_claim_header] AS hd
ON re.[claim_header_id] = hd.[claim_header_id]
GO

/*
-- 84,893
SELECT COUNT(*) 
FROM [stage].[v_perf_fuh_inpatient_index_stay_readmit]
WHERE [admit_date] BETWEEN '2017-01-01' AND '2017-12-31';

SELECT DISTINCT
 [id_mcaid]
,[claim_header_id]
,[admit_date]
,[discharge_date]
,[first_service_date]
,[last_service_date]
,[acuity]
,[flag]
FROM [stage].[v_perf_fuh_inpatient_index_stay_readmit]
WHERE [admit_date] BETWEEN '2017-01-01' AND '2017-12-31';
*/