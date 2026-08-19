-- Recria somente o ambiente do episódio 01.
DROP SCHEMA IF EXISTS sql_semana_01 CASCADE;
CREATE SCHEMA sql_semana_01;
SET search_path TO sql_semana_01;

CREATE TABLE jobs (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao   text NOT NULL,
    status      text NOT NULL DEFAULT 'pendente'
                CHECK (status IN ('pendente', 'em_execucao', 'concluido')),
    prioridade  smallint NOT NULL CHECK (prioridade BETWEEN 1 AND 5)
);
