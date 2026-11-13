-- Execute após 01 a 04, sem transação externa.
-- Objetos auxiliares temporários, restritos à sessão de validação.
CREATE OR REPLACE FUNCTION pg_temp.conferir(caso text, consulta text, esperado text)
RETURNS void LANGUAGE plpgsql AS $funcao$
DECLARE divergencias bigint;
BEGIN
    EXECUTE format(
        'WITH obtido AS (%s), esperado AS (%s)
         SELECT count(*) FROM (
             (SELECT * FROM obtido EXCEPT ALL SELECT * FROM esperado)
             UNION ALL
             (SELECT * FROM esperado EXCEPT ALL SELECT * FROM obtido)
         ) d', consulta, esperado) INTO divergencias;
    IF divergencias <> 0 THEN
        RAISE EXCEPTION '%: % divergências (chaves, cardinalidade ou valores)', caso, divergencias;
    END IF;
    RAISE NOTICE 'OK: %', caso;
END
$funcao$;

CREATE OR REPLACE TEMP VIEW expansao_validacao AS
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
SELECT produto, nivel, quantidade_acumulada, ciclo, caminho::text AS caminho
FROM explosao;

CREATE OR REPLACE TEMP VIEW folhas_validacao AS
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

CREATE OR REPLACE TEMP VIEW tres_kits_validacao AS
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

CREATE OR REPLACE TEMP VIEW expansao_tres_validacao AS
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
SELECT produto, nivel, quantidade_acumulada, ciclo, caminho::text AS caminho
FROM explosao;

SELECT pg_temp.conferir(
    'Carga: quatro produtos',
    $consulta$SELECT * FROM sql_semana_16.produtos$consulta$,
    $esperado$VALUES ('KIT'::text, 'Kit de montagem'::text), ('MOD', 'Módulo montado'), ('P01', 'Parafuso'), ('P02', 'Arruela')$esperado$
);

SELECT pg_temp.conferir(
    'Carga: quatro relacionamentos',
    $consulta$SELECT * FROM sql_semana_16.estrutura$consulta$,
    $esperado$VALUES ('KIT'::text, 'MOD'::text, 2::numeric), ('KIT', 'P01', 4), ('MOD', 'P01', 3), ('MOD', 'P02', 6)$esperado$
);

SELECT pg_temp.conferir(
    'Base: cinco caminhos completos',
    $consulta$SELECT * FROM expansao_validacao$consulta$,
    $esperado$VALUES ('KIT'::text, 0, 1::numeric, false, '{(KIT)}'::text), ('MOD', 1, 2, false, '{(KIT),(MOD)}'), ('P01', 2, 6, false, '{(KIT),(MOD),(P01)}'), ('P02', 2, 12, false, '{(KIT),(MOD),(P02)}'), ('P01', 1, 4, false, '{(KIT),(P01)}')$esperado$
);

SELECT pg_temp.conferir(
    'Base: folhas e totais',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 10::numeric), ('P02', 'Arruela', 12)$esperado$
);

BEGIN;
INSERT INTO sql_semana_16.estrutura VALUES ('P02', 'KIT', 1);

SELECT pg_temp.conferir(
    'Ciclo: seis caminhos e encerramento do ramo',
    $consulta$SELECT * FROM expansao_validacao$consulta$,
    $esperado$VALUES ('KIT'::text, 0, 1::numeric, false, '{(KIT)}'::text), ('MOD', 1, 2, false, '{(KIT),(MOD)}'), ('P01', 2, 6, false, '{(KIT),(MOD),(P01)}'), ('P02', 2, 12, false, '{(KIT),(MOD),(P02)}'), ('P01', 1, 4, false, '{(KIT),(P01)}'), ('KIT', 3, 12, true, '{(KIT),(MOD),(P02),(KIT)}')$esperado$
);

SELECT pg_temp.conferir(
    'Ciclo: fechamento identificado',
    $consulta$SELECT * FROM expansao_validacao WHERE ciclo$consulta$,
    $esperado$VALUES ('KIT'::text, 3, 12::numeric, true, '{(KIT),(MOD),(P02),(KIT)}'::text)$esperado$
);

SELECT pg_temp.conferir(
    'Ciclo: bloqueio de todos os totais',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$SELECT NULL::text, NULL::text, NULL::numeric WHERE false$esperado$
);

ROLLBACK;

SELECT pg_temp.conferir(
    'Ciclo revertido: relacionamentos originais',
    $consulta$SELECT * FROM sql_semana_16.estrutura$consulta$,
    $esperado$VALUES ('KIT'::text, 'MOD'::text, 2::numeric), ('KIT', 'P01', 4), ('MOD', 'P01', 3), ('MOD', 'P02', 6)$esperado$
);

SELECT pg_temp.conferir(
    'Ciclo revertido: totais restaurados',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 10::numeric), ('P02', 'Arruela', 12)$esperado$
);

BEGIN;
INSERT INTO sql_semana_16.estrutura VALUES ('KIT', 'P02', 3);

SELECT pg_temp.conferir(
    'Desafio: seis caminhos sem ciclo',
    $consulta$SELECT * FROM expansao_validacao$consulta$,
    $esperado$VALUES ('KIT'::text, 0, 1::numeric, false, '{(KIT)}'::text), ('MOD', 1, 2, false, '{(KIT),(MOD)}'), ('P01', 2, 6, false, '{(KIT),(MOD),(P01)}'), ('P02', 2, 12, false, '{(KIT),(MOD),(P02)}'), ('P01', 1, 4, false, '{(KIT),(P01)}'), ('P02', 1, 3, false, '{(KIT),(P02)}')$esperado$
);

SELECT pg_temp.conferir(
    'Desafio: folhas para um kit',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 10::numeric), ('P02', 'Arruela', 15)$esperado$
);

SELECT pg_temp.conferir(
    'Desafio: três kits preservam os caminhos e triplicam quantidades',
    $consulta$SELECT * FROM expansao_tres_validacao$consulta$,
    $esperado$VALUES ('KIT'::text, 0, 3::numeric, false, '{(KIT)}'::text), ('MOD', 1, 6, false, '{(KIT),(MOD)}'), ('P01', 2, 18, false, '{(KIT),(MOD),(P01)}'), ('P02', 2, 36, false, '{(KIT),(MOD),(P02)}'), ('P01', 1, 12, false, '{(KIT),(P01)}'), ('P02', 1, 9, false, '{(KIT),(P02)}')$esperado$
);

SELECT pg_temp.conferir(
    'Desafio: folhas para três kits',
    $consulta$SELECT * FROM tres_kits_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 30::numeric), ('P02', 'Arruela', 45)$esperado$
);

ROLLBACK;

SELECT pg_temp.conferir(
    'Desafio revertido: caminhos originais',
    $consulta$SELECT * FROM expansao_validacao$consulta$,
    $esperado$VALUES ('KIT'::text, 0, 1::numeric, false, '{(KIT)}'::text), ('MOD', 1, 2, false, '{(KIT),(MOD)}'), ('P01', 2, 6, false, '{(KIT),(MOD),(P01)}'), ('P02', 2, 12, false, '{(KIT),(MOD),(P02)}'), ('P01', 1, 4, false, '{(KIT),(P01)}')$esperado$
);

SELECT pg_temp.conferir(
    'Desafio revertido: totais originais',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 10::numeric), ('P02', 'Arruela', 12)$esperado$
);

BEGIN;
INSERT INTO sql_semana_16.produtos VALUES ('AUX1', 'Auxiliar 1'), ('AUX2', 'Auxiliar 2');
INSERT INTO sql_semana_16.estrutura VALUES ('AUX1', 'AUX2', 1), ('AUX2', 'AUX1', 1);

SELECT pg_temp.conferir(
    'Ciclo desconectado não afeta o KIT',
    $consulta$SELECT * FROM folhas_validacao$consulta$,
    $esperado$VALUES ('P01'::text, 'Parafuso'::text, 10::numeric), ('P02', 'Arruela', 12)$esperado$
);

ROLLBACK;

SELECT pg_temp.conferir(
    'Raiz inexistente: consolidação vazia',
    $consulta$WITH RECURSIVE explosao (produto, nivel, quantidade_acumulada) AS (
    -- Ponto de partida: uma unidade do kit.
    SELECT codigo, 0, 1::numeric
    FROM sql_semana_16.produtos
    WHERE codigo = 'AUSENTE'

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
ORDER BY x.produto$consulta$,
    $esperado$SELECT NULL::text, NULL::text, NULL::numeric WHERE false$esperado$
);

SELECT pg_temp.conferir(
    'Raiz folha: consolidação vazia abaixo da raiz',
    $consulta$WITH RECURSIVE explosao (produto, nivel, quantidade_acumulada) AS (
    -- Ponto de partida: uma unidade do kit.
    SELECT codigo, 0, 1::numeric
    FROM sql_semana_16.produtos
    WHERE codigo = 'P01'

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
ORDER BY x.produto$consulta$,
    $esperado$SELECT NULL::text, NULL::text, NULL::numeric WHERE false$esperado$
);

DO $fim$ BEGIN RAISE NOTICE 'Validação do episódio 16 concluída com sucesso: 18 verificações.'; END $fim$;
