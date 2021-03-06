
/*
This view gets claims that meet the requirements for the DSHS RDA Substance Use
Disorder Treatment Penetration rate numerator.

Author: Philip Sylling
Created: 2019-04-23
Modified: 2019-08-07 | Point to new [final] analytic tables

Returns:
 [id_mcaid]
,[claim_header_id]
,[first_service_date], [FROM_SRVC_DATE]
,[flag], 1 for claim meeting numerator criteria
*/

USE [PHClaims];
GO

IF OBJECT_ID('[stage].[v_perf_tps_numerator]', 'V') IS NOT NULL
DROP VIEW [stage].[v_perf_tps_numerator];
GO
CREATE VIEW [stage].[v_perf_tps_numerator]
AS
/*
SELECT [value_set_group]
      ,[value_set_name]
      ,[data_source_type]
      ,[code_set]
	  ,[active]
      ,COUNT([code])
FROM [ref].[rda_value_set]
WHERE [value_set_group] = 'SUD'
GROUP BY [value_set_group], [value_set_name], [data_source_type], [code_set], [active]
ORDER BY [value_set_group], [value_set_name], [data_source_type], [code_set], [active];
*/

/*
1. Procedure and DRG codes indicating receipt of inpatient/residential, 
outpatient, or methadone OST: SUD-Tx-Pen-Value-Set-2
SELECT *
FROM [ref].[rda_value_set] AS rda
WHERE rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-2';
*/

SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-2'
AND rda.[code_set] IN ('HCPCS', 'ICD9PCS')
AND pr.[procedure_code] = rda.[code]

UNION

SELECT 
 hd.[id_mcaid]
,hd.[claim_header_id]
,hd.[first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_header] AS hd
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-2'
AND rda.[code_set] IN ('DRG')
AND hd.[drvd_drg_code] = rda.[code]

UNION

/*
2. NDC codes indicating receipt of other forms of medication assisted treatment
for SUD: SUD-Tx-Pen-Value-Set-3
SELECT *
FROM [ref].[rda_value_set] AS rda
WHERE rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-3'
*/

SELECT 
 ph.[id_mcaid]
,ph.[claim_header_id]
,ph.[rx_fill_date] AS [first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_pharm] AS ph
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-3'
AND rda.[code_set] = 'NDC'
AND rda.[active] = 'Y'
AND ph.[ndc] = rda.[code]

UNION

/*
3. Outpatient encounters meeting procedure code and primary diagnosis criteria:
a. Procedure code in SUD-Tx-Pen-Value-Set-6 AND
b. Primary diagnosis code in SUD-Tx-Pen-Value-Set-1
*/

(
SELECT 
 pr.[id_mcaid]
,pr.[claim_header_id]
,pr.[first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_procedure] AS pr
INNER JOIN [ref].[rda_value_set] AS rda
ON rda.[value_set_name] = 'SUD-Tx-Pen-Value-Set-6'
AND rda.[code_set] IN ('CPT', 'HCPCS')
AND pr.[procedure_code] = rda.[code]

INTERSECT

(
SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON [value_set_name] = 'SUD-Tx-Pen-Value-Set-1'
AND rda.[code_set] = 'ICD9CM'
AND dx.[icdcm_version] = 9
-- Primary Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code]
WHERE dx.[first_service_date] < '2015-10-01'

UNION

SELECT 
 dx.[id_mcaid]
,dx.[claim_header_id]
,dx.[first_service_date]
--,ym.[year_month]
,1 AS [flag]

FROM [final].[mcaid_claim_icdcm_header] AS dx
INNER JOIN [ref].[rda_value_set] AS rda
ON [value_set_name] = 'SUD-Tx-Pen-Value-Set-1'
AND rda.[code_set] = 'ICD10CM'
AND dx.[icdcm_version] = 10
-- Primary Diagnosis
AND dx.[icdcm_number] = '01'
AND dx.[icdcm_norm] = rda.[code]
WHERE dx.[first_service_date] >= '2015-10-01'
));

/*
4. Outpatient encounters meeting taxonomy and primary diagnosis criteria:
a. Billing or servicing provider taxonomy code in SUD-Tx-Pen-Value-Set-7 AND
b. Primary diagnosis code in SUD-Tx-Pen-Value-Set-1

TAXONOMY CODE NOT AVAILABLE IN MEDICAID DATA
*/
GO

/*
-- 4,926,625
SELECT COUNT(*) FROM [stage].[v_perf_tps_numerator]; -- 00:02:22
*/