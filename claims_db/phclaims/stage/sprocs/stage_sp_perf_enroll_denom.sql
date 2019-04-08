
USE [PHClaims];
GO

IF OBJECT_ID('[stage].[sp_perf_enroll_denom]','P') IS NOT NULL
DROP PROCEDURE [stage].[sp_perf_enroll_denom];
GO
CREATE PROCEDURE [stage].[sp_perf_enroll_denom]
 @start_date_int INT = 201701
,@end_date_int INT = 201712
AS
SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN

SET @SQL = @SQL + N'
IF OBJECT_ID(''tempdb..#temp'', ''U'') IS NOT NULL
DROP TABLE #temp;
SELECT *
INTO #temp
FROM [stage].[fn_perf_enroll_member_month](' + CAST(@start_date_int AS NVARCHAR(20)) + ', ' + CAST(@end_date_int AS NVARCHAR(20)) + ');

CREATE CLUSTERED INDEX [idx_cl_#temp_id_year_month] ON #temp([id], [year_month]);

IF OBJECT_ID(''[stage].[perf_enroll_denom]'',''U'') IS NOT NULL
DROP TABLE [stage].[perf_enroll_denom];

WITH CTE AS
(
SELECT
 [year_month]
,[month]
,[id]
,[dob]
,[end_month_age]
,CASE WHEN [end_month_age] BETWEEN 0 AND 20 THEN [age_in_months] ELSE NULL END AS [age_in_months]

,[enrolled_any]
,SUM([enrolled_any]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS [enrolled_any_t_12_m]

,[full_benefit]
,SUM([full_benefit]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS [full_benefit_t_12_m]

,[dual]
,SUM([dual]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS [dual_t_12_m]

,[hospice]
,SUM([hospice]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS [hospice_t_12_m]
,SUM([hospice]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 23 PRECEDING AND 12 PRECEDING) AS [hospice_prior_t_12_m]
,SUM([hospice]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS [hospice_p_2_m]

,[full_criteria]
,SUM([full_criteria]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS [full_criteria_t_12_m]
,SUM([full_criteria]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN 23 PRECEDING AND 12 PRECEDING) AS [full_criteria_prior_t_12_m]
,SUM([full_criteria]) OVER(PARTITION BY [id] ORDER BY [year_month] ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS [full_criteria_p_2_m]

,[row_num]
FROM #temp
)
SELECT
 [year_month]
,CASE WHEN [month] IN (3, 6, 9, 12) THEN 1 ELSE 0 END AS [end_quarter]
,[id]
,[dob]
,[end_month_age]
,[age_in_months]

,[enrolled_any]
,[enrolled_any_t_12_m]

,[full_benefit]
,[full_benefit_t_12_m]

,[dual]
,[dual_t_12_m]

,[hospice]
,[hospice_t_12_m]
,[hospice_prior_t_12_m]
,[hospice_p_2_m]

,[full_criteria]
,[full_criteria_t_12_m]
,[full_criteria_prior_t_12_m]
,[full_criteria_p_2_m]

INTO [stage].[perf_enroll_denom]
FROM CTE
WHERE 1 = 1
-- Months with at least 23 prior months
AND [row_num] >= 24
-- Include members enrolled at least one month
AND [enrolled_any_t_12_m] >= 1;

CREATE CLUSTERED INDEX [idx_cl_stage_perf_enroll_denom_id_year_month] ON [stage].[perf_enroll_denom]([id], [year_month]);
CREATE NONCLUSTERED INDEX [idx_nc_stage_perf_enroll_denom_end_month_age] ON [stage].[perf_enroll_denom]([end_month_age]);
CREATE NONCLUSTERED INDEX [idx_nc_stage_perf_enroll_denom_age_in_months] ON [stage].[perf_enroll_denom]([age_in_months]);

IF OBJECT_ID(''[stage].[perf_distinct_member]'',''U'') IS NOT NULL
DROP TABLE [stage].[perf_distinct_member];
SELECT DISTINCT [id]
INTO [stage].[perf_distinct_member]
FROM [stage].[perf_enroll_denom];

CREATE CLUSTERED INDEX [idx_cl_stage_perf_distinct_member_id] ON [stage].[perf_distinct_member]([id]);'

PRINT @SQL;
END

EXEC sp_executeSQL @statement=@SQL, 
                   @params=N'@start_date_int INT, @end_date_int INT',
				   @start_date_int=@start_date_int, @end_date_int=@end_date_int;
GO

/*
If the first 12-month period ends 201303
@start_date_int = 201204 to get the full 12 months
If the last 12-month period ends 201712
@end_date_int = 201712
THESE PARAMETERS ARE INTEGERS
This procedure will index the [stage].[perf_enroll_denom] table

EXEC [stage].[sp_perf_enroll_denom] @start_date_int = 201501, @end_date_int = 201712;

SELECT 
 [year_month]
,COUNT(*)
FROM [stage].[perf_enroll_denom]
GROUP BY [year_month]
ORDER BY [year_month];

SELECT NumRows
      ,COUNT(*)
FROM
(
SELECT [id]
      ,[year_month]
      ,COUNT(*) AS NumRows
FROM [stage].[perf_enroll_denom]
GROUP BY [id], [year_month]
) AS SubQuery
GROUP BY NumRows
ORDER BY NumRows;

SELECT b.[end_month], a.*
FROM [stage].[perf_enroll_denom] AS a
INNER JOIN [ref].[perf_year_month] AS b
ON a.[year_month] = b.[year_month]
WHERE [end_month_age] <= 2
ORDER BY [id], [year_month];

SELECT
 [end_month_age]
,[age_in_months]
,COUNT(*)
FROM [PHClaims].[stage].[perf_enroll_denom]
GROUP BY [end_month_age], [age_in_months]
ORDER BY [end_month_age], [age_in_months];
*/