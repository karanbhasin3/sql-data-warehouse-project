/*
==================================================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==================================================================================================================

Script Purpose:
    This stored procedure performs the ETL(Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    It performs the following actions:
    - Truncates the silver tables.
    - Insert transformed and cleansed data from bronze into silver layer.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;

==================================================================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
BEGIN TRY
	SET @batch_start_time = GETDATE();
	PRINT '===========================================';
	PRINT 'Loading Silver Layer';
	PRINT '==========================================='

	PRINT '-------------------------------------------'
	PRINT 'Loading CRM Tables'
	PRINT '-------------------------------------------'

SET @start_time = GETDATE();
PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info' 
INSERT INTO silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)
select cst_id,
cst_key,
TRIM(cst_firstname) cst_firstname,
TRIM(cst_lastname) cst_lastname ,
	case when UPPER(TRIM(cst_marital_status)) = 'M' then 'Married'
	when UPPER(TRIM(cst_marital_status)) = 's' then 'Single'
	else 'n/a' end cst_marital_status,
	case when UPPER(TRIM(cst_gndr)) = 'M' then '
	Male'
	when UPPER(TRIM(cst_gndr)) = 'F' then  'Female' 
	else 'n/a'
	end cst_gndr,
cst_create_date
from (
select *,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info
where cst_id is not null
)t where flag_last = 1;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE();
PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into: silver.crm_prd_info' 
INSERT INTO silver.crm_prd_info (
prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
    )
select 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) prd_key,
prd_nm,
ISNULL(prd_cost, 0) prd_cost,
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'MOUNTAIN'
     WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'ROAD'
     WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'OTHER SALES'
     WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'TOURING'
     ELSE 'n/a'
END pd_line,
CAST(prd_start_dt AS DATE) prd_start_dt,
CAST(LEAD(prd_start_dt) OVER( PARTITION BY prd_key order by prd_start_dt)- 1 AS DATE)  prd_end_dt
from bronze.crm_prd_info;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into: silver.crm_sales_details' 
INSERT INTO silver.crm_sales_details (
sls_ord_num ,
sls_prd_key,
sls_cust_id ,
sls_order_dt ,
sls_ship_dt ,
sls_due_dt ,
sls_sales ,
sls_quantity ,
sls_price
)
select 
sls_ord_num,
sls_prd_key,
sls_cust_id,
case when sls_order_dt = 0  or len(sls_order_dt) != 8 then null
else cast(cast(sls_order_dt as varchar) as date) 
end sls_order_dt,
case when sls_ship_dt = 0  or len(sls_ship_dt) != 8 then null
else cast(cast(sls_ship_dt as varchar) as date) 
end sls_ship_dt,
case when sls_due_dt = 0  or len(sls_due_dt) != 8 then null
else cast(cast(sls_due_dt as varchar) as date) 
end sls_due_dt,
case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
	then sls_quantity * ABS(sls_price) 
	else sls_sales
end as sls_sales,
sls_quantity,
case when sls_price is null or sls_price <= 0 or sls_price != sls_sales / sls_quantity
	then sls_sales / nullif(sls_quantity, 0)
	else sls_price 
end as sls_price
from bronze.crm_sales_details;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'


SET @start_time = GETDATE()
PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>> Inserting Data Into: silver.erp_cust_az12' 
INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT
CASE WHEN cid like '%NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END cid,
CASE WHEN bdate > GETDATE() THEN NULL
	else bdate
	END AS bdate,
CASE WHEN upper(trim(gen)) in ('F' , 'Female') then 'Female'
	 WHEN upper(trim(gen)) in ('M' , 'Male') then 'Male'
	 ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: silver.erp_loc_a101';
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into: silver.erp_loc_a101' 
INSERT INTO silver.erp_loc_a101 (cid, cntry) 
SELECT replace(cid, '-', '') cid,
CASE WHEN trim(cntry) = 'DE' then 'Germany'
	 WHEN trim(cntry) IN ('US' , 'USA') then 'United States'
	 WHEN trim(cntry) is null then 'n/a'
	 WHEN trim(cntry) = ' ' then 'n/a'
	 ELSE trim(cntry)
END cntry
FROM bronze.erp_loc_a101;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2' 
INSERT INTO silver.erp_px_cat_g1v2
(id, cat, subcat, maintenance)
SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;
	SET @end_time = GETDATE();
	Print 'Load Duration:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' Seconds';
	Print '--------------------------------'

	SET @batch_end_time = GETDATE()
	PRINT '=========================================================================='
	PRINT ' - Total Load Duration:' + Cast(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
	PRINT '=========================================================================='
END TRY
BEGIN CATCH
	Print '================================================================';
	Print 'ERROR OCCURED DURING LOADING SILVER LAYER';
	Print 'ERROR MESSAGE' + ERROR_MESSAGE();
	Print 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
	Print 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
	Print '================================================================';
End Catch
END
