-- Reinicialização: remove somente os objetos do episódio 14.
DROP SCHEMA IF EXISTS sql_semana_14 CASCADE;
CREATE SCHEMA sql_semana_14;

CREATE TABLE sql_semana_14.movimentacoes (
    movimento_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conta_id     bigint NOT NULL,
    ocorrido_em  timestamptz NOT NULL,
    descricao    text NOT NULL,
    valor        numeric(12, 2) NOT NULL,
    CHECK (valor <> 0)
);

-- Ajuda a localizar o histórico de uma conta na ordem usada pelos acumulados.
-- A massa didática é pequena demais para demonstrar ganho de desempenho.
CREATE INDEX movimentacoes_conta_ocorrido_movimento_idx
    ON sql_semana_14.movimentacoes (conta_id, ocorrido_em, movimento_id);
