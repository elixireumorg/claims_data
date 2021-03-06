--Code to create table to hold DISTINCT diagnoses in long format for Medicaid claims data -> dbo.mcaid_claim_diag
--Eli Kern
--APDE, PHSKC
--3/21/2018
--Run time: 22 min

use PHClaims
go

if object_id('dbo.mcaid_claim_dx_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_claim_dx_load;

select distinct cast(id as varchar(200)) as 'id', cast(tcn as varchar(200)) as 'tcn',

	--original diagnosis codes
	cast(diagnoses as varchar(200)) as 'dx_raw',
	
	cast(
		case
			when (diagnoses like '[0-9]%' and len(diagnoses) = 3) then diagnoses + '00'
			when (diagnoses like '[0-9]%' and len(diagnoses) = 4) then diagnoses + '0'
			when (diagnoses like 'V%' and TO_SRVC_DATE < '2015-10-01' and len(diagnoses) = 3) then diagnoses + '00'
			when (diagnoses like 'V%' and TO_SRVC_DATE < '2015-10-01' and len(diagnoses) = 4) then diagnoses + '0'
			when (diagnoses like 'E%' and TO_SRVC_DATE < '2015-10-01' and len(diagnoses) = 3) then diagnoses + '00'
			when (diagnoses like 'E%' and TO_SRVC_DATE < '2015-10-01' and len(diagnoses) = 4) then diagnoses + '0'
			else diagnoses 
		end 
	as varchar(200)) as 'dx_norm',

	cast(
		case
			when (diagnoses like '[0-9]%') then 9
			when (diagnoses like 'V%' and TO_SRVC_DATE < '2015-10-01') then 9
			when (diagnoses like 'E%' and TO_SRVC_DATE < '2015-10-01') then 9
			else 10 
		end 
	as tinyint) as 'dx_ver',

	cast(substring(dx_number, 3,2) as tinyint) as 'dx_number'

into PHClaims.dbo.mcaid_claim_dx_load

from (
	select MEDICAID_RECIPIENT_ID AS 'id', TCN as 'tcn', CLM_LINE_TCN, TO_SRVC_DATE,
	PRIMARY_DIAGNOSIS_CODE AS DX1,
	DIAGNOSIS_CODE_2 AS DX2,DIAGNOSIS_CODE_3 AS DX3,DIAGNOSIS_CODE_4 AS DX4,DIAGNOSIS_CODE_5 AS DX5,
	DIAGNOSIS_CODE_6 AS DX6,DIAGNOSIS_CODE_7 AS DX7,DIAGNOSIS_CODE_8 AS DX8,DIAGNOSIS_CODE_9 AS DX9,
	DIAGNOSIS_CODE_10 AS DX10,DIAGNOSIS_CODE_11 AS DX11,DIAGNOSIS_CODE_12 AS DX12
	from PHClaims.dbo.mcaid_claim_raw
) a
unpivot(diagnoses for dx_number IN(DX1, DX2,DX3,DX4,DX5,DX6,DX7,DX8,DX9,DX10,DX11,DX12)) as diagnoses

--create indexes
CREATE CLUSTERED INDEX [idx_cl_tcn_dx_number] ON PHClaims.dbo.mcaid_claim_dx (tcn, dx_number)
CREATE INDEX [idx_dx] on PHClaims.dbo.mcaid_claim_dx_load (dx_norm)


