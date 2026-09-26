-- Execute depois de 01-tabelas.sql e 02-dados.sql.

-- 1. Consulta direta inicial: cinco grupos por dia e situação.
SELECT
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date AS dia,
    situacao,
    count(*) AS quantidade,
    sum(valor_total) AS valor_total,
    round(avg(valor_total), 2) AS ticket_medio
FROM sql_semana_10.pedidos
GROUP BY
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date,
    situacao
ORDER BY dia, situacao;

-- 2. O resultado da consulta é armazenado no momento da criação.
CREATE MATERIALIZED VIEW sql_semana_10.indicadores_pedidos AS
SELECT
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date AS dia,
    situacao,
    count(*) AS quantidade,
    sum(valor_total) AS valor_total,
    round(avg(valor_total), 2) AS ticket_medio
FROM sql_semana_10.pedidos
GROUP BY
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date,
    situacao;

SELECT
    dia,
    situacao,
    quantidade,
    valor_total,
    ticket_medio
FROM sql_semana_10.indicadores_pedidos
ORDER BY dia, situacao;

-- 3. A origem muda: o pedido 5 é aprovado e o pedido 7 é inserido.
UPDATE sql_semana_10.pedidos
SET situacao = 'aprovado'
WHERE pedido_id = 5;

INSERT INTO sql_semana_10.pedidos
    (pedido_id, criado_em, situacao, valor_total)
VALUES
    (7, '2026-09-29 18:45:00-03', 'aprovado', 110.00);

-- 4. A origem já mostra três aprovados; a materialized view está defasada.
SELECT
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date AS dia,
    situacao,
    count(*) AS quantidade,
    sum(valor_total) AS valor_total,
    round(avg(valor_total), 2) AS ticket_medio
FROM sql_semana_10.pedidos
WHERE (criado_em AT TIME ZONE 'America/Sao_Paulo')::date = DATE '2026-09-29'
GROUP BY
    (criado_em AT TIME ZONE 'America/Sao_Paulo')::date,
    situacao
ORDER BY dia, situacao;

SELECT
    dia,
    situacao,
    quantidade,
    valor_total,
    ticket_medio
FROM sql_semana_10.indicadores_pedidos
WHERE dia = DATE '2026-09-29'
ORDER BY dia, situacao;

-- 5. O refresh comum substitui o conteúdo armazenado pelo resultado atual.
REFRESH MATERIALIZED VIEW sql_semana_10.indicadores_pedidos;

SELECT
    dia,
    situacao,
    quantidade,
    valor_total,
    ticket_medio
FROM sql_semana_10.indicadores_pedidos
WHERE dia = DATE '2026-09-29'
ORDER BY dia, situacao;

-- 6. Este índice identifica unicamente cada grupo e habilita o modo concorrente.
CREATE UNIQUE INDEX indicadores_pedidos_dia_situacao_uq
    ON sql_semana_10.indicadores_pedidos (dia, situacao);

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_catalog.pg_indexes
WHERE schemaname = 'sql_semana_10'
  AND tablename = 'indicadores_pedidos'
ORDER BY indexname;

-- 7. A view está populada e possui o índice UNIQUE exigido.
REFRESH MATERIALIZED VIEW CONCURRENTLY
    sql_semana_10.indicadores_pedidos;

SELECT
    dia,
    situacao,
    quantidade,
    valor_total,
    ticket_medio
FROM sql_semana_10.indicadores_pedidos
ORDER BY dia, situacao;
