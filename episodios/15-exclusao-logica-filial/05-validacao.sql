-- Execute depois dos arquivos 01 a 04, na mesma base.
-- Função temporária: não acrescenta objetos permanentes ao laboratório.
CREATE OR REPLACE FUNCTION pg_temp.conferir(
    caso text, consulta text, esperado text
) RETURNS void LANGUAGE plpgsql AS $funcao$
DECLARE
    divergencias bigint;
BEGIN
    EXECUTE format(
        'WITH obtido AS (%s), esperado AS (%s)
         SELECT count(*) FROM (
             (SELECT * FROM obtido EXCEPT ALL SELECT * FROM esperado)
             UNION ALL
             (SELECT * FROM esperado EXCEPT ALL SELECT * FROM obtido)
         ) d', consulta, esperado
    ) INTO divergencias;
    IF divergencias <> 0 THEN
        RAISE EXCEPTION '%: % divergências (chaves, cardinalidade ou valores)',
                        caso, divergencias;
    END IF;
    RAISE NOTICE 'OK: %', caso;
END
$funcao$;

SELECT pg_temp.conferir(
    'Carga: pedidos',
    $consulta$SELECT * FROM sql_semana_15.pedidos$consulta$,
    $esperado$VALUES (1::bigint, '01', '100', ' '), (2, '02', '100', ' '), (3, '01', '101', '*'), (4, '01', '102', ' '), (5, '01', '103', ' ')$esperado$
);

SELECT pg_temp.conferir(
    'Carga: itens',
    $consulta$SELECT * FROM sql_semana_15.itens$consulta$,
    $esperado$VALUES (11::bigint, '01', '100', '01', 'P01', 100.00, ' '), (12, '01', '100', '02', 'P02', 50.00, '*'), (13, '02', '100', '01', 'P01', 900.00, ' '), (14, '01', '101', '01', 'P01', 300.00, ' '), (15, '01', '103', '01', 'P01', 70.00, '*')$esperado$
);

SELECT pg_temp.conferir(
    'Carga: produtos',
    $consulta$SELECT * FROM sql_semana_15.produtos$consulta$,
    $esperado$VALUES (21::bigint, '  ', 'P01', 'Produto A', ' '), (22, '  ', 'P02', 'Produto B', ' ')$esperado$
);

SELECT pg_temp.conferir(
    '1. CORRETO: itens ativos de cabeçalhos ativos da filial 01.',
    $consulta$SELECT p.filial, p.numero, i.item, i.valor
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$VALUES ('01', '100', '01', 100.00)$esperado$
);

SELECT pg_temp.conferir(
    '2. INCORRETO: sem filtro de exclusão do item; 100 = 150 e 103 = 70.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 2::bigint, 150.00), ('01', '103', 1, 70.00)$esperado$
);

SELECT pg_temp.conferir(
    '3. INCORRETO: sem filtro do cabeçalho; 101 reaparece com 300.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00), ('01', '101', 1, 300.00)$esperado$
);

SELECT pg_temp.conferir(
    '4a. INCORRETO: relacionamento só por número mistura filiais; 100 = 1000.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 2::bigint, 1000.00)$esperado$
);

SELECT pg_temp.conferir(
    '4b. CORRETO: filial e número identificam o pedido.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens, sum(i.valor) AS total
FROM sql_semana_15.pedidos p
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
WHERE p.filial = '01' AND p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00)$esperado$
);

SELECT pg_temp.conferir(
    '5. CORRETO: escopos separados, produto compartilhado encontrado uma vez.',
    $consulta$WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = e.filial_cadastro AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$VALUES ('01', '100', '01', 100.00, 'Produto A')$esperado$
);

SELECT pg_temp.conferir(
    '6a. INCORRETO: filial do cadastro igual à do movimento; descrição NULL.',
    $consulta$WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = p.filial AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$VALUES ('01', '100', '01', 100.00, NULL::text)$esperado$
);

SELECT pg_temp.conferir(
    '6b. INCORRETO: mesmo escopo errado com INNER JOIN; nenhuma linha.',
    $consulta$WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
INNER JOIN sql_semana_15.produtos pr
    ON pr.filial = p.filial AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$SELECT '01'::text, '100'::text, '01'::text, 100.00, NULL::text WHERE false$esperado$
);

SELECT pg_temp.conferir(
    '7. CORRETO: filtro do item no ON preserva pedidos sem itens ativos.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00), ('01', '102', 0, 0.00), ('01', '103', 0, 0.00)$esperado$
);

SELECT pg_temp.conferir(
    '8. INCORRETO: filtro do item no WHERE elimina 102 e 103.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero
WHERE i.d_e_l_e_t_ = ' ' AND p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00)$esperado$
);

SELECT pg_temp.conferir(
    '9. Comparação: count(*) conta a linha preservada, mesmo sem item.',
    $consulta$SELECT p.filial, p.numero, count(*) AS linhas, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND p.filial = '01'
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 1::bigint, 100.00), ('01', '102', 1, 0, 0.00), ('01', '103', 1, 0, 0.00)$esperado$
);

SELECT pg_temp.conferir(
    '10a. Solução: quatro cabeçalhos ativos nas duas filiais.',
    $consulta$SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00), ('01', '102', 0, 0.00), ('01', '103', 0, 0.00), ('02', '100', 1, 900.00)$esperado$
);

SELECT pg_temp.conferir(
    '10b. Totais por filial, a partir dos pedidos agrupados pela chave completa.',
    $consulta$WITH por_pedido AS (
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
)
SELECT filial, count(*) AS pedidos, sum(total) AS total
FROM por_pedido
GROUP BY filial$consulta$,
    $esperado$VALUES ('01', 3::bigint, 100.00), ('02', 1, 900.00)$esperado$
);

-- Cenário isolado; ROLLBACK restaura a massa-base.
BEGIN;
UPDATE sql_semana_15.produtos SET d_e_l_e_t_ = '*' WHERE filial = '  ' AND codigo = 'P01';
SELECT pg_temp.conferir(
    '11a. Produto excluído preserva item',
    $consulta$WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = e.filial_cadastro AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$VALUES ('01', '100', '01', 100.00, NULL::text)$esperado$
);

SELECT pg_temp.conferir(
    '11a. Produto excluído preserva total',
    $consulta$WITH detalhe AS (
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
)
SELECT filial, numero, count(*) AS itens, sum(valor) AS total
FROM detalhe GROUP BY filial, numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00)$esperado$
);

ROLLBACK;

SELECT pg_temp.conferir(
    '11a. Produto excluído revertido',
    $consulta$SELECT * FROM sql_semana_15.produtos$consulta$,
    $esperado$VALUES (21::bigint, '  ', 'P01', 'Produto A', ' '), (22, '  ', 'P02', 'Produto B', ' ')$esperado$
);

-- Cenário isolado; ROLLBACK restaura a massa-base.
BEGIN;
DELETE FROM sql_semana_15.produtos WHERE filial = '  ' AND codigo = 'P01';
SELECT pg_temp.conferir(
    '11b. Produto removido preserva item',
    $consulta$WITH escopo AS (
    SELECT '01'::text AS filial_movimento, '  '::text AS filial_cadastro
)
SELECT p.filial, p.numero, i.item, i.valor, pr.descricao
FROM escopo e
JOIN sql_semana_15.pedidos p ON p.filial = e.filial_movimento
JOIN sql_semana_15.itens i ON i.filial = p.filial AND i.numero = p.numero
LEFT JOIN sql_semana_15.produtos pr
    ON pr.filial = e.filial_cadastro AND pr.codigo = i.produto
   AND pr.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' ' AND i.d_e_l_e_t_ = ' '$consulta$,
    $esperado$VALUES ('01', '100', '01', 100.00, NULL::text)$esperado$
);

SELECT pg_temp.conferir(
    '11b. Produto removido preserva total',
    $consulta$WITH detalhe AS (
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
)
SELECT filial, numero, count(*) AS itens, sum(valor) AS total
FROM detalhe GROUP BY filial, numero$consulta$,
    $esperado$VALUES ('01', '100', 1::bigint, 100.00)$esperado$
);

ROLLBACK;

SELECT pg_temp.conferir(
    '11b. Produto removido revertido',
    $consulta$SELECT * FROM sql_semana_15.produtos$consulta$,
    $esperado$VALUES (21::bigint, '  ', 'P01', 'Produto A', ' '), (22, '  ', 'P02', 'Produto B', ' ')$esperado$
);

DO $fim$ BEGIN RAISE NOTICE 'Validação do episódio 15 concluída com sucesso: 22 verificações.'; END $fim$;
