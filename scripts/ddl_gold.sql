/*
==============================================================================
  DDL SCRIPT: CREATE GOLD VIEWS
==============================================================================
SCRIPT PURPOSE:
  This script creates views for the gold layer in the data warehouse.
  The gold layer represents the final dimension and fact tables (Star Schema)

  Each view performs transformations and combines data from the silver layer
  to produce a clean, enriched, and business ready dataset.

Usage: 
    - These views can be queried directly for analytics and reporting.
==============================================================================
*/


==============================================================================
CREATE DIMENSION: gold_dim_customers
==============================================================================
IF OBJECT_ID('gold_dim_customers', 'V') IS NOT NULL
  DROP VIEW gold_dim_customers;
GO

CREATE VIEW gold_dim_customers as 
SELECT 
	row_number() over(order by ci.cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr
		else coalesce(ca.gen, 'n/a')  
	end as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on ci.cst_key = ca.cid
left join silver.erp_loc_a101 la
on ci.cst_key = la.cid
GO

==============================================================================
CREATE DIMENSION: gold.dim_products
==============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
  DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products as 
SELECT 
	row_number() over (order by prd_start_dt, prd_key) as product_key,
	prd_id as product_id,
	prd_key as product_number,
	prd_nm as product_name,
	cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance as maintenance,
	prd_cost as cost,
	prd_line as product_line,
	prd_start_dt as start_date
FROM silver.crm_prd_info as pn
left join silver.erp_px_cat_g1v2 as pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is null 
GO

==============================================================================
CREATE FACT TABLE: gold.fact_sales
==============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
  DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales as
SELECT 
	sls_ord_num as order_number,
	pr.product_key,
	cu.customer_key,
	sls_order_dt as order_date,
	sls_ship_dt as shipping_date,
	sls_due_dt as due_date,
	sls_sales as sales_amount,
	sls_quantity as quantity,
	sls_price as price
FROM silver.crm_sales_details as sd
left join gold.dim_products as pr
ON sd.sls_prd_key = pr.product_number
left join gold_dim_customers as cu
ON sd.sls_cust_id = cu.customer_id
GO
