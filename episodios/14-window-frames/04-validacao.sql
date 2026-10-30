-- Valida a massa-base antes do exercício. Falha imediatamente em divergências.
DO $validacao$
DECLARE
    v_detalhe text;
BEGIN
    IF (SELECT count(*) FROM sql_semana_14.movimentacoes) <> 8 THEN
        RAISE EXCEPTION 'Carga-base inválida: esperadas 8 movimentações';
    END IF;

    WITH esperado(conta_id, movimento_id, saldo) AS (
        VALUES (101::bigint, 1::bigint, 1000.00::numeric),
               (101, 2, 820.00), (101, 3, 1070.00),
               (101, 4, 1060.00), (101, 5, 1000.00),
               (202, 6, 500.00), (202, 7, 620.00), (202, 8, 420.00)
    ), obtido AS (
        SELECT conta_id, movimento_id,
               sum(valor) OVER (
                   PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               ) AS saldo
        FROM sql_semana_14.movimentacoes
    ), divergencia AS (
        SELECT coalesce(e.movimento_id, o.movimento_id) AS id,
               e.saldo AS esperado, o.saldo AS obtido
        FROM esperado e FULL JOIN obtido o USING (conta_id, movimento_id)
        WHERE e.saldo IS DISTINCT FROM o.saldo
    )
    SELECT string_agg(format('id %s: %s/%s', id, esperado, obtido), '; ' ORDER BY id)
      INTO v_detalhe FROM divergencia;
    IF v_detalhe IS NOT NULL THEN
        RAISE EXCEPTION 'Saldos por conta inválidos: %', v_detalhe;
    END IF;

    IF EXISTS (
        SELECT 1 FROM (
            SELECT movimento_id,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em) AS saldo
            FROM sql_semana_14.movimentacoes WHERE conta_id = 101
        ) s WHERE movimento_id IN (3, 4) AND saldo IS DISTINCT FROM 1060.00
    ) THEN RAISE EXCEPTION 'Moldura padrão não retornou 1060.00 para os pares'; END IF;

    IF EXISTS (
        SELECT 1 FROM (
            SELECT movimento_id,
                   sum(valor) OVER (
                       PARTITION BY conta_id ORDER BY ocorrido_em
                       GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
                   ) AS total
            FROM sql_semana_14.movimentacoes WHERE conta_id = 101
        ) s WHERE movimento_id IN (3, 4) AND total IS DISTINCT FROM 60.00
    ) THEN RAISE EXCEPTION 'GROUPS não retornou 60.00 para os pares'; END IF;

    IF (SELECT liquido FROM (
            SELECT movimento_id, sum(valor) OVER (
                PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS liquido
            FROM sql_semana_14.movimentacoes WHERE conta_id = 101
        ) s WHERE movimento_id = 5) IS DISTINCT FROM 180.00::numeric THEN
        RAISE EXCEPTION 'Janela móvel da quinta movimentação não retornou 180.00';
    END IF;

    IF (SELECT count(*) FROM (
            SELECT row_number() OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id) AS pos,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS anterior
            FROM sql_semana_14.movimentacoes
        ) s WHERE pos = 1 AND anterior IS NULL) <> 2 THEN
        RAISE EXCEPTION 'Saldo anterior da primeira linha não é NULL nas duas contas';
    END IF;

    IF (SELECT array_agg(saldo ORDER BY movimento_id) FROM (
            SELECT movimento_id, ocorrido_em,
                   sum(valor) OVER (PARTITION BY conta_id ORDER BY ocorrido_em, movimento_id
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS saldo
            FROM sql_semana_14.movimentacoes WHERE conta_id = 101
        ) s WHERE ocorrido_em >= '2026-10-30 10:00:00-03')
       IS DISTINCT FROM ARRAY[1070.00,1060.00,1000.00]::numeric[] THEN
        RAISE EXCEPTION 'Filtro após o cálculo não preservou o histórico';
    END IF;

    RAISE NOTICE 'Validação da massa-base do episódio 14 concluída com sucesso.';
END
$validacao$;
