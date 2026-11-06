# Episódio 15 — Exclusão lógica e filial: consultas sobre um modelo inspirado no Protheus

## Objetivo e limites

Demonstrar como exclusão lógica, chaves compostas por filial e cadastros compartilhados afetam a correção de consultas SQL. O [artigo SQL da Semana 15](https://dfls.eti.br/posts/sql-da-semana-15-exclusao-logica-filial-modelo-protheus/) está previsto para **06/11/2026**, com publicação pendente. O endereço corresponde ao slug do artigo; na conferência de 06/11/2026, retornou HTTP 404 e o artigo local ainda estava marcado como rascunho.

Os dados são exclusivamente sintéticos, em tabelas próprias do schema `sql_semana_15`, com um único contexto de empresa. O laboratório funciona apenas com PostgreSQL: não depende de Protheus, AppServer, DBAccess ou licenças. O modelo é inspirado nesses conceitos; não reproduz o dicionário, os índices físicos nem as regras completas do ERP. Não cobre múltiplas empresas, regras gerais de compartilhamento, benchmarks, tuning ou autovacuum, nem apresenta conclusões sobre desempenho.

## Contrato dos dados

| Tabela | Chave técnica | Chave de negócio | Escopo de filial |
|---|---|---|---|
| `pedidos` (cabeçalhos) | `r_e_c_n_o_` | `(filial, numero)` | exclusiva: `'01'` ou `'02'` |
| `itens` | `r_e_c_n_o_` | `(filial, numero, item)` | exclusiva: `'01'` ou `'02'` |
| `produtos` | `r_e_c_n_o_` | `(filial, codigo)` | compartilhada: `'  '` (dois espaços) |

- `r_e_c_n_o_` é `bigint`, chave primária técnica em cada tabela; não representa tempo nem relaciona tabelas.
- `d_e_l_e_t_` é `text NOT NULL`: exatamente um espaço (`' '`) para ativo e `'*'` para excluído. Texto vazio não equivale a ativo.
- As filiais também usam `text`, preservando a distinção entre um e dois espaços; não se aplica `trim()` aos escopos.
- `valor` é `numeric(12,2)`.
- `CHECK`, `NOT NULL` e `UNIQUE` expressam o contrato simplificado do exercício. Essas chaves não reproduzem índices físicos do ERP.
- Não há FK para produtos, permitindo demonstrar um cadastro fisicamente ausente. A unicidade `(filial, codigo)` evita multiplicar itens ao buscar o produto no escopo correto.

## Preparação e execução

Use Docker, Docker Compose e o PostgreSQL 16 do `compose.yaml`. Na raiz do repositório, copie a configuração somente se necessário e inicie o banco:

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

| Arquivo | Finalidade |
|---|---|
| `01-tabelas.sql` | Remove e recria o schema do episódio e suas três tabelas |
| `02-dados.sql` | Carrega cinco cabeçalhos, cinco itens e dois produtos |
| `03-consultas.sql` | Compara consultas corretas e erros intencionais |
| `04-exercicio.sql` | Enunciado e solução para as duas filiais |
| `05-validacao.sql` | 22 verificações automatizadas, incluindo transações revertidas |

Abra o cliente com interrupção no primeiro erro:

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Execute na ordem:

```psql
\i /sql-da-semana/15-exclusao-logica-filial/01-tabelas.sql
\i /sql-da-semana/15-exclusao-logica-filial/02-dados.sql
\i /sql-da-semana/15-exclusao-logica-filial/03-consultas.sql
\i /sql-da-semana/15-exclusao-logica-filial/04-exercicio.sql
\i /sql-da-semana/15-exclusao-logica-filial/05-validacao.sql
```

Execução não interativa equivalente, também usada na validação:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -f /sql-da-semana/15-exclusao-logica-filial/01-tabelas.sql \
  -f /sql-da-semana/15-exclusao-logica-filial/02-dados.sql \
  -f /sql-da-semana/15-exclusao-logica-filial/03-consultas.sql \
  -f /sql-da-semana/15-exclusao-logica-filial/04-exercicio.sql \
  -f /sql-da-semana/15-exclusao-logica-filial/05-validacao.sql
```

Para repetir, execute novamente desde `01-tabelas.sql`: ele elimina com `CASCADE` e recria somente `sql_semana_15`. Recarregar apenas `02-dados.sql` causa conflito de chave. O exercício é somente leitura; as alterações nos produtos em `05-validacao.sql` são revertidas separadamente com `ROLLBACK`. Execute esse arquivo sem uma transação externa, pois ele controla suas próprias transações.

## Resultados esperados e observados

O único item ativo de cabeçalho ativo da filial 01 é `(01, 100, 01)`, com valor `100.00`.

| Cenário | Resultado |
|---|---|
| Sem filtro de exclusão do item | pedido 100 soma `150.00`; pedido 103 soma `70.00` |
| Sem filtro de exclusão do cabeçalho | pedido 101 reaparece com `300.00` |
| Cabeçalho e item relacionados só pelo número | pedido 100 da filial 01 recebe dois itens e soma `1000.00` |
| Relacionamento por filial e número | pedido 100 da filial 01 recebe um item e soma `100.00` |
| Produto buscado em `'  '` | exatamente uma linha, com descrição `Produto A` |
| Produto buscado na filial do movimento, com `LEFT JOIN` | item preservado, descrição `NULL` |
| Mesmo escopo errado, com `INNER JOIN` | nenhuma linha |
| Filtro de item no `WHERE` após `LEFT JOIN` | pedidos 102 e 103 desaparecem |
| `count(*)` nos pedidos sem itens ativos | conta incorretamente uma linha; `count(i.r_e_c_n_o_)` retorna zero |

O exemplo 5 declara `filial_movimento = '01'` e `filial_cadastro = '  '` separadamente, sem `OR` ou `IN` para misturar escopos. O filtro de exclusão do produto fica no `ON`, permitindo preservar o item quando o cadastro não é encontrado.

A consulta que preserva cabeçalhos ativos coloca o filtro de exclusão do item no `ON` e usa `coalesce(sum(i.valor), 0.00)`:

| filial | numero | itens ativos | total |
|---|---|---:|---:|
| 01 | 100 | 1 | 100.00 |
| 01 | 102 | 0 | 0.00 |
| 01 | 103 | 0 | 0.00 |

O pedido 102 não tem itens; o 103 tem somente um item excluído. No primeiro, o `LEFT JOIN` gera a linha sem correspondência; no segundo, o filtro no `ON` impede que o item excluído seja considerado uma correspondência. Mover o filtro para o `WHERE` elimina ambos. A contagem da chave técnica não nula do item distingue uma correspondência real da linha preservada pelo `LEFT JOIN`.

O exercício mantém `(filial, numero)` no agrupamento e acrescenta `(02, 100)`, com um item e `900.00`: são quatro cabeçalhos ativos, três na filial 01 e um na 02. Os totais por filial são respectivamente `100.00` e `900.00`.

O cenário 11 testa separadamente a exclusão lógica e a remoção física de P01. Em ambos, o `LEFT JOIN` preserva exatamente `(01, 100, 01, 100.00, NULL)` e o total do pedido continua `100.00`. Cada cenário termina com `ROLLBACK` e conferência de restauração dos dois produtos.

## Validação realizada

Executado em **02/11/2026**, usando a imagem **`postgres:16`** do Compose. Versão obtida com:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -c 'SELECT version();'
```

```text
PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

Foram executados `docker compose up -d` e o roteiro não interativo completo acima **duas vezes**, desde a recriação do schema. Na primeira execução, `SELECT version();` também foi passado com `-c` antes dos arquivos. Ambas terminaram com código de saída **0**, reproduzindo os resultados apresentados e a mensagem:

```text
NOTICE:  Validação do episódio 15 concluída com sucesso: 22 verificações.
```

A validação compara os resultados completos por diferença bidirecional com `EXCEPT ALL`, incluindo chaves, cardinalidades, duplicatas e valores. São três conferências da massa-base, onze dos exemplos, duas do exercício e seis dos cenários revertidos. Os resultados errados são verificados como demonstrações intencionais, não aprovados como consultas de negócio.

Também foi testada a falha explícita, alterando temporariamente o valor do item 11:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -c "BEGIN; UPDATE sql_semana_15.itens SET valor = 101.00 WHERE r_e_c_n_o_ = 11;" \
  -f /sql-da-semana/15-exclusao-logica-filial/05-validacao.sql
```

O cliente terminou com código **3** e `ERROR: Carga: itens: 2 divergências (chaves, cardinalidade ou valores)`. As duas diferenças correspondem à linha esperada ausente e à linha alterada excedente. A conexão encerrada reverteu a transação aberta. Não há pendências de validação funcional no ambiente testado; o laboratório está tecnicamente pronto para sustentar o artigo dentro do escopo descrito.
