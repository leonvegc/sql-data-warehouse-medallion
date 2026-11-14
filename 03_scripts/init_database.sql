/* =============================================================
   init_database.sql
   Crea la base de datos datawarehouse y los esquemas de la
   arquitectura Medallion: bronze, silver y gold.
   ADVERTENCIA: si la base ya existe, se elimina y se recrea.

   Ejecutar con psql:   psql -U postgres -f init_database.sql
   (En pgAdmin: ejecutar la PARTE 1 conectado a "postgres" y la
    PARTE 2 conectado a "datawarehouse".)
   ============================================================= */

-- PARTE 1: base de datos
DROP DATABASE IF EXISTS datawarehouse WITH (FORCE);
CREATE DATABASE datawarehouse ENCODING 'UTF8';

\c datawarehouse

-- PARTE 2: esquemas
CREATE SCHEMA bronze;  -- Datos originales
CREATE SCHEMA silver;  -- Datos depurados
CREATE SCHEMA gold;    -- Datos analíticos
