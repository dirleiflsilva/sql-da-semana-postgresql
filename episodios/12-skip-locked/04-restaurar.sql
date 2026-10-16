-- Restaura somente a massa sintética do episódio 12.
-- Locks ativos precisam ser encerrados com COMMIT ou ROLLBACK antes da execução.
TRUNCATE TABLE sql_semana_12.fila_documentos RESTART IDENTITY;

INSERT INTO sql_semana_12.fila_documentos
    (chave, nome_arquivo, conteudo_xml, criado_em)
VALUES
    ('NFE-0001', 'nfe-0001.xml',
     xmlparse(document '<nfe id="NFE-0001"><valor>101.10</valor></nfe>'),
     timestamptz '2026-10-16 09:00:01-03'),
    ('NFE-0002', 'nfe-0002.xml',
     xmlparse(document '<nfe id="NFE-0002"><valor>202.20</valor></nfe>'),
     timestamptz '2026-10-16 09:00:02-03'),
    ('NFE-0003', 'nfe-0003.xml',
     xmlparse(document '<nfe id="NFE-0003"><valor>303.30</valor></nfe>'),
     timestamptz '2026-10-16 09:00:03-03'),
    ('NFE-0004', 'nfe-0004.xml',
     xmlparse(document '<nfe id="NFE-0004"><valor>404.40</valor></nfe>'),
     timestamptz '2026-10-16 09:00:04-03');
