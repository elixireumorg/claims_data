
USE PHClaims;
GO

/*
Truncate [ref] schema tables and load data from temp tables into [ref] schema 
tables. (1) Adjust the temp table names in the FROM clauses based on the temp 
table destinations in load_ref.hedis_value_set.R.
*/
TRUNCATE TABLE [ref].[hedis_measure];

/*
(2) Adjust the [Measure.ID] column from the source spreadsheets so it is unique
and <= 5 characters.
*/
INSERT INTO [ref].[hedis_measure]
([version]
,[measure_id]
,[measure_name])
SELECT DISTINCT
 2019 AS [version]
,CASE WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'CPT Code Modifiers' THEN 'GG_1'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Identifying Events/Diagnoses Using Laboratory or Pharmacy Data' THEN 'GG_2'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Members in Hospice' THEN 'GG_3'
      WHEN [Measure.ID] = 'PCR2020' AND [Measure.Name] = 'Plan All-Cause Readmissions 2020 Version' THEN 'PCR20'
	  ELSE [Measure.ID]
 END AS [measure_id]
,[Measure.Name] AS [measure_name]
FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-2.xlsx]
ORDER BY [version], [measure_id];

/*
(3) Add [Measure.ID] from the medications measures if not already included in 
the medical measures.
*/
INSERT INTO [ref].[hedis_measure]
([version]
,[measure_id]
,[measure_name])
SELECT DISTINCT
 2019 AS [version]
,[Measure.ID] AS [measure_id]
,[Measure.Name] AS [measure_name]
FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-2.xlsx]
WHERE [Measure.ID] NOT IN
(
SELECT DISTINCT [measure_id] FROM [ref].[hedis_measure]
);

TRUNCATE TABLE [ref].[hedis_value_set];

INSERT INTO [ref].[hedis_value_set]
([version]
,[measure_id]
,[value_set_name]
,[value_set_oid])
SELECT 
 2019 AS [version]
,CASE WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'CPT Code Modifiers' THEN 'GG_1'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Identifying Events/Diagnoses Using Laboratory or Pharmacy Data' THEN 'GG_2'
      WHEN [Measure.ID] = 'GG' AND [Measure.Name] = 'Members in Hospice' THEN 'GG_3'
      WHEN [Measure.ID] = 'PCR2020' AND [Measure.Name] = 'Plan All-Cause Readmissions 2020 Version' THEN 'PCR20'
	  ELSE [Measure.ID]
 END AS [measure_id]
,[Value.Set.Name] AS [value_set_name]
,[Value.Set.OID] AS [value_set_oid]
FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-2.xlsx]
ORDER BY [version], [measure_id], [value_set_name];

TRUNCATE TABLE [ref].[hedis_medication_list];

INSERT INTO [ref].[hedis_medication_list]
([version]
,[measure_id]
,[medication_list_name])
SELECT 
 2019 AS [version]
,[Measure.ID] AS [measure_id]
,[Medication.List.Name] AS [medication_list_name]
FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-2.xlsx]
ORDER BY [version], [measure_id], [medication_list_name];

TRUNCATE TABLE [ref].[hedis_code_system];

INSERT INTO [ref].[hedis_code_system]
([version]
,[value_set_name]
,[code_system]
,[code]
,[definition]
,[value_set_version]
,[code_system_version]
,[value_set_oid]
,[code_system_oid])

/*
(4) Reformat codes: Remove '.' from ICD10CM, Remove '.' and right-zero-pad ICD9CM.
*/
SELECT 
 2019 AS [version]
,[Value.Set.Name] AS [value_set_name]
,[Code.System] AS [code_system]
,CASE WHEN [Code.System] = 'ICD10CM' THEN REPLACE([Code], '.', '') 
      WHEN [Code.System] = 'ICD9CM' THEN REPLACE(CAST(REPLACE([Code], '.', '') AS CHAR(5)), ' ', '0')
	  WHEN [Code.System] = 'ICD9PCS' THEN REPLACE([Code], '.', '')
	  WHEN [Code.System] = 'UBTOB' THEN SUBSTRING([Code], 2, 3)
	  ELSE [Code] 
 END AS [code]
,[Definition] AS [definition]
,[Value.Set.Version] AS [value_set_version]
,[Code.System.Version] AS [code_system_version]
,[Value.Set.OID] AS [value_set_oid]
,[Code.System.OID] AS [code_system_oid]
FROM [tmp].[HEDIS_2019_Volume_2_VSD_11_05_2018-3.xlsx]
ORDER BY [version], [value_set_name], [code_system], [code];

TRUNCATE TABLE [ref].[hedis_ndc_code]

INSERT INTO [ref].[hedis_ndc_code]
([version]
,[medication_list_name]
,[ndc_code]
,[brand_name]
,[generic_product_name]
,[route]
,[description]
,[drug_id]
,[drug_name]
,[package_size]
,[unit]
,[dose]
,[form]
,[med_conversion_factor])

SELECT DISTINCT
 2019 AS [version]
,CASE WHEN [Medication.List] = 'N/A' THEN NULL ELSE [Medication.List] END AS [medication_list_name]
,CASE WHEN [NDC.Code] = 'N/A' THEN NULL ELSE [NDC.Code] END AS [ndc_code]
,CASE WHEN [Brand.Name] = 'N/A' THEN NULL ELSE [Brand.Name] END AS [brand_name]
,CASE WHEN [Generic.Product.Name] = 'N/A' THEN NULL ELSE [Generic.Product.Name] END AS [generic_product_name] 
,CASE WHEN [Route] = 'N/A' THEN NULL ELSE [Route] END AS [route]
,CASE WHEN [Description] = 'N/A' THEN NULL ELSE [Description] END AS [description] 
,CASE WHEN [Drug.ID] = 'N/A' THEN NULL ELSE [Drug.ID] END AS [drug_id]
,CASE WHEN [Drug.Name] = 'N/A' THEN NULL ELSE [Drug.Name] END AS [drug_name]
,CASE WHEN [Package.Size] = 'N/A' THEN NULL ELSE CAST([Package.Size] AS NUMERIC(18, 4)) END AS [package_size]
,CASE WHEN [Unit] = 'N/A' THEN NULL ELSE [Unit] END AS [unit]
,CASE WHEN [Dose] = 'N/A' THEN NULL ELSE CAST([Dose] AS NUMERIC(18, 4)) END AS [dose]
,CASE WHEN [Form] = 'N/A' THEN NULL ELSE [Form] END AS [form]
,CASE WHEN [MED.Conversion.Factor] = 'N/A' THEN NULL ELSE CAST([MED.Conversion.Factor] AS NUMERIC(18, 4)) END AS [med_conversion_factor]
FROM [tmp].[HEDIS_2019_NDC_MLD_Directory-3.xlsx]
ORDER BY [version], [medication_list_name], [ndc_code];
