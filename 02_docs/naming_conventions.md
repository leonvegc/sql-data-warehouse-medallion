# Convención de nombres

Este documento describe cómo se nombran los esquemas, tablas, vistas, columnas y demás objetos del almacén de datos.

## Principios generales

- Todo en **snake_case**: minúsculas y palabras separadas por guion bajo (`_`).
- Nombres en **inglés** para todos los objetos.
- No usar palabras reservadas de SQL ni mayúsculas (PostgreSQL convierte a minúsculas los nombres sin comillas).

## Convenciones para nombrar tablas

### Reglas para Bronze
- Patrón: `<sistema_origen>_<entidad>`
- Se conserva el nombre original de la fuente, sin renombrar.
- `<sistema_origen>`: `crm` o `erp`.
- `<entidad>`: nombre exacto de la tabla en el sistema de origen.
- Ejemplo: `bronze.crm_cust_info` → información de clientes del CRM.

### Reglas para Silver
- Mismo patrón que Bronze: `<sistema_origen>_<entidad>`.
- Ejemplo: `silver.erp_loc_a101`.

### Reglas para Gold
- Patrón: `<categoría>_<entidad>` con nombres de negocio.

| Prefijo | Significado         | Ejemplo                          |
|---------|---------------------|----------------------------------|
| `dim_`  | Tabla de dimensión  | `dim_customers`, `dim_products`  |
| `fact_` | Tabla de hechos     | `fact_sales`                     |
| `agg_`  | Tabla agregada      | `agg_sales_monthly`              |

## Convenciones para nombrar columnas

### Claves subrogadas
- Toda clave subrogada de una dimensión termina en `_key`.
- Patrón: `<entidad>_key`. Ejemplo: `customer_key` en `gold.dim_customers`.

### Columnas técnicas
- Columnas generadas por el sistema (no vienen de la fuente) empiezan con `dwh_`.
- Patrón: `dwh_<nombre>`. Ejemplo: `dwh_create_date` = fecha en que se cargó el registro.

## Convenciones para nombrar procedimientos almacenados

- Patrón: `load_<capa>`, creado dentro del esquema de su capa.
- Ejemplos: `bronze.load_bronze`, `silver.load_silver`.
