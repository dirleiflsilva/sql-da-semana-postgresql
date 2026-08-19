SET search_path TO sql_semana_05;

-- CTEs nomeiam cada etapa: recorte, métricas por grupo e média de todas as linhas.
WITH execucoes_recentes AS (
    SELECT
        pipeline,
        status,
        extract(epoch FROM finalizado_em - iniciado_em) AS duracao_segundos
    FROM execucoes_pipeline
    WHERE iniciado_em >= current_timestamp - interval '30 days'
      AND finalizado_em IS NOT NULL
),
metricas_por_pipeline AS (
    SELECT
        pipeline,
        count(*) AS total_execucoes,
        round(avg(duracao_segundos), 2) AS duracao_media,
        round(
            100.0 * count(*) FILTER (WHERE status = 'falha') / count(*),
            2
        ) AS taxa_falhas_percentual
    FROM execucoes_recentes
    GROUP BY pipeline
),
media_geral AS (
    SELECT avg(duracao_segundos) AS duracao_media_geral
    FROM execucoes_recentes
)
SELECT
    metricas.pipeline,
    metricas.total_execucoes,
    metricas.duracao_media,
    metricas.taxa_falhas_percentual,
    round(media.duracao_media_geral, 2) AS duracao_media_geral
FROM metricas_por_pipeline AS metricas
CROSS JOIN media_geral AS media
WHERE metricas.total_execucoes >= 5
  AND metricas.duracao_media > media.duracao_media_geral
ORDER BY metricas.pipeline;

-- MATERIALIZED força a materialização do resultado intermediário.
WITH execucoes_finalizadas AS MATERIALIZED (
    SELECT pipeline, status
    FROM execucoes_pipeline
    WHERE iniciado_em >= current_timestamp - interval '30 days'
      AND finalizado_em IS NOT NULL
)
SELECT
    pipeline,
    count(*) AS total,
    count(*) FILTER (WHERE status = 'falha') AS falhas
FROM execucoes_finalizadas
GROUP BY pipeline
ORDER BY pipeline;

-- NOT MATERIALIZED permite que o planejador incorpore a CTE à consulta principal.
WITH execucoes_finalizadas AS NOT MATERIALIZED (
    SELECT pipeline, status
    FROM execucoes_pipeline
    WHERE iniciado_em >= current_timestamp - interval '30 days'
      AND finalizado_em IS NOT NULL
)
SELECT pipeline, count(*) AS sucessos
FROM execucoes_finalizadas
WHERE status = 'sucesso'
GROUP BY pipeline
ORDER BY pipeline;

-- A CTE modificadora atualiza linhas e alimenta o INSERT com RETURNING.
WITH execucoes_atualizadas AS (
    UPDATE execucoes_pipeline
    SET status = 'reprocessar'
    WHERE pipeline = 'backup'
      AND status = 'falha'
    RETURNING id, pipeline, status
)
INSERT INTO execucoes_arquivadas (
    execucao_id, pipeline, status, arquivado_em
)
SELECT id, pipeline, status, current_timestamp
FROM execucoes_atualizadas
RETURNING execucao_id, pipeline, status;

-- CTE recursiva percorre a hierarquia a partir das categorias raiz.
WITH RECURSIVE arvore_categorias AS (
    SELECT
        id,
        nome,
        categoria_pai_id,
        1 AS nivel,
        nome::text AS caminho
    FROM categorias
    WHERE categoria_pai_id IS NULL

    UNION ALL

    SELECT
        filha.id,
        filha.nome,
        filha.categoria_pai_id,
        pai.nivel + 1,
        pai.caminho || ' > ' || filha.nome
    FROM categorias AS filha
    JOIN arvore_categorias AS pai
      ON filha.categoria_pai_id = pai.id
)
SELECT id, nome, nivel, caminho
FROM arvore_categorias
ORDER BY caminho;
