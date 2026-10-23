-- Validação automatizada e determinística para PostgreSQL 16.
-- Qualquer divergência interrompe o psql quando ON_ERROR_STOP=1 está ativo.
DO $validacao$
DECLARE
    v_detalhe text;
BEGIN
    IF (SELECT count(*) FROM sql_semana_13.faturamento_importado) <> 9
       OR (SELECT sum(valor) FROM sql_semana_13.faturamento_importado)
          IS DISTINCT FROM 645.50::numeric THEN
        RAISE EXCEPTION 'Carga inválida: esperadas 9 linhas e soma 645.50';
    END IF;

    WITH esperado(movimento_id, situacao) AS (
        VALUES (1, 'valida'), (2, 'valida'), (3, 'valida'), (4, 'valida'),
               (5, 'ausente'), (6, 'ausente'), (7, 'data_invalida'),
               (8, 'formato_invalido'), (9, 'ausente')
    ), normalizado AS (
        SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
        FROM sql_semana_13.faturamento_importado AS f
    ), candidato AS (
        SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2) END AS data_iso
        FROM normalizado
    ), obtido AS (
        SELECT movimento_id, CASE
            WHEN texto_limpo IS NULL THEN 'ausente'
            WHEN data_iso IS NULL THEN 'formato_invalido'
            WHEN NOT pg_input_is_valid(data_iso, 'date') THEN 'data_invalida'
            ELSE 'valida' END AS situacao
        FROM candidato
    ), divergencia AS (
        SELECT coalesce(e.movimento_id, o.movimento_id) AS movimento_id,
               e.situacao AS esperado, o.situacao AS obtido
        FROM esperado AS e
        FULL JOIN obtido AS o USING (movimento_id)
        WHERE e.situacao IS DISTINCT FROM o.situacao
    )
    SELECT string_agg(format('id %s: esperado=%s, obtido=%s',
                      movimento_id, esperado, obtido), '; ' ORDER BY movimento_id)
    INTO v_detalhe
    FROM divergencia;

    IF v_detalhe IS NOT NULL THEN
        RAISE EXCEPTION 'Classificação individual inválida: %', v_detalhe;
    END IF;

    WITH esperado(situacao, quantidade) AS (
        VALUES ('ausente', 3::bigint), ('data_invalida', 1::bigint),
               ('formato_invalido', 1::bigint), ('valida', 4::bigint)
    ), normalizado AS (
        SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
        FROM sql_semana_13.faturamento_importado AS f
    ), candidato AS (
        SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2) END AS data_iso
        FROM normalizado
    ), contagem AS (
        SELECT CASE WHEN texto_limpo IS NULL THEN 'ausente'
                    WHEN data_iso IS NULL THEN 'formato_invalido'
                    WHEN NOT pg_input_is_valid(data_iso, 'date') THEN 'data_invalida'
                    ELSE 'valida' END AS situacao, count(*) AS quantidade
        FROM candidato GROUP BY 1
    )
    SELECT string_agg(format('%s: esperado=%s, obtido=%s',
                      coalesce(e.situacao, c.situacao), e.quantidade, c.quantidade), '; ')
    INTO v_detalhe
    FROM esperado AS e FULL JOIN contagem AS c USING (situacao)
    WHERE e.quantidade IS DISTINCT FROM c.quantidade;

    IF v_detalhe IS NOT NULL THEN
        RAISE EXCEPTION 'Contagens por situação inválidas: %', v_detalhe;
    END IF;

    WITH normalizado AS (
        SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
        FROM sql_semana_13.faturamento_importado AS f
    ), candidato AS (
        SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2) END AS data_iso
        FROM normalizado
    ), totais AS (
        SELECT
            count(*) FILTER (WHERE data_iso IS NOT NULL AND
                             pg_input_is_valid(data_iso, 'date')) AS qtd_valida,
            sum(valor) FILTER (WHERE data_iso IS NOT NULL AND
                              pg_input_is_valid(data_iso, 'date')) AS soma_valida,
            count(*) FILTER (WHERE data_iso IS NULL OR
                             NOT pg_input_is_valid(data_iso, 'date')) AS qtd_rejeitada,
            sum(valor) FILTER (WHERE data_iso IS NULL OR
                              NOT pg_input_is_valid(data_iso, 'date')) AS soma_rejeitada
        FROM candidato
    )
    SELECT CASE WHEN qtd_valida <> 4 OR soma_valida IS DISTINCT FROM 445.50::numeric
                          OR qtd_rejeitada <> 5 OR soma_rejeitada IS DISTINCT FROM 200.00::numeric
                     THEN format('válidas=%s/%s; rejeitadas=%s/%s',
                                 qtd_valida, soma_valida, qtd_rejeitada, soma_rejeitada) END
    INTO v_detalhe FROM totais;

    IF v_detalhe IS NOT NULL THEN
        RAISE EXCEPTION 'Conciliação inválida: %', v_detalhe;
    END IF;

    WITH esperado(dia, movimentos, total) AS (
        VALUES (date '2026-10-01', 1::bigint, 120.00::numeric),
               (date '2026-10-02', 0::bigint,   0.00::numeric),
               (date '2026-10-03', 2::bigint, 125.50::numeric),
               (date '2026-10-04', 0::bigint,   0.00::numeric),
               (date '2026-10-05', 0::bigint,   0.00::numeric),
               (date '2026-10-06', 0::bigint,   0.00::numeric),
               (date '2026-10-07', 1::bigint, 200.00::numeric)
    ), normalizado AS (
        SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
        FROM sql_semana_13.faturamento_importado AS f
    ), candidato AS (
        SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2) END AS data_iso
        FROM normalizado
    ), diario AS (
        SELECT data_iso::date AS dia, count(*) AS movimentos, sum(valor) AS total
        FROM candidato
        WHERE data_iso IS NOT NULL AND pg_input_is_valid(data_iso, 'date')
        GROUP BY data_iso::date
    ), calendario AS (
        SELECT dia::date
        FROM generate_series(date '2026-10-01', date '2026-10-07', interval '1 day') s(dia)
    ), obtido AS (
        SELECT c.dia, coalesce(d.movimentos, 0) AS movimentos,
               coalesce(d.total, 0.00)::numeric AS total
        FROM calendario AS c LEFT JOIN diario AS d USING (dia)
    ), divergencia AS (
        SELECT coalesce(e.dia, o.dia) AS dia,
               e.movimentos AS mov_esperado, o.movimentos AS mov_obtido,
               e.total AS total_esperado, o.total AS total_obtido
        FROM esperado AS e FULL JOIN obtido AS o USING (dia)
        WHERE e.movimentos IS DISTINCT FROM o.movimentos
           OR e.total IS DISTINCT FROM o.total
    )
    SELECT string_agg(format('%s: movimentos %s/%s, total %s/%s', dia,
                      mov_esperado, mov_obtido, total_esperado, total_obtido), '; ' ORDER BY dia)
    INTO v_detalhe FROM divergencia;

    IF (SELECT count(*) FROM generate_series(
            date '2026-10-01', date '2026-10-07', interval '1 day')) <> 7 THEN
        RAISE EXCEPTION 'Calendário inválido: esperadas 7 linhas';
    END IF;
    IF v_detalhe IS NOT NULL THEN
        RAISE EXCEPTION 'Valores diários inválidos: %', v_detalhe;
    END IF;

    RAISE NOTICE 'Validação do episódio 13 concluída com sucesso.';
END
$validacao$;
