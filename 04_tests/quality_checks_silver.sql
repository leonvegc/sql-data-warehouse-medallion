/* =============================================================
   quality_checks_silver.sql
   Verificaciones de calidad de la capa Silver.
   Resultado esperado: TODAS las consultas devuelven 0 filas.
   ============================================================= */


-- 1. Clientes: id nulo o duplicado
SELECT cst_id, COUNT(*) AS veces
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Clientes: espacios sobrantes en nombres
SELECT cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname);

-- 3. Clientes/Productos/ERP: valores fuera del catálogo estandarizado
SELECT DISTINCT cst_gndr           FROM silver.crm_cust_info WHERE cst_gndr NOT IN ('Male','Female','n/a');
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info WHERE cst_marital_status NOT IN ('Single','Married','n/a');
SELECT DISTINCT prd_line           FROM silver.crm_prd_info  WHERE prd_line NOT IN ('Mountain','Road','Other Sales','Touring','n/a');
SELECT DISTINCT gen                FROM silver.erp_cust_az12 WHERE gen NOT IN ('Male','Female','n/a');
SELECT DISTINCT cntry              FROM silver.erp_loc_a101  WHERE cntry IN ('DE','US','USA','');

-- 4. Productos: costo nulo/negativo o fecha fin antes del inicio
SELECT * FROM silver.crm_prd_info WHERE prd_cost IS NULL OR prd_cost < 0;
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-- 5. Ventas: fechas en orden incorrecto
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- 6. Ventas: ventas <> cantidad * precio, o valores nulos/negativos
SELECT * FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- 7. ERP: fechas de nacimiento futuras
SELECT * FROM silver.erp_cust_az12 WHERE bdate > CURRENT_DATE;
