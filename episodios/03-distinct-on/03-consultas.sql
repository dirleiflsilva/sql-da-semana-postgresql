SET search_path TO sql_semana_03;

-- A primeira expressão do ORDER BY corresponde à expressão do DISTINCT ON.
-- id DESC resolve de modo determinístico empates em executado_em.
SELECT DISTINCT ON (pipeline)
    pipeline, id, status, executado_em
FROM execucoes_pipeline
ORDER BY pipeline, executado_em DESC, id DESC;

-- Alternativa equivalente com função de janela.
SELECT pipeline, id, status, executado_em
FROM (
    SELECT
        pipeline,
        id,
        status,
        executado_em,
        row_number() OVER (
            PARTITION BY pipeline
            ORDER BY executado_em DESC, id DESC
        ) AS posicao
    FROM execucoes_pipeline
) AS execucoes_ordenadas
WHERE posicao = 1
ORDER BY pipeline;
