-- Execute depois de 01-tabelas.sql e 02-dados.sql.

-- 1. Entrada original: nove linhas, inclusive vazios, espaços e SQL NULL.
SELECT movimento_id, data_emissao, valor
FROM sql_semana_13.faturamento_importado
ORDER BY movimento_id;

-- 2. Normalização segura. Apenas AAAAMMDD vira candidato; linhas rejeitadas
-- permanecem no resultado para diagnóstico. O cast ocorre após a validação.
WITH texto_normalizado AS (
    SELECT
        movimento_id,
        data_emissao,
        valor,
        NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado
), candidato AS (
    SELECT
        *,
        CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' ||
            substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2)
        END AS data_iso
    FROM texto_normalizado
), validado AS (
    SELECT
        *,
        CASE
            WHEN data_iso IS NOT NULL
             AND pg_input_is_valid(data_iso, 'date')
            THEN data_iso::date
        END AS data_valida
    FROM candidato
)
SELECT movimento_id, data_emissao, valor, texto_limpo, data_iso, data_valida
FROM validado
ORDER BY movimento_id;

-- 3. Classificação: ausência, contrato inválido, calendário inválido ou válida.
WITH texto_normalizado AS (
    SELECT
        f.*,
        NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado AS f
), candidato AS (
    SELECT
        *,
        CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' ||
            substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2)
        END AS data_iso
    FROM texto_normalizado
), classificado AS (
    SELECT
        *,
        CASE
            WHEN texto_limpo IS NULL THEN 'ausente'
            WHEN data_iso IS NULL THEN 'formato_invalido'
            WHEN NOT pg_input_is_valid(data_iso, 'date') THEN 'data_invalida'
            ELSE 'valida'
        END AS situacao
    FROM candidato
)
SELECT movimento_id, data_emissao, valor, data_iso, situacao
FROM classificado
ORDER BY movimento_id;

-- Contagens esperadas: ausente 3, data_invalida 1,
-- formato_invalido 1 e valida 4.
WITH texto_normalizado AS (
    SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado AS f
), candidato AS (
    SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
        substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
        substr(texto_limpo, 7, 2) END AS data_iso
    FROM texto_normalizado
), classificado AS (
    SELECT *, CASE
        WHEN texto_limpo IS NULL THEN 'ausente'
        WHEN data_iso IS NULL THEN 'formato_invalido'
        WHEN NOT pg_input_is_valid(data_iso, 'date') THEN 'data_invalida'
        ELSE 'valida' END AS situacao
    FROM candidato
)
SELECT situacao, count(*) AS quantidade
FROM classificado
GROUP BY situacao
ORDER BY situacao;

-- 4. Agregação exclusiva dos quatro movimentos com data válida.
WITH normalizado AS (
    SELECT
        f.*,
        NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado AS f
), candidato AS (
    SELECT
        *,
        CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
            substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
            substr(texto_limpo, 7, 2) END AS data_iso
    FROM normalizado
), valido AS (
    SELECT *, data_iso::date AS dia
    FROM candidato
    WHERE data_iso IS NOT NULL
      AND pg_input_is_valid(data_iso, 'date')
)
SELECT dia, count(*) AS movimentos, sum(valor) AS total
FROM valido
GROUP BY dia
ORDER BY dia;

-- 5. Calendário à esquerda: preserva os sete dias, mesmo sem movimento válido.
-- O zero de 2026-10-05 significa "nenhum movimento válido associado ao dia".
-- Não significa ausência de problemas: há R$ 70,00 rejeitados por formato.
WITH normalizado AS (
    SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado AS f
), candidato AS (
    SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
        substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
        substr(texto_limpo, 7, 2) END AS data_iso
    FROM normalizado
), valido AS (
    SELECT *, data_iso::date AS dia
    FROM candidato
    WHERE data_iso IS NOT NULL
      AND pg_input_is_valid(data_iso, 'date')
), faturamento_diario AS (
    SELECT dia, count(*) AS movimentos, sum(valor) AS total
    FROM valido
    GROUP BY dia
), calendario AS (
    SELECT dia::date
    FROM generate_series(
        date '2026-10-01', date '2026-10-07', interval '1 day'
    ) AS serie(dia)
)
SELECT
    calendario.dia,
    coalesce(faturamento_diario.movimentos, 0) AS movimentos,
    coalesce(faturamento_diario.total, 0.00)::numeric(12, 2) AS total
FROM calendario
LEFT JOIN faturamento_diario USING (dia)
ORDER BY calendario.dia;

-- 6. Conciliação: recebido = válido + rejeitado, em linhas e em valor.
WITH normalizado AS (
    SELECT f.*, NULLIF(btrim(data_emissao), '') AS texto_limpo
    FROM sql_semana_13.faturamento_importado AS f
), candidato AS (
    SELECT *, CASE WHEN texto_limpo ~ '^[0-9]{8}$' THEN
        substr(texto_limpo, 1, 4) || '-' || substr(texto_limpo, 5, 2) || '-' ||
        substr(texto_limpo, 7, 2) END AS data_iso
    FROM normalizado
), classificado AS (
    SELECT *, data_iso IS NOT NULL
              AND pg_input_is_valid(data_iso, 'date') AS data_utilizavel
    FROM candidato
)
SELECT
    count(*) AS linhas_recebidas,
    sum(valor) AS valor_recebido,
    count(*) FILTER (WHERE data_utilizavel) AS movimentos_validos,
    sum(valor) FILTER (WHERE data_utilizavel) AS valor_valido,
    count(*) FILTER (WHERE NOT data_utilizavel) AS linhas_sem_data_utilizavel,
    sum(valor) FILTER (WHERE NOT data_utilizavel) AS valor_rejeitado
FROM classificado;
