-- Massa-base sintética do artigo. Execute depois de 01-tabelas.sql.
INSERT INTO sql_semana_14.movimentacoes
    (conta_id, ocorrido_em, descricao, valor)
VALUES
    (101, '2026-10-30 08:00:00-03', 'Saldo inicial',          1000.00),
    (101, '2026-10-30 09:15:00-03', 'Pagamento fornecedor',   -180.00),
    (101, '2026-10-30 10:00:00-03', 'Recebimento pedido 501',  250.00),
    (101, '2026-10-30 10:00:00-03', 'Tarifa da operação',      -10.00),
    (101, '2026-10-30 14:30:00-03', 'Pagamento frete',         -60.00),
    (202, '2026-10-30 08:00:00-03', 'Saldo inicial',           500.00),
    (202, '2026-10-30 11:00:00-03', 'Recebimento pedido 880',  120.00),
    (202, '2026-10-30 16:00:00-03', 'Pagamento fornecedor',   -200.00);
