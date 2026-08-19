# Episódio 01 — RETURNING

## Objetivo

Observar como `RETURNING` devolve linhas afetadas por `INSERT`, `UPDATE` e `DELETE`, incluindo identificadores gerados e novos valores.

## Conceito demonstrado

No PostgreSQL, `RETURNING` evita uma consulta adicional quando a aplicação precisa conhecer a linha inserida, alterada ou removida. A tabela `jobs` representa tarefas com estado e prioridade.

## Ordem de execução

Dentro do `psql`, execute:

```psql
\i /sql-da-semana/01-returning/01-tabelas.sql
\i /sql-da-semana/01-returning/02-dados.sql
\i /sql-da-semana/01-returning/03-consultas.sql
```

Os dados iniciais têm três tarefas. As consultas inserem a tarefa de id 4, alteram estado e prioridade da tarefa 1, removem a tarefa 3 e exibem o estado final.

## Resultado esperado

- `INSERT ... RETURNING`: id 4, `Gerar relatório semanal`, `pendente`, prioridade 4;
- `UPDATE ... RETURNING`: id 1, `Importar pedidos`, `em_execucao`, prioridade 5;
- `DELETE ... RETURNING`: id 3, `Remover arquivos temporários`, `concluido`, prioridade 1;
- consulta final: ids 1, 2 e 4, nessa ordem.

Leia o [artigo do episódio 01](https://dfls.eti.br/posts/sql-da-semana-01-returning-postgresql/).

Para recomeçar, execute novamente os três arquivos, desde `01-tabelas.sql`.
