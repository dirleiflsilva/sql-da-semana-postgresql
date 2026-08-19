-- Recria somente o ambiente do episódio 02.
DROP SCHEMA IF EXISTS sql_semana_02 CASCADE;
CREATE SCHEMA sql_semana_02;
SET search_path TO sql_semana_02;

CREATE TABLE pedidos (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente     text NOT NULL,
    status      text NOT NULL CHECK (status IN ('pendente', 'concluido', 'cancelado')),
    valor       numeric(10, 2) NOT NULL CHECK (valor >= 0),
    criado_em   date NOT NULL
);
