SET search_path TO sql_semana_01;

INSERT INTO jobs (descricao, status, prioridade)
VALUES
    ('Importar pedidos', 'pendente', 3),
    ('Atualizar indicadores', 'pendente', 2),
    ('Remover arquivos temporários', 'concluido', 1);
