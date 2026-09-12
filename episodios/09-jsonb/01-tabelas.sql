-- Reinicialização: remove os objetos e dados somente do episódio 09.
-- Execute em uma base de estudos; o conteúdo de sql_semana_09 será apagado.
DROP SCHEMA IF EXISTS sql_semana_09 CASCADE;
CREATE SCHEMA sql_semana_09;

CREATE TABLE sql_semana_09.documentos (
    documento_id integer PRIMARY KEY,
    referencia   text NOT NULL UNIQUE,
    metadados    jsonb NOT NULL,
    CHECK (jsonb_typeof(metadados) = 'object')
);

