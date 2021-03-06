-- Code to create an overall record of a person's Medicaid eligibility by coverage group information, including dual eligibility and RAC codes
-- Alastair Matheson and Eli Kern (PHSKC-APDE)
-- 2017-05
--updated 2018-06-01 to account for nested time periods that occur due to multiple RAC codes with overlapping coverage periods and adding coverage time
--updated 2018-07-03 to merge elig_dual and elig_covgrp tables into one

-- Code collapses data from 1+ rows per person per month to a single row of contiguous coverage per person per coverage variables
-- Takes 7-8m to run

--------------
--step 1: create temp table - 1 row of contiguous coverage per person per dual flag and RAC codes
--------------

-- Remove existing table
if object_id('tempdb..#mcaid_elig_covgrp_load') IS NOT NULL drop table #mcaid_elig_covgrp_load

-- Collapse to single row again (2nd and final time given we have now removed nested periods)
select cast(i.id as varchar(200)) as 'id', cast(min(i.from_date) as date) as from_date,
	cast(max(i.to_date) as date) as to_date, cast(i.dual as varchar(200)) as 'dual', 
	cast(i.rac_code as varchar(200)) as 'rac_code',	datediff(dd, min(i.from_date), max(i.to_date)) + 1 as cov_time_day

into #mcaid_elig_covgrp_load

from (	
	-- Set up groups where there is contiguous coverage (2nd time around given we have now removed nested periods)
	select h.id, h.dual, h.rac_code, h.from_date, h.to_date, h.group_num2,
		sum(case when h.group_num2 is null then 0 else 1 end) over
			(partition by h.id, h.dual, h.rac_code order by h.temp_row rows between unbounded preceding and current row) as group_num3

	from (
		-- Set up flag for when there is a break in coverage, and drop nested time periods
		select g.id, g.dual, g.rac_code, g.from_date, g.to_date,
		case 
			when g.from_date - lag(g.to_date) over (partition by g.id, g.dual, g.rac_code order by g.id, g.from_date) <= 1 then null
			else row_number() over (partition by g.id, g.dual, g.rac_code order by g.from_date)
		end as group_num2,
		row_number() over (partition by g.id, g.dual, g.rac_code order by g.id, g.from_date, g.to_date) as temp_row

		from (
			--Flag nested time periods (occurs due to multiple RACs with overlapping time)
			select f.id, f.dual, f.rac_code, f.from_date, f.to_date,
				--Sorting by ID, from_date and to_date (descending so tied from_dates have most recent to_date listed first), 
					--go down rows and find minimum from date thus far
				min(f.from_date) over (partition by f.id, f.dual, f.rac_code order by f.id, f.from_date, f.to_date desc
					rows between unbounded preceding and current row) as 'min_from',

				--Sorting by ID, from_date and to_date (descending so tied from_dates have most recent to_date listed first), 
					--go down rows and find maximum to date thus far
				max(f.to_date) over (partition by f.id, f.dual, f.rac_code order by f.id, f.from_date, f.to_date desc
					rows between unbounded preceding and current row) as 'max_to'

			from (
				-- Use the from and to date info to find sub-month coverage
				select e.id, e.dual, e.rac_code, e.group_num,
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
					select d.id, d.dual, d.rac_code, min(calmonth) as startdate, dateadd(day, - 1, dateadd(month, 1, max(calmonth))) as enddate,
						d.group_num, d.fromdate, d.todate
						
					from (
						-- Keep just the variables formed in the select statement below
						select distinct c.id, c.dual, c.rac_code, c.calmonth, c.group_num, c.fromdate, c.todate
							
						from (
							-- This sets assigns a contiguous set of months to the same group number per id
							select distinct b.id, b.dual, b.rac_code, b.calmonth, b.fromdate,b.todate,
								datediff(month, 0, calmonth) - 
									row_number() over (partition by b.id, b.dual, b.rac_code order by calmonth) as group_num
									
							from (
								-- Start here by pulling out the row per month data and converting the row per month field into a date
								select distinct a.MEDICAID_RECIPIENT_ID as id, a.DUAL_ELIG AS dual, a.rac_code as rac_code,
									CONVERT(DATETIME, CAST(a.CLNDR_YEAR_MNTH as varchar(200)) + '01', 112) AS calmonth,
									a.FROM_DATE as fromdate, a.TO_DATE as todate
									
								from ( 
									select * from [PHClaims].[dbo].[mcaid_elig_raw]
								) a
							) b
						) c
					) d
					group by d.id, d.dual, d.rac_code, d.group_num, d.fromdate, d.todate
				) e
			) f
		) g
		where g.from_date >= g.min_from and g.to_date = g.max_to
	) h
) i
group by i.id, i.dual, i.rac_code, i.group_num3
order by i.id, from_date

--------------
--step 2: create final table with RAC-based coverage group variables
--------------

use PHClaims
go

if object_id('dbo.mcaid_elig_covgrp_load', 'U') IS NOT NULL 
  drop table dbo.mcaid_elig_covgrp_load;

--create coverage group vars per EDMA's code
select distinct x.*,

--new adults (medicaid cn expansion adults + aem expansion adults)
case when x.rac_code in (1201,1217,1178,1181,1210) then 1 else 0 end as 'new_adult',

--apple health for kids
case when x.rac_code in (1029,1030,1031,1032,1033,1039,1040,1138,1139,1140,1141,1142,1202,1203,
1204,1205,1206,1207,1211,1212,1213,1052,1056,1059,1060,1179,1034,1036,
1037,1040) then 1 else 0 end as 'apple_kids',

--older adults (elderly persons)
case when x.rac_code in (1000,1001,1006,1007,1010,1011,1041,1043,1046,1048,1050,1065,1066,1071,
1072,1073,1074,1077,1082,1083,1084,1085,1086,1089,1090,1188,1104,1108,
1109,1119,1124,1125,1146,1148,1149,1174,1154,1155,1158,1190,1191,1192,
1214,1218,1222,1223,1226,1230,1231,1232,1236,1240,1241,1248,1249,1250,
1251,1256,1257,1260,1264,1265,1266,1004,1068,1069,1106,1152,1220,1228,
1238,1246,1262) then 1 else 0 end as 'older_adults',

--family (TANF) medical
case when x.rac_code in (1024,1026,1027,1028,1038,1103,1035,1038,1122,1123) then 1 else 0 end as 'family_med',

--family planning
case when x.rac_code in (1097,1098,1099,1100) then 1 else 0 end as 'family_planning',

--former foster care adults
case when x.rac_code in(1196) then 1 else 0 end as 'former_foster',

--foster care
case when x.rac_code in (1014,1015,1016,1017,1018,1019,1020,1021,1022,1023) then 1 else 0 end as 'foster',

--medicaid cn caretaker adults
case when x.rac_code in (1208,1197,1198,1054,1055,1058,1063,1064,1181) then 1 else 0 end as 'caretaker_adults',

--partial duals
case when x.rac_code in (1112,1113,1114,1115,1116,1117,1118) then 1 else 0 end as 'partial_duals',

--disabled
case when x.rac_code in (1002,1003,1008,1009,1012,1013,1044,1047,1049,1067,1075,1076,1081,1184,
1082,1085,1086,1087,1187,1091,1092,1189,1105,1110,1111,1120,1121,1126,
1127,1134,1137,1147,1150,1151,1175,1091,1156,1157,1160,1161,1162,1163,
1164,1165,1166,1167,1168,1156,1193,1194,1195,1215,1219,1224,1225,1227,
1233,1234,1235,1237,1242,1245,1252,1253,1254,1255,1258,1259,1261,1267,
1268,1269,1229,3199,1132,1005,1051,1176,1070,1107,1153,1169,1221,1229,
1239,1247,1263,1005,1070,1042,1094,1136,1135,1145,1216,1128,1170,1130,
1172,1045,1129,1171,1131,1173,1133) then 1 else 0 end as 'disabled',

--pregnant women's coverage
case when x.rac_code in (1095,1096,1101,1102,1199,1200,1209,1061,1053,1057,1177,1062,1180) then 1 else 0 end as 'pregnancy'

into PHClaims.dbo.mcaid_elig_covgrp_load
from #mcaid_elig_covgrp_load as x