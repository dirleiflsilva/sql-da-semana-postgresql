-- Execute depois de 01-tabelas.sql e 02-dados.sql.

-- 1. Saldo acumulado evento a evento, isolado por conta.
SELECT movimento_id, conta_id, ocorrido_em, descricao, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS saldo
FROM sql_semana_14.movimentacoes
ORDER BY conta_id, ocorrido_em, movimento_id;

-- 2. Moldura padrão: os pares das 10:00 recebem juntos o saldo 1060.00.
-- A coluna seguinte explicita ROWS e mostra a evolução evento a evento.
SELECT movimento_id, ocorrido_em, descricao, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em
       ) AS saldo_moldura_padrao,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS saldo_rows
FROM sql_semana_14.movimentacoes
WHERE conta_id = 101
ORDER BY ocorrido_em, movimento_id;

-- 3. RANGE usa o domínio temporal; a quantidade de linhas pode variar.
-- Um deslocamento RANGE exige uma única expressão de ordenação compatível.
SELECT movimento_id, conta_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em
           RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
       ) AS movimentado_ultimas_24h
FROM sql_semana_14.movimentacoes
ORDER BY conta_id, ocorrido_em, movimento_id;

-- 4. GROUPS inclui o grupo de pares atual e o imediatamente anterior.
-- Nas duas linhas das 10:00: -180 + 250 - 10 = 60.00.
SELECT movimento_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em
           GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
       ) AS grupo_atual_e_anterior
FROM sql_semana_14.movimentacoes
WHERE conta_id = 101
ORDER BY ocorrido_em, movimento_id;

-- 5. Líquido das três movimentações mais recentes (não é o saldo total).
SELECT movimento_id, conta_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS liquido_ultimos_tres_movimentos
FROM sql_semana_14.movimentacoes
ORDER BY conta_id, ocorrido_em, movimento_id;

-- 6. Duas molduras declaradas com WINDOW na mesma consulta.
SELECT movimento_id, conta_id, ocorrido_em, descricao, valor,
       sum(valor) OVER saldo_desde_inicio AS saldo,
       sum(valor) OVER ultimos_tres AS liquido_ultimos_tres
FROM sql_semana_14.movimentacoes
WINDOW
    saldo_desde_inicio AS (
        PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),
    ultimos_tres AS (
        PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )
ORDER BY conta_id, ocorrido_em, movimento_id;

-- 7. Na primeira linha de cada conta, a moldura anterior é vazia e retorna NULL.
SELECT movimento_id, conta_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
       ) AS saldo_anterior,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS saldo_atual
FROM sql_semana_14.movimentacoes
ORDER BY conta_id, ocorrido_em, movimento_id;

-- 8. O WHERE abaixo ocorre antes da janela e descarta o histórico anterior.
SELECT movimento_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS saldo_sem_historico_anterior
FROM sql_semana_14.movimentacoes
WHERE conta_id = 101
  AND ocorrido_em >= '2026-10-30 10:00:00-03'
ORDER BY ocorrido_em, movimento_id;

-- 9. A CTE calcula o histórico; o filtro externo apenas limita a apresentação.
WITH saldos AS (
    SELECT movimento_id, conta_id, ocorrido_em, descricao, valor,
           sum(valor) OVER (
               PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS saldo
    FROM sql_semana_14.movimentacoes
    WHERE conta_id = 101
)
SELECT *
FROM saldos
WHERE ocorrido_em >= '2026-10-30 10:00:00-03'
ORDER BY ocorrido_em, movimento_id;

-- 10. Opcional: observe WindowAgg e as operações de ordenação/acesso.
-- Com apenas oito linhas, este plano não permite concluir ganhos de desempenho.
EXPLAIN (ANALYZE, BUFFERS)
SELECT movimento_id, conta_id, ocorrido_em, valor,
       sum(valor) OVER (
           PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS saldo
FROM sql_semana_14.movimentacoes
ORDER BY conta_id, ocorrido_em, movimento_id;
