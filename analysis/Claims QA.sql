/***** EXAMINE NEW CLAIMS DATA
Eli Kern, APDE
Script date: 8/22/2017
Claims data received from HCA on 8/18/2017
51 Server, dbo.NewClaims (created 8/4/17), 79,275,544 lines
This new data extract from HCA was designed to include additional line level variables not shared before,
including procedure codes, diagnostic codes and RAC codes
 *****/

--Number of distinct claims and claim lines by service year (denominator)
select srvc_year, count(distinct tcn) as tcn_count, count(distinct clm_line_tcn) as clmline_count
from (
	select year(from_srvc_date) as srvc_year, tcn, clm_line_tcn
	from dbo.NewClaims
	) temp1
group by srvc_year

--Number of distinct claims and claim lines by service year and claim type (denominator), 20 min run time
select srvc_year, clm_type_cid, count(distinct tcn) as tcn_count, count(distinct clm_line_tcn) as clmline_count
from (
	select year(from_srvc_date) as srvc_year, tcn, clm_line_tcn, CLM_TYPE_CID
	from dbo.NewClaims
	) temp1
group by srvc_year, CLM_TYPE_CID

--Number of claim lines with non-missing procedure code variables, by service year and claim type, 11 min run time
select srvc_year, clm_type_cid, count(prcdr_code_1) as proc1, count(prcdr_code_2) as proc2, count(prcdr_code_3) as proc3, count(prcdr_code_4) as proc4,
	count(prcdr_code_5) as proc5, count(prcdr_code_6) as proc6, count(prcdr_code_7) as proc7, count(prcdr_code_8) as proc8,
	count(prcdr_code_9) as proc9, count(prcdr_code_10) as proc10, count(prcdr_code_11) as proc11, count(prcdr_code_12) as proc12,
	count(line_prcdr_code) as lineproc
from (
	select distinct CLM_LINE_TCN, PRCDR_CODE_1, PRCDR_CODE_2, PRCDR_CODE_3, PRCDR_CODE_4, PRCDR_CODE_5, PRCDR_CODE_6, PRCDR_CODE_7,
		PRCDR_CODE_8, PRCDR_CODE_9, PRCDR_CODE_10, PRCDR_CODE_11, PRCDR_CODE_12, LINE_PRCDR_CODE, CLM_TYPE_CID, year(FROM_SRVC_DATE) as srvc_year
	from dbo.NewClaims
	) temp1
group by srvc_year, CLM_TYPE_CID

--Number of claim lines with non-missing diagnosis code variables, by service year and claim type, 11 min run time
select srvc_year, clm_type_cid, count(primary_diagnosis_code) as diag1, count(diagnosis_code_2) as diag2, count(diagnosis_code_3) as diag3, count(diagnosis_code_4) as diag4,
	count(diagnosis_code_5) as diag5, count(diagnosis_code_6) as diag6, count(diagnosis_code_7) as diag7, count(diagnosis_code_8) as diag8,
	count(diagnosis_code_9) as diag9, count(diagnosis_code_10) as diag10, count(diagnosis_code_11) as diag11, count(diagnosis_code_12) as diag12,
	count(primary_diagnosis_code_line) as diag1_line, count(diagnosis_code_2_line) as diag2_line, count(diagnosis_code_3_line) as diag3_line, count(diagnosis_code_4_line) as diag4_line,
	count(diagnosis_code_5_line) as diag5_line, count(diagnosis_code_6_line) as diag6_line, count(diagnosis_code_7_line) as diag7_line, count(diagnosis_code_8_line) as diag8_line,
	count(diagnosis_code_9_line) as diag9_line, count(diagnosis_code_10_line) as diag10_line, count(diagnosis_code_11_line) as diag11_line, count(diagnosis_code_12_line) as diag12_line
from (
	select distinct CLM_LINE_TCN, PRIMARY_DIAGNOSIS_CODE, DIAGNOSIS_CODE_2, DIAGNOSIS_CODE_3, DIAGNOSIS_CODE_4, DIAGNOSIS_CODE_5, DIAGNOSIS_CODE_6, DIAGNOSIS_CODE_7,
		DIAGNOSIS_CODE_8, DIAGNOSIS_CODE_9, DIAGNOSIS_CODE_10, DIAGNOSIS_CODE_11, DIAGNOSIS_CODE_12, PRIMARY_DIAGNOSIS_CODE_LINE, DIAGNOSIS_CODE_2_LINE, DIAGNOSIS_CODE_3_LINE, DIAGNOSIS_CODE_4_LINE,
		DIAGNOSIS_CODE_5_LINE, DIAGNOSIS_CODE_6_LINE, DIAGNOSIS_CODE_7_LINE, DIAGNOSIS_CODE_8_LINE, DIAGNOSIS_CODE_9_LINE, DIAGNOSIS_CODE_10_LINE, DIAGNOSIS_CODE_11_LINE, DIAGNOSIS_CODE_12_LINE,
		CLM_TYPE_CID, year(FROM_SRVC_DATE) as srvc_year
	from dbo.NewClaims
	) temp1
group by srvc_year, CLM_TYPE_CID

--Number of claim lines with non-missing other code variables, by service year and claim type, 11 min run time
select srvc_year, clm_type_cid, count(drg_code) as drg, count(revenue_code) as revcode, count(paid_amt_h) as paid_head, count(paid_amt_l) as paid_line, count(ndc) as ndc,
	count(rac_code_line) as rac_line, count(mdfr_code1) as mdfr1, count(mdfr_code2) as mdfr2, count(mdfr_code3) as mdfr3, count(mdfr_code4) as mdfr4
from (
	select distinct CLM_LINE_TCN, DRG_CODE, REVENUE_CODE, PAID_AMT_H, PAID_AMT_L, NDC, RAC_CODE_LINE, MDFR_CODE1, MDFR_CODE2, MDFR_CODE3, MDFR_CODE4,
		CLM_TYPE_CID, year(FROM_SRVC_DATE) as srvc_year
	from dbo.NewClaims
	) temp1
group by srvc_year, CLM_TYPE_CID

----------------------
----------------------
----Testing code below
--View line level procedure codes for inpatient claims in 2016
select distinct from_srvc_date, CLM_LINE_TCN, clm_type_cid, line_prcdr_code
from dbo.NewClaims
where year(FROM_SRVC_DATE) = 2016 and CLM_TYPE_CID = 31
order by FROM_SRVC_DATE