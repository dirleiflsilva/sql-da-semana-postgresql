-- Reinicialização: remove os objetos e dados somente do episódio 11.
-- Execute em uma base de estudos; o conteúdo de sql_semana_11 será apagado.
DROP SCHEMA IF EXISTS sql_semana_11 CASCADE;
CREATE SCHEMA sql_semana_11;

CREATE TABLE sql_semana_11.contas_integracao (
    conta_id         bigint PRIMARY KEY,
    saldo_disponivel numeric(12, 2) NOT NULL
        CHECK (saldo_disponivel >= 0),
    atualizado_em    timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE sql_semana_11.reservas (
    reserva_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conta_id   bigint NOT NULL
        REFERENCES sql_semana_11.contas_integracao (conta_id),
    valor      numeric(12, 2) NOT NULL CHECK (valor > 0),
    origem     text NOT NULL,
    criada_em  timestamptz NOT NULL DEFAULT clock_timestamp()
);
