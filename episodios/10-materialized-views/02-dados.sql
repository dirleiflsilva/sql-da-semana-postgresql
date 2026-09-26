-- Seis pedidos sintéticos e determinísticos.
-- Execute depois de 01-tabelas.sql.
INSERT INTO sql_semana_10.pedidos
    (pedido_id, criado_em, situacao, valor_total)
VALUES
    (1, '2026-09-28 09:15:00-03', 'aprovado',  120.00),
    (2, '2026-09-28 10:40:00-03', 'aprovado',   80.00),
    (3, '2026-09-28 14:10:00-03', 'cancelado',  50.00),
    (4, '2026-09-29 08:30:00-03', 'aprovado',  200.00),
    (5, '2026-09-29 11:20:00-03', 'pendente',   90.00),
    (6, '2026-09-30 16:00:00-03', 'aprovado',  160.00);
