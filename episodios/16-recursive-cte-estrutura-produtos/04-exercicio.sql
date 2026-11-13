-- Desafio: adicione três arruelas diretamente ao kit.
-- Tente adaptar as consultas antes de executar a solução abaixo.
-- Execute sem transação externa; o ROLLBACK restaura a massa-base.
BEGIN;
INSERT INTO sql_semana_16.estrutura VALUES ('KIT', 'P02', 3);

-- Uma unidade: seis linhas na expansão, sem ciclos.
WITH RECURSIVE explosao (produto, nivel, quantidade_acumulada) AS (
    -- Ponto de partida: uma unidade do kit.
    SELECT codigo, 0, 1::numeric
    FROM sql_semana_16.produtos
    WHERE codigo = 'KIT'

    UNION ALL

    -- Expande os componentes encontrados na etapa anterior.
    SELECT
        e.componente,
        x.nivel + 1,
        x.quantidade_acumulada * e.quantidade
    FROM explosao AS x
    JOIN sql_semana_16.estrutura AS e
      ON e.produto_pai = x.produto
)
CYCLE produto SET ciclo USING caminho
SELECT
    produto,
    nivel,
    quantidade_acumulada,
    ciclo,
    caminho
FROM explosao
ORDER BY caminho;

-- Folhas: P01 = 10 e P02 = 15.
WITH RECURSIVE explosao (produto, nivel, quantidade_acumulada) AS (
    -- Ponto de partida: uma unidade do kit.
    SELECT codigo, 0, 1::numeric
    FROM sql_semana_16.produtos
    WHERE codigo = 'KIT'

    UNION ALL

    -- Expande os componentes encontrados na etapa anterior.
    SELECT
        e.componente,
        x.nivel + 1,
        x.quantidade_acumulada * e.quantidade
    FROM explosao AS x
    JOIN sql_semana_16.estrutura AS e
      ON e.produto_pai = x.produto
)
CYCLE produto SET ciclo USING caminho
SELECT
    x.produto,
    p.descricao,
    sum(x.quantidade_acumulada) AS quantidade_necessaria
FROM explosao AS x
JOIN sql_semana_16.produtos AS p
  ON p.codigo = x.produto
WHERE x.nivel > 0
  AND NOT x.ciclo
  AND NOT EXISTS (
      SELECT 1
      FROM explosao AS diagnostico
      WHERE diagnostico.ciclo
  )
  AND NOT EXISTS (
      SELECT 1
      FROM sql_semana_16.estrutura AS e
      WHERE e.produto_pai = x.produto
  )
GROUP BY x.produto, p.descricao
ORDER BY x.produto;

-- Três unidades: altere somente o multiplicador inicial para 3::numeric.
-- Folhas: P01 = 30 e P02 = 45; continuam sendo seis caminhos.
WITH RECURSIVE explosao (produto, nivel, quantidade_acumulada) AS (
    -- Ponto de partida: uma unidade do kit.
    SELECT codigo, 0, 3::numeric
    FROM sql_semana_16.produtos
    WHERE codigo = 'KIT'

    UNION ALL

    -- Expande os componentes encontrados na etapa anterior.
    SELECT
        e.componente,
        x.nivel + 1,
        x.quantidade_acumulada * e.quantidade
    FROM explosao AS x
    JOIN sql_semana_16.estrutura AS e
      ON e.produto_pai = x.produto
)
CYCLE produto SET ciclo USING caminho
SELECT
    x.produto,
    p.descricao,
    sum(x.quantidade_acumulada) AS quantidade_necessaria
FROM explosao AS x
JOIN sql_semana_16.produtos AS p
  ON p.codigo = x.produto
WHERE x.nivel > 0
  AND NOT x.ciclo
  AND NOT EXISTS (
      SELECT 1
      FROM explosao AS diagnostico
      WHERE diagnostico.ciclo
  )
  AND NOT EXISTS (
      SELECT 1
      FROM sql_semana_16.estrutura AS e
      WHERE e.produto_pai = x.produto
  )
GROUP BY x.produto, p.descricao
ORDER BY x.produto;

ROLLBACK;
