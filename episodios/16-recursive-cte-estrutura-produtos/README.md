# Episódio 16 — Recursive CTE: explorando uma estrutura de produtos

## Objetivo e limites

Explorar uma estrutura de produtos com `WITH RECURSIVE`, preservar cada caminho com `UNION ALL`, multiplicar quantidades e detectar ciclos com `CYCLE` antes de consolidar somente as folhas.

O laboratório acompanha o artigo [SQL da Semana 16 — Recursive CTE: explorando uma estrutura de produtos](https://dfls.eti.br/posts/sql-da-semana-16-recursive-cte-estrutura-produtos/), datado de **13/11/2026**.

São tabelas próprias e dados sintéticos no schema `sql_semana_16`. O modelo não reproduz o cadastro de estruturas nem regras de produção do Protheus. Não considera filial, vigência, revisão, perdas ou conversão de unidades. A massa permite conferir a semântica; não sustenta conclusões sobre desempenho.

## Contrato da estrutura

- `produtos.codigo` identifica cada produto.
- Cada par `(produto_pai, componente)` aparece uma única vez em `estrutura`.
- `quantidade` é `numeric`, positiva, na unidade de contagem do componente, por unidade do pai.
- Um produto sem componentes cadastrados é uma folha.
- A mesma peça pode aparecer em caminhos distintos; cada contribuição deve ser somada.
- As FKs exigem produtos existentes e o `CHECK` impede autorreferência direta. Ciclos indiretos são aceitos pelas constraints e diagnosticados na consulta.

A raiz `KIT` começa no nível zero, com quantidade `1::numeric`. O caminho gerado por `CYCLE` é um array de registros; no `psql`, por exemplo, `{(KIT),(MOD),(P01)}`. A ordenação final por caminho organiza a apresentação, sem determinar a ordem interna de avaliação.

## Preparação e execução

Use Docker, Docker Compose e o PostgreSQL 16 do `compose.yaml`. Na raiz do repositório:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

| Arquivo | Finalidade |
|---|---|
| `01-tabelas.sql` | Remove e recria somente o schema do episódio e suas duas tabelas |
| `02-dados.sql` | Carrega quatro produtos e quatro relacionamentos |
| `03-consultas.sql` | Expansão, consolidação, ciclo indireto e restauração com `ROLLBACK` |
| `04-exercicio.sql` | Desafio e solução: arruelas diretas e três kits, com `ROLLBACK` |
| `05-validacao.sql` | 18 verificações automatizadas dos caminhos, totais e limites |

Abra o cliente com interrupção no primeiro erro:

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Execute na ordem:

```psql
\i /sql-da-semana/16-recursive-cte-estrutura-produtos/01-tabelas.sql
\i /sql-da-semana/16-recursive-cte-estrutura-produtos/02-dados.sql
\i /sql-da-semana/16-recursive-cte-estrutura-produtos/03-consultas.sql
\i /sql-da-semana/16-recursive-cte-estrutura-produtos/04-exercicio.sql
\i /sql-da-semana/16-recursive-cte-estrutura-produtos/05-validacao.sql
```

Execução não interativa equivalente:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -f /sql-da-semana/16-recursive-cte-estrutura-produtos/01-tabelas.sql \
  -f /sql-da-semana/16-recursive-cte-estrutura-produtos/02-dados.sql \
  -f /sql-da-semana/16-recursive-cte-estrutura-produtos/03-consultas.sql \
  -f /sql-da-semana/16-recursive-cte-estrutura-produtos/04-exercicio.sql \
  -f /sql-da-semana/16-recursive-cte-estrutura-produtos/05-validacao.sql
```

Em outro cliente SQL, abra e execute os arquivos locais na mesma ordem, na mesma conexão e com autocommit habilitado. Os arquivos 03 a 05 controlam suas próprias transações; execute-os sem transação externa, sem `psql --single-transaction` e sem envolver o roteiro inteiro em `BEGIN`.

Para repetir, comece por `01-tabelas.sql`: ele remove com `CASCADE` somente `sql_semana_16`. Recarregar apenas `02-dados.sql` causa conflito de chave. Após os exemplos, o desafio e a validação, permanecem os quatro produtos e os quatro relacionamentos originais. Se interromper um exemplo dentro de uma transação, execute `ROLLBACK` antes de recomeçar.

## Resultados esperados e observados

A expansão da massa-base retorna:

| Produto | Nível | Quantidade acumulada | Ciclo | Caminho |
|---|---:|---:|---|---|
| KIT | 0 | 1 | false | KIT |
| MOD | 1 | 2 | false | KIT → MOD |
| P01 | 2 | 6 | false | KIT → MOD → P01 |
| P02 | 2 | 12 | false | KIT → MOD → P02 |
| P01 | 1 | 4 | false | KIT → P01 |

`P01` aparece por dois ramos válidos: quatro unidades diretas e seis pelos módulos. A consolidação soma dez parafusos e doze arruelas. O módulo não aparece entre as folhas.

| Cenário | Expansão | Folhas consolidadas |
|---|---|---|
| Massa-base, um kit | Cinco linhas, nenhum ciclo | P01 = 10; P02 = 12 |
| Referência `P02 → KIT`, quantidade 1 | Seis linhas; KIT no nível 3, quantidade 12, marcado como ciclo | Zero linhas |
| Após reverter o ciclo | Cinco linhas, nenhum ciclo | P01 = 10; P02 = 12 |
| Desafio: `KIT → P02`, quantidade 3 | Seis linhas, nenhum ciclo | P01 = 10; P02 = 15 |
| Desafio: multiplicador inicial 3 | Mesmos seis caminhos, quantidades triplicadas | P01 = 30; P02 = 45 |

O bloqueio usa `NOT EXISTS` sobre todas as linhas cíclicas da expansão. Apenas excluir as linhas marcadas permitiria apresentar totais parciais. `CYCLE` interrompe o ramo circular nessa consulta, mas não impede sua gravação na tabela.

Uma consolidação vazia exige diagnóstico: também ocorre para uma raiz inexistente ou uma raiz sem componentes, pois a consulta considera apenas folhas abaixo do nível zero. A validação cobre ambos e confirma que um ciclo desconectado do `KIT` não afeta seus totais. A navegação não valida o restante do cadastro.

Uma estrutura acíclica pode produzir muitos caminhos. Cortar a profundidade altera os totais e exigiria sinalizar truncamento; o laboratório não aplica esse corte.

## Validação realizada

Roteiro completo executado em **08/11/2026** e revalidado em **13/11/2026**, com a imagem `postgres:16` do Compose:

```text
PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

A execução com `ON_ERROR_STOP=1` terminou com código **0** e a mensagem:

```text
NOTICE:  Validação do episódio 16 concluída com sucesso: 18 verificações.
```

As comparações usam diferenças nas duas direções com `EXCEPT ALL`, verificando cardinalidade, duplicatas, níveis, quantidades, marcas de ciclo e caminhos completos. Função e views auxiliares são temporárias, restritas à sessão. Os cenários de ciclo, desafio e ciclo desconectado são revertidos individualmente.

Os resultados apresentados no artigo foram reproduzidos no ambiente testado. O artigo registra a validação e inclui o link para este laboratório.

## Referências

- [PostgreSQL 16 — Consultas recursivas](https://www.postgresql.org/docs/16/queries-with.html#QUERIES-WITH-RECURSIVE)
- [PostgreSQL 16 — Ordenação da busca](https://www.postgresql.org/docs/16/queries-with.html#QUERIES-WITH-SEARCH)
- [PostgreSQL 16 — Detecção de ciclos](https://www.postgresql.org/docs/16/queries-with.html#QUERIES-WITH-CYCLE)
