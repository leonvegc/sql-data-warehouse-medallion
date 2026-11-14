/* =============================================================
   proc_load_bronze.sql
   Procedimiento bronze.load_bronze: carga completa
   (Truncate & Insert) de los 6 CSV usando COPY.

   Uso:
     CALL bronze.load_bronze();   -- usa la ruta por defecto
     CALL bronze.load_bronze('C:/otra/ruta/01_datasets/');

   p_ruta = carpeta 01_datasets (con "/" y terminada en "/").
   COPY lee el archivo desde el SERVIDOR: el servicio de
   PostgreSQL debe tener permiso de lectura sobre esa carpeta, y
   el usuario debe ser superusuario o tener pg_read_server_files.
   ============================================================= */

CREATE OR REPLACE PROCEDURE bronze.load_bronze(
    p_ruta TEXT DEFAULT 'C:/Users/criss/OneDrive/Escritorio/DB UTN/Ejercicio 7/sql-data-warehouse-medallion/01_datasets/'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inicio TIMESTAMP := clock_timestamp();
    v_carga  RECORD;
BEGIN
    RAISE NOTICE '=== Cargando capa Bronze ===';

    -- Tabla destino -> archivo de origen
    FOR v_carga IN
        SELECT * FROM (VALUES
            (1, 'bronze.crm_cust_info',     'source_crm/cust_info.csv'),
            (2, 'bronze.crm_prd_info',      'source_crm/prd_info.csv'),
            (3, 'bronze.crm_sales_details', 'source_crm/sales_details.csv'),
            (4, 'bronze.erp_cust_az12',     'source_erp/CUST_AZ12.csv'),
            (5, 'bronze.erp_loc_a101',      'source_erp/LOC_A101.csv'),
            (6, 'bronze.erp_px_cat_g1v2',   'source_erp/PX_CAT_G1V2.csv')
        ) AS t(orden, tabla, archivo)
        ORDER BY orden
    LOOP
        EXECUTE format('TRUNCATE TABLE %s', v_carga.tabla);
        EXECUTE format('COPY %s FROM %L WITH (FORMAT csv, HEADER true, ENCODING ''UTF8'')',
                       v_carga.tabla, p_ruta || v_carga.archivo);
        RAISE NOTICE '>> % cargada', v_carga.tabla;
    END LOOP;

    RAISE NOTICE '=== Bronze terminado en % s ===',
        round(extract(epoch FROM clock_timestamp() - v_inicio), 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR cargando Bronze: %', SQLERRM;
        RAISE;
END;
$$;
