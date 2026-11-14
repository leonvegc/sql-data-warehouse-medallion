/* =============================================================
   proc_load_silver.sql
   Procedimiento silver.load_silver: lee Bronze, limpia y carga
   Silver (Truncate & Insert).

   Uso:  CALL silver.load_silver();
   ============================================================= */

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE '=== Cargando capa Silver ===';

    /* ---------- crm_cust_info ----------
       - Quita duplicados (se queda con el registro más reciente)
       - Quita espacios en nombres
       - Estandariza estado civil y género                      */
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info
        (cst_id, cst_key, cst_firstname, cst_lastname,
         cst_marital_status, cst_gndr, cst_create_date)
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a' END,
        CASE UPPER(TRIM(cst_gndr))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'n/a' END,
        cst_create_date
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id
                                     ORDER BY cst_create_date DESC) AS rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE rn = 1;
    RAISE NOTICE '>> silver.crm_cust_info cargada';

    /* ---------- crm_prd_info ----------
       - Separa la categoría (cat_id) de la clave del producto
       - Costo nulo = 0
       - Traduce la línea de producto
       - Fecha fin = día anterior al siguiente inicio            */
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info
        (prd_id, cat_id, prd_key, prd_nm, prd_cost,
         prd_line, prd_start_dt, prd_end_dt)
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_'),
        SUBSTRING(prd_key FROM 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a' END,
        prd_start_dt::DATE,
        (LEAD(prd_start_dt) OVER (PARTITION BY prd_key
                                  ORDER BY prd_start_dt) - INTERVAL '1 day')::DATE
    FROM bronze.crm_prd_info;
    RAISE NOTICE '>> silver.crm_prd_info cargada';

    /* ---------- crm_sales_details ----------
       - Convierte fechas YYYYMMDD a DATE
       - Fecha de pedido inválida = fecha de envío - 7 días
       - Recalcula ventas = cantidad * precio cuando no cuadran
       - Deriva el precio cuando es nulo o negativo            */
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details
        (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt,
         sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN LENGTH(sls_order_dt::TEXT) = 8 THEN TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
             -- Fecha inválida: se reconstruye (el envío siempre es 7 días después del pedido)
             WHEN LENGTH(sls_ship_dt::TEXT)  = 8 THEN TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD') - 7
        END,
        CASE WHEN LENGTH(sls_ship_dt::TEXT)  = 8 THEN TO_DATE(sls_ship_dt::TEXT,  'YYYYMMDD') END,
        CASE WHEN LENGTH(sls_due_dt::TEXT)   = 8 THEN TO_DATE(sls_due_dt::TEXT,   'YYYYMMDD') END,
        CASE WHEN sls_sales IS NULL OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0
             THEN sls_sales / NULLIF(sls_quantity, 0)
             ELSE sls_price END
    FROM bronze.crm_sales_details;
    RAISE NOTICE '>> silver.crm_sales_details cargada';

    /* ---------- erp_cust_az12 ----------
       - Quita el prefijo 'NAS' del id de cliente
       - Fechas de nacimiento futuras = NULL
       - Estandariza el género                                  */
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4) ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE THEN NULL ELSE bdate END,
        CASE UPPER(TRIM(gen))
            WHEN 'F' THEN 'Female' WHEN 'FEMALE' THEN 'Female'
            WHEN 'M' THEN 'Male'   WHEN 'MALE'   THEN 'Male'
            ELSE 'n/a' END
    FROM bronze.erp_cust_az12;
    RAISE NOTICE '>> silver.erp_cust_az12 cargada';

    /* ---------- erp_loc_a101 ----------
       - Quita guiones del id para que coincida con el CRM
       - Estandariza nombres de país                            */
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE WHEN TRIM(cntry) = 'DE'              THEN 'Germany'
             WHEN TRIM(cntry) IN ('US', 'USA')    THEN 'United States'
             WHEN COALESCE(TRIM(cntry), '') = ''  THEN 'n/a'
             ELSE TRIM(cntry) END
    FROM bronze.erp_loc_a101;
    RAISE NOTICE '>> silver.erp_loc_a101 cargada';

    /* ---------- erp_px_cat_g1v2 ----------
       Los datos ya vienen limpios: se copian tal cual.         */
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;
    RAISE NOTICE '>> silver.erp_px_cat_g1v2 cargada';

    RAISE NOTICE '=== Silver terminado ===';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR cargando Silver: %', SQLERRM;
        RAISE;
END;
$$;
