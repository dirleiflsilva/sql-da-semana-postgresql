-- Reinicialização: remove os objetos e dados somente do episódio 12.
-- Execute em uma base de estudos; o conteúdo de sql_semana_12 será apagado.
DROP SCHEMA IF EXISTS sql_semana_12 CASCADE;
CREATE SCHEMA sql_semana_12;

CREATE TABLE sql_semana_12.fila_documentos (
    documento_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chave        text NOT NULL UNIQUE,
    nome_arquivo text NOT NULL,
    conteudo_xml xml NOT NULL,
    status       text NOT NULL DEFAULT 'pendente'
        CHECK (status IN ('pendente', 'processando', 'concluido', 'falhou')),
    tentativas   integer NOT NULL DEFAULT 0 CHECK (tentativas >= 0),
    worker_id    text,
    criado_em    timestamptz NOT NULL DEFAULT clock_timestamp(),
    iniciado_em  timestamptz,
    concluido_em timestamptz,
    ultimo_erro  text
);

CREATE INDEX fila_documentos_pendentes_idx
    ON sql_semana_12.fila_documentos (criado_em, documento_id)
    WHERE status = 'pendente';
