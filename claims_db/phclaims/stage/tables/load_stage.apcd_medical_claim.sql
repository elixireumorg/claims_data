--Code to load data to stage.apcd_medical_claim
--Eli Kern (PHSKC-APDE)
--2019-6-27

------------------
--STEP 1: Set cutoff date for pulling rows from archive table
-------------------
declare @cutoff_date date;
set @cutoff_date = '2017-12-31';

------------------
--STEP 2: Insert archived rows older than cutoff date
--Note exclude any columns that will be completely overwritten with new extract
--Run time: 50 min
-------------------
if object_id('PHClaims.tmp.apcd_medical_claim', 'U') is not null
	drop table PHClaims.tmp.apcd_medical_claim;
--archived rows before cutoff date
--note that eci_diagnosis is commented out as it will be replaced with new data
select
[medical_claim_service_line_id]
,[extract_id]
,[submitter_id]
,[internal_member_id]
,[submitter_clm_control_num]
,[product_code_id]
,[product_code]
,[gender_code]
,[age]
,[age_in_months]
,[subscriber_relationship_id]
,[subscriber_relationship_code]
,[line_counter]
,[first_service_dt]
,[last_service_dt]
,[first_paid_dt]
,[last_paid_dt]
,[admission_dt]
,[discharge_dt]
,[type_of_bill_code]
,[place_of_service_code]
,[revenue_code]
,[procedure_code]
,[procedure_modifier_code_1]
,[procedure_modifier_code_2]
,[procedure_modifier_code_3]
,[procedure_modifier_code_4]
,[national_drug_code]
,[claim_status_id]
,[claim_status_code]
,[payment_arrangement_ind_id]
,[payment_arrangement_ind_code]
,[quantity]
,[charge_amt]
,[icd_version_ind]
,[admitting_diagnosis_code]
,[principal_diagnosis_code]
,[diagnosis_code_other_1]
,[diagnosis_code_other_2]
,[diagnosis_code_other_3]
,[diagnosis_code_other_4]
,[diagnosis_code_other_5]
,[diagnosis_code_other_6]
,[diagnosis_code_other_7]
,[diagnosis_code_other_8]
,[diagnosis_code_other_9]
,[diagnosis_code_other_10]
,[diagnosis_code_other_11]
,[diagnosis_code_other_12]
,[diagnosis_code_other_13]
,[diagnosis_code_other_14]
,[diagnosis_code_other_15]
,[diagnosis_code_other_16]
,[diagnosis_code_other_17]
,[diagnosis_code_other_18]
,[diagnosis_code_other_19]
,[diagnosis_code_other_20]
,[diagnosis_code_other_21]
,[diagnosis_code_other_22]
,[diagnosis_code_other_23]
,[diagnosis_code_other_24]
--,[eci_diagnosis]
,[principal_icd_procedure_code]
,[icd_procedure_code_1]
,[icd_procedure_code_2]
,[icd_procedure_code_3]
,[icd_procedure_code_4]
,[icd_procedure_code_5]
,[icd_procedure_code_6]
,[icd_procedure_code_7]
,[icd_procedure_code_8]
,[icd_procedure_code_9]
,[icd_procedure_code_10]
,[icd_procedure_code_11]
,[icd_procedure_code_12]
,[icd_procedure_code_13]
,[icd_procedure_code_14]
,[icd_procedure_code_15]
,[icd_procedure_code_16]
,[icd_procedure_code_17]
,[icd_procedure_code_18]
,[icd_procedure_code_19]
,[icd_procedure_code_20]
,[icd_procedure_code_21]
,[icd_procedure_code_22]
,[icd_procedure_code_23]
,[icd_procedure_code_24]
,[discharge_status_code]
,[admission_point_of_origin_code]
,[admission_type]
,[family_planning_ind_code]
,[rendering_provider_id]
,[rendering_internal_provider_id]
,[billing_provider_id]
,[billing_internal_provider_id]
,[attending_provider_id]
,[attending_internal_provider_id]
,[referring_provider_id]
,[referring_internal_provider_id]
,[network_indicator_id]
,[network_indicator_code]
,[city]
,[state]
,[zip]
,[age_65_flag]
,[out_of_state_flag]
,[claim_type_id]
,[type_of_setting_id]
,[place_of_setting_id]
,[orphaned_adjustment_flag]
,[denied_claim_flag]
,[emergency_room_flag]
,[dup_flag_pbm_tpa]
,[dup_flag_managed_care]
,[poa_diagnosis_code_principal]
,[poa_diagnosis_code_other_1]
,[poa_diagnosis_code_other_2]
,[poa_diagnosis_code_other_3]
,[poa_diagnosis_code_other_4]
,[poa_diagnosis_code_other_5]
,[poa_diagnosis_code_other_6]
,[poa_diagnosis_code_other_7]
,[poa_diagnosis_code_other_8]
,[poa_diagnosis_code_other_9]
,[poa_diagnosis_code_other_10]
,[poa_diagnosis_code_other_11]
,[medicaid_ffs_flag]
,[injury_dt]
,[benefits_exhausted_dt]
into phclaims.tmp.apcd_medical_claim
from PHclaims.archive.apcd_medical_claim
where first_service_dt <= @cutoff_date;

------------------
--STEP 3: Insert all rows from new extract (load_raw)
--Note exclude any columns that will be completely overwritten with new extract
--Run time: 29 min
-------------------
--new rows from new extract
--note that eci_diagnosis is commented out as it will be replaced with new data
insert into PHClaims.tmp.apcd_medical_claim with (tablock)
select
[medical_claim_service_line_id]
,[extract_id]
,[submitter_id]
,[internal_member_id]
,[submitter_clm_control_num]
,[product_code_id]
,[product_code]
,[gender_code]
,[age]
,[age_in_months]
,[subscriber_relationship_id]
,[subscriber_relationship_code]
,[line_counter]
,[first_service_dt]
,[last_service_dt]
,[first_paid_dt]
,[last_paid_dt]
,[admission_dt]
,[discharge_dt]
,[type_of_bill_code]
,[place_of_service_code]
,[revenue_code]
,[procedure_code]
,[procedure_modifier_code_1]
,[procedure_modifier_code_2]
,[procedure_modifier_code_3]
,[procedure_modifier_code_4]
,[national_drug_code]
,[claim_status_id]
,[claim_status_code]
,[payment_arrangement_ind_id]
,[payment_arrangement_ind_code]
,[quantity]
,[charge_amt]
,[icd_version_ind]
,[admitting_diagnosis_code]
,[principal_diagnosis_code]
,[diagnosis_code_other_1]
,[diagnosis_code_other_2]
,[diagnosis_code_other_3]
,[diagnosis_code_other_4]
,[diagnosis_code_other_5]
,[diagnosis_code_other_6]
,[diagnosis_code_other_7]
,[diagnosis_code_other_8]
,[diagnosis_code_other_9]
,[diagnosis_code_other_10]
,[diagnosis_code_other_11]
,[diagnosis_code_other_12]
,[diagnosis_code_other_13]
,[diagnosis_code_other_14]
,[diagnosis_code_other_15]
,[diagnosis_code_other_16]
,[diagnosis_code_other_17]
,[diagnosis_code_other_18]
,[diagnosis_code_other_19]
,[diagnosis_code_other_20]
,[diagnosis_code_other_21]
,[diagnosis_code_other_22]
,[diagnosis_code_other_23]
,[diagnosis_code_other_24]
--,[eci_diagnosis]
,[principal_icd_procedure_code]
,[icd_procedure_code_1]
,[icd_procedure_code_2]
,[icd_procedure_code_3]
,[icd_procedure_code_4]
,[icd_procedure_code_5]
,[icd_procedure_code_6]
,[icd_procedure_code_7]
,[icd_procedure_code_8]
,[icd_procedure_code_9]
,[icd_procedure_code_10]
,[icd_procedure_code_11]
,[icd_procedure_code_12]
,[icd_procedure_code_13]
,[icd_procedure_code_14]
,[icd_procedure_code_15]
,[icd_procedure_code_16]
,[icd_procedure_code_17]
,[icd_procedure_code_18]
,[icd_procedure_code_19]
,[icd_procedure_code_20]
,[icd_procedure_code_21]
,[icd_procedure_code_22]
,[icd_procedure_code_23]
,[icd_procedure_code_24]
,[discharge_status_code]
,[admission_point_of_origin_code]
,[admission_type]
,[family_planning_ind_code]
,[rendering_provider_id]
,[rendering_internal_provider_id]
,[billing_provider_id]
,[billing_internal_provider_id]
,[attending_provider_id]
,[attending_internal_provider_id]
,[referring_provider_id]
,[referring_internal_provider_id]
,[network_indicator_id]
,[network_indicator_code]
,[city]
,[state]
,[zip]
,[age_65_flag]
,[out_of_state_flag]
,[claim_type_id]
,[type_of_setting_id]
,[place_of_setting_id]
,[orphaned_adjustment_flag]
,[denied_claim_flag]
,[emergency_room_flag]
,[dup_flag_pbm_tpa]
,[dup_flag_managed_care]
,[poa_diagnosis_code_principal]
,[poa_diagnosis_code_other_1]
,[poa_diagnosis_code_other_2]
,[poa_diagnosis_code_other_3]
,[poa_diagnosis_code_other_4]
,[poa_diagnosis_code_other_5]
,[poa_diagnosis_code_other_6]
,[poa_diagnosis_code_other_7]
,[poa_diagnosis_code_other_8]
,[poa_diagnosis_code_other_9]
,[poa_diagnosis_code_other_10]
,[poa_diagnosis_code_other_11]
,[medicaid_ffs_flag]
,[injury_dt]
,[benefits_exhausted_dt]
from PHclaims.load_raw.apcd_medical_claim;

------------------
--STEP 3: Create indexes on tmp schema table and new column table in load_raw
--Run time: 84 min
-------------------
create clustered index idx_cl_tmp_apcd_medical_claim_line_id
on phclaims.tmp.apcd_medical_claim (medical_claim_service_line_id);
create clustered index idx_cl_load_raw_apcd_medical_claim_column_add_line_id
on phclaims.load_raw.apcd_medical_claim_column_add (medical_claim_service_line_id);

------------------
--STEP 4: Join with new columns on claim line ID and insert into table shell
--Run time: 99 min
-------------------
insert into PHClaims.stage.apcd_medical_claim with (tablock)
select
a.[medical_claim_service_line_id]
,a.[extract_id]
,a.[submitter_id]
,a.[internal_member_id]
,a.[submitter_clm_control_num]
,a.[product_code_id]
,a.[product_code]
,a.[gender_code]
,a.[age]
,a.[age_in_months]
,a.[subscriber_relationship_id]
,a.[subscriber_relationship_code]
,a.[line_counter]
,a.[first_service_dt]
,a.[last_service_dt]
,a.[first_paid_dt]
,a.[last_paid_dt]
,a.[admission_dt]
,a.[discharge_dt]
,a.[type_of_bill_code]
,a.[place_of_service_code]
,a.[revenue_code]
,a.[procedure_code]
,a.[procedure_modifier_code_1]
,a.[procedure_modifier_code_2]
,a.[procedure_modifier_code_3]
,a.[procedure_modifier_code_4]
,a.[national_drug_code]
,a.[claim_status_id]
,a.[claim_status_code]
,a.[payment_arrangement_ind_id]
,a.[payment_arrangement_ind_code]
,a.[quantity]
,a.[charge_amt]
,a.[icd_version_ind]
,a.[admitting_diagnosis_code]
,a.[principal_diagnosis_code]
,a.[diagnosis_code_other_1]
,a.[diagnosis_code_other_2]
,a.[diagnosis_code_other_3]
,a.[diagnosis_code_other_4]
,a.[diagnosis_code_other_5]
,a.[diagnosis_code_other_6]
,a.[diagnosis_code_other_7]
,a.[diagnosis_code_other_8]
,a.[diagnosis_code_other_9]
,a.[diagnosis_code_other_10]
,a.[diagnosis_code_other_11]
,a.[diagnosis_code_other_12]
,a.[diagnosis_code_other_13]
,a.[diagnosis_code_other_14]
,a.[diagnosis_code_other_15]
,a.[diagnosis_code_other_16]
,a.[diagnosis_code_other_17]
,a.[diagnosis_code_other_18]
,a.[diagnosis_code_other_19]
,a.[diagnosis_code_other_20]
,a.[diagnosis_code_other_21]
,a.[diagnosis_code_other_22]
,a.[diagnosis_code_other_23]
,a.[diagnosis_code_other_24]
,b.[eci_diagnosis] -- pulled from new extract
,a.[principal_icd_procedure_code]
,a.[icd_procedure_code_1]
,a.[icd_procedure_code_2]
,a.[icd_procedure_code_3]
,a.[icd_procedure_code_4]
,a.[icd_procedure_code_5]
,a.[icd_procedure_code_6]
,a.[icd_procedure_code_7]
,a.[icd_procedure_code_8]
,a.[icd_procedure_code_9]
,a.[icd_procedure_code_10]
,a.[icd_procedure_code_11]
,a.[icd_procedure_code_12]
,a.[icd_procedure_code_13]
,a.[icd_procedure_code_14]
,a.[icd_procedure_code_15]
,a.[icd_procedure_code_16]
,a.[icd_procedure_code_17]
,a.[icd_procedure_code_18]
,a.[icd_procedure_code_19]
,a.[icd_procedure_code_20]
,a.[icd_procedure_code_21]
,a.[icd_procedure_code_22]
,a.[icd_procedure_code_23]
,a.[icd_procedure_code_24]
,a.[discharge_status_code]
,a.[admission_point_of_origin_code]
,a.[admission_type]
,a.[family_planning_ind_code]
,a.[rendering_provider_id]
,a.[rendering_internal_provider_id]
,a.[billing_provider_id]
,a.[billing_internal_provider_id]
,a.[attending_provider_id]
,a.[attending_internal_provider_id]
,a.[referring_provider_id]
,a.[referring_internal_provider_id]
,a.[network_indicator_id]
,a.[network_indicator_code]
,a.[city]
,a.[state]
,a.[zip]
,a.[age_65_flag]
,a.[out_of_state_flag]
,a.[claim_type_id]
,a.[type_of_setting_id]
,a.[place_of_setting_id]
,a.[orphaned_adjustment_flag]
,a.[denied_claim_flag]
,a.[emergency_room_flag]
,a.[dup_flag_pbm_tpa]
,a.[dup_flag_managed_care]
,a.[poa_diagnosis_code_principal]
,a.[poa_diagnosis_code_other_1]
,a.[poa_diagnosis_code_other_2]
,a.[poa_diagnosis_code_other_3]
,a.[poa_diagnosis_code_other_4]
,a.[poa_diagnosis_code_other_5]
,a.[poa_diagnosis_code_other_6]
,a.[poa_diagnosis_code_other_7]
,a.[poa_diagnosis_code_other_8]
,a.[poa_diagnosis_code_other_9]
,a.[poa_diagnosis_code_other_10]
,a.[poa_diagnosis_code_other_11]
,a.[medicaid_ffs_flag]
,a.[injury_dt]
,a.[benefits_exhausted_dt]
,b.[submitted_claim_type_id] --new column
,b.[submitted_claim_type] --new column
from PHClaims.tmp.apcd_medical_claim as a
left join PHClaims.load_raw.apcd_medical_claim_column_add as b
on a.medical_claim_service_line_id = b.medical_claim_service_line_id;

------------------
--STEP 5: Drop tmp schema table
-------------------
drop table PHClaims.tmp.apcd_medical_claim;

