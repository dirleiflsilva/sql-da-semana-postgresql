# SQL da Semana — laboratórios PostgreSQL

Este repositório é o complemento prático da série [SQL da Semana](https://dfls.eti.br/). O objetivo é oferecer um PostgreSQL local e exemplos pequenos para que você execute cada comando manualmente, observe os resultados e experimente variações.

O Compose cria somente o PostgreSQL. Nenhum arquivo SQL é executado durante a inicialização: a prática de entrar no banco e carregar cada etapa faz parte do laboratório.

## Pré-requisitos

- Docker;
- Docker Compose.

Se precisar preparar o PostgreSQL antes de começar, consulte:

- [PostgreSQL com Docker](https://dfls.eti.br/posts/postgresql-reliability-lab-lab-01-ambiente-confiavel-com-docker/);
- [Instalação do PostgreSQL no Windows](https://dfls.eti.br/posts/configurando-postgresql-windows-protheus-desenvolvimento/).

## Episódios disponíveis

| Episódio | Assunto | Diretório | Artigo |
|---:|---|---|---|
| 01 | `RETURNING` | `episodios/01-returning` | [SQL da Semana 01](https://dfls.eti.br/posts/sql-da-semana-01-returning-postgresql/) |
| 02 | `FILTER` | `episodios/02-filter` | [SQL da Semana 02](https://dfls.eti.br/posts/sql-da-semana-02-filter-postgresql/) |
| 03 | `DISTINCT ON` | `episodios/03-distinct-on` | [SQL da Semana 03](https://dfls.eti.br/posts/sql-da-semana-03-distinct-on-postgresql/) |
| 04 | UPSERT | `episodios/04-upsert` | [SQL da Semana 04](https://dfls.eti.br/posts/sql-da-semana-04-upsert-postgresql/) |
| 05 | CTE com `WITH` | `episodios/05-cte` | [SQL da Semana 05](https://dfls.eti.br/posts/sql-da-semana-05-cte-postgresql/) |

## Preparar o ambiente

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Os valores do `.env.example` destinam-se somente a estudos locais. Entre no `psql` com:

```bash
docker compose exec postgres \
  psql -U postgres -d sql_da_semana
```

Dentro do `psql`, execute os três arquivos do episódio desejado **na ordem numérica**. Por exemplo:

```psql
\i /sql-da-semana/05-cte/01-tabelas.sql
\i /sql-da-semana/05-cte/02-dados.sql
\i /sql-da-semana/05-cte/03-consultas.sql
```

Use `\q` para sair do `psql`.

Também é possível usar pgAdmin, DBeaver ou outro cliente SQL. Conecte-se a `localhost`, na porta definida por `POSTGRES_PORT` no `.env`, usando o banco, usuário e senha definidos no mesmo arquivo. Nesse caso, abra e execute os arquivos locais na ordem numérica.

## Encerrar ou recomeçar

Para parar o ambiente preservando os dados:

```bash
docker compose down
```

Para apagar os dados e recomeçar do zero:

```bash
docker compose down -v
```

> **Atenção:** `docker compose down -v` remove o volume nomeado e todos os dados dos laboratórios. Essa operação não pode ser desfeita pelo Docker Compose.

Cada episódio também pode ser reiniciado sem apagar o volume: execute novamente seus três arquivos, começando por `01-tabelas.sql`.

## Licença

Os exemplos de código são disponibilizados sob a [licença MIT](LICENSE).
