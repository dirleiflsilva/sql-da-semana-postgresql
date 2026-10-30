-- Exercício: execute somente após validar a massa-base com 04-validacao.sql.
INSERT INTO sql_semana_14.movimentacoes
    (conta_id, ocorrido_em, descricao, valor)
VALUES
    (101, '2026-10-31 10:00:00-03', 'Recebimento pedido 502', 100.00),
    (101, '2026-11-01 10:00:00-03', 'Pagamento serviço',      -40.00),
    -- Evento adicional no mesmo instante para comparar pares em ROWS e RANGE.
    (101, '2026-11-01 10:00:00-03', 'Ajuste simultâneo',       25.00);

SELECT movimento_id, conta_id, ocorrido_em, descricao, valor,
       sum(valor) OVER acumulado AS saldo,
       sum(valor) OVER dois_movimentos AS liquido_ultimos_dois,
       sum(valor) OVER ultimas_24h AS liquido_ultimas_24h,
       sum(valor) OVER anterior AS saldo_anterior,
       count(*) OVER dois_movimentos AS linhas_em_rows,
       count(*) OVER ultimas_24h AS linhas_em_range
FROM sql_semana_14.movimentacoes
WINDOW
    acumulado AS (
        PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    dois_movimentos AS (
        PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW),
    ultimas_24h AS (
        PARTITION BY conta_id ORDER BY ocorrido_em
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW),
    anterior AS (
        PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
ORDER BY conta_id, ocorrido_em, movimento_id;
