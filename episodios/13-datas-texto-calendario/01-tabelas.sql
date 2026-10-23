-- Reinicialização: remove os objetos e dados somente do episódio 13.
-- Execute em uma base de estudos; o conteúdo de sql_semana_13 será apagado.
DROP SCHEMA IF EXISTS sql_semana_13 CASCADE;
CREATE SCHEMA sql_semana_13;

CREATE TABLE sql_semana_13.faturamento_importado (
    movimento_id integer PRIMARY KEY,
    data_emissao  text,
    valor         numeric(12, 2) NOT NULL
);
