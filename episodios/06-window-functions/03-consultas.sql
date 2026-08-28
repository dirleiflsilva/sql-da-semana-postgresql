SET search_path TO sql_semana_06;

-- 1. GROUP BY reduz as cinco vendas de cada vendedor a uma linha.
SELECT
    vendedor_id,
    count(*) AS quantidade_vendas,
    sum(valor) AS valor_total
FROM vendas
GROUP BY vendedor_id
ORDER BY vendedor_id;

-- 2. A função de janela preserva cada venda e reinicia a numeração por vendedor.
-- venda_id torna determinística a ordem entre vendas de mesmo valor.
SELECT
    venda_id,
    vendedor_id,
    valor,
    row_number() OVER (
        PARTITION BY vendedor_id
        ORDER BY valor DESC, venda_id
    ) AS posicao
FROM vendas
ORDER BY vendedor_id, valor DESC, venda_id;

-- 3. row_number gera posições únicas. rank e dense_rank preservam empates;
-- rank deixa lacunas após o empate, enquanto dense_rank não deixa lacunas.
SELECT
    venda_id,
    vendedor_id,
    valor,
    row_number() OVER (
        PARTITION BY vendedor_id
        ORDER BY valor DESC, venda_id
    ) AS row_number,
    rank() OVER (
        PARTITION BY vendedor_id
        ORDER BY valor DESC
    ) AS rank,
    dense_rank() OVER (
        PARTITION BY vendedor_id
        ORDER BY valor DESC
    ) AS dense_rank
FROM vendas
ORDER BY vendedor_id, valor DESC, venda_id;

-- 4. O total acumulado segue a ordem cronológica dentro de cada vendedor.
-- venda_id desempata as vendas 3 e 4, realizadas no mesmo instante.
SELECT
    venda_id,
    vendedor_id,
    realizada_em,
    valor,
    sum(valor) OVER (
        PARTITION BY vendedor_id
        ORDER BY realizada_em, venda_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS valor_acumulado
FROM vendas
ORDER BY vendedor_id, realizada_em, venda_id;

-- 5. Sem ORDER BY, a janela abrange todas as vendas da partição.
-- valor é sempre positivo, portanto o total de cada vendedor nunca será zero.
SELECT
    venda_id,
    vendedor_id,
    valor,
    round(
        valor / sum(valor) OVER (PARTITION BY vendedor_id) * 100,
        2
    ) AS percentual_do_vendedor
FROM vendas
ORDER BY vendedor_id, venda_id;

-- 6. Ranking por valor, acumulado cronológico e percentual na mesma consulta.
SELECT
    venda_id,
    vendedor_id,
    realizada_em,
    valor,
    dense_rank() OVER (
        PARTITION BY vendedor_id
        ORDER BY valor DESC
    ) AS ranking_por_valor,
    sum(valor) OVER (
        PARTITION BY vendedor_id
        ORDER BY realizada_em, venda_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS valor_acumulado,
    round(
        valor / sum(valor) OVER (PARTITION BY vendedor_id) * 100,
        2
    ) AS percentual_do_vendedor
FROM vendas
ORDER BY vendedor_id, realizada_em, venda_id;
