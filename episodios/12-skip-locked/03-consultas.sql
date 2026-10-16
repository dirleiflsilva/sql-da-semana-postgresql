-- Exemplos de uma sessão. A concorrência com duas sessões está no README.

-- Reserva atômica: escolha, lock e mudança de estado no mesmo comando.
WITH proximo AS (
    SELECT documento_id
    FROM sql_semana_12.fila_documentos
    WHERE status = 'pendente'
    ORDER BY criado_em, documento_id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE sql_semana_12.fila_documentos AS fila
SET status = 'processando',
    worker_id = 'worker-exemplo',
    tentativas = fila.tentativas + 1,
    iniciado_em = clock_timestamp(),
    concluido_em = NULL,
    ultimo_erro = NULL
FROM proximo
WHERE fila.documento_id = proximo.documento_id
RETURNING fila.documento_id, fila.chave, fila.nome_arquivo,
          fila.status, fila.worker_id, fila.tentativas;

-- O processamento do XML deve ocorrer fora da transação de reserva.
-- Registra uma conclusão em outra transação curta (autocommit neste script).
UPDATE sql_semana_12.fila_documentos
SET status = 'concluido',
    concluido_em = clock_timestamp(),
    ultimo_erro = NULL
WHERE chave = 'NFE-0001'
  AND status = 'processando'
  AND worker_id = 'worker-exemplo'
RETURNING documento_id, chave, status, worker_id, tentativas;

-- Reserva outro item e registra falha em comandos curtos separados.
WITH proximo AS (
    SELECT documento_id
    FROM sql_semana_12.fila_documentos
    WHERE status = 'pendente'
    ORDER BY criado_em, documento_id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE sql_semana_12.fila_documentos AS fila
SET status = 'processando',
    worker_id = 'worker-exemplo',
    tentativas = fila.tentativas + 1,
    iniciado_em = clock_timestamp(),
    concluido_em = NULL,
    ultimo_erro = NULL
FROM proximo
WHERE fila.documento_id = proximo.documento_id
RETURNING fila.documento_id, fila.chave, fila.status, fila.worker_id;

UPDATE sql_semana_12.fila_documentos
SET status = 'falhou',
    concluido_em = clock_timestamp(),
    ultimo_erro = 'Falha sintética ao enviar documento'
WHERE chave = 'NFE-0002'
  AND status = 'processando'
  AND worker_id = 'worker-exemplo'
RETURNING documento_id, chave, status, worker_id, tentativas, ultimo_erro;

SELECT documento_id, chave, status, worker_id, tentativas
FROM sql_semana_12.fila_documentos
ORDER BY documento_id;
