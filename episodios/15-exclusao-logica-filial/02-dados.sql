-- Massa sintética. Reexecute somente depois de 01-tabelas.sql.
INSERT INTO sql_semana_15.pedidos (r_e_c_n_o_, filial, numero, d_e_l_e_t_) VALUES
    (1, '01', '100', ' '),
    (2, '02', '100', ' '),
    (3, '01', '101', '*'),
    (4, '01', '102', ' '),
    (5, '01', '103', ' ');

INSERT INTO sql_semana_15.itens
    (r_e_c_n_o_, filial, numero, item, produto, valor, d_e_l_e_t_) VALUES
    (11, '01', '100', '01', 'P01', 100.00, ' '),
    (12, '01', '100', '02', 'P02',  50.00, '*'),
    (13, '02', '100', '01', 'P01', 900.00, ' '),
    (14, '01', '101', '01', 'P01', 300.00, ' '),
    (15, '01', '103', '01', 'P01',  70.00, '*');

INSERT INTO sql_semana_15.produtos
    (r_e_c_n_o_, filial, codigo, descricao, d_e_l_e_t_) VALUES
    (21, '  ', 'P01', 'Produto A', ' '),
    (22, '  ', 'P02', 'Produto B', ' ');
