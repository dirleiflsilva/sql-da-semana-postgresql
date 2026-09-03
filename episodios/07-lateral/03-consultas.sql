SET search_path TO sql_semana_07;

-- 1. A subconsulta é executada para cada categoria e devolve até três produtos.
-- CROSS JOIN omite a categoria quando a subconsulta não encontra produtos.
SELECT
    c.category_id,
    c.name AS category_name,
    p.product_id,
    p.name AS product_name,
    p.sales_count
FROM categories AS c
CROSS JOIN LATERAL (
    SELECT
        product_id,
        name,
        sales_count
    FROM products AS p
    WHERE p.category_id = c.category_id
    ORDER BY p.sales_count DESC, p.product_id
    LIMIT 3
) AS p
ORDER BY c.name, p.sales_count DESC, p.product_id;

-- 2. LEFT JOIN preserva a categoria sem produtos, preenchendo p com NULL.
SELECT
    c.category_id,
    c.name AS category_name,
    p.product_id,
    p.name AS product_name,
    p.sales_count
FROM categories AS c
LEFT JOIN LATERAL (
    SELECT
        product_id,
        name,
        sales_count
    FROM products AS p
    WHERE p.category_id = c.category_id
    ORDER BY p.sales_count DESC, p.product_id
    LIMIT 3
) AS p ON true
ORDER BY c.name, p.sales_count DESC NULLS LAST, p.product_id;

-- 3. LIMIT 1 encontra o produto mais vendido de cada categoria.
SELECT
    c.category_id,
    c.name AS category_name,
    top_product.product_id,
    top_product.name AS product_name,
    top_product.sales_count
FROM categories AS c
LEFT JOIN LATERAL (
    SELECT
        p.product_id,
        p.name,
        p.sales_count
    FROM products AS p
    WHERE p.category_id = c.category_id
    ORDER BY p.sales_count DESC, p.product_id
    LIMIT 1
) AS top_product ON true
ORDER BY c.name;

-- 4. row_number oferece uma alternativa para o top 3 por categoria.
SELECT
    category_id,
    category_name,
    product_id,
    product_name,
    sales_count
FROM (
    SELECT
        c.category_id,
        c.name AS category_name,
        p.product_id,
        p.name AS product_name,
        p.sales_count,
        row_number() OVER (
            PARTITION BY c.category_id
            ORDER BY p.sales_count DESC, p.product_id
        ) AS position
    FROM categories AS c
    JOIN products AS p
      ON p.category_id = c.category_id
) AS ranked_products
WHERE position <= 3
ORDER BY category_name, sales_count DESC, product_id;

-- 5. A função recebe o JSON da linha externa e o expande em pares chave-valor.
SELECT
    e.event_id,
    item.key,
    item.value
FROM (
    VALUES
        (1, '{"source":"site","status":"paid"}'::jsonb),
        (2, '{"source":"api","status":"pending"}'::jsonb)
) AS e(event_id, payload)
CROSS JOIN LATERAL jsonb_each_text(e.payload) AS item
ORDER BY e.event_id, item.key;

-- 6. O índice acompanha o filtro e a ordenação da busca lateral.
CREATE INDEX products_category_sales_idx
    ON products (category_id, sales_count DESC, product_id);

-- Com apenas onze produtos, uma leitura sequencial ainda pode ser mais barata.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.category_id,
    c.name AS category_name,
    p.product_id,
    p.name AS product_name,
    p.sales_count
FROM categories AS c
CROSS JOIN LATERAL (
    SELECT
        product_id,
        name,
        sales_count
    FROM products AS p
    WHERE p.category_id = c.category_id
    ORDER BY p.sales_count DESC, p.product_id
    LIMIT 3
) AS p
ORDER BY c.name, p.sales_count DESC, p.product_id;
