# Episódio 03 — DISTINCT ON

## Objetivo

Selecionar a execução mais recente de cada pipeline e resolver empates de modo determinístico.

## Conceito demonstrado

`DISTINCT ON (pipeline)` mantém a primeira linha de cada grupo conforme o `ORDER BY`. Por isso, a ordenação começa por `pipeline`, segue pelo horário decrescente e usa o id decrescente como desempate. Os dados contêm várias execuções e empates de horário em `carga-clientes` e `relatorio`.

## Ordem de execução

```psql
\i /sql-da-semana/03-distinct-on/01-tabelas.sql
\i /sql-da-semana/03-distinct-on/02-dados.sql
\i /sql-da-semana/03-distinct-on/03-consultas.sql
```

## Resultado esperado

As duas consultas retornam as mesmas linhas, ordenadas por pipeline:

| Pipeline | id | Status |
|---|---:|---|
| backup | 5 | sucesso |
| carga-clientes | 3 | sucesso |
| relatorio | 7 | sucesso |

Nos empates, vence o maior id. A segunda consulta mostra a alternativa com `row_number()`.

Leia o [artigo do episódio 03](https://dfls.eti.br/posts/sql-da-semana-03-distinct-on-postgresql/).

Para recomeçar, execute novamente os três arquivos, desde `01-tabelas.sql`.
