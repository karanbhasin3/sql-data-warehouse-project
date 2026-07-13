/*
==================================================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
==================================================================================================================

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the BULK INSERT command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;

==================================================================================================================
*/

Create or Alter procedure bronze.load_bronze as 
Begin 
Declare @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
Begin Try
SET @batch_start_time = GETDATE();
					Print '==================================================';
					Print 'Loading Bronze Layer';
					Print '==================================================';


		Print '--------------------------------------------------';
		Print 'Loading CRM Tables';
		Print '--------------------------------------------------'
SET @start_time = GETDATE();
Bulk Insert bronze.crm_cust_info
From  'D:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
with 
(
	FirstRow = 2,
	Fieldterminator = ',',
	Tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE();
Bulk Insert bronze.crm_prd_info
From 'D:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
with 
(
	FirstRow = 2,
	Fieldterminator = ',',
	Tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE();
Bulk Insert bronze.crm_sales_details
From 'D:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
with
(
	Firstrow = 2,
	Fieldterminator = ',',
	Tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------';

		Print '--------------------------------------------------';
		Print 'Loading ERP Tables';
		Print '--------------------------------------------------'


SET @start_time = GETDATE()
Bulk Insert bronze.erp_cust_az12
From 'D:\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
with 
(
	firstrow = 2,
	fieldterminator = ',',
	tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------';


SET @start_time = GETDATE()
Bulk Insert bronze.erp_loc_a101
from 'D:\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
with 
(
	firstrow = 2,
	fieldterminator = ',',
	tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------';


SET @start_time = GETDATE()
Bulk Insert bronze.erp_px_cat_g1v2
from 'D:\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
with 
(
	firstrow = 2,
	fieldterminator = ',',
	tablock
)
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------';

	SET @batch_end_time = GETDATE()
	PRINT '=========================================================================='
	PRINT ' - Total Load Duration:' + Cast(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
	PRINT '=========================================================================='
End Try
Begin Catch
	Print '================================================================';
	Print 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	Print 'ERROR MESSAGE' + ERROR_MESSAGE();
	Print 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
	Print 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
	Print '================================================================';
End Catch
end
