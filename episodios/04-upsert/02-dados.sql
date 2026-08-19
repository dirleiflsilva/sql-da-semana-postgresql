SET search_path TO sql_semana_04;

INSERT INTO pipeline_status (
    pipeline, data_referencia, status, execucoes, atualizado_em
)
VALUES
    ('carga-clientes', DATE '2026-01-15', 'sucesso', 1,
     TIMESTAMPTZ '2026-01-15 10:00:00+00');
