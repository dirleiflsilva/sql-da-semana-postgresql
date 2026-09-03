SET search_path TO sql_semana_07;

-- Quatro categorias: uma sem produtos, uma com dois e duas com mais de três.
INSERT INTO categories (name)
VALUES
    ('Banco de dados'),
    ('DevOps'),
    ('Backend'),
    ('Sem produtos');

-- O JOIN evita depender dos valores gerados para category_id.
-- Em Banco de dados, dois produtos empatam com 850 vendas.
INSERT INTO products (category_id, name, sales_count)
SELECT
    c.category_id,
    data.product_name,
    data.sales_count
FROM (
    VALUES
        ('Banco de dados', 'PostgreSQL para operações', 980),
        ('Banco de dados', 'Backup e PITR', 850),
        ('Banco de dados', 'Otimização SQL', 850),
        ('Banco de dados', 'Streaming replication', 720),
        ('Banco de dados', 'Índices no PostgreSQL', 680),
        ('DevOps', 'Docker Compose', 930),
        ('DevOps', 'CI/CD', 810),
        ('DevOps', 'Observabilidade', 760),
        ('DevOps', 'Infraestrutura como código', 700),
        ('Backend', 'FastAPI', 870),
        ('Backend', 'APIs REST', 820)
) AS data(category_name, product_name, sales_count)
JOIN categories AS c
  ON c.name = data.category_name
ORDER BY c.category_id, data.product_name;
