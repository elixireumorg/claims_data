--Code to create table to hold DISTINCT header-level claim information -> dbo.mcaid_claim_header
--Eli Kern
--APDE, PHSKC
--3/21/2018
--Run time: ~ 17 min

use PHClaims
go

if object_id('dbo.mcaid_claim_header_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_claim_header_load;

select distinct cast(MEDICAID_RECIPIENT_ID as varchar(200)) as 'id', cast(TCN as varchar(200)) as 'tcn',
	cast(CLM_TYPE_CID as varchar(200)) as 'clm_type_code', cast(FROM_SRVC_DATE as date) as 'from_date',
	cast(TO_SRVC_DATE as date) as 'to_date', cast(PATIENT_STATUS_DESC as varchar(200)) as 'patient_status',
	cast(ADMSN_SOURCE_NAME as varchar(200)) as 'adm_source', cast(left(PLACE_OF_SERVICE, 2) as varchar(200)) as 'pos_code',
	cast(CLM_CTGRY_LKPCD as varchar(200)) as 'clm_cat_code', cast(TYPE_OF_BILL as varchar(200)) as 'bill_type_code',
	cast(CLAIM_STATUS as varchar(200)) as 'clm_status_code', 
	cast(BLNG_NATIONAL_PRVDR_IDNTFR as varchar(200)) as 'billing_npi', cast(DRG_CODE as varchar(200)) as 'drg_code',
	cast(UNIT_SRVC_H as numeric(38,4)) as 'unit_srvc_h'
into PHClaims.dbo.mcaid_claim_header_load
from PHClaims.dbo.mcaid_claim_raw

--create indexes
create index [idx_clm_type] on PHClaims.dbo.mcaid_claim_header_load (clm_type_code)
create index [idx_pos] on PHClaims.dbo.mcaid_claim_header_load (pos_code)
create index [idx_bill_type] on PHClaims.dbo.mcaid_claim_header_load (bill_type_code)

--create index [idx_drg] on PHClaims.dbo.mcaid_claim_header_load (DRG DERIVED WHEN AVAILABLE FROM HCA)


