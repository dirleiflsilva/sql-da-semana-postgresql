-- Reinicialização restrita ao episódio 16; execute em uma base de estudos.
DROP SCHEMA IF EXISTS sql_semana_16 CASCADE;
CREATE SCHEMA sql_semana_16;

CREATE TABLE sql_semana_16.produtos (
    codigo text PRIMARY KEY,
    descricao text NOT NULL
);

CREATE TABLE sql_semana_16.estrutura (
    produto_pai text NOT NULL REFERENCES sql_semana_16.produtos (codigo),
    componente text NOT NULL REFERENCES sql_semana_16.produtos (codigo),
    quantidade numeric NOT NULL CHECK (quantidade > 0),
    PRIMARY KEY (produto_pai, componente),
    CHECK (produto_pai <> componente)
);
