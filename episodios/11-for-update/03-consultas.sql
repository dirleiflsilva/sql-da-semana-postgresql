-- Execute depois de 01-tabelas.sql e 02-dados.sql.
-- A prática concorrente com duas sessões está no README deste episódio.

-- 1. Estado inicial: saldo 100,00 e nenhuma reserva.
SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
ORDER BY conta_id;

SELECT reserva_id, conta_id, valor, origem
FROM sql_semana_11.reservas
ORDER BY reserva_id;

-- 2. Reserva atômica: o débito e o registro dependem da mesma linha retornada.
WITH saldo_reservado AS (
    UPDATE sql_semana_11.contas_integracao
    SET saldo_disponivel = saldo_disponivel - 70.00,
        atualizado_em = clock_timestamp()
    WHERE conta_id = 1
      AND saldo_disponivel >= 70.00
    RETURNING conta_id, saldo_disponivel
)
INSERT INTO sql_semana_11.reservas (conta_id, valor, origem)
SELECT conta_id, 70.00, 'worker-a'
FROM saldo_reservado
RETURNING reserva_id, conta_id, valor, origem;

-- 3. A mesma tentativa encontra saldo 30,00: zero linhas atualizadas e inseridas.
WITH saldo_reservado AS (
    UPDATE sql_semana_11.contas_integracao
    SET saldo_disponivel = saldo_disponivel - 70.00,
        atualizado_em = clock_timestamp()
    WHERE conta_id = 1
      AND saldo_disponivel >= 70.00
    RETURNING conta_id, saldo_disponivel
)
INSERT INTO sql_semana_11.reservas (conta_id, valor, origem)
SELECT conta_id, 70.00, 'worker-b'
FROM saldo_reservado
RETURNING reserva_id, conta_id, valor, origem;

-- 4. Estado final: saldo 30,00 e somente a reserva de worker-a.
SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
ORDER BY conta_id;

SELECT reserva_id, conta_id, valor, origem
FROM sql_semana_11.reservas
ORDER BY reserva_id;
