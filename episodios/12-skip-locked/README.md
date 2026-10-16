# Episódio 12 — `SKIP LOCKED` e fila concorrente de XML

## Objetivo e ambiente validado

Este laboratório demonstra como `FOR UPDATE SKIP LOCKED` distribui itens independentes de uma fila entre workers concorrentes. Todos os documentos XML são fictícios e ficam no schema exclusivo `sql_semana_12`, em uma base própria de integração. Nenhuma tabela de ERP é acessada.

O roteiro foi executado em **PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1), 64-bit**, usando a imagem `postgres:16` definida no Compose do repositório.

## Pré-requisitos

- Docker;
- Docker Compose;
- dois terminais para os testes concorrentes.

Na raiz do repositório:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

Abra dois terminais e conecte ambos ao mesmo banco:

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Eles serão chamados de **Sessão A** e **Sessão B**. Prepare o laboratório em apenas uma sessão:

```psql
\i /sql-da-semana/12-skip-locked/01-tabelas.sql
\i /sql-da-semana/12-skip-locked/02-dados.sql
```

O primeiro script apaga e recria somente o schema `sql_semana_12`. O segundo insere quatro documentos XML sintéticos com horários fixos, para que `documento_id = 1` seja sempre o primeiro item. Para repetir os testes sem recriar a tabela:

```psql
\i /sql-da-semana/12-skip-locked/04-restaurar.sql
```

Antes de restaurar, encerre transações abertas nas duas sessões.

## 1. Comparação: `FOR UPDATE` aguarda a primeira linha

Restaure a fila. Na **Sessão A**, execute e mantenha a transação aberta:

```sql
BEGIN;

SELECT documento_id, chave
FROM sql_semana_12.fila_documentos
WHERE status = 'pendente'
ORDER BY criado_em, documento_id
FOR UPDATE
LIMIT 1;
```

Resultado observado na Sessão A: `documento_id = 1`, `chave = NFE-0001`.

Na **Sessão B**, limite a espera para tornar o teste determinístico e execute a mesma seleção:

```sql
BEGIN;
SET LOCAL lock_timeout = '2s';

SELECT documento_id, chave
FROM sql_semana_12.fila_documentos
WHERE status = 'pendente'
ORDER BY criado_em, documento_id
FOR UPDATE
LIMIT 1;
```

Resultado observado após aproximadamente dois segundos:

```text
ERROR:  canceling statement due to lock timeout
CONTEXT:  while locking tuple (0,1) in relation "fila_documentos"
```

Havia outros três itens pendentes, mas a Sessão B tentou bloquear a primeira candidata. Limpe ambas as transações:

```sql
-- Sessão B (a transação está abortada após o erro)
ROLLBACK;
```

```sql
-- Sessão A
ROLLBACK;
```

## 2. Duas reservas concorrentes com `SKIP LOCKED`

Restaure a fila. Na **Sessão A**, escolha e marque o primeiro item, sem confirmar ainda:

```sql
BEGIN;

WITH proximo AS (
    SELECT documento_id
    FROM sql_semana_12.fila_documentos
    WHERE status = 'pendente'
    ORDER BY criado_em, documento_id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE sql_semana_12.fila_documentos AS fila
SET status = 'processando',
    worker_id = 'worker-a',
    tentativas = fila.tentativas + 1,
    iniciado_em = clock_timestamp(),
    concluido_em = NULL,
    ultimo_erro = NULL
FROM proximo
WHERE fila.documento_id = proximo.documento_id
RETURNING fila.documento_id, fila.chave, fila.worker_id, fila.tentativas;
```

Resultado observado: a Sessão A reservou `NFE-0001`, documento 1, para `worker-a`.

Sem encerrar a Sessão A, execute na **Sessão B**:

```sql
BEGIN;
SET LOCAL lock_timeout = '2s';

WITH proximo AS (
    SELECT documento_id
    FROM sql_semana_12.fila_documentos
    WHERE status = 'pendente'
    ORDER BY criado_em, documento_id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE sql_semana_12.fila_documentos AS fila
SET status = 'processando',
    worker_id = 'worker-b',
    tentativas = fila.tentativas + 1,
    iniciado_em = clock_timestamp(),
    concluido_em = NULL,
    ultimo_erro = NULL
FROM proximo
WHERE fila.documento_id = proximo.documento_id
RETURNING fila.documento_id, fila.chave, fila.worker_id, fila.tentativas;
```

Resultado observado: a Sessão B retornou imediatamente `NFE-0002`, documento 2, para `worker-b`; o `lock_timeout` não foi atingido. Confirme sem demora:

```sql
-- Sessão A
COMMIT;
```

```sql
-- Sessão B
COMMIT;
```

Em qualquer sessão:

```sql
SELECT documento_id, chave, status, worker_id, tentativas
FROM sql_semana_12.fila_documentos
ORDER BY documento_id;
```

Resultado observado:

```text
 documento_id |   chave    |   status    | worker_id | tentativas
--------------+------------+-------------+-----------+------------
            1 | NFE-0001   | processando | worker-a  |          1
            2 | NFE-0002   | processando | worker-b  |          1
            3 | NFE-0003   | pendente    |           |          0
            4 | NFE-0004   | pendente    |           |          0
```

O lock de linha existiu apenas até cada `COMMIT`. O estado `processando`, por outro lado, é a reserva persistida e continua visível depois do fim da transação. O processamento do XML deve começar somente após o `COMMIT` e ocorrer fora dessa transação curta.

## 3. Nenhuma linha disponível não significa fila vazia

Restaure a fila. Na **Sessão A**, bloqueie todos os itens pendentes, sem alterá-los:

```sql
BEGIN;

SELECT documento_id
FROM sql_semana_12.fila_documentos
WHERE status = 'pendente'
ORDER BY criado_em, documento_id
FOR UPDATE;
```

Na **Sessão B**:

```sql
SELECT documento_id
FROM sql_semana_12.fila_documentos
WHERE status = 'pendente'
ORDER BY criado_em, documento_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

Resultado observado: zero linhas. Na mesma Sessão B, uma contagem comum retornou quatro itens pendentes:

```sql
SELECT count(*) AS pendentes
FROM sql_semana_12.fila_documentos
WHERE status = 'pendente';
```

`SKIP LOCKED` omitiu linhas temporariamente indisponíveis; portanto, “nenhuma linha retornada” não prova que a fila esteja vazia. Termine a Sessão A com `ROLLBACK`.

## 4. Conclusão, falha e estado final

O arquivo `03-consultas.sql` **não** restaura dados automaticamente. Restaure primeiro e execute-o para observar duas reservas atômicas, uma conclusão e uma falha:

```psql
\i /sql-da-semana/12-skip-locked/04-restaurar.sql
\i /sql-da-semana/12-skip-locked/03-consultas.sql
```

Resultado observado: `NFE-0001` terminou como `concluido`, `NFE-0002` como `falhou`, ambos com uma tentativa, e os documentos 3 e 4 permaneceram pendentes. Cada comando executado em autocommit formou uma transação curta.

As atualizações de conclusão e falha conferem `status` e `worker_id`. Em produção, prefira um token único por tentativa para impedir que uma execução antiga finalize uma reserva reassumida por outro worker.

## Limites e cuidados operacionais

`SKIP LOCKED` coordena somente a disputa imediata por linhas. Ele não implementa retry, lease expirado, idempotência nem entrega exatamente uma vez. Se um worker falhar após confirmar a reserva, a linha poderá permanecer `processando`; a aplicação precisa definir expiração, recuperação, limite de tentativas e fila de falhas. Efeitos externos também precisam ser idempotentes, pois o efeito pode ocorrer antes de uma falha ao registrar a conclusão.

`ORDER BY criado_em, documento_id` prioriza os itens mais antigos **entre os disponíveis**, mas não garante ordem global rígida de reserva ou conclusão. Um item frequentemente bloqueado pode sofrer starvation enquanto itens posteriores avançam. Monitore a idade das reservas e pendências e aplique uma política explícita de recuperação ou prioridade.

Não mantenha a transação aberta durante leitura de arquivo, chamada HTTP, transformação do XML ou qualquer trabalho externo. O fluxo recomendado é: reservar e confirmar; processar fora da transação; registrar sucesso ou falha em outra transação curta.

## Arquivos

- `01-tabelas.sql`: recria o schema, a tabela e o índice parcial da fila;
- `02-dados.sql`: insere quatro XMLs sintéticos;
- `03-consultas.sql`: demonstra reserva atômica, conclusão e falha;
- `04-restaurar.sql`: restaura a massa inicial e reinicia a identidade.
