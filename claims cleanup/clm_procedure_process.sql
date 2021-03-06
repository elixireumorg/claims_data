--Code to create table to hold DISTINCT procedure codes in long format for Medicaid claims data -> dbo.mcaid_claim_proc
--Eli Kern
--APDE, PHSKC
--3/21/2018
--Run time: 12 min

use PHClaims
go

if object_id('dbo.mcaid_claim_proc_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_claim_proc_load;

select distinct cast(id as varchar(200)) as 'id', cast(tcn as varchar(200)) as 'tcn',
	cast(pcode as varchar(200)) as 'pcode', cast(substring(proc_number, 6,4) as varchar(4)) as 'proc_number',
	cast(MDFR_CODE1 as varchar(200)) as 'pcode_mod_1', cast(MDFR_CODE2 as varchar(200)) as 'pcode_mod_2',
	cast(MDFR_CODE3 as varchar(200)) as 'pcode_mod_3', cast(MDFR_CODE4 as varchar(200)) as 'pcode_mod_4'

into PHClaims.dbo.mcaid_claim_proc_load

from (
	select MEDICAID_RECIPIENT_ID AS 'id', TCN as 'tcn',
	PRCDR_CODE_1 AS 'proc_01', PRCDR_CODE_2 AS 'proc_02', PRCDR_CODE_3 AS 'proc_03', PRCDR_CODE_4 AS 'proc_04',
	PRCDR_CODE_5 AS 'proc_05', PRCDR_CODE_6 AS 'proc_06', PRCDR_CODE_7 AS 'proc_07', PRCDR_CODE_8 AS 'proc_08',
	PRCDR_CODE_9 AS 'proc_09', PRCDR_CODE_10 AS 'proc_10', PRCDR_CODE_11 AS 'proc_11',
	PRCDR_CODE_12 AS 'proc_12', LINE_PRCDR_CODE as 'proc_line', MDFR_CODE1, MDFR_CODE2, MDFR_CODE3, MDFR_CODE4
	from PHClaims.dbo.mcaid_claim_raw
) a
unpivot(pcode for proc_number IN(proc_01,proc_02,proc_03,proc_04,proc_05,proc_06,proc_07,proc_08,proc_09,proc_10,proc_11,proc_12,proc_line)) as pcode
order by id, tcn, proc_number

--create indexes
create index [idx_proc] on PHClaims.dbo.mcaid_claim_proc_load (pcode)


