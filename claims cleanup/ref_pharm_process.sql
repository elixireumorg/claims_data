--Code to create table to hold pharmacy lookup information -> dbo.ref_pharm
--Eli Kern
--APDE, PHSKC
--6/25/2018

--Run time: XX

use PHClaims
go

--Create temp table of distinct NDC codes and descriptions
if object_id('tempdb..#ndc') IS NOT NULL 
  drop table #ndc

select distinct cast(ndc as varchar(200)) as 'ndc_code',
	cast(ndc_desc as varchar(500)) as 'ndc_desc'
into #ndc
from PHClaims.dbo.NewClaims
where ndc is not null

--Separate out drugs with only one NDC code listed in temp table
if object_id('tempdb..#ndc_single') IS NOT NULL 
  drop table #ndc_single

select ref.ndc_code, ref.ndc_desc
into #ndc_single
from (
	select a.*
	from (
		select ndc_code, count(ndc_code) as 'cnt'
		from PHClaims.dbo.ref_pharm
		group by ndc_code
	) as a
	where a.cnt = 1
) as single

left join (
	select *
	from PHClaims.dbo.ref_pharm
) as ref
on single.ndc_code = ref.ndc_code

--Process drugs with multiple descriptions per code (just take 1st description)
if object_id('tempdb..#ndc_mult') IS NOT NULL 
  drop table #ndc_mult

select x.ndc_code, x.ndc_desc
into #ndc_mult
from (
	select ref.ndc_code, ref.ndc_desc, row_number() over (partition by ref.ndc_code order by ref.ndc_code, ref.ndc_desc) as 'rank'
	from (
		select a.*
		from (
			select ndc_code, count(ndc_code) as 'cnt'
			from PHClaims.dbo.ref_pharm
			group by ndc_code
		) as a
		where a.cnt > 1
	) as multiple

	left join (
		select *
		from PHClaims.dbo.ref_pharm
	) as ref
	on multiple.ndc_code = ref.ndc_code
) as x
where x.rank = 1

--Append two temp tables together to create final table
if object_id('dbo.ref_pharm', 'U') IS NOT NULL 
  drop table dbo.ref_pharm;

select a.*
into PHClaims.dbo.ref_pharm
from (
	select * from #ndc_single
	union
	select * from #ndc_mult
) as a
where a.ndc_desc is not null

--create indexes
create index [idx_ndc] on PHClaims.dbo.ref_pharm (ndc_code)



