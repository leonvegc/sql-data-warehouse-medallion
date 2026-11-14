# Guía de configuración

## Requisitos
- PostgreSQL 13 o superior (probado en PostgreSQL 16).
- `psql` (viene con PostgreSQL) o pgAdmin.

## Pasos (ejecutar en este orden)

Desde una terminal ubicada en la carpeta del proyecto:

```bash
# 1. Base de datos y esquemas (bronze, silver, gold)
psql -U postgres -f 03_scripts/init_database.sql

# 2. Tablas y procedimientos (conectado a datawarehouse)
psql -U postgres -d datawarehouse -f 03_scripts/bronze/ddl_bronze.sql
psql -U postgres -d datawarehouse -f 03_scripts/bronze/proc_load_bronze.sql
psql -U postgres -d datawarehouse -f 03_scripts/silver/ddl_silver.sql
psql -U postgres -d datawarehouse -f 03_scripts/silver/proc_load_silver.sql
```

3. Cargar los datos (en psql o en el Query Tool de pgAdmin, conectado a `datawarehouse`):
   ```sql
   CALL bronze.load_bronze();
   CALL silver.load_silver();
   ```
4. Crear la capa Gold:
   ```bash
   psql -U postgres -d datawarehouse -f 03_scripts/gold/ddl_gold.sql
   ```
5. Validar: ejecutar `04_tests/quality_checks_silver.sql` y `04_tests/quality_checks_gold.sql`. Todas las consultas deben devolver **0 filas**.

> **pgAdmin:** `init_database.sql` usa `\c`, que solo funciona en psql. En pgAdmin ejecuta la PARTE 1 conectado a la base `postgres` y la PARTE 2 conectado a `datawarehouse`.

## Ruta de los CSV
`bronze.load_bronze` usa por defecto:
```
C:/Users/criss/OneDrive/Escritorio/DB UTN/Ejercicio 7/sql-data-warehouse-medallion/01_datasets/
```
Si mueves el proyecto, pasa la nueva ruta (con `/` y terminada en `/`):
```sql
CALL bronze.load_bronze('C:/datos/01_datasets/');
```

**Si `COPY` da "Permission denied" o "could not open file":** el servicio de PostgreSQL no puede leer tu carpeta de OneDrive. Lo más sencillo es copiar `01_datasets` a una carpeta como `C:/datos/` y usar esa ruta. El usuario debe ser `postgres` (superusuario) o tener el rol `pg_read_server_files`.

## Resultado esperado
| Objeto              | Filas  |
|---------------------|--------|
| gold.dim_customers  | 18,484 |
| gold.dim_products   | 295    |
| gold.fact_sales     | 60,398 |

## Consulta de ejemplo
```sql
SELECT c.country, SUM(f.sales_amount) AS total_ventas
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_ventas DESC;
```
