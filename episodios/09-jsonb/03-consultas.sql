-- Execute depois de 01-tabelas.sql e 02-dados.sql.

-- 1. Extração: cinco linhas; a UF do documento 5 é SQL NULL.
SELECT
    documento_id,
    metadados -> 'emitente' AS emitente,
    metadados ->> 'origem' AS origem,
    metadados #>> '{emitente,uf}' AS uf
FROM sql_semana_09.documentos
ORDER BY documento_id;

-- 2. Contenção: documentos 1 e 4.
SELECT documento_id, referencia
FROM sql_semana_09.documentos
WHERE metadados @> '{"origem":"api","situacao":"autorizado"}'::jsonb
ORDER BY documento_id;

-- 3. Evento de cancelamento: somente documento 2.
SELECT documento_id, referencia
FROM sql_semana_09.documentos
WHERE metadados @> '{"eventos":[{"tipo":"cancelamento"}]}'::jsonb
ORDER BY documento_id;

-- 4. Protocolo: existência da chave, JSON null e SQL NULL.
SELECT
    documento_id,
    metadados ? 'protocolo' AS possui_chave,
    metadados -> 'protocolo' = 'null'::jsonb AS valor_json_null,
    metadados ->> 'protocolo' IS NULL AS texto_sql_null
FROM sql_semana_09.documentos
ORDER BY documento_id;

-- 5. CROSS JOIN LATERAL: três linhas de eventos.
SELECT
    d.documento_id,
    e.posicao,
    e.evento ->> 'tipo' AS tipo,
    (e.evento ->> 'sequencia')::integer AS sequencia
FROM sql_semana_09.documentos AS d
CROSS JOIN LATERAL jsonb_array_elements(
    CASE
        WHEN jsonb_typeof(d.metadados -> 'eventos') = 'array'
            THEN d.metadados -> 'eventos'
        ELSE '[]'::jsonb
    END
) WITH ORDINALITY AS e(evento, posicao)
ORDER BY d.documento_id, e.posicao;

-- 6. LEFT JOIN LATERAL: seis linhas, preservando documentos sem eventos.
SELECT
    d.documento_id,
    e.posicao,
    e.evento ->> 'tipo' AS tipo,
    (e.evento ->> 'sequencia')::integer AS sequencia
FROM sql_semana_09.documentos AS d
LEFT JOIN LATERAL jsonb_array_elements(
    CASE
        WHEN jsonb_typeof(d.metadados -> 'eventos') = 'array'
            THEN d.metadados -> 'eventos'
        ELSE '[]'::jsonb
    END
) WITH ORDINALITY AS e(evento, posicao) ON true
ORDER BY d.documento_id, e.posicao;

-- 7. Índice GIN e plano: com cinco documentos, Seq Scan é plausível.
-- A massa valida resultados, não ganhos de desempenho.
CREATE INDEX documentos_metadados_gin_idx
    ON sql_semana_09.documentos USING gin (metadados);

ANALYZE sql_semana_09.documentos;

EXPLAIN (ANALYZE, BUFFERS)
SELECT documento_id
FROM sql_semana_09.documentos
WHERE metadados @> '{"eventos":[{"tipo":"cancelamento"}]}'::jsonb;
