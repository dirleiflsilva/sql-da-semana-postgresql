# Episódio 09 — JSONB

## Objetivo

Consultar eventos e metadados de documentos fiscais com `jsonb`: extração de campos, contenção, presença de chaves, valores nulos e expansão de arrays com `LATERAL`.

## Pré-requisitos e execução

- Docker e Docker Compose;
- PostgreSQL 16, fornecido pelo Compose do repositório.

Na raiz do repositório, copie a configuração somente se ainda não tiver um `.env`:

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

Dentro do `psql`, execute na ordem:

```psql
\pset null 'SQL NULL'
\i /sql-da-semana/09-jsonb/01-tabelas.sql
\i /sql-da-semana/09-jsonb/02-dados.sql
\i /sql-da-semana/09-jsonb/03-consultas.sql
```

Também é possível abrir os três arquivos em um cliente como DBeaver ou pgAdmin e executá-los na mesma ordem. Os comandos iniciados por `\` são exclusivos do `psql`.

**Reinicialização:** `01-tabelas.sql` remove o schema `sql_semana_09` com `CASCADE`, incluindo seus dados e objetos, e o recria. Reserve esse schema ao episódio, sem dependências externas. Para repetir o laboratório, execute a sequência completa; executar somente a carga novamente causa conflito de chave primária, e repetir somente as consultas causa conflito no nome do índice já criado.

## Cenário

São exatamente cinco documentos sintéticos. Os identificadores não são chaves fiscais válidas e o JSON não representa um leiaute oficial. A tabela pertence à base de estudos, sem acesso a tabelas do Protheus. XML original e regras fiscais ficam fora do exercício.

| Documento | Origem | Situação | Protocolo | Eventos |
|---|---|---|---|---|
| 1 | api | autorizado | PROTO-001 | Uma autorização |
| 2 | arquivo | cancelado | PROTO-002 | Autorização e cancelamento |
| 3 | api | pendente | Chave ausente | Array vazio |
| 4 | api | autorizado | JSON `null` | JSON `null` |
| 5 | arquivo | pendente | Chave ausente | Chave ausente |

`documento_id` e `referencia` ficam em colunas relacionais, com chave primária e unicidade. `metadados` exige um objeto JSONB não nulo na raiz; o `CHECK` não valida os campos internos.

## Resultados esperados

### 1. Extração de campos e caminhos

A primeira consulta retorna cinco linhas. `->` preserva JSONB; `->>` e `#>>` extraem texto. As UFs são `SP`, `RJ`, `MG`, `SP` e SQL `NULL`, na ordem dos IDs. O documento 5 também não possui `emitente`.

### 2 e 3. Filtros por conteúdo

O filtro com `@>` por origem `api` e situação `autorizado` retorna os IDs **1 e 4**. A contenção do evento de cancelamento retorna somente **2**, independentemente de sua posição no array. A presença de um evento não determina, por si só, a situação atual do documento.

### 4. Presença e nulidade do protocolo

| documento_id | possui_chave | valor_json_null | texto_sql_null |
|---|---|---|---|
| 1 | true | false | false |
| 2 | true | false | false |
| 3 | false | SQL NULL | true |
| 4 | true | true | true |
| 5 | false | SQL NULL | true |

O `psql` mostra booleanos como `t` e `f`. O operador `?` verifica a existência da chave no nível consultado. Chave ausente e JSON `null` tornam-se SQL `NULL` na extração com `->>`; esse teste sozinho não informa se o campo foi enviado.

### 5 e 6. Eventos em linhas

O `CROSS JOIN LATERAL` retorna:

| documento_id | posicao | tipo | sequencia |
|---|---|---|---|
| 1 | 1 | autorizacao | 1 |
| 2 | 1 | autorizacao | 1 |
| 2 | 2 | cancelamento | 2 |

O `LEFT JOIN LATERAL ... ON true` retorna essas mesmas linhas e mais uma para cada documento **3, 4 e 5**, com posição, tipo e sequência em SQL `NULL`: **seis linhas** no total.

O `CASE` fornece um array vazio quando `eventos` está ausente, contém JSON `null` ou tem outro tipo. Tipos inesperados podem exigir rejeição ou registro de erro em uma integração real. A conversão de `sequencia` para inteiro pressupõe os valores da massa; dados externos precisam de validação. `WITH ORDINALITY` conta a partir de 1 e indica a posição no array, não uma cronologia fiscal.

### 7. Índice e plano

O script cria um índice GIN, atualiza as estatísticas com `ANALYZE` e executa `EXPLAIN (ANALYZE, BUFFERS)` no filtro de cancelamento. Observe o plano e a linha retornada, sem exigir um tipo específico de acesso.

A classe padrão do GIN para JSONB suporta `@>` e `?`. Um filtro como `metadados ->> 'origem' = 'api'` não utiliza automaticamente esse mesmo caminho de acesso. Com cinco documentos, uma leitura sequencial é plausível: esta carga valida comportamento funcional. Uma investigação de desempenho exige volume e distribuição documentados, com planos antes e depois do índice.

## Validação realizada

Scripts executados em 12/09/2026 no **PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1)**, com `ON_ERROR_STOP=1`. A sequência completa foi repetida, reproduzindo os cinco documentos, os filtros, a tabela de nulidade e as três/seis linhas das junções. O plano observado foi `Seq Scan`, com um documento retornado. A comparação dos dumps dos schemas dos episódios 01 a 07 antes e depois de uma nova reinicialização não apresentou diferenças (desconsiderando os tokens aleatórios de proteção do dump).

## Sair ou parar

Use `\q` para sair do `psql`. Para parar o ambiente preservando os dados:

```bash
docker compose down
```

Para reiniciar somente este episódio, repita os três arquivos. Consulte o [README principal](../../README.md) para as opções de encerramento do ambiente completo.

Leia o artigo [SQL da Semana #09 — JSONB: consultando eventos e metadados de documentos fiscais](https://dfls.eti.br/posts/sql-da-semana-09-jsonb-postgresql/), publicado em 25/09/2026.
