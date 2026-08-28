-- Recria somente o ambiente do episódio 06.
DROP SCHEMA IF EXISTS sql_semana_06 CASCADE;
CREATE SCHEMA sql_semana_06;
SET search_path TO sql_semana_06;

CREATE TABLE vendas (
    venda_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendedor_id  bigint NOT NULL,
    realizada_em timestamptz NOT NULL,
    valor        numeric(12, 2) NOT NULL CHECK (valor > 0)
);
