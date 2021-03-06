
USE PHClaims;
GO

IF OBJECT_ID('[ref].[hedis_measure]', 'U') IS NOT NULL
DROP TABLE [ref].[hedis_measure];
CREATE TABLE [ref].[hedis_measure]
([measure_id] VARCHAR(5) NOT NULL
,[measure_name] VARCHAR(200) NOT NULL
,CONSTRAINT [PK_ref_hedis_measure] PRIMARY KEY CLUSTERED([measure_id])
);
GO

IF OBJECT_ID('[ref].[hedis_value_set]', 'U') IS NOT NULL
DROP TABLE [ref].[hedis_value_set];
CREATE TABLE [ref].[hedis_value_set]
([measure_id] VARCHAR(5) NOT NULL
,[value_set_name] VARCHAR(100) NOT NULL
,[value_set_oid] VARCHAR(50) NOT NULL
,CONSTRAINT [PK_ref_hedis_value_set] PRIMARY KEY CLUSTERED([measure_id], [value_set_name])
);
GO

IF OBJECT_ID('[ref].[hedis_medication_list]', 'U') IS NOT NULL
DROP TABLE [ref].[hedis_medication_list];
CREATE TABLE [ref].[hedis_medication_list]
([measure_id] VARCHAR(5) NOT NULL
,[medication_list_name] VARCHAR(100) NOT NULL
,CONSTRAINT [PK_ref_hedis_medication_list] PRIMARY KEY CLUSTERED([measure_id], [medication_list_name])
);
GO

IF OBJECT_ID('[ref].[hedis_code_system]', 'U') IS NOT NULL
DROP TABLE [ref].[hedis_code_system];
CREATE TABLE [ref].[hedis_code_system]
([value_set_name] VARCHAR(100) NOT NULL
,[code_system] VARCHAR(50) NOT NULL
,[code] VARCHAR(50) NOT NULL
,[definition] VARCHAR(2000)
,[value_set_version] DATE NOT NULL
,[code_system_version] VARCHAR(50) NOT NULL
,[value_set_oid] VARCHAR(50) NOT NULL
,[code_system_oid] VARCHAR(50)
,CONSTRAINT [PK_ref_hedis_code_system] PRIMARY KEY CLUSTERED([value_set_name], [code_system], [code])
);
GO

IF OBJECT_ID('[ref].[hedis_ndc_code]', 'U') IS NOT NULL
DROP TABLE [ref].[hedis_ndc_code];
CREATE TABLE [ref].[hedis_ndc_code]
([medication_list_name] VARCHAR(100) NOT NULL
,[ndc_code] VARCHAR(20) NOT NULL
,[brand_name] VARCHAR(100)
,[generic_product_name] VARCHAR(200)
,[route] VARCHAR(50)
,[description] VARCHAR(200)
,[drug_id] VARCHAR(20)
,[drug_name] VARCHAR(50)
,[package_size] NUMERIC(18,4)
,[unit] VARCHAR(20)
,[dose] NUMERIC(18,4)
,[form] VARCHAR(20)
,[med_conversion_factor] NUMERIC(18,4)
,CONSTRAINT [PK_ref_hedis_ndc_code] PRIMARY KEY CLUSTERED([medication_list_name], [ndc_code])
);
GO