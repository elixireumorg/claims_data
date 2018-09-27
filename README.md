# King County Medicaid eligibility and claims data
This README describes the structure and content of Medicaid eligibility and claims data that King County government routinely receives from the WA State Health Care Authority (HCA), as well as an R package King County has developed to facilitate analysis and dissemination of these data.

## Available data tables on SQL Server
Currently King County receives quarterly Medicaid eligibility and claims data files (i.e. ProviderOne data) from HCA and loads these into SQL. Moving forward under a new Master Data Sharing Agreement (DSA), King County will begin to receive monthly files which consist of a rolling 12-month refresh of eligibility and claims data. These monthly files will be loaded to SQL Server through an update process – old records will be replaced with new records where duplicates exist, and new records without old duplicates will simply be appended.

King County analysts transform the raw eligibility and claims data to create an array of analytic-ready tables that can be used to flexibly compute people and event-based statistics over time, such as the count of Emergency Department visits by Medicaid member race/ethnicity.

For more information on data tables available on King County's SQL Servers, users can review the purpose and structure of each table (place link here), as well as a [data dictionary](https://kc1-my.sharepoint.com/:x:/g/personal/eli_kern_kingcounty_gov/EZE5ge9YnXxFifiyDIeq8JYBDbiRHIK_t_9-ERAhd13zhQ?e=5PZPiH) that describes each individual data element.

## Creation of analytic-ready person and event-level tables
Users interested in learning about how the raw eligibility and claims data files are transformed to create analytic-ready tables can review the SQL and R scripts for [eligibility data](https://github.com/PHSKC-APDE/Medicaid/tree/master/eligibility%20cleanup) and [claims data](https://github.com/PHSKC-APDE/Medicaid/tree/master/claims%20cleanup).

## Medicaid R package for rapid data analysis
King County analysts developed the *medicaid* R package to facilitate querying and analyzing the aforementioned analytic-ready eligibility and claims data tables.

### Instructions for installing the *medicaid* package
1) Make sure devtools is installed (install.packages("devtools")).
2) Type devtools::install_github("PHSKC-APDE/Medicaid")

### Instructions for updating the *medicaid* package
1) Simply reinstall the package by typing devtools::install_github("PHSKC-APDE/Medicaid")

### Current functionality of the *medicaid* package (v 0.1.2)
- Request an eligibility and demographics-based Medicaid member cohort
- Request a claims summary (e.g. ED visits, avoidable ED, behavioral health hospital stays) for a member cohort
- Request coverage group information (e.g. persons with disabilities) and automatically join to a specified data frame
- Request chronic health condition (e.g. asthma) information and automatically join to a specified data frame
- Tabulate counts by fixed and looped by variables (i.e. data aggregation), with automatic suppression and other features

### Training
R users can view a [training video](https://kc1-my.sharepoint.com/:v:/r/personal/eli_kern_kingcounty_gov/Documents/Shared%20with%20Everyone/Medicaid%20R%20Package%20Training_2018.mp4?csf=1&e=3OydL9) for how to use the *medicaid* package. Users can also view the [R script used in the training video](https://github.com/PHSKC-APDE/Medicaid/blob/master/Medicaid%20package%20orientation.R).
