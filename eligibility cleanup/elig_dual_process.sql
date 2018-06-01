-- Code to create an overall record of a person's Medicaid eligibility by dual status
-- Alastair Matheson and Eli Kern (PHSKC-APDE)
-- 2017-05, updated 2018-06-01 to account for nested time periods that occur due to multiple 
	-- RAC codes with overlapping coverage periods and adding coverage time

-- Code collapses data from 1+ rows per person per month to 
	-- a single row of contiguous coverage per person per dual eligibility status
-- Takes ~7.5m to run

-- Remove existing table
use PHClaims
go
if object_id('dbo.mcaid_elig_dual', 'U') is not null 
  drop table dbo.mcaid_elig_dual;

-- Collapse to single row again (2nd and final time given we have now removed nested periods)
select cast(i.id as varchar(200)) as 'id', cast(min(i.from_date) as date) as from_date,
	cast(max(i.to_date) as date) as to_date, cast(i.dual as varchar(200)) as 'dual', 
	datediff(dd, min(i.from_date), max(i.to_date)) + 1 as cov_time_day

into PHClaims.dbo.mcaid_elig_dual

from (	
	-- Set up groups where there is contiguous coverage (2nd time around given we have now removed nested periods)
	select h.id, h.dual, h.from_date, h.to_date, h.group_num2,
		sum(case when h.group_num2 is null then 0 else 1 end) over
			(partition by h.id, h.dual order by h.temp_row rows between unbounded preceding and current row) as group_num3

	from (
		-- Set up flag for when there is a break in coverage, and drop nested time periods
		select g.id, g.dual, g.from_date, g.to_date,
		case 
			when g.from_date - lag(g.to_date) over (partition by g.id, g.dual order by g.id, g.from_date) <= 1 then null
			else row_number() over (partition by g.id, g.dual order by g.from_date)
		end as group_num2,
		row_number() over (partition by g.id, g.dual order by g.id, g.from_date, g.to_date) as temp_row

		from (
			--Flag nested time periods (occurs due to multiple RACs with overlapping time)
			select f.id, f.dual, f.from_date, f.to_date,
				--Sorting by ID, from_date and to_date (descending so tied from_dates have most recent to_date listed first), 
					--go down rows and find minimum from date thus far
				min(f.from_date) over (partition by f.id, f.dual order by f.id, f.from_date, f.to_date desc
					rows between unbounded preceding and current row) as 'min_from',

				--Sorting by ID, from_date and to_date (descending so tied from_dates have most recent to_date listed first), 
					--go down rows and find maximum to date thus far
				max(f.to_date) over (partition by f.id, f.dual order by f.id, f.from_date, f.to_date desc
					rows between unbounded preceding and current row) as 'max_to'

			from (
				-- Use the from and to date info to find sub-month coverage
				select e.id, e.dual, e.group_num,
					--recreate from_date
					case 
						when e.startdate >= e.fromdate then e.startdate
						when e.startdate < e.fromdate then e.fromdate
						else null
					end as from_date,
					--recreate to_date
					case 
						when e.enddate <= e.todate then e.enddate
						when e.enddate > e.todate then e.todate
						else null
					end as to_date

				from (
					-- Now take the max and min of each ID/contiguous date combo to collapse to one row
					select d.id, d.dual, min(calmonth) as startdate, dateadd(day, - 1, dateadd(month, 1, max(calmonth))) as enddate,
						d.group_num, d.fromdate, d.todate
						
					from (
						-- Keep just the variables formed in the select statement below
						select distinct c.id, c.dual, c.calmonth, c.group_num, c.fromdate, c.todate
							
						from (
							-- This sets assigns a contiguous set of months to the same group number per id
							select distinct b.id, b.dual, b.calmonth, b.fromdate,b.todate,
								datediff(month, 0, calmonth) - 
									row_number() over (partition by b.id, b.dual order by calmonth) as group_num
									
							from (
								-- Start here by pulling out the row per month data and converting the row per month field into a date
								select distinct a.MEDICAID_RECIPIENT_ID as id, a.DUAL_ELIG AS dual,
									CONVERT(DATETIME, a.CLNDR_YEAR_MNTH + '01', 112) AS calmonth,
									a.FROM_DATE as fromdate, a.TO_DATE as todate
									
								from ( 
									select * from [PHClaims].[dbo].[NewEligibility]
								) a
							) b
						) c
					) d
					group by d.id, d.dual, d.group_num, d.fromdate, d.todate
				) e
			) f
		) g
		where g.from_date >= g.min_from and g.to_date = g.max_to
	) h
) i
group by i.id, i.dual, i.group_num3
order by i.id, from_date

