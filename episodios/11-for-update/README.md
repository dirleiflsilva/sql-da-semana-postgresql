# Episódio 11 — FOR UPDATE e controle de concorrência

## Objetivo

Demonstrar como duas transações concorrentes podem tomar decisões com base no mesmo saldo e como proteger a operação com `SELECT ... FOR UPDATE` ou com um `UPDATE` condicional atômico.

## Pré-requisitos e execução

- Docker e Docker Compose;
- PostgreSQL 16, fornecido pelo Compose do repositório;
- dois terminais para os testes concorrentes.

Na raiz do repositório, copie a configuração somente se ainda não tiver um `.env` e inicie o ambiente:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

Abra dois terminais e entre no banco em ambos (ajuste usuário e banco se personalizou o `.env`):

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Eles serão chamados de **Sessão A** e **Sessão B**. Para a preparação inicial, execute em apenas uma delas:

```psql
\i /sql-da-semana/11-for-update/01-tabelas.sql
\i /sql-da-semana/11-for-update/02-dados.sql
```

O arquivo `01-tabelas.sql` remove com `CASCADE` e recria exclusivamente o schema `sql_semana_11`. Execute esses dois arquivos novamente sempre que uma seção pedir a restauração do estado inicial. Isso apaga somente os objetos deste episódio.

O arquivo `03-consultas.sql` contém a alternativa atômica e pode ser executado separadamente depois da restauração:

```psql
\i /sql-da-semana/11-for-update/03-consultas.sql
```

## Cenário

`contas_integracao` mantém um saldo disponível em uma base própria de integração. `reservas` registra cada valor efetivamente debitado. Os dados são sintéticos; o laboratório não consulta nem escreve em tabelas de ERP.

O saldo inicial da conta 1 é `100.00`. Dois workers tentam reservar `70.00` cada. Como há saldo para somente uma reserva, o resultado correto é saldo `30.00` e uma única linha em `reservas`.

O nível de isolamento padrão do PostgreSQL é `READ COMMITTED`. Cada comando enxerga um retrato iniciado no começo daquele comando. Um comando que aguarda um lock de linha reavalia a linha atualizada depois que a transação bloqueadora termina.

## 1. Condição de corrida sem bloqueio preventivo

Restaure o estado inicial. Na **Sessão A**, inicie uma transação e leia o saldo:

```sql
BEGIN;

SELECT saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1;
```

Sem encerrar a Sessão A, faça o mesmo na **Sessão B**:

```sql
BEGIN;

SELECT saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1;
```

As duas sessões recebem `100.00` e poderiam decidir reservar `70.00`. Simule uma aplicação que calculou o novo saldo fora do banco. Na **Sessão A**:

```sql
UPDATE sql_semana_11.contas_integracao
SET saldo_disponivel = 30.00,
    atualizado_em = clock_timestamp()
WHERE conta_id = 1;

INSERT INTO sql_semana_11.reservas (conta_id, valor, origem)
VALUES (1, 70.00, 'worker-a');

COMMIT;
```

Na **Sessão B**, execute depois do `COMMIT` da Sessão A:

```sql
UPDATE sql_semana_11.contas_integracao
SET saldo_disponivel = 30.00,
    atualizado_em = clock_timestamp()
WHERE conta_id = 1;

INSERT INTO sql_semana_11.reservas (conta_id, valor, origem)
VALUES (1, 70.00, 'worker-b');

COMMIT;
```

Confira em qualquer sessão:

```sql
SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao;

SELECT reserva_id, conta_id, valor, origem
FROM sql_semana_11.reservas
ORDER BY reserva_id;
```

O saldo mostra `30.00`, mas existem duas reservas de `70.00`: o registro está inconsistente. A restrição que impede saldo negativo não detecta esse erro, pois as duas atualizações gravaram o mesmo valor absoluto. Não use esse padrão em uma aplicação.

## 2. Reserva correta com FOR UPDATE

Restaure o estado inicial antes deste teste. Na **Sessão A**:

```sql
BEGIN;

SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1
FOR UPDATE;
```

A linha fica bloqueada até `COMMIT` ou `ROLLBACK`. Ainda não encerre a transação.

Na **Sessão B**:

```sql
BEGIN;

SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1
FOR UPDATE;
```

O comando fica aguardando. Enquanto ele espera, volte à **Sessão A**, faça o débito e registre a reserva dentro da mesma transação:

```sql
UPDATE sql_semana_11.contas_integracao
SET saldo_disponivel = saldo_disponivel - 70.00,
    atualizado_em = clock_timestamp()
WHERE conta_id = 1;

INSERT INTO sql_semana_11.reservas (conta_id, valor, origem)
VALUES (1, 70.00, 'worker-a');

COMMIT;
```

Após o `COMMIT`, o comando bloqueado na **Sessão B** termina e retorna `30.00`, não o valor antigo. No nível `READ COMMITTED`, a sessão recebe a versão atualizada da linha. Como `30.00` é insuficiente, rejeite a segunda reserva e finalize:

```sql
ROLLBACK;
```

Confira o resultado:

```sql
SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao;

SELECT reserva_id, conta_id, valor, origem
FROM sql_semana_11.reservas
ORDER BY reserva_id;
```

O resultado correto é saldo `30.00` e somente a reserva de `worker-a`.

## 3. Falha imediata com NOWAIT

Restaure o estado inicial. Na **Sessão A**, adquira o lock e mantenha a transação aberta:

```sql
BEGIN;

SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1
FOR UPDATE;
```

Na **Sessão B**:

```sql
BEGIN;

SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id = 1
FOR UPDATE NOWAIT;
```

Em vez de aguardar, o PostgreSQL retorna imediatamente `ERROR: could not obtain lock on row in relation "contas_integracao"`. Como `ON_ERROR_STOP=1` não encerra uma sessão interativa, o prompt passa a indicar uma transação abortada. Limpe-a na Sessão B e libere a Sessão A:

```sql
ROLLBACK;
```

```sql
-- Sessão A
ROLLBACK;
```

`NOWAIT` é útil quando a aplicação sabe tratar indisponibilidade imediata, por exemplo com nova tentativa e espera controlada.

## 4. Alternativa atômica com UPDATE condicional

Quando a regra cabe em uma condição SQL, não é necessário ler o saldo previamente. Restaure o estado inicial e execute `03-consultas.sql`:

```psql
\i /sql-da-semana/11-for-update/03-consultas.sql
```

A CTE modificadora debita somente quando há saldo suficiente. O `INSERT` recebe linhas exclusivamente do `UPDATE ... RETURNING`, portanto a reserva só é registrada quando o débito ocorreu. A primeira execução reserva `70.00` para `worker-a` e deixa saldo `30.00`. A segunda tentativa retorna `INSERT 0 0`, não cria a reserva de `worker-b` e mantém o saldo.

Com chamadas concorrentes, o próprio `UPDATE` obtém o lock da linha. Se precisar aguardar, a condição `saldo_disponivel >= 70.00` é reavaliada sobre a versão atualizada antes de qualquer débito.

## Autocommit e transações curtas

O `psql` usa autocommit por padrão. Um `SELECT ... FOR UPDATE` executado fora de `BEGIN` libera o lock assim que o comando termina e não protege uma atualização posterior. Mantenha leitura protegida, decisão, débito e inserção da reserva na mesma transação.

Transações que mantêm locks devem ser curtas: não espere entrada de usuário, chamadas HTTP ou processamento demorado entre `BEGIN` e `COMMIT`. Defina timeouts e tratamento de erro adequados na aplicação. Depois de qualquer erro dentro de uma transação, execute `ROLLBACK` antes de continuar.

## SKIP LOCKED não reserva saldo

`FOR UPDATE SKIP LOCKED` ignora linhas que outra transação já bloqueou, produzindo uma visão intencionalmente inconsistente. Isso é apropriado para múltiplos consumidores retirarem trabalhos independentes de uma fila, mas não para concluir que uma conta inexistente no resultado está sem saldo ou para reservar valor nela. Em reserva de saldo, aguarde a conta correta, use `NOWAIT` com tratamento explícito ou prefira o `UPDATE` condicional.

## Locks em ordem consistente e deadlocks

Uma operação que transfere ou reserva em mais de uma conta deve adquirir locks sempre na mesma ordem. Caso uma transação bloqueie a conta 1 e depois a 2, enquanto outra bloqueia a 2 e depois a 1, cada uma pode esperar pela outra. O PostgreSQL detecta o deadlock e aborta uma delas, mas a aplicação ainda precisa tratar e repetir a transação inteira.

Exercício opcional: restaure o laboratório e crie uma segunda conta:

```sql
INSERT INTO sql_semana_11.contas_integracao (conta_id, saldo_disponivel)
VALUES (2, 100.00);
```

Nas duas sessões, use transações separadas e adquira os locks com um único comando e a mesma ordenação:

```sql
BEGIN;

SELECT conta_id, saldo_disponivel
FROM sql_semana_11.contas_integracao
WHERE conta_id IN (1, 2)
ORDER BY conta_id
FOR UPDATE;

-- Faça as alterações necessárias e encerre sem demora.
COMMIT;
```

Inicie primeiro na Sessão A e depois na B. A Sessão B aguarda, mas não forma um ciclo: ambas pedem as contas 1 e 2 na ordem crescente. A ordenação deve ser uma convenção de toda a aplicação. Restaure o estado inicial ao terminar.

## Inspeção opcional dos locks

Enquanto a Sessão B aguarda no teste com `FOR UPDATE`, uma terceira sessão pode localizar bloqueadores:

```sql
SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    pg_blocking_pids(pid) AS pids_bloqueadores,
    query
FROM pg_catalog.pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
ORDER BY pid;
```

Para observar os locks desses processos:

```sql
SELECT
    locktype,
    pid,
    mode,
    granted,
    relation::regclass AS relacao,
    transactionid
FROM pg_catalog.pg_locks
WHERE pid IN (
    SELECT pid
    FROM pg_catalog.pg_stat_activity
    WHERE datname = current_database()
)
ORDER BY pid, locktype, mode;
```

Os detalhes podem variar entre execuções. O sinal determinístico é `pg_blocking_pids()` listar o PID da Sessão A para a Sessão B enquanto ela aguarda.

## Resultados esperados

- saldo inicial: `100.00`;
- primeira reserva: `70.00`;
- saldo depois da primeira transação: `30.00`;
- segunda reserva de `70.00`: rejeitada;
- total final: uma linha em `reservas`.

## Validação realizada

Scripts e roteiro concorrente executados em **10/10/2026** no **PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1)**, com `psql -X -v ON_ERROR_STOP=1`.

A sequência completa foi executada duas vezes desde `01-tabelas.sql`. Em duas sessões reais, `pg_stat_activity` mostrou a Sessão B aguardando um lock de `transactionid` e `pg_blocking_pids()` identificou o PID da Sessão A. Depois do `COMMIT`, a Sessão B retornou o saldo atualizado de `30.00`. O teste com `NOWAIT` retornou imediatamente `could not obtain lock on row in relation "contas_integracao"`.

A alternativa atômica criou uma reserva de `70.00`, reduziu o saldo para `30.00` e retornou zero linhas na segunda tentativa, mantendo somente uma reserva. A comparação dos dumps dos schemas dos episódios anteriores não mostrou alterações, desconsiderando os tokens aleatórios de proteção do `pg_dump`.

## Referências oficiais

- [Explicit Locking — PostgreSQL 16](https://www.postgresql.org/docs/16/explicit-locking.html)
- [SELECT — cláusula de bloqueio — PostgreSQL 16](https://www.postgresql.org/docs/16/sql-select.html#SQL-FOR-UPDATE-SHARE)
- [Transaction Isolation — PostgreSQL 16](https://www.postgresql.org/docs/16/transaction-iso.html)
- [UPDATE — PostgreSQL 16](https://www.postgresql.org/docs/16/sql-update.html)
- [WITH Queries — PostgreSQL 16](https://www.postgresql.org/docs/16/queries-with.html)

## Encerrar o ambiente

Use `\q` em cada sessão para sair do `psql`. Para parar o ambiente preservando o volume e os dados:

```bash
docker compose down
```

Para reiniciar somente este episódio, repita `01-tabelas.sql` e `02-dados.sql`. Consulte o [README principal](../../README.md) antes de usar qualquer opção que remova volumes.
