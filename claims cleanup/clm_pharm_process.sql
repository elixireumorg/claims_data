--Code to create table to hold DISTINCT pharmacy information -> dbo.mcaid_claim_pharm
--Only includes claims with non-null ndc values
--Eli Kern
--APDE, PHSKC
--3/21/2018

--Run time: 4 min

use PHClaims
go

if object_id('dbo.mcaid_claim_pharm_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_claim_pharm_load;

select distinct cast(MEDICAID_RECIPIENT_ID as varchar(200)) as 'id', cast(TCN as varchar(200)) as 'tcn',
	cast(NDC as varchar(200)) as 'ndc_code', cast(DRUG_STRENGTH as varchar(200)) as 'drug_strength',
	cast(DAYS_SUPPLY as smallint) as 'drug_supply_d', cast(DRUG_DOSAGE as varchar(200)) as 'drug_dosage',
	cast(SBMTD_DISPENSED_QUANTITY as numeric(38,3)) as 'drug_dispensed_amt', cast(PRSCRPTN_FILLED_DATE as date) as 'drug_fill_date',
	cast(PRSCRBR_ID as varchar(200)) as 'prescriber_id'
into PHClaims.dbo.mcaid_claim_pharm_load
from PHClaims.dbo.mcaid_claim_raw
where ndc is not null

--create indexes
create index [idx_ndc] on PHClaims.dbo.mcaid_claim_pharm_load (ndc_code)


