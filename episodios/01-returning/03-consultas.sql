SET search_path TO sql_semana_01;

-- O RETURNING devolve o identificador gerado pelo INSERT.
INSERT INTO jobs (descricao, status, prioridade)
VALUES ('Gerar relatório semanal', 'pendente', 4)
RETURNING id, descricao, status, prioridade;

-- O RETURNING mostra os valores que foram efetivamente alterados.
UPDATE jobs
SET status = 'em_execucao',
    prioridade = 5
WHERE id = 1
RETURNING id, descricao, status, prioridade;

-- Também é possível conhecer a linha removida sem uma consulta anterior.
DELETE FROM jobs
WHERE id = 3
RETURNING id, descricao, status, prioridade;

-- Estado final, com ordenação determinística.
SELECT id, descricao, status, prioridade
FROM jobs
ORDER BY id;
