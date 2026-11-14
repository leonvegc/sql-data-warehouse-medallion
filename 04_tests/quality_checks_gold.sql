/* =============================================================
   quality_checks_gold.sql
   Verificaciones de calidad de la capa Gold.
   Resultado esperado: TODAS las consultas devuelven 0 filas.
   ============================================================= */


-- 1. Claves subrogadas únicas en las dimensiones
SELECT customer_key, COUNT(*) FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1;
SELECT product_key,  COUNT(*) FROM gold.dim_products  GROUP BY product_key  HAVING COUNT(*) > 1;

-- 2. Integridad referencial: cada venta tiene cliente y producto
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products  p ON f.product_key  = p.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;
