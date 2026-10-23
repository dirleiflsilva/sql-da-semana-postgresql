# Episódio 13 — Datas textuais, validação e calendário de faturamento

## Objetivo

Este laboratório recebe datas como texto, separa ausência, formato inválido e data inexistente, converte somente valores seguros e produz um relatório diário que também mostra dias sem movimento. Os nove registros e valores são sintéticos, determinísticos e existem apenas no schema `sql_semana_13`; nenhuma tabela de ERP ou sistema externo é acessada.

## Pré-requisitos e preparação

- Docker e Docker Compose;
- PostgreSQL 16, fornecido pelo Compose do repositório.

Na raiz do repositório, prepare o ambiente (copie a configuração somente se `.env` ainda não existir):

```bash
cp -n .env.example .env
docker compose up -d
docker compose ps
```

Abra o `psql`:

```bash
docker compose exec postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana
```

Execute os arquivos na ordem:

```psql
\i /sql-da-semana/13-datas-texto-calendario/01-tabelas.sql
\i /sql-da-semana/13-datas-texto-calendario/02-dados.sql
\i /sql-da-semana/13-datas-texto-calendario/03-consultas.sql
\i /sql-da-semana/13-datas-texto-calendario/04-validacao.sql
```

Também é possível executar tudo sem sessão interativa:

```bash
docker compose exec -T postgres \
  psql -X -v ON_ERROR_STOP=1 -U postgres -d sql_da_semana \
  -f /sql-da-semana/13-datas-texto-calendario/01-tabelas.sql \
  -f /sql-da-semana/13-datas-texto-calendario/02-dados.sql \
  -f /sql-da-semana/13-datas-texto-calendario/03-consultas.sql \
  -f /sql-da-semana/13-datas-texto-calendario/04-validacao.sql
```

## Contrato e validação das datas

O contrato de entrada é estritamente `AAAAMMDD`: oito algarismos, sem separadores. Por isso, `2026-10-05` é `formato_invalido`, mesmo sendo uma representação de data reconhecida em outros contextos.

- `ausente`: `NULL`, texto vazio ou somente espaços, após `btrim()` e `NULLIF(..., '')`;
- `formato_invalido`: texto presente que não atende a `^[0-9]{8}$`;
- `data_invalida`: oito algarismos que não formam uma data de calendário, como `20260230`;
- `valida`: atende ao formato e representa uma data existente.

A expressão regular valida somente a forma. Ela não sabe quantos dias há em fevereiro. Depois da regex, o roteiro monta `AAAA-MM-DD` e usa `pg_input_is_valid(data_iso, 'date')` para consultar o parser do tipo `date` sem lançar erro. O cast `::date` ocorre apenas depois desse teste; assim, uma linha ruim não interrompe o lote e continua disponível para diagnóstico.

`to_date()` não deve ser usado sozinho como validador estrito. Ele é voltado à interpretação por máscara e pode normalizar determinadas entradas fora do calendário, em vez de rejeitar exatamente segundo o contrato. Neste laboratório, formato e validade do tipo são verificações separadas.

Experimento opcional, fora do fluxo principal: execute isoladamente `SELECT '2026-02-30'::date;` para observar o erro. Não inclua essa conversão na sequência com `ON_ERROR_STOP=1`.

## Calendário e dias sem movimento

`generate_series()` cria um dia por linha entre 1 e 7 de outubro de 2026. O calendário fica à esquerda de um `LEFT JOIN` com o faturamento válido agregado, preservando inclusive datas sem correspondência. `coalesce()` apresenta quantidade e total como zero nesses dias.

Zero, ausência e erro não são sinônimos. Em 05/10, zero quer dizer “nenhum movimento **válido** associado ao dia”; existe uma linha de R$ 70,00 rejeitada porque `2026-10-05` viola o formato contratado. Uma data ausente não informa um dia, enquanto uma data inválida registra um problema que precisa ser conciliado.

## Resultados esperados

Classificação:

| situação | quantidade |
|---|---:|
| ausente | 3 |
| data_invalida | 1 |
| formato_invalido | 1 |
| valida | 4 |

Faturamento válido por dia:

| dia | movimentos | total |
|---|---:|---:|
| 2026-10-01 | 1 | 120.00 |
| 2026-10-03 | 2 | 125.50 |
| 2026-10-07 | 1 | 200.00 |

Calendário completo:

| dia | movimentos | total |
|---|---:|---:|
| 2026-10-01 | 1 | 120.00 |
| 2026-10-02 | 0 | 0.00 |
| 2026-10-03 | 2 | 125.50 |
| 2026-10-04 | 0 | 0.00 |
| 2026-10-05 | 0 | 0.00 |
| 2026-10-06 | 0 | 0.00 |
| 2026-10-07 | 1 | 200.00 |

A conciliação fecha 9 linhas e R$ 645,50 recebidos: 4 movimentos e R$ 445,50 válidos, mais 5 linhas sem data utilizável e R$ 200,00 rejeitados. O script `04-validacao.sql` confere carga, classificação individual, contagens, totais e cada linha do calendário, falhando com uma mensagem clara diante de divergências.

## Limites e recomendação

A massa pequena demonstra correção funcional; ela não sustenta alegações de desempenho. O intervalo do relatório é fixo, e o exemplo não cobre formatos alternativos, regras históricas, localização, timestamps ou tratamento operacional de rejeições.

Em sistemas reais, armazene datas curadas em colunas `date`. Quando a origem entrega texto, preserve o valor bruto em uma camada de staging, valide-o, registre a causa das rejeições e publique apenas valores tipados na camada curada.

## Reinicialização

Repetir o laboratório com segurança exige começar novamente por `01-tabelas.sql`. Ele elimina com `CASCADE` e recria somente `sql_semana_13`; executar apenas `02-dados.sql` novamente causaria conflito de chave primária. Depois, repita os outros três arquivos na ordem indicada. Para parar o ambiente preservando os dados, use `docker compose down`.

## Validação realizada

Executado em **23/10/2026** com `psql -X -v ON_ERROR_STOP=1`, usando a imagem **`postgres:16`** definida em `compose.yaml`.

Versão retornada por `SELECT version();`:

```text
PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

Foram executados `docker compose up -d`, `SELECT version();` e o comando não interativo completo mostrado acima. A sequência de `01-tabelas.sql` a `04-validacao.sql` foi executada duas vezes desde a recriação do schema; os resultados e a mensagem final da validação foram reproduzidos nas duas execuções.

Leia o artigo [SQL da Semana #13 — datas textuais, validação e calendário de faturamento](https://dfls.eti.br/posts/sql-da-semana-13-datas-texto-calendario-faturamento/).
