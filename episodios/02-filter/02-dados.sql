SET search_path TO sql_semana_02;

INSERT INTO pedidos (cliente, status, valor, criado_em)
VALUES
    ('Ana', 'concluido', 100.00, DATE '2026-01-05'),
    ('Ana', 'pendente',   50.00, DATE '2026-01-06'),
    ('Ana', 'cancelado',  20.00, DATE '2026-01-07'),
    ('Bruno', 'concluido', 200.00, DATE '2026-01-08'),
    ('Bruno', 'concluido', 150.00, DATE '2026-01-09'),
    ('Bruno', 'pendente',   80.00, DATE '2026-01-10'),
    ('Carla', 'cancelado',  40.00, DATE '2026-01-11'),
    ('Carla', 'concluido', 120.00, DATE '2026-01-12');
