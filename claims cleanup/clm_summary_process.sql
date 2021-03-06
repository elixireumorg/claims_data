--Code to create table to hold DISTINCT header-level claim information -> dbo.mcaid_claim_summary
--Eli Kern and Alastair Matheson
--APDE, PHSKC
--6/6/2018

--6/6/18 update: added RDA-based MH and SUD flags
--7/26/18 update: added NY ED classification algorithm
--9/6/18 update: reran table to include new ICD-CCS mappings based on request from Titus
--10/5/18 update: add primary diagnosis and version to table, add SDOH flag for ICD-10-CM codes
--10/11/18 update: fix external cause process for ICD9-CM and ICD10-CM codes, and reorganized script to use temp tables in linear fashion
--10/15/18 update: added final ccs categories
--10/24/18 update: added table indices
--10/30/18 update: added original NYU ED algorithm columns

--Run time: approximately 36 min, over 50 million records

--------------------------------------
--STEP 1: select header-level information needed for event flags
--------------------------------------
if object_id('tempdb..#header') is not null drop table #header
select id, tcn, clm_type_code, from_date, to_date, patient_status, adm_source, pos_code, clm_cat_code,
	bill_type_code, clm_status_code, billing_npi, drg_code, unit_srvc_h,
	--inpatient stay
	case when clm_type_code in (31,33) then 1 else 0 end as 'inpatient',
	--mental health-related DRG
	case when drg_code between '876' and '897'
		or drg_code between '945' and '946'
	then 1 else 0 end as 'mh_drg',
	--newborn/liveborn infant-related DRG
	case when drg_code between '789' and '795'
	then 1 else 0 end as 'newborn_drg',
	--maternity-related DRG or type of bill
	case when bill_type_code in ('840','841','842','843','844','845','847','848','84F','84G','84H','84I','84J','84K','84M',
		'84O','84X','84Y','84Z') or drg_code between '765' and '782'
	then 1 else 0 end as 'maternal_drg_tob'
into #header
from PHClaims.dbo.mcaid_claim_header

--------------------------------------
--STEP 2: select header-level information needed for event flags
--------------------------------------
if object_id('tempdb..#line') is not null drop table #line
select tcn, 
	--ed visits sub-flags
	max(case when rcode like '045[01269]' or rcode like '0981'
	then 1 else 0 end) as 'ed_rcode',
	--maternity revenue codes
	max(case when rcode in ('0112','0122','0132','0142','0152','0720','0721','0722','0724')
	then 1 else 0 end) as 'maternal_rcode'
into #line
from PHClaims.dbo.mcaid_claim_line
group by tcn

--------------------------------------
--STEP 3: select diagnosis code information needed for event flags
--------------------------------------
if object_id('tempdb..#diag') is not null drop table #diag
select tcn,
	--primary diagnosis code with version
	max(case when dx_number = 1 then dx_norm else null end) as dx_norm,
	max(case when dx_number = 1 then dx_ver else null end) as dx_ver,
	--mental health-related primary diagnosis (HEDIS 2017)
	max(case when dx_number = 1
		and ((dx_norm between '290' and '316' and dx_ver = 9 )
		or (dx_norm between 'F03' and 'F0391' and dx_ver = 10)
		or (dx_norm between 'F10' and 'F69' and dx_ver = 10)
		or (dx_norm between 'F80' and 'F99' and dx_ver = 10))
	then 1 else 0 end) as 'dx1_mental',
	--mental health-related, any diagnosis (HEDIS 2017)
	max(case when ((dx_norm between '290' and '316' and dx_ver = 9)
		or (dx_norm between 'F03' and 'F0391' and dx_ver = 10)
		or (dx_norm between 'F10' and 'F69' and dx_ver = 10)
		or (dx_norm between 'F80' and 'F99' and dx_ver = 10))
	then 1 else 0 end) as 'dxany_mental',
	--newborn-related primary diagnosis (HEDIS 2017)
	max(case when dx_number = 1
		and ((dx_norm between 'V30' and 'V39' and dx_ver = 9)
		or (dx_norm between 'Z38' and 'Z389' and dx_ver = 10))
	then 1 else 0 end) as 'dx1_newborn',
	--maternity-related primary diagnosis (HEDIS 2017)
	max(case when dx_number = 1
		and  ((dx_norm between '630' and '679' and dx_ver = 9)
		or (dx_norm between 'V24' and 'V242' and dx_ver = 9)
		or (dx_norm between 'O00' and 'O9279' and dx_ver = 10)
		or (dx_norm between 'O98' and 'O9989' and dx_ver = 10)
		or (dx_norm between 'O9A' and 'O9A53' and dx_ver = 10)
		or (dx_norm between 'Z0371' and 'Z0379' and dx_ver = 10)
		or (dx_norm between 'Z332' and 'Z3329' and dx_ver = 10)
		or (dx_norm between 'Z39' and 'Z3909' and dx_ver = 10))
	then 1 else 0 end) as 'dx1_maternal',
	--maternity-related primary diagnosis (broader)
	max(case when dx_number = 1
		and  ((dx_norm between '630' and '679' and dx_ver = 9)
		or (dx_norm between 'V20' and 'V29' and dx_ver = 9) /*broader*/
		or (dx_norm between 'O00' and 'O9279' and dx_ver = 10)
		or (dx_norm between 'O94' and 'O9989' and dx_ver = 10) /*broader*/
		or (dx_norm between 'O9A' and 'O9A53' and dx_ver = 10)
		or (dx_norm between 'Z0371' and 'Z0379' and dx_ver = 10)
		or (dx_norm between 'Z30' and 'Z392' and dx_ver = 10) /*broader*/
		or (dx_norm between 'Z3A0' and 'Z3A49' and dx_ver = 10)) /*broader*/
	then 1 else 0 end) as 'dx1_maternal_broad',
	--SDOH-related (any diagnosis)
	max(case when dx_norm between 'Z55' and 'Z659' and dx_ver = 10
	then 1 else 0 end) as 'sdoh_any'
into #diag
from PHClaims.dbo.mcaid_claim_dx
group by tcn

--------------------------------------
--STEP 4: select procedure code information needed for event flags
--------------------------------------
if object_id('tempdb..#pcode') is not null drop table #pcode
select tcn,
	--ed visits sub-flags
	max(case when pcode like '9928[123458]'
	then 1 else 0 end) as 'ed_pcode1',
	max(case when pcode between '10021' and '69990'
	then 1 else 0 end) as 'ed_pcode2'
into #pcode
from PHClaims.dbo.mcaid_claim_proc
group by tcn

--------------------------------------
--STEP 5: create temp summary claims table with event-based flags
--------------------------------------
if object_id('tempdb..#temp1') is not null drop table #temp1
select header.id, header.tcn, header.clm_type_code, header.from_date, header.to_date,
	header.patient_status, header.adm_source, header.pos_code, header.clm_cat_code,
	header.bill_type_code, header.clm_status_code, header.billing_npi,
	header.drg_code, header.unit_srvc_h,
	--Mental health-related primary diagnosis
	case when header.mh_drg = 1 or diag.dx1_mental = 1
	then 1 else 0 end as 'mental_dx1',
	--Mental health-related, any diagnosis
	case when header.mh_drg = 1 or diag.dxany_mental = 1
	then 1 else 0 end as 'mental_dxany',
	--Maternity-related care (primary diagnosis only)
	case when header.maternal_drg_tob = 1 or line.maternal_rcode = 1 or diag.dx1_maternal = 1
	then 1 else 0 end as 'maternal_dx1',
	--Maternity-related care (primary diagnosis only), broader definition for diagnosis codes
	case when header.maternal_drg_tob = 1 or line.maternal_rcode = 1 or diag.dx1_maternal_broad = 1
	then 1 else 0 end as 'maternal_broad_dx1',
	--Newborn-related care (prim. diagnosis only)
	case when header.newborn_drg = 1 or diag.dx1_newborn = 1
	then 1 else 0 end as 'newborn_dx1',
	--Inpatient stay flag
	header.inpatient,
	--ED visit (broad definition)
	case when header.clm_type_code in (3,26,34)
		and (line.ed_rcode = 1
		or pcode.ed_pcode1 = 1
		or (pos_code = '23' and ed_pcode2 = 1))
	then 1 else 0 end as 'ed',
	--Primary diagnosis and version
	diag.dx_norm, diag.dx_ver,
	--SDOH flags
	diag.sdoh_any
into #temp1
from #header as header
left join #line as line on header.tcn = line.tcn
left join #diag as diag on header.tcn = diag.tcn
left join #pcode as pcode on header.tcn = pcode.tcn

--------------------------------------
--STEP 6: Avoidable ED visit flag, California algorithm
--------------------------------------
if object_id('tempdb..#avoid_ca') is not null drop table #avoid_ca
select b.tcn, max(a.ed_avoid_ca) as 'ed_avoid_ca'
into #avoid_ca
from (select dx, dx_ver, ed_avoid_ca from PHClaims.dbo.ref_dx_lookup where ed_avoid_ca = 1) as a
inner join (select tcn, dx_norm, dx_ver from PHClaims.dbo.mcaid_claim_dx where dx_number = 1) as b
on (a.dx = b.dx_norm) and (a.dx_ver = b.dx_ver)
group by b.tcn

--------------------------------------
--STEP 7: ED visit classification, NYU algorithm
--------------------------------------
if object_id('tempdb..#avoid_nyu') is not null drop table #avoid_nyu
select b.tcn, a.ed_needed_unavoid_nyu, a.ed_needed_avoid_nyu,
		a.ed_pc_treatable_nyu, a.ed_nonemergent_nyu, a.ed_mh_nyu, 
		a.ed_sud_nyu, a.ed_alc_nyu, a.ed_injury_nyu,
		a.ed_unclass_nyu
into #avoid_nyu
from PHClaims.dbo.ref_dx_lookup as a
inner join (select tcn, dx_norm, dx_ver from PHClaims.dbo.mcaid_claim_dx where dx_number = 1) as b
on (a.dx = b.dx_norm) and (a.dx_ver = b.dx_ver)

--------------------------------------
--STEP 8: CCS groupings (CCS, CCS-level 1, CCS-level 2), primary diagnosis, final categorization
--------------------------------------
if object_id('tempdb..#ccs') is not null drop table #ccs
select b.tcn, a.ccs, a.ccs_description, a.ccs_description_plain_lang, a.multiccs_lv1, a.multiccs_lv1_description, a.multiccs_lv2, 
	a.multiccs_lv2_description, a.multiccs_lv2_plain_lang, a.ccs_final_code, a.ccs_final_description, a.ccs_final_plain_lang
into #ccs
from PHClaims.dbo.ref_dx_lookup as a
inner join (select tcn, dx_norm, dx_ver from PHClaims.dbo.mcaid_claim_dx where dx_number = 1) as b
on (a.dx = b.dx_norm) and (a.dx_ver = b.dx_ver)

--------------------------------------
--STEP 9: RDA Mental health and Substance use disorder diagnosis flags, any diagnosis
--------------------------------------
if object_id('tempdb..#rda') is not null drop table #rda
select b.tcn, max(a.mental_dx_rda) as 'mental_dx_rda_any', max(a.sud_dx_rda) as 'sud_dx_rda_any'
into #rda
from PHClaims.dbo.ref_dx_lookup as a
inner join PHClaims.dbo.mcaid_claim_dx as b
on (a.dx = b.dx_norm) and (a.dx_ver = b.dx_ver)
group by b.tcn

--------------------------------------
--STEP 10: Injury intent and mechanism, ICD9-CM
--------------------------------------
if object_id('tempdb..#injury9cm') is not null drop table #injury9cm
select c.tcn, c.intent, c.mechanism
into #injury9cm
from (
	--find external cause codes (ICD9-CM) for each TCN, then rank by diagnosis number
	select b.tcn, intent, mechanism, row_number() over (partition by b.tcn order by b.dx_number) as 'diag_rank'
	from (select dx, intent, mechanism from PHClaims.dbo.ref_dx_lookup where intent is not null and dx_ver = 9) as a
	inner join (select tcn, dx_norm, dx_number from PHClaims.dbo.mcaid_claim_dx where dx_ver = 9) as b
	on (a.dx = b.dx_norm)
) as c
--only keep the highest ranked external cause code per claim
where c.diag_rank = 1

--------------------------------------
--STEP 11: Injury intent and mechanism, ICD10-CM
--------------------------------------
--first identify all injury claims (primary diagnosis only)
if object_id('tempdb..#inj10_temp1') is not null drop table #inj10_temp1
select b.tcn
into #inj10_temp1
from (select dx, injury_icd10cm from PHClaims.dbo.ref_dx_lookup where injury_icd10cm = 1 and dx_ver = 10) as a
inner join (select tcn, dx_norm from PHClaims.dbo.mcaid_claim_dx where dx_number = 1 and dx_ver = 10) as b
on a.dx = b.dx_norm

--grab the full list of diagnosis codes for these injury claims
if object_id('tempdb..#inj10_temp2') is not null drop table #inj10_temp2
select b.tcn, b.dx_norm, b.dx_number
into #inj10_temp2
from #inj10_temp1 as a
inner join (select tcn, dx_norm, dx_number from PHClaims.dbo.mcaid_claim_dx where dx_ver = 10) as b
on a.tcn = b.tcn

--grab the highest ranked external cause code for each injury claim
if object_id('tempdb..#injury10cm') is not null drop table #injury10cm
select c.tcn, c.intent, c.mechanism
into #injury10cm
from (
	select b.tcn, intent, mechanism, row_number() over (partition by b.tcn order by b.dx_number) as 'diag_rank'
	from (select dx, dx_ver, intent, mechanism from PHClaims.dbo.ref_dx_lookup where intent is not null and dx_ver = 10) as a
	inner join #inj10_temp2 as b
	on a.dx = b.dx_norm
) as c
where c.diag_rank = 1

--------------------------------------
--STEP 12: Union ICD9-CM and ICD10-CM injury tables
--------------------------------------
if object_id('tempdb..#injury') is not null drop table #injury
select tcn, intent, mechanism into #injury from #injury9cm
union
select tcn, intent, mechanism from #injury10cm

--------------------------------------
--STEP 13: create flags that require comparison of previously created event-based flags across time
--------------------------------------
if object_id('tempdb..#temp2') is not null drop table #temp2
select temp1.*, case when ed_nohosp.ed_nohosp = 1 then 1 else 0 end as 'ed_nohosp'
into #temp2
from #temp1 as temp1
--ED flag that rules out visits with an inpatient stay within 24hrs
left join (
	select y.id, y.tcn, ed_nohosp = 1
	from (
		--group by ID and ED visit date and take minimum difference to get closest inpatient stay
		select distinct x.id, x.tcn, min(x.eh_ddiff) as 'eh_ddiff_pmin'
		from (
			select distinct e.id, ed_date = e.from_date, hosp_date = h.from_date, tcn,
				--create field that calculates difference in days between each ED visit and following inpatient stay
				--set to null when comparison is between ED visits and PRIOR inpatient stays
				case
					when datediff(dd, e.from_date, h.from_date) >=0 then datediff(dd, e.from_date, h.from_date)
					else null
				end as 'eh_ddiff'
			from #temp1 as e
			left join (
				select distinct id, from_date
				from #temp1
				where inpatient = 1
			) as h
			on e.id = h.id
			where e.ed = 1
		) as x
		group by x.id, x.tcn
	) as y
	where y.eh_ddiff_pmin > 1 or y.eh_ddiff_pmin is null
) ed_nohosp
on temp1.tcn = ed_nohosp.tcn

--------------------------------------
--STEP 14: create final table structure
--------------------------------------
IF object_id('PHClaims.dbo.mcaid_claim_summary_load', 'U') is not null DROP TABLE PHClaims.dbo.mcaid_claim_summary_load;
CREATE TABLE PHClaims.dbo.mcaid_claim_summary_load (
	id VARCHAR(200),
	tcn BIGINT NOT NULL,
	clm_type_code VARCHAR(200),
	from_date DATE,
	to_date DATE,
	patient_status VARCHAR(200),
	adm_source VARCHAR(200),
	pos_code VARCHAR(200),
	clm_cat_code VARCHAR(200),
	bill_type_code VARCHAR(200),
	clm_status_code VARCHAR(200),
	billing_npi VARCHAR(200),
	drg_code VARCHAR(200),
	unit_srvc_h NUMERIC(38,4),
	dx_norm VARCHAR(200),
	dx_ver TINYINT,
	mental_dx1 TINYINT,
	mental_dxany TINYINT,
	mental_dx_rda_any TINYINT,
	sud_dx_rda_any TINYINT,
	maternal_dx1 TINYINT,
	maternal_broad_dx1 TINYINT NOT NULL,
	newborn_dx1 TINYINT NOT NULL,
	ed TINYINT NOT NULL,
	ed_nohosp TINYINT NOT NULL,
	ed_bh TINYINT NOT NULL,
	ed_avoid_ca TINYINT NOT NULL,
	ed_avoid_ca_nohosp TINYINT NOT NULL,
	ed_ne_nyu TINYINT NOT NULL,
	ed_pct_nyu TINYINT NOT NULL,
	ed_pa_nyu TINYINT NOT NULL,
	ed_npa_nyu TINYINT NOT NULL,
	ed_mh_nyu TINYINT NOT NULL,
	ed_sud_nyu TINYINT NOT NULL,
	ed_alc_nyu TINYINT NOT NULL,
	ed_injury_nyu TINYINT NOT NULL,
	ed_unclass_nyu TINYINT NOT NULL,
	ed_emergent_nyu TINYINT NOT NULL,
	ed_nonemergent_nyu TINYINT NOT NULL,
	ed_intermediate_nyu TINYINT NOT NULL,
	inpatient TINYINT NOT NULL,
	ipt_medsurg TINYINT,
	ipt_bh TINYINT,
	intent VARCHAR(200),
	mechanism VARCHAR(200),
	sdoh_any TINYINT,
	ed_sdoh TINYINT,
	ipt_sdoh TINYINT,
	ccs VARCHAR(200),
	ccs_description VARCHAR(500),
	ccs_description_plain_lang VARCHAR(500),
	ccs_mult1 VARCHAR(200),
	ccs_mult1_description VARCHAR(500),
	ccs_mult2 VARCHAR(200),
	ccs_mult2_description VARCHAR(500),
	ccs_mult2_plain_lang VARCHAR(500),
	ccs_final_description VARCHAR(500),
	ccs_final_plain_lang VARCHAR(500)
	)


--------------------------------------
--STEP 15: create final summary claims table with all event-based flags (temp table stage)
--------------------------------------
-- Using a temp table because you don't seem to be able to cast a not null variable
select a.*,
	--ED-related flags
	case when a.ed = 1 and a.mental_dxany = 1 then 1 else 0 end as 'ed_bh',
	case when a.ed = 1 and b.ed_avoid_ca = 1 then 1 else 0 end as 'ed_avoid_ca',
	case when a.ed_nohosp = 1 and b.ed_avoid_ca = 1 then 1 else 0 end as 'ed_avoid_ca_nohosp',

	--original nine categories of NYU ED algorithm
	case when a.ed = 1 and c.ed_nonemergent_nyu > 0.50 then 1 else 0 end as 'ed_ne_nyu',
	case when a.ed = 1 and c.ed_pc_treatable_nyu > 0.50 then 1 else 0 end as 'ed_pct_nyu',
	case when a.ed = 1 and c.ed_needed_avoid_nyu > 0.50 then 1 else 0 end as 'ed_pa_nyu',
	case when a.ed = 1 and c.ed_needed_unavoid_nyu > 0.50 then 1 else 0 end as 'ed_npa_nyu',
	case when a.ed = 1 and c.ed_mh_nyu > 0.50 then 1 else 0 end as 'ed_mh_nyu',
	case when a.ed = 1 and c.ed_sud_nyu > 0.50 then 1 else 0 end as 'ed_sud_nyu',
	case when a.ed = 1 and c.ed_alc_nyu > 0.50 then 1 else 0 end as 'ed_alc_nyu',
	case when a.ed = 1 and c.ed_injury_nyu > 0.50 then 1 else 0 end as 'ed_injury_nyu',
	case 
		when a.ed = 1 and ((c.ed_unclass_nyu > 0.50)  or (c.ed_nonemergent_nyu <= 0.50 and c.ed_pc_treatable_nyu <= 0.50
		and c.ed_needed_avoid_nyu <= 0.50 and c.ed_needed_unavoid_nyu <= 0.50 and c.ed_mh_nyu <= 0.50 and c.ed_sud_nyu <= 0.50
		and c.ed_alc_nyu <= 0.50 and c.ed_injury_nyu <= 0.50 and c.ed_unclass_nyu <= 0.50))
	then 1 else 0 end as 'ed_unclass_nyu',

	--collapsed 3 categories of NYU ED algorithm based on Ghandi et al.
	case when a.ed = 1 and (c.ed_needed_unavoid_nyu + c.ed_needed_avoid_nyu) > 0.50 then 1 else 0 end as 'ed_emergent_nyu',
	case when a.ed = 1 and (c.ed_pc_treatable_nyu + c.ed_nonemergent_nyu) > 0.50 then 1 else 0 end as 'ed_nonemergent_nyu',
	case when a.ed = 1 and (((c.ed_needed_unavoid_nyu + c.ed_needed_avoid_nyu) = 0.50) or 
			((c.ed_pc_treatable_nyu + c.ed_nonemergent_nyu) = 0.50)) then 1 else 0 end as 'ed_intermediate_nyu',

	--Inpatient-related flags
	case when a.inpatient = 1 and a.mental_dx1 = 0 and a.newborn_dx1 = 0 and a.maternal_dx1 = 0 then 1 else 0 end as 'ipt_medsurg',
	case when a.inpatient = 1 and a.mental_dxany = 1 then 1 else 0 end as 'ipt_bh',
	--Injuries
	f.intent, f.mechanism,
	--CCS
	d.ccs, d.ccs_description, d.ccs_description_plain_lang, d.multiccs_lv1 as 'ccs_mult1', d.multiccs_lv1_description as 'ccs_mult1_description', d.multiccs_lv2 as 'ccs_mult2', 
	d.multiccs_lv2_description as 'ccs_mult2_description', d.multiccs_lv2_plain_lang as 'ccs_mult2_plain_lang', 
	d.ccs_final_description, d.ccs_final_plain_lang,
	--RDA MH and SUD flagas
	case when e.mental_dx_rda_any = 1 then 1 else 0 end as 'mental_dx_rda_any', 
	case when e.sud_dx_rda_any = 1 then 1 else 0 end as 'sud_dx_rda_any',
	--SDOH ED and IPT flags
	case when a.ed = 1 and a.sdoh_any = 1 then 1 else 0 end as 'ed_sdoh',
	case when a.inpatient = 1 and a.sdoh_any = 1 then 1 else 0 end as 'ipt_sdoh'
into #temp_final
from #temp2 as a
left join #avoid_ca as b
on a.tcn = b.tcn
left join #avoid_nyu as c
on a.tcn = c.tcn
left join #ccs as d
on a.tcn = d.tcn
left join #rda as e
on a.tcn = e.tcn
left join #injury as f
on a.tcn = f.tcn


--------------------------------------
--STEP 16: copy final temp table into summary claims table
--------------------------------------
INSERT INTO PHClaims.dbo.mcaid_claim_summary_load
(id, tcn, clm_type_code, from_date, to_date, patient_status, adm_source, pos_code, clm_cat_code, bill_type_code, clm_status_code,
	billing_npi, drg_code, unit_srvc_h, dx_norm, dx_ver, 
	mental_dx1, mental_dxany, mental_dx_rda_any, sud_dx_rda_any,
	maternal_dx1, maternal_broad_dx1, newborn_dx1,
	ed, ed_nohosp, ed_bh, ed_avoid_ca, ed_avoid_ca_nohosp, 
	ed_ne_nyu, ed_pct_nyu, ed_pa_nyu, ed_npa_nyu,
	ed_mh_nyu, ed_sud_nyu, ed_alc_nyu, ed_injury_nyu, ed_unclass_nyu, 
	ed_emergent_nyu, ed_nonemergent_nyu, ed_intermediate_nyu,
	inpatient, ipt_medsurg, ipt_bh,
	intent, mechanism,
	sdoh_any, ed_sdoh, ipt_sdoh, 
	ccs, ccs_description, ccs_description_plain_lang, ccs_mult1, ccs_mult1_description, ccs_mult2, ccs_mult2_description,
	ccs_mult2_plain_lang, ccs_final_description, ccs_final_plain_lang)
SELECT id, tcn, clm_type_code, from_date, to_date, patient_status, adm_source, pos_code, clm_cat_code, bill_type_code, clm_status_code,
	billing_npi, drg_code, unit_srvc_h, dx_norm, dx_ver, 
	mental_dx1, mental_dxany, mental_dx_rda_any, sud_dx_rda_any,
	maternal_dx1, maternal_broad_dx1, newborn_dx1,
	ed, ed_nohosp, ed_bh, ed_avoid_ca, ed_avoid_ca_nohosp, 
	ed_ne_nyu, ed_pct_nyu, ed_pa_nyu, ed_npa_nyu,
	ed_mh_nyu, ed_sud_nyu, ed_alc_nyu, ed_injury_nyu, ed_unclass_nyu, 
	ed_emergent_nyu, ed_nonemergent_nyu, ed_intermediate_nyu,
	inpatient, ipt_medsurg, ipt_bh,
	intent, mechanism,
	sdoh_any, ed_sdoh, ipt_sdoh, 
	ccs, ccs_description, ccs_description_plain_lang, ccs_mult1, ccs_mult1_description, ccs_mult2, ccs_mult2_description,
	ccs_mult2_plain_lang, ccs_final_description, ccs_final_plain_lang
FROM #temp_final


--------------------------------------
--STEP 17: create table indices
--------------------------------------
ALTER TABLE PHClaims.dbo.mcaid_claim_summary_load ADD CONSTRAINT pk_mcaid_claim_summary_tcn PRIMARY KEY CLUSTERED (tcn)
CREATE NONCLUSTERED INDEX idx_id ON PHClaims.dbo.mcaid_claim_summary_load (id)
CREATE NONCLUSTERED INDEX idx_from_date ON PHClaims.dbo.mcaid_claim_summary_load (from_date)
