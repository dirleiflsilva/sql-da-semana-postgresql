# Episódio 06 — Funções de janela

## Objetivo

Usar funções de janela para calcular rankings, totais acumulados e percentuais sem perder as linhas individuais das vendas.

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

A tabela `vendas` possui dez linhas: cinco do vendedor 101 e cinco do vendedor 202. Cada vendedor vendeu exatamente R$ 1.000,00, o que facilita a conferência dos percentuais. Existem valores repetidos nos dois grupos e as vendas 3 e 4 ocorreram no mesmo instante.

A ordem cronológica também difere da ordem por valor. Por exemplo, a primeira venda do vendedor 101 vale R$ 100,00, mas a segunda vale R$ 300,00.

## Ordem de execução

Dentro do `psql`, execute os arquivos na ordem numérica:

```psql
\i /sql-da-semana/06-window-functions/01-tabelas.sql
\i /sql-da-semana/06-window-functions/02-dados.sql
\i /sql-da-semana/06-window-functions/03-consultas.sql
```

O primeiro arquivo remove e recria somente o schema `sql_semana_06`. Por isso, a sequência completa pode ser executada novamente sem duplicar dados.

## Partição, ordenação e moldura

- `OVER` transforma uma função agregada ou de ranking em função de janela, preservando cada venda no resultado;
- `PARTITION BY vendedor_id` separa as linhas por vendedor e reinicia os cálculos em cada grupo;
- `ORDER BY` dentro de `OVER` define a sequência usada pela função de janela;
- `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` define a moldura do início da partição até a linha atual.

O `ORDER BY` da janela controla o cálculo, mas não garante a apresentação final das linhas. Por isso, todas as consultas que dependem de ordem também possuem um `ORDER BY` externo explícito.

## O que observar

### 1. GROUP BY

`GROUP BY` reduz as dez vendas a duas linhas:

| Vendedor | Quantidade | Total |
|---:|---:|---:|
| 101 | 5 | 1.000,00 |
| 202 | 5 | 1.000,00 |

As vendas individuais deixam de aparecer. Nas consultas seguintes, as funções de janela calculam valores relacionados ao grupo e mantêm as dez linhas.

### 2. row_number()

`row_number()` atribui posições únicas em ordem decrescente de valor e reinicia em 1 para cada vendedor. O `venda_id` no `ORDER BY` da janela resolve os empates de forma determinística.

### 3. row_number(), rank() e dense_rank()

Para o vendedor 101, os valores ordenados são 300, 200, 200, 200 e 100:

| venda_id | valor | row_number | rank | dense_rank |
|---:|---:|---:|---:|---:|
| 2 | 300,00 | 1 | 1 | 1 |
| 3 | 200,00 | 2 | 2 | 2 |
| 4 | 200,00 | 3 | 2 | 2 |
| 5 | 200,00 | 4 | 2 | 2 |
| 1 | 100,00 | 5 | 5 | 3 |

`row_number()` mantém números exclusivos porque também ordena por `venda_id`. `rank()` e `dense_rank()` ordenam apenas por `valor`, preservando o empate. Depois das três linhas empatadas, `rank()` salta para 5 e `dense_rank()` avança para 3.

No vendedor 202, três vendas de R$ 250,00 empatam na posição 1. A venda de R$ 150,00 recebe `rank` 4 e `dense_rank` 2.

### 4. Total acumulado

Em ordem cronológica, os acumulados são:

| Vendedor | venda_id | Sequência do acumulado |
|---:|---:|---:|
| 101 | 1, 2, 3, 4, 5 | 100, 400, 600, 800, 1.000 |
| 202 | 6, 7, 8, 9, 10 | 250, 350, 600, 750, 1.000 |

As vendas 3 e 4 possuem o mesmo `realizada_em`. O desempate por `venda_id`, combinado com a moldura explícita `ROWS`, define qual delas contribui primeiro para o acumulado.

### 5. Percentual sobre o total

Como o total de cada vendedor é R$ 1.000,00, uma venda de R$ 100,00 representa 10%, uma de R$ 150,00 representa 15%, e assim por diante. Os percentuais somam 100% em cada partição.

A restrição `CHECK (valor > 0)` garante valores positivos. Como cada partição possui ao menos uma venda, o total usado como divisor não pode ser zero.

### 6. Consulta combinada

A última consulta preserva a ordem cronológica de apresentação e mostra, para cada venda:

- o `dense_rank()` calculado pela ordem decrescente de valor;
- o acumulado calculado pela ordem cronológica e pelo `venda_id`;
- o percentual calculado sobre todas as vendas do vendedor.

Uma linha pode aparecer cedo no resultado cronológico e possuir ranking inferior por valor. Isso evidencia que cada janela possui sua própria ordenação, independente do `ORDER BY` final.

## Sair, parar ou reiniciar

Use `\q` para sair do `psql`. Para parar o ambiente preservando os dados:

```bash
docker compose down
```

Para reiniciar apenas este cenário, execute novamente os três arquivos desde `01-tabelas.sql`. Para apagar o volume e todos os laboratórios, consulte o aviso no README principal antes de usar `docker compose down -v`.

O artigo do episódio 06 está em preparação.
