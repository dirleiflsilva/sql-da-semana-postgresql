SET search_path TO sql_semana_04;

-- Inserção normal: ainda não existe a chave composta de backup nesta data.
INSERT INTO pipeline_status (
    pipeline, data_referencia, status, execucoes, atualizado_em
)
VALUES (
    'backup', DATE '2026-01-15', 'pendente', 0,
    TIMESTAMPTZ '2026-01-15 11:00:00+00'
)
RETURNING 'inserido' AS acao, pipeline, data_referencia, status, execucoes;

-- O conflito é ignorado. O comando retorna INSERT 0 0 e nenhuma linha.
INSERT INTO pipeline_status (
    pipeline, data_referencia, status, execucoes, atualizado_em
)
VALUES (
    'carga-clientes', DATE '2026-01-15', 'falha', 99,
    TIMESTAMPTZ '2026-01-15 12:00:00+00'
)
ON CONFLICT (pipeline, data_referencia) DO NOTHING
RETURNING 'inserido' AS acao, pipeline, data_referencia, status, execucoes;

-- EXCLUDED contém a linha proposta; seus valores atualizam a linha existente.
INSERT INTO pipeline_status (
    pipeline, data_referencia, status, execucoes, atualizado_em
)
VALUES (
    'carga-clientes', DATE '2026-01-15', 'falha', 2,
    TIMESTAMPTZ '2026-01-15 12:30:00+00'
)
ON CONFLICT (pipeline, data_referencia) DO UPDATE
SET status = EXCLUDED.status,
    execucoes = pipeline_status.execucoes + EXCLUDED.execucoes,
    atualizado_em = EXCLUDED.atualizado_em
RETURNING 'atualizado' AS acao, pipeline, data_referencia, status, execucoes;

-- A mesma forma de UPSERT também insere quando não há conflito.
INSERT INTO pipeline_status (
    pipeline, data_referencia, status, execucoes, atualizado_em
)
VALUES (
    'relatorio', DATE '2026-01-15', 'sucesso', 1,
    TIMESTAMPTZ '2026-01-15 13:00:00+00'
)
ON CONFLICT (pipeline, data_referencia) DO UPDATE
SET status = EXCLUDED.status,
    execucoes = pipeline_status.execucoes + EXCLUDED.execucoes,
    atualizado_em = EXCLUDED.atualizado_em
RETURNING 'inserido' AS acao, pipeline, data_referencia, status, execucoes;

SELECT pipeline, data_referencia, status, execucoes
FROM pipeline_status
ORDER BY pipeline, data_referencia;
