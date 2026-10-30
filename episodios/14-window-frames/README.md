# Episódio 14 — Window Frames: saldos e movimentações acumuladas

## Objetivo

Este laboratório mostra como `ROWS`, `RANGE` e `GROUPS` alteram as linhas vistas por uma função de janela. O cenário usa duas contas fictícias, créditos, débitos e eventos com o mesmo timestamp para comparar saldo evento a evento, grupos de pares e intervalos temporais. Todos os objetos ficam em `sql_semana_14` e não dependem de outros episódios.

## Pré-requisitos

- Docker e Docker Compose;
- PostgreSQL 16, fornecido pelo Compose do repositório.

Na raiz do repositório, copie a configuração se necessário e inicie o banco:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

Abra o `psql` com interrupção no primeiro erro:

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

## Estrutura e ordem de execução

| Arquivo | Finalidade |
|---|---|
| `01-tabelas.sql` | Recria o schema, a tabela e o índice composto |
| `02-dados.sql` | Carrega as oito movimentações da massa-base |
| `03-consultas.sql` | Executa os exemplos de molduras e o plano opcional |
| `04-validacao.sql` | Valida os resultados da massa-base |
| `05-exercicio.sql` | Adiciona três eventos e resolve o exercício |
| `06-validacao-exercicio.sql` | Valida o exercício e a comparação `ROWS`/`RANGE` |

Execute na ordem. A validação-base deve ocorrer antes do exercício, pois os dados extras mudam os saldos finais:

```psql
\i /sql-da-semana/14-window-frames/01-tabelas.sql
\i /sql-da-semana/14-window-frames/02-dados.sql
\i /sql-da-semana/14-window-frames/03-consultas.sql
\i /sql-da-semana/14-window-frames/04-validacao.sql
\i /sql-da-semana/14-window-frames/05-exercicio.sql
\i /sql-da-semana/14-window-frames/06-validacao-exercicio.sql
```

Execução não interativa:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -f /sql-da-semana/14-window-frames/01-tabelas.sql \
  -f /sql-da-semana/14-window-frames/02-dados.sql \
  -f /sql-da-semana/14-window-frames/03-consultas.sql \
  -f /sql-da-semana/14-window-frames/04-validacao.sql \
  -f /sql-da-semana/14-window-frames/05-exercicio.sql \
  -f /sql-da-semana/14-window-frames/06-validacao-exercicio.sql
```

## Conceitos e exemplos

`PARTITION BY conta_id` reinicia o cálculo em cada conta. Para saldos evento a evento, `ORDER BY ocorrido_em, movimento_id` cria uma ordem total e `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` inclui cada posição até a atual. O identificador serve como desempate nesta massa; em produção, a coluna escolhida precisa representar a sequência de negócio.

Quando a moldura é omitida e há `ORDER BY`, a moldura padrão inclui os pares da linha atual. Ordenados somente por `ocorrido_em`, os movimentos 3 e 4, ambos às 10:00, recebem juntos o saldo `1060.00`. A versão explícita com `ROWS` produz primeiro `1070.00` e depois `1060.00`.

- `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` soma posições individuais e calcula o líquido dos três eventos mais recentes;
- `RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW` inclui os eventos no domínio temporal, inclusive todos os pares no instante atual;
- `GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW` inclui o grupo de pares atual e o grupo anterior;
- `ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING` calcula o saldo anterior e retorna `NULL` na primeira linha;
- a cláusula `WINDOW` nomeia molduras diferentes usadas pela mesma consulta.

Um deslocamento `RANGE` temporal permite apenas uma expressão de ordenação compatível; por isso sua janela ordena somente por `ocorrido_em`, sem acrescentar `movimento_id`.

## Resultados esperados da massa-base

Saldos da conta 101: `1000.00`, `820.00`, `1070.00`, `1060.00` e `1000.00`. O saldo final da conta 202 é `420.00`.

Para os dois movimentos das 10:00 da conta 101:

- a moldura padrão retorna `1060.00` nas duas linhas;
- `GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW` retorna `60.00` nas duas linhas;
- `ROWS` preserva a evolução individual dos eventos.

Na quinta movimentação da conta 101, as três posições mais recentes (`250`, `-10`, `-60`) somam `180.00`. O script de validação também verifica isolamento por conta, saldo anterior vazio e o filtro aplicado somente depois do cálculo histórico.

## Filtros e histórico

Funções de janela são calculadas depois do `WHERE`. Filtrar a partir das 10:00 na mesma consulta elimina os eventos anteriores antes do acumulado. O roteiro contrapõe esse resultado a uma CTE: nela o saldo é calculado com todo o histórico da conta e o filtro externo limita apenas as linhas apresentadas.

## Exercício resolvido

O exercício adiciona os movimentos de 31/10 e 01/11 descritos no artigo. Um terceiro evento fictício, de `25.00`, ocorre também em 01/11 às 10:00 para tornar visível a diferença entre as molduras.

Para o último evento, `ROWS BETWEEN 1 PRECEDING AND CURRENT ROW` contém duas linhas e soma `-15.00`. Já o intervalo `RANGE` de 24 horas contém três linhas — inclusive o evento exatamente 24 horas antes e os dois pares atuais — e soma `85.00`. O saldo final fica em `1085.00` e o imediatamente anterior em `1060.00`.

## Desempenho e limites

O índice `(conta_id, ocorrido_em, movimento_id)` acompanha filtros por conta e a ordem dos acumulados. `03-consultas.sql` inclui `EXPLAIN (ANALYZE, BUFFERS)` para inspeção, mas oito linhas não sustentam alegações de ganho de desempenho: o plano pode preferir leitura sequencial e ordenação. Avalie com volume representativo. Históricos extensos podem exigir posições de fechamento, com regras explícitas para eventos atrasados e correções.

## Reinicialização

Reexecute a sequência desde `01-tabelas.sql`. Esse arquivo remove com `CASCADE` e recria apenas `sql_semana_14`. Não execute `02-dados.sql` ou `05-exercicio.sql` duas vezes sem reinicializar, pois isso duplicaria movimentos.

Leia o artigo [SQL da Semana #14 — Window Frames: saldos e movimentações acumuladas](https://dfls.eti.br/posts/sql-da-semana-14-window-frames-saldos-movimentacoes-acumuladas/).
