# Episódio 04 — UPSERT

## Objetivo

Inserir ou tratar conflitos de unicidade com `ON CONFLICT`, usando `DO NOTHING`, `DO UPDATE`, `EXCLUDED` e `RETURNING`.

## Conceito demonstrado

Cada pipeline pode ter apenas um estado por data, garantido pela restrição única composta `(pipeline, data_referencia)`. A tabela começa com `carga-clientes` em 15/01/2026.

## Ordem de execução

```psql
\i /sql-da-semana/04-upsert/01-tabelas.sql
\i /sql-da-semana/04-upsert/02-dados.sql
\i /sql-da-semana/04-upsert/03-consultas.sql
```

## Resultado esperado

- `backup` não conflita e retorna a ação `inserido`;
- o primeiro conflito de `carga-clientes` usa `DO NOTHING`, não devolve linha e mostra `INSERT 0 0` no `psql`;
- o segundo conflito usa os valores de `EXCLUDED`, retorna `atualizado`, muda o status para `falha` e soma 2 ao contador existente, resultando em 3;
- `relatorio` usa a forma `DO UPDATE`, mas é inserido porque não havia conflito.

O estado final, ordenado por pipeline, é:

| Pipeline | Data | Status | Execuções |
|---|---|---|---:|
| backup | 2026-01-15 | pendente | 0 |
| carga-clientes | 2026-01-15 | falha | 3 |
| relatorio | 2026-01-15 | sucesso | 1 |

Leia o [artigo do episódio 04](https://dfls.eti.br/posts/sql-da-semana-04-upsert-postgresql/).

Para recomeçar, execute novamente os três arquivos, desde `01-tabelas.sql`.
