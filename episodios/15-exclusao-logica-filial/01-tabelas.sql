-- Reinicialização restrita ao episódio 15; execute em uma base de estudos.
DROP SCHEMA IF EXISTS sql_semana_15 CASCADE;
CREATE SCHEMA sql_semana_15;

-- Chaves de negócio simplificadas para este exercício, não índices do ERP.
CREATE TABLE sql_semana_15.pedidos (
    r_e_c_n_o_ bigint PRIMARY KEY,
    filial text NOT NULL CHECK (filial IN ('01', '02')),
    numero text NOT NULL,
    d_e_l_e_t_ text NOT NULL CHECK (d_e_l_e_t_ IN (' ', '*')),
    UNIQUE (filial, numero)
);

CREATE TABLE sql_semana_15.itens (
    r_e_c_n_o_ bigint PRIMARY KEY,
    filial text NOT NULL CHECK (filial IN ('01', '02')),
    numero text NOT NULL,
    item text NOT NULL,
    produto text NOT NULL,
    valor numeric(12, 2) NOT NULL,
    d_e_l_e_t_ text NOT NULL CHECK (d_e_l_e_t_ IN (' ', '*')),
    UNIQUE (filial, numero, item)
);

CREATE TABLE sql_semana_15.produtos (
    r_e_c_n_o_ bigint PRIMARY KEY,
    filial text NOT NULL CHECK (filial = '  '), -- Exatamente dois espaços.
    codigo text NOT NULL,
    descricao text NOT NULL,
    d_e_l_e_t_ text NOT NULL CHECK (d_e_l_e_t_ IN (' ', '*')),
    UNIQUE (filial, codigo)
);
-- Sem FK de item para produto: o roteiro também demonstra cadastro ausente.
-- r_e_c_n_o_ identifica linhas; não representa tempo nem relaciona tabelas.
