DO $validacao_exercicio$
DECLARE
    v_obtido record;
BEGIN
    IF (SELECT count(*) FROM sql_semana_14.movimentacoes) <> 11 THEN
        RAISE EXCEPTION 'Exercício inválido: esperadas 11 movimentações';
    END IF;

    SELECT * INTO v_obtido FROM (
        SELECT movimento_id, saldo, ultimos_dois, ultimas_24h, anterior,
               linhas_rows, linhas_range
        FROM (
            SELECT movimento_id,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS saldo,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS ultimos_dois,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em
                       RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW) AS ultimas_24h,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS anterior,
                   count(*) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS linhas_rows,
                   count(*) OVER (PARTITION BY conta_id ORDER BY ocorrido_em
                       RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW) AS linhas_range
            FROM sql_semana_14.movimentacoes WHERE conta_id = 101
        ) calculado WHERE movimento_id = 11
    ) resultado;

    IF v_obtido.saldo IS DISTINCT FROM 1085.00::numeric
       OR v_obtido.ultimos_dois IS DISTINCT FROM (-15.00)::numeric
       OR v_obtido.ultimas_24h IS DISTINCT FROM 85.00::numeric
       OR v_obtido.anterior IS DISTINCT FROM 1060.00::numeric
       OR v_obtido.linhas_rows <> 2 OR v_obtido.linhas_range <> 3 THEN
        RAISE EXCEPTION 'Resultado do evento simultâneo divergente: %', row_to_json(v_obtido);
    END IF;

    RAISE NOTICE 'Validação do exercício do episódio 14 concluída com sucesso.';
END
$validacao_exercicio$;
