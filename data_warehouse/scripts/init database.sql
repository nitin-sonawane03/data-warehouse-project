-- ============================================================
-- DATAWAREHOUSE DATABASE INITIALIZATION SCRIPT
-- ============================================================
-- Purpose     : Initializes the DataWarehouse database and
--               creates the Medallion Architecture schemas
--               (Bronze, Silver, Gold) for a layered data
--               warehouse pipeline.
--
-- Warning     : THIS SCRIPT WILL DROP AND RECREATE THE
--               DataWarehouse DATABASE IF IT ALREADY EXISTS.
--               ALL EXISTING DATA WILL BE PERMANENTLY LOST.
--               DO NOT RUN ON PRODUCTION WITHOUT A BACKUP.
--

-- ============================================================

USE master;
GO

-- Drop existing database if exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    PRINT 'Dropping existing DataWarehouse database...';

    ALTER DATABASE DataWarehouse
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE DataWarehouse;

    PRINT 'Database dropped successfully.';
END;
GO

-- Create fresh database
CREATE DATABASE DataWarehouse;
GO

PRINT 'DataWarehouse database created successfully.';
GO

-- Create Medallion Architecture schemas
USE DataWarehouse;
GO

CREATE SCHEMA bronze;   -- Raw / ingested data layer
GO

CREATE SCHEMA silver;   -- Cleaned / transformed data layer
GO

CREATE SCHEMA gold;     -- Aggregated / business-ready layer
GO

PRINT 'Schemas bronze, silver, gold created successfully.';
GO