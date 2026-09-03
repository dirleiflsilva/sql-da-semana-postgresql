# Episódio 07 — LATERAL

## Objetivo

Usar `LATERAL` para executar uma subconsulta dependente de cada linha externa e obter os produtos mais vendidos de cada categoria.

## Pré-requisitos

- Docker;
- Docker Compose.

Na raiz do repositório, prepare e inicie o PostgreSQL caso ele ainda não esteja em execução:

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Entre no `psql`:

```bash
docker compose exec postgres \
  psql -U postgres -d sql_da_semana
```

## Cenário e dados

O laboratório possui quatro categorias e onze produtos. `Banco de dados` e `DevOps` têm mais de três produtos, `Backend` tem apenas dois e `Sem produtos` não tem nenhum. Em `Banco de dados`, dois produtos possuem 850 vendas para tornar visível o desempate por `product_id`.

## Ordem de execução

Dentro do `psql`, execute os arquivos na ordem numérica:

```psql
\i /sql-da-semana/07-lateral/01-tabelas.sql
\i /sql-da-semana/07-lateral/02-dados.sql
\i /sql-da-semana/07-lateral/03-consultas.sql
```

O primeiro arquivo remove e recria somente o schema `sql_semana_07`. Por isso, a sequência completa pode ser executada novamente sem duplicar dados nem índices.

## O que observar

### 1. Três produtos com `CROSS JOIN LATERAL`

A subconsulta usa o `category_id` da categoria corrente, ordena os produtos e devolve até três linhas. O resultado contém oito linhas: três de `Banco de dados`, três de `DevOps` e duas de `Backend`. `Sem produtos` não aparece.

O segundo critério da ordenação, `product_id`, torna determinística a posição dos dois produtos empatados com 850 vendas.

### 2. Categoria vazia com `LEFT JOIN LATERAL`

O `LEFT JOIN` preserva a categoria mesmo quando a subconsulta não retorna linhas. O resultado contém nove linhas; `Sem produtos` aparece uma vez, com as colunas do produto iguais a `NULL`.

### 3. Um produto por categoria

Ao usar `LIMIT 1`, o resultado contém quatro linhas, uma por categoria. As três categorias com produtos exibem seu item mais vendido, enquanto `Sem produtos` continua com valores `NULL`.

### 4. Alternativa com função de janela

`row_number()` classifica os produtos dentro de cada categoria antes de o filtro manter as três primeiras posições. A consulta retorna as mesmas oito linhas da primeira demonstração.

### 5. Expansão de JSON

`jsonb_each_text()` recebe o `payload` de cada evento e produz duas linhas com pares de chave e valor. Os dois eventos geram quatro linhas no total.

### 6. Índice e plano de execução

O índice `(category_id, sales_count DESC, product_id)` é compatível com o filtro e a ordenação da subconsulta lateral. O `EXPLAIN (ANALYZE, BUFFERS)` executa a consulta e mostra o plano escolhido.

Com somente onze produtos, é normal o PostgreSQL preferir uma leitura sequencial. Esta massa serve para validar o comportamento funcional, não para comparar desempenho. Avaliações de performance exigem dados em volume e distribuição representativos do cenário real.

## Sair, parar ou reiniciar

Use `\q` para sair do `psql`. Para parar o ambiente preservando os dados:

```bash
docker compose down
```

Para reiniciar apenas este cenário, execute novamente os três arquivos desde `01-tabelas.sql`. Para apagar o volume e todos os laboratórios, consulte o aviso no README principal antes de usar `docker compose down -v`.

Leia o [artigo do episódio 07](https://dfls.eti.br/posts/sql-da-semana-07-lateral-postgresql/).
