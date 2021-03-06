
#library("chron")
library("dplyr")
library("dbplyr")
library("DBI")
library("odbc")
library("tidyr")
library("glue")
library("devtools")
#library("medicaid")
library("openxlsx")
library("lubridate")
library("janitor")

dsn <- "PHClaims"
db.connection <- dbConnect(odbc(), dsn)

# RAC Codes
file.dir <- "C:/Users/XXX/github/claims_data/claims_db/phclaims/ref/tables_data/"

input <- read.xlsx(paste0(file.dir, "Medicaid-RAC-Codes-for-Inclusion-Criteria-and-Grouping DSHS.xlsx"), sheet = 1)
tbl <- Id(schema="tmp", table="Medicaid_RAC_Codes_Grouping")
dbWriteTable(db.connection, name=tbl, value=input, overwrite=TRUE)

input <- read.xlsx(paste0(file.dir, "Medicaid-RAC-Codes-for-Inclusion-Criteria-and-Grouping DSHS.xlsx"), sheet = 2)
tbl <- Id(schema="tmp", table="Medicaid_RAC_Codes_Detailed_Codes")
dbWriteTable(db.connection, name=tbl, value=input, overwrite=TRUE)

input <- read.xlsx(paste0(file.dir, "Medicaid-RAC-Codes-for-Inclusion-Criteria-and-Grouping DSHS.xlsx"), sheet = 3)
tbl <- Id(schema="tmp", table="Medicaid_RAC_Codes_Fund_Source")
dbWriteTable(db.connection, name=tbl, value=input, overwrite=TRUE)

input <- read.xlsx(paste0(file.dir, "Medicaid-RAC-Codes-for-Inclusion-Criteria-and-Grouping DSHS.xlsx"), sheet = 4)
tbl <- Id(schema="tmp", table="Medicaid_RAC_Codes_BSP_Group")
dbWriteTable(db.connection, name=tbl, value=input, overwrite=TRUE)