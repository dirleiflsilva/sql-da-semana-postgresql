-- Enunciado: consulte as duas filiais, preservando todos os cabeçalhos ativos,
-- inclusive sem itens ativos. Agrupe por (filial, numero) e calcule os totais
-- por filial. Espere quatro pedidos: três da 01 e um da 02.
-- Tente escrever a consulta antes de executar a solução abaixo.

-- 10a. Solução: quatro cabeçalhos ativos nas duas filiais.
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
ORDER BY 1, 2;

-- 10b. Totais por filial, a partir dos pedidos agrupados pela chave completa.
WITH por_pedido AS (
SELECT p.filial, p.numero, count(i.r_e_c_n_o_) AS itens,
       coalesce(sum(i.valor), 0.00) AS total
FROM sql_semana_15.pedidos p
LEFT JOIN sql_semana_15.itens i
    ON i.filial = p.filial AND i.numero = p.numero AND i.d_e_l_e_t_ = ' '
WHERE p.d_e_l_e_t_ = ' '
GROUP BY p.filial, p.numero
)
SELECT filial, count(*) AS pedidos, sum(total) AS total
FROM por_pedido
GROUP BY filial
ORDER BY 1, 2;
