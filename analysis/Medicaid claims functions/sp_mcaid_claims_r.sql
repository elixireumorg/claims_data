--Eli Kern
--Assessment, Policy Development & Evaluation, Public Health - Seattle & King County
--6/27/18
--Code to return a claim summary for a member cohort generated by the Medicaid eligibility cohort function
--This script creates a stored procedure for use within R (only difference is that this does not create a temp table)
--This stored procedure is intended to be run in sequence with the MEdicaid eligibilty cohort function (sp_mcaidcohort_sql)

--select database
use PHClaims
go

--drop stored procedure before creating new
drop procedure dbo.sp_mcaid_claims_r
go

--create stored procedure
create proc dbo.sp_mcaid_claims_r
	(
	@from_date as date,
	@to_date as date
	)
as
begin

select query_from_date = @from_date, query_to_date = @to_date, elig.*, 
	case when claim.mental_dx1_cnt is null then 0 else claim.mental_dx1_cnt end as 'mental_dx1_cnt',
	case when claim.mental_dxany_cnt is null then 0 else claim.mental_dxany_cnt end as 'mental_dxany_cnt',
	case when claim.maternal_dx1_cnt is null then 0 else claim.maternal_dx1_cnt end as 'maternal_dx1_cnt',
	case when claim.maternal_broad_dx1_cnt is null then 0 else claim.maternal_broad_dx1_cnt end as 'maternal_broad_dx1_cnt',
	case when claim.newborn_dx1_cnt is null then 0 else claim.newborn_dx1_cnt end as 'newborn_dx1_cnt',
	case when claim.inpatient_cnt is null then 0 else claim.inpatient_cnt end as 'inpatient_cnt',
	case when claim.ipt_medsurg_cnt is null then 0 else claim.ipt_medsurg_cnt end as 'ipt_medsurg_cnt',
	case when claim.ipt_bh_cnt is null then 0 else claim.ipt_bh_cnt end as 'ipt_bh_cnt',
	case when claim.ed_cnt is null then 0 else claim.ed_cnt end as 'ed_cnt',
	case when claim.ed_nohosp_cnt is null then 0 else claim.ed_nohosp_cnt end as 'ed_nohosp_cnt',
	case when claim.ed_avoid_ca_cnt is null then 0 else claim.ed_avoid_ca_cnt end as 'ed_avoid_ca_cnt',
	case when claim.ed_avoid_ca_nohosp_cnt is null then 0 else claim.ed_avoid_ca_nohosp_cnt end as 'ed_avoid_ca_nohosp_cnt',
	case when claim.mental_dx_rda_any_cnt is null then 0 else claim.mental_dx_rda_any_cnt end as 'mental_dx_rda_any_cnt',
	case when claim.sud_dx_rda_any_cnt is null then 0 else claim.sud_dx_rda_any_cnt end as 'sud_dx_rda_any_cnt',
	case when claim.dental_cnt is null then 0 else claim.dental_cnt end as 'dental_cnt',
	case when claim.ed_cnt is null then 1 else 0 end as 'no_claims'

from (
	select * from ##mcaidcohort
) as elig

left join (
	select b.id,
			sum(b.mental_dx1) as 'mental_dx1_cnt', sum(b.mental_dxany) as 'mental_dxany_cnt',
			sum(b.maternal_dx1) as 'maternal_dx1_cnt', sum(b.maternal_broad_dx1) as 'maternal_broad_dx1_cnt',
			sum(b.newborn_dx1) as 'newborn_dx1_cnt', sum(b.inpatient) as 'inpatient_cnt', sum(b.ipt_medsurg) as 'ipt_medsurg_cnt',
			sum(b.ipt_bh) as 'ipt_bh_cnt', sum( b.ed) as 'ed_cnt', sum(b.ed_nohosp) as 'ed_nohosp_cnt', sum(b.ed_avoid_ca) as 'ed_avoid_ca_cnt', 
			sum(b.ed_avoid_ca_nohosp) as 'ed_avoid_ca_nohosp_cnt', sum(b.mental_dx_rda_any) as 'mental_dx_rda_any_cnt', sum(b.sud_dx_rda_any) as 'sud_dx_rda_any_cnt',
			sum(b.dental) as 'dental_cnt'

	from (
		select a.id,
			max(a.mental_dx1) as 'mental_dx1', max(a.mental_dxany) as 'mental_dxany',
			max(a.maternal_dx1) as 'maternal_dx1', max(a.maternal_broad_dx1) as 'maternal_broad_dx1',
			max(a.newborn_dx1) as 'newborn_dx1', max(a.inpatient) as 'inpatient', max(a.ipt_medsurg) as 'ipt_medsurg',
			max(a.ipt_bh) as 'ipt_bh', max(a.ed) as 'ed', max(a.ed_nohosp) as 'ed_nohosp', max(a.ed_avoid_ca) as 'ed_avoid_ca', 
			max(a.ed_avoid_ca_nohosp) as 'ed_avoid_ca_nohosp', max(a.mental_dx_rda_any) as 'mental_dx_rda_any', max(a.sud_dx_rda_any) as 'sud_dx_rda_any',
			max(a.dental) as 'dental'

		from (
			select id from ##mcaidcohort
		) as id

		left join (
			select *, 
			case when clm_type_code = '4' then 1 else 0 end as 'dental'
			from PHClaims.dbo.mcaid_claim_summary
			where from_date <= @to_date and to_date >= @from_date
				and exists (select id from ##id where id = PHClaims.dbo.mcaid_claim_summary.id)
		) as a
		on id.id = a.id
		group by a.id, a.from_date
	) as b
	group by b.id
) as claim
on elig.id = claim.id

end