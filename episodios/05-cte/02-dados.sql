SET search_path TO sql_semana_05;

-- As datas são relativas à execução para que o recorte de 30 dias continue válido.
INSERT INTO execucoes_pipeline (
    pipeline, status, iniciado_em, finalizado_em
)
VALUES
    ('carga-vendas', 'sucesso', current_timestamp - interval '1 day',
     current_timestamp - interval '1 day' + interval '600 seconds'),
    ('carga-vendas', 'sucesso', current_timestamp - interval '3 days',
     current_timestamp - interval '3 days' + interval '720 seconds'),
    ('carga-vendas', 'falha', current_timestamp - interval '5 days',
     current_timestamp - interval '5 days' + interval '660 seconds'),
    ('carga-vendas', 'sucesso', current_timestamp - interval '7 days',
     current_timestamp - interval '7 days' + interval '780 seconds'),
    ('carga-vendas', 'sucesso', current_timestamp - interval '9 days',
     current_timestamp - interval '9 days' + interval '840 seconds'),

    ('backup', 'sucesso', current_timestamp - interval '2 days',
     current_timestamp - interval '2 days' + interval '120 seconds'),
    ('backup', 'falha', current_timestamp - interval '4 days',
     current_timestamp - interval '4 days' + interval '180 seconds'),
    ('backup', 'sucesso', current_timestamp - interval '6 days',
     current_timestamp - interval '6 days' + interval '150 seconds'),
    ('backup', 'falha', current_timestamp - interval '8 days',
     current_timestamp - interval '8 days' + interval '210 seconds'),
    ('backup', 'sucesso', current_timestamp - interval '10 days',
     current_timestamp - interval '10 days' + interval '240 seconds'),

    ('relatorio', 'sucesso', current_timestamp - interval '11 days',
     current_timestamp - interval '11 days' + interval '900 seconds'),
    ('relatorio', 'sucesso', current_timestamp - interval '13 days',
     current_timestamp - interval '13 days' + interval '960 seconds'),
    ('relatorio', 'falha', current_timestamp - interval '15 days',
     current_timestamp - interval '15 days' + interval '1020 seconds'),
    ('relatorio', 'sucesso', current_timestamp - interval '17 days',
     current_timestamp - interval '17 days' + interval '1080 seconds'),
    ('relatorio', 'sucesso', current_timestamp - interval '19 days',
     current_timestamp - interval '19 days' + interval '1140 seconds'),

    -- Esta execução antiga fica fora do recorte de 30 dias.
    ('carga-vendas', 'sucesso', current_timestamp - interval '40 days',
     current_timestamp - interval '40 days' + interval '3000 seconds'),
    -- Esta execução recente ainda não possui duração completa.
    ('backup', 'executando', current_timestamp - interval '1 hour', NULL);

INSERT INTO categorias (nome, categoria_pai_id)
VALUES ('Tecnologia', NULL);

INSERT INTO categorias (nome, categoria_pai_id)
VALUES
    ('Bancos de dados', 1),
    ('Infraestrutura', 1);

INSERT INTO categorias (nome, categoria_pai_id)
VALUES
    ('PostgreSQL', 2),
    ('Contêineres', 3);
