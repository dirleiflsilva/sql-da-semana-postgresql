-- Recria somente o ambiente do episódio 04.
DROP SCHEMA IF EXISTS sql_semana_04 CASCADE;
CREATE SCHEMA sql_semana_04;
SET search_path TO sql_semana_04;

CREATE TABLE pipeline_status (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline         text NOT NULL,
    data_referencia  date NOT NULL,
    status           text NOT NULL CHECK (status IN ('pendente', 'sucesso', 'falha')),
    execucoes        integer NOT NULL CHECK (execucoes >= 0),
    atualizado_em    timestamptz NOT NULL,
    CONSTRAINT pipeline_status_pipeline_data_key
        UNIQUE (pipeline, data_referencia)
);
