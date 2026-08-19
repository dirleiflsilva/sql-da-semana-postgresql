-- Recria somente o ambiente do episódio 05.
DROP SCHEMA IF EXISTS sql_semana_05 CASCADE;
CREATE SCHEMA sql_semana_05;
SET search_path TO sql_semana_05;

CREATE TABLE execucoes_pipeline (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline      text NOT NULL,
    status        text NOT NULL,
    iniciado_em   timestamptz NOT NULL,
    finalizado_em timestamptz
);

CREATE TABLE execucoes_arquivadas (
    execucao_id    bigint PRIMARY KEY,
    pipeline       text NOT NULL,
    status         text NOT NULL,
    arquivado_em   timestamptz NOT NULL
);

CREATE TABLE categorias (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome       text NOT NULL,
    categoria_pai_id bigint REFERENCES categorias (id)
);
