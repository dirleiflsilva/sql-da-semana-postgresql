-- Massa sintética. Reexecute somente depois de 01-tabelas.sql.
INSERT INTO sql_semana_16.produtos VALUES
    ('KIT', 'Kit de montagem'),
    ('MOD', 'Módulo montado'),
    ('P01', 'Parafuso'),
    ('P02', 'Arruela');

INSERT INTO sql_semana_16.estrutura VALUES
    ('KIT', 'MOD', 2),
    ('KIT', 'P01', 4),
    ('MOD', 'P01', 3),
    ('MOD', 'P02', 6);
