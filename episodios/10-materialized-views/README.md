# Episódio 10 — Materialized Views

## Objetivo

Criar uma materialized view com indicadores diários de pedidos, observar a defasagem em relação à tabela de origem e atualizar o resultado armazenado com refresh comum e concorrente.

## Pré-requisitos e execução

- Docker e Docker Compose;
- PostgreSQL 16, fornecido pelo Compose do repositório.

Na raiz do repositório, copie a configuração somente se ainda não tiver um `.env` e inicie o ambiente:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

Entre no banco (ajuste usuário e banco se personalizou o `.env`):

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Dentro do `psql`, execute exatamente nesta ordem:

```psql
\i /sql-da-semana/10-materialized-views/01-tabelas.sql
\i /sql-da-semana/10-materialized-views/02-dados.sql
\i /sql-da-semana/10-materialized-views/03-consultas.sql
```

O `01-tabelas.sql` remove com `CASCADE` e recria exclusivamente o schema `sql_semana_10`. Para uma reinicialização segura deste episódio, execute novamente os três arquivos desde o primeiro. Executar somente a carga ou as consultas outra vez causará conflitos de chave ou de nomes de objetos.

## Cenário e limites

A tabela contém pedidos de uma base própria de integração. Os dados são inteiramente sintéticos e não representam escrita direta em tabelas do Protheus ou de outro ERP. A data do indicador é calculada explicitamente com `(criado_em AT TIME ZONE 'America/Sao_Paulo')::date`, sem depender do timezone da sessão.

Os seis registros iniciais — e o sétimo inserido durante a demonstração — servem para validar comportamento funcional. Não existe comparação de performance confiável com sete pedidos; qualquer avaliação de desempenho exige volume, distribuição e medições representativos.

## Resultados esperados

### 1 e 2. Origem e retrato inicial

A consulta direta e a materialized view recém-criada retornam os mesmos cinco grupos:

| dia | situacao | quantidade | valor_total | ticket_medio |
|---|---|---:|---:|---:|
| 2026-09-28 | aprovado | 2 | 200.00 | 100.00 |
| 2026-09-28 | cancelado | 1 | 50.00 | 50.00 |
| 2026-09-29 | aprovado | 1 | 200.00 | 200.00 |
| 2026-09-29 | pendente | 1 | 90.00 | 90.00 |
| 2026-09-30 | aprovado | 1 | 160.00 | 160.00 |

Uma materialized view persiste o resultado de sua consulta em forma semelhante a uma tabela. Diferentemente de uma view comum, consultar esse objeto lê o conteúdo armazenado; a consulta de definição é reutilizada quando um refresh é solicitado.

### 3 e 4. Mudança e defasagem

O script aprova o pedido 5 e inclui o pedido 7. A consulta direta de `2026-09-29` passa a retornar:

| dia | situacao | quantidade | valor_total | ticket_medio |
|---|---|---:|---:|---:|
| 2026-09-29 | aprovado | 3 | 400.00 | 133.33 |

Antes do refresh, a materialized view ainda guarda o retrato anterior: um aprovado de `200.00` e um pendente de `90.00`. Alterações na origem não a atualizam automaticamente. Por isso, o uso é apropriado somente quando alguma defasagem é aceitável.

### 5. Refresh comum

`REFRESH MATERIALIZED VIEW` substitui o conteúdo armazenado pelo resultado atual da consulta de definição. Depois dele, o dia `2026-09-29` contém somente o grupo aprovado, com quantidade `3`, total `400.00` e ticket médio `133.33`.

O refresh comum pode bloquear leitores enquanto troca o conteúdo. Para grandes quantidades de linhas, tende a usar menos recursos e terminar mais rapidamente que o concorrente, mas isso não é uma garantia para todo cenário.

### 6 e 7. Índice único e refresh concorrente

O catálogo `pg_catalog.pg_indexes` mostra `indicadores_pedidos_dia_situacao_uq`, índice `UNIQUE` sobre `(dia, situacao)`. Essas colunas identificam cada grupo produzido pela definição.

`REFRESH MATERIALIZED VIEW CONCURRENTLY` mantém a materialized view disponível para `SELECT` durante a atualização. Ele só é permitido quando o objeto já está populado e possui pelo menos um índice `UNIQUE` que use apenas nomes de colunas, inclua todas as linhas e não seja parcial nem baseado em expressões. Mesmo nesse modo, somente um refresh pode executar por vez no mesmo objeto.

O modo concorrente possui requisitos e custos próprios; não é sempre melhor nem mais rápido. Como experimento opcional, em uma execução separada, tente o modo concorrente antes de criar o índice para observar a rejeição do PostgreSQL. Esse comando inválido não faz parte da sequência validada.

Ambos os tipos de refresh atualizam sob demanda: `REFRESH MATERIALIZED VIEW` não é um agendador e nenhum dos modos implementa uma política operacional de atualização. Em produção, defina frequência segundo a defasagem tolerada, estime o custo da consulta e da substituição, trate falhas e monitore duração, sucesso e idade do último resultado válido.

Mesmo que uma consulta de definição tenha `ORDER BY`, um refresh não garante preservar essa ordem. Consultas consumidoras devem usar seu próprio `ORDER BY`, como fazem os exemplos do laboratório.

## Validação realizada

Scripts executados em **26/09/2026** no **PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1)**, com `psql -X -v ON_ERROR_STOP=1`. Foram usados:

```bash
docker compose up -d
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -f /sql-da-semana/10-materialized-views/01-tabelas.sql \
  -f /sql-da-semana/10-materialized-views/02-dados.sql \
  -f /sql-da-semana/10-materialized-views/03-consultas.sql
```

A sequência completa foi executada duas vezes desde `01-tabelas.sql`. Foram conferidos o resultado inicial, o estado defasado, o grupo atualizado, a existência do índice `UNIQUE`, o sucesso do refresh concorrente. A comparação dos dumps dos schemas anteriores não mostrou alterações, desconsiderando os tokens aleatórios de proteção do `pg_dump`.

## Referências oficiais

- [Materialized Views — PostgreSQL 16](https://www.postgresql.org/docs/16/rules-materializedviews.html)
- [CREATE MATERIALIZED VIEW — PostgreSQL 16](https://www.postgresql.org/docs/16/sql-creatematerializedview.html)
- [REFRESH MATERIALIZED VIEW — PostgreSQL 16](https://www.postgresql.org/docs/16/sql-refreshmaterializedview.html)

## Sair ou parar

Use `\q` para sair do `psql`. Para parar o ambiente preservando os dados:

```bash
docker compose down
```

Para reiniciar somente este episódio, repita os três arquivos. Consulte o [README principal](../../README.md) para as opções de encerramento do ambiente completo.
