-- Nove movimentos sintéticos e determinísticos.
-- Execute depois de 01-tabelas.sql.
INSERT INTO sql_semana_13.faturamento_importado
    (movimento_id, data_emissao, valor)
VALUES
    (1, '20261001',   120.00),
    (2, '20261003',    80.00),
    (3, '20261003',    45.50),
    (4, '20261007',   200.00),
    (5, '',            30.00),
    (6, '        ',    25.00),
    (7, '20260230',    60.00),
    (8, '2026-10-05',  70.00),
    (9, NULL,          15.00);
