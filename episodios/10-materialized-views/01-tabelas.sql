-- Reinicialização: remove os objetos e dados somente do episódio 10.
-- Execute em uma base de estudos; o conteúdo de sql_semana_10 será apagado.
DROP SCHEMA IF EXISTS sql_semana_10 CASCADE;
CREATE SCHEMA sql_semana_10;

CREATE TABLE sql_semana_10.pedidos (
    pedido_id   integer PRIMARY KEY,
    criado_em   timestamptz NOT NULL,
    situacao    text NOT NULL,
    valor_total numeric(12,2) NOT NULL,
    CHECK (situacao IN ('pendente', 'aprovado', 'cancelado')),
    CHECK (valor_total >= 0)
);
