-- Recria somente o ambiente do episódio 03.
DROP SCHEMA IF EXISTS sql_semana_03 CASCADE;
CREATE SCHEMA sql_semana_03;
SET search_path TO sql_semana_03;

CREATE TABLE execucoes_pipeline (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline      text NOT NULL,
    status        text NOT NULL CHECK (status IN ('sucesso', 'falha')),
    executado_em  timestamptz NOT NULL
);
