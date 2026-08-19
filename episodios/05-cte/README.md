# Episódio 05 — CTE com WITH

## Objetivo

Organizar uma análise em etapas com CTEs e explorar materialização, modificação de dados e recursão.

## Conceito demonstrado

Uma CTE (`WITH`) dá nome ao resultado de uma subconsulta para uso pela instrução principal. O laboratório contém 15 execuções finalizadas recentes — cinco para cada pipeline —, uma execução antiga e uma não finalizada. As durações são intencionalmente diferentes. Há também uma tabela de arquivo e uma pequena hierarquia de categorias.

## Ordem de execução

```psql
\i /sql-da-semana/05-cte/01-tabelas.sql
\i /sql-da-semana/05-cte/02-dados.sql
\i /sql-da-semana/05-cte/03-consultas.sql
```

## Resultado esperado

A consulta principal calcula a média geral diretamente sobre as 15 execuções recentes: **640 segundos**. Ela retorna apenas:

| Pipeline | Execuções | Média (s) | Falhas | Média geral (s) |
|---|---:|---:|---:|---:|
| carga-vendas | 5 | 720,00 | 20,00% | 640,00 |
| relatorio | 5 | 1020,00 | 20,00% | 640,00 |

`backup` tem média de 180 segundos e fica abaixo da média geral. A execução de 40 dias e a execução sem término não entram nos cálculos.

O exemplo `MATERIALIZED` retorna cinco execuções para cada pipeline e, respectivamente, 2, 1 e 1 falhas para `backup`, `carga-vendas` e `relatorio`. O exemplo `NOT MATERIALIZED` retorna 3, 4 e 4 sucessos.

A CTE modificadora muda as execuções 7 e 9 de `backup` para `reprocessar` e insere essas duas linhas em `execucoes_arquivadas`. A CTE recursiva retorna os cinco caminhos da hierarquia, começando por `Tecnologia`.

Leia o [artigo do episódio 05](https://dfls.eti.br/posts/sql-da-semana-05-cte-postgresql/).

Para recomeçar, execute novamente os três arquivos, desde `01-tabelas.sql`.
