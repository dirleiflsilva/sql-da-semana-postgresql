SET search_path TO sql_semana_06;

-- Cada vendedor possui cinco vendas que somam R$ 1.000,00.
-- Há valores e instantes repetidos para tornar os empates visíveis.
INSERT INTO vendas (vendedor_id, realizada_em, valor)
VALUES
    (101, TIMESTAMPTZ '2026-02-10 09:00:00+00', 100.00),
    (101, TIMESTAMPTZ '2026-02-10 10:00:00+00', 300.00),
    (101, TIMESTAMPTZ '2026-02-11 09:00:00+00', 200.00),
    (101, TIMESTAMPTZ '2026-02-11 09:00:00+00', 200.00),
    (101, TIMESTAMPTZ '2026-02-12 08:00:00+00', 200.00),
    (202, TIMESTAMPTZ '2026-02-10 08:00:00+00', 250.00),
    (202, TIMESTAMPTZ '2026-02-10 12:00:00+00', 100.00),
    (202, TIMESTAMPTZ '2026-02-11 08:00:00+00', 250.00),
    (202, TIMESTAMPTZ '2026-02-12 09:00:00+00', 150.00),
    (202, TIMESTAMPTZ '2026-02-13 10:00:00+00', 250.00);
