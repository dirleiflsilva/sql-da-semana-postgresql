-- Execute depois de 01 e 02. Os exemplos INCORRETOS são intencionais.

-- 1. CORRETO: itens ativos de cabeçalhos ativos da filial 01.
SELECT p.filial, p.numero, i.item, i.valor
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
ORDER BY 1, 2;

-- 2. INCORRETO: sem filtro de exclusão do item; 100 = 150 e 103 = 70.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 3. INCORRETO: sem filtro do cabeçalho; 101 reaparece com 300.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 4a. INCORRETO: relacionamento só por número mistura filiais; 100 = 1000.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 4b. CORRETO: filial e número identificam o pedido.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 5. CORRETO: escopos separados, produto compartilhado encontrado uma vez.
WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = e.filial_cadastro AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
ORDER BY 1, 2;

-- 6a. INCORRETO: filial do cadastro igual à do movimento; descrição NULL.
WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = p.filial AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
ORDER BY 1, 2;

-- 6b. INCORRETO: mesmo escopo errado com INNER JOIN; nenhuma linha.
WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
INNER JOIN sql_semana_15.produtos pr
    ON pr.filial = p.filial AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
ORDER BY 1, 2;

-- 7. CORRETO: filtro do item no ON preserva pedidos sem itens ativos.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 8. INCORRETO: filtro do item no WHERE elimina 102 e 103.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero
WHERE i.d_e_l_e_t_ = ' ' AND p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 9. Comparação: count(*) conta a linha preservada, mesmo sem item.
SELECT p.filial, p.numero, count(*) AS linhas, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero
ORDER BY 1, 2;
