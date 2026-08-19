# Episódio 02 — FILTER

## Objetivo

Calcular agregações condicionais com `FILTER` e compará-las com a forma equivalente baseada em `CASE`.

## Conceito demonstrado

`FILTER (WHERE condição)` restringe as linhas entregues a uma função de agregação. Os oito pedidos pertencem a Ana, Bruno e Carla e usam três estados, com valores que tornam visíveis as diferenças entre as métricas.

## Ordem de execução

```psql
\i /sql-da-semana/02-filter/01-tabelas.sql
\i /sql-da-semana/02-filter/02-dados.sql
\i /sql-da-semana/02-filter/03-consultas.sql
```

## Resultado esperado

A primeira consulta retorna 8 pedidos: 4 concluídos, 2 pendentes e 2 cancelados. O valor total é 760,00, dividido em 570,00 concluídos, 130,00 pendentes e 60,00 cancelados.

Por cliente, em ordem alfabética:

| Cliente | Total | Concluídos | Valor concluído |
|---|---:|---:|---:|
| Ana | 3 | 1 | 100,00 |
| Bruno | 3 | 2 | 350,00 |
| Carla | 2 | 1 | 120,00 |

A comparação final retorna 4 nas duas colunas, confirmando a equivalência do `CASE` e do `FILTER` nesse cálculo.

Leia o [artigo do episódio 02](https://dfls.eti.br/posts/sql-da-semana-02-filter-postgresql/).

Para recomeçar, execute novamente os três arquivos, desde `01-tabelas.sql`.
