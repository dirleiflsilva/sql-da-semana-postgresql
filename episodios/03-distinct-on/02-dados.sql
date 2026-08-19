SET search_path TO sql_semana_03;

INSERT INTO execucoes_pipeline (pipeline, status, executado_em)
VALUES
    ('carga-clientes', 'sucesso', TIMESTAMPTZ '2026-01-10 09:00:00+00'),
    ('carga-clientes', 'falha',   TIMESTAMPTZ '2026-01-11 10:00:00+00'),
    ('carga-clientes', 'sucesso', TIMESTAMPTZ '2026-01-11 10:00:00+00'),
    ('backup', 'sucesso', TIMESTAMPTZ '2026-01-10 08:00:00+00'),
    ('backup', 'sucesso', TIMESTAMPTZ '2026-01-12 11:00:00+00'),
    ('relatorio', 'falha',   TIMESTAMPTZ '2026-01-13 12:00:00+00'),
    ('relatorio', 'sucesso', TIMESTAMPTZ '2026-01-13 12:00:00+00');
