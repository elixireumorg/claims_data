--Code to create table to hold DISTINCT line-level claim information -> dbo.mcaid_claim_line
--Eli Kern
--APDE, PHSKC
--3/21/2018 
--Run time: 9 mins

use PHClaims
go

if object_id('dbo.mcaid_claim_line_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_claim_line_load;

select distinct cast(MEDICAID_RECIPIENT_ID as varchar(200)) as 'id', cast(TCN as varchar(200)) as 'tcn',
	cast(CLM_LINE_TCN as varchar(200)) as 'tcn_line', cast(REVENUE_CODE as varchar(200)) as 'rcode',
	cast(RAC_CODE_LINE as varchar(200)) as 'rac_code_l'
into PHClaims.dbo.mcaid_claim_line_load
from PHClaims.dbo.mcaid_claim_raw

--create indexes
create index [idx_rcode] on PHClaims.dbo.mcaid_claim_line_load (rcode)
create index [idx_rac_code_l] on PHClaims.dbo.mcaid_claim_line_load (rac_code_l)


