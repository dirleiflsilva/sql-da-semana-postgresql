-- 1. Expansão: cinco linhas, com P01 em dois caminhos válidos.
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

-- 2. Somente folhas: P01 = 10 e P02 = 12.
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

-- 3. Ciclo indireto aceito pelas constraints, revertido ao final.
-- Execute este arquivo sem uma transação externa.
BEGIN;
INSERT INTO sql_semana_16.estrutura VALUES ('P02', 'KIT', 1);

-- Seis linhas; KIT no nível 3 é marcado como ciclo.
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

-- Diagnóstico: somente KIT → MOD → P02 → KIT, quantidade 12.
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
SELECT produto, nivel, quantidade_acumulada, caminho
FROM explosao
WHERE ciclo
ORDER BY caminho;

-- Consolidação bloqueada: zero linhas, mesmo existindo P01 válido.
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

ROLLBACK;

-- 4. Massa restaurada: P01 = 10 e P02 = 12.
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
