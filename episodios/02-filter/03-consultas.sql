SET search_path TO sql_semana_02;

-- Várias métricas condicionais são calculadas em uma única leitura.
SELECT
    count(*) AS total_pedidos,
    count(*) FILTER (WHERE status = 'concluido') AS pedidos_concluidos,
    count(*) FILTER (WHERE status = 'pendente') AS pedidos_pendentes,
    count(*) FILTER (WHERE status = 'cancelado') AS pedidos_cancelados,
    sum(valor) AS valor_total,
    sum(valor) FILTER (WHERE status = 'concluido') AS valor_concluido,
    sum(valor) FILTER (WHERE status = 'pendente') AS valor_pendente,
    sum(valor) FILTER (WHERE status = 'cancelado') AS valor_cancelado
FROM pedidos;

-- FILTER mantém a condição separada da expressão agregada.
SELECT
    cliente,
    count(*) AS total_pedidos,
    count(*) FILTER (WHERE status = 'concluido') AS concluidos,
    sum(valor) FILTER (WHERE status = 'concluido') AS valor_concluido
FROM pedidos
GROUP BY cliente
ORDER BY cliente;

-- A mesma contagem com CASE, para comparação de legibilidade.
SELECT
    sum(CASE WHEN status = 'concluido' THEN 1 ELSE 0 END) AS concluidos_com_case,
    count(*) FILTER (WHERE status = 'concluido') AS concluidos_com_filter
FROM pedidos;
