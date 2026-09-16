# hr-analytics-sql

Camada analítica em SQL sobre a base de RH, construída com dbt e DuckDB.
Dezessete modelos, 42 testes, tudo versionado e reproduzível com um comando.

Base sintética: [hr-synthetic-data-br](../hr-synthetic-data-br).

```bash
pip install dbt-duckdb
DBT_PROFILES_DIR=. dbt build
```

Não precisa de servidor, credencial nem carga. O DuckDB lê os arquivos Parquet
direto do disco como se fossem tabelas, e o banco inteiro vive num arquivo
local de alguns megabytes.

---

## Por que este projeto existe

Um portfólio de RH com Python e Power BI e nenhuma linha de SQL é um portfólio
que não passa no filtro. SQL é a primeira coisa que aparece em descrição de
vaga de analista de dados, e a única que não dá para demonstrar por tabela de
resultado.

Mas escrever cem consultas soltas num arquivo também não demonstra nada. O que
demonstra é **modelagem**: camadas separadas, grão declarado, testes que
rodam sozinhos e linhagem rastreável.

## Arquitetura

```
data_base/*.parquet
      │
      ▼
staging/          8 views · tipagem, renomeação, nenhuma regra de negócio
      │
      ▼
intermediate/     2 modelos efêmeros · não viram tabela no banco
      │
      ▼
marts/rh/         quadro, turnover, sobrevivência, progressão
marts/financeiro/ custo de folha, decomposição, posicionamento
```

Três decisões da camada de staging que valem citar:

**`nome` não é selecionado.** Nenhum modelo analítico precisa dele, e o que
não é selecionado não vaza para dashboard nem para extração ad hoc. Privacidade
por construção custa uma linha a menos.

**Calendário colapsa para o grão mês.** A origem traz grão dia. Manter isso na
camada analítica só multiplicaria linha sem servir a nenhum modelo.

**Nenhuma regra de negócio em staging.** Tipagem e renomeação, só. A primeira
vez que alguém calcula turnover em staging é a última vez que se sabe de onde
o número veio.

## Os modelos que valem a leitura

**`fct_sobrevivencia_safra`** — curva de sobrevivência por safra de admissão,
com tratamento de censura à direita. Responde o que a taxa anual de turnover
não responde: em que momento da carreira as pessoas saem.

Uma safra admitida há oito meses não teve tempo de chegar ao mês 24. Contá-la
como sobrevivente no mês 24 infla a curva, e é o erro que faz a análise de
coorte mentir. O denominador só inclui quem teve exposição suficiente.

**`fct_turnover_mensal`** — janela móvel de 12 meses, com duas decisões que
mudam o número e quase nunca são explicitadas. O denominador é o headcount
**médio**, não o final: usar o final subestima a taxa em empresa que cresce.
E a taxa é **nula** enquanto a janela está incompleta, porque publicar 12 meses
de turnover com 3 meses de dado é o jeito mais rápido de perder a confiança do
usuário.

**`fct_variacao_folha`** — decompõe a variação da massa em dissídio, mérito,
promoção e movimentação de quadro. As quatro fecham com a variação total por
construção, e o resíduo é uma categoria nomeada em vez de "outros".

**`fct_posicionamento_salarial`** — dispersão por cargo, com supressão
obrigatória de grupos com menos de 5 pessoas. Com n=3, salário mediano deixa
de ser estatística e vira exposição individual. Há um teste que falha se
qualquer métrica escapar da supressão.

## O que os dados disseram

**Turnover concentrado no primeiro ano e meio.** O risco de saída voluntária
tem pico nos meses 8 e 9 (1,9% ao mês) e um segundo pico entre 16 e 18. Se o
vale está aí, o orçamento certo é integração e carreira inicial, não
remuneração — são conversas diferentes, com donos diferentes.

**Em 2024 o dissídio respondeu por 150% do aumento da folha.** O número passa
de 100% porque a movimentação de quadro foi negativa em R$ 675 mil: a empresa
encolheu o quadro e ainda assim a folha subiu. Traduzindo, o corte de pessoal
pagou o reajuste coletivo e sobrou conta. É o tipo de leitura que um indicador
de "variação da folha" sozinho jamais entregaria.

| Ano | Dissídio | Mérito | Promoção | Quadro | % dissídio |
|---|---|---|---|---|---|
| 2021 | 507.973 | 235.801 | 38.490 | 472.616 | 41% |
| 2022 | 1.528.607 | 271.162 | 46.756 | 844.857 | 57% |
| 2023 | 914.214 | 316.254 | 47.493 | −49.235 | 74% |
| 2024 | 785.872 | 355.593 | 58.521 | **−675.170** | **150%** |
| 2025 | 885.207 | 374.773 | 67.580 | −41.428 | 69% |

**Só 6,6% das pessoas foram promovidas alguma vez na janela observada.** De 74
safras com 20 pessoas ou mais, várias não promoveram ninguém. Isso conversa
diretamente com o projeto de turnover, onde tempo sem promoção é o driver mais
forte — e mostra que o problema não é de percepção.

## Testes

42 no total. Genéricos declarados no YAML (unicidade, não nulo, integridade
referencial, domínio de valores) e seis singulares que valem explicar:

| Teste | O que protege |
|---|---|
| `assert_grao_unico_quadro` | Grão duplicado é a falha que mais silenciosamente dobra um indicador |
| `assert_sem_quadro_apos_desligamento` | Pessoa desligada não pode reaparecer no quadro |
| `assert_variacao_folha_fecha` | Reconciliação: os quatro componentes têm que reproduzir a variação |
| `assert_supressao_aplicada` | Nenhuma métrica de remuneração escapa do n mínimo |
| `assert_turnover_em_faixa_plausivel` | Erro de denominador, a falha silenciosa mais comum |
| `assert_promocoes_reconciliam` | Divergência entre detecção por janela e registro de evento |

### Um teste que falhou e o que foi feito

`assert_turnover_em_faixa_plausivel` quebrou na primeira execução, em nove
linhas. Todas eram áreas de cerca de 20 pessoas com um único desligamento no
ano: 4,8% de turnover, que é perfeitamente plausível. Não era erro de dado, era
limite errado.

O limite inferior foi afrouxado de 5% para 1% e a exigência de porte subiu para
30 pessoas — **depois** de investigar as nove linhas. A diferença entre isso e
maquiar o teste está inteira no "depois": afrouxar limite para ficar verde é
como suíte de testes vira decoração.

### Uma divergência conhecida, registrada em vez de escondida

`houve_promocao` é detectado comparando o grade com o mês anterior. O registro
de movimentação aponta 199 pessoas promovidas; a detecção por janela aponta
194. A diferença são promoções ocorridas no primeiro mês observado da pessoa,
que não têm mês anterior para comparar.

Cinco pessoas em 2.949 não invalida nada, mas o teste existe com severidade
`warn` e um limite: se a divergência passar de 5%, não é mais borda de janela,
é mudança na carga. Quem lê o número sabe de quanto é o erro e de onde vem.

## Estrutura

```
dbt_project.yml          configuração, variáveis de negócio fora do SQL
profiles.yml             conexão DuckDB local
models/
  staging/               8 views + _sources.yml
  intermediate/          2 modelos efêmeros
  marts/rh/              6 modelos
  marts/financeiro/      3 modelos
  marts/_marts.yml       documentação e testes genéricos
macros/testes.sql        2 testes genéricos próprios
tests/                   6 testes singulares
analyses/                5 consultas de negócio
```

## Detalhes de implementação

**Testes genéricos próprios em vez de `dbt_utils`.** Os dois usados aqui
(valor positivo, valor entre limites) são vinte linhas cada. Trazer um pacote
inteiro para ganhar duas funções acrescenta uma dependência de rede ao build, e
escrevê-los mostra que você sabe o que o pacote faz.

**Intermediários efêmeros.** `int_quadro_enriquecido` e `int_desligamentos` não
viram tabela: são compilados como CTE dentro de quem os referencia. Poupa
espaço e deixa claro que não são superfície pública.

**Variáveis de negócio no `dbt_project.yml`.** Janela de turnover e data de
corte ficam fora do SQL. Mudar o recorte não pode exigir editar modelo.

**`qualify` em vez de subconsulta com `row_number`.** O DuckDB suporta, e a
leitura fica muito mais direta em `int_desligamentos`.

## Documentação navegável

```bash
DBT_PROFILES_DIR=. dbt docs generate
DBT_PROFILES_DIR=. dbt docs serve
```

Gera o grafo de linhagem e a documentação coluna a coluna. Vale um screenshot
no README do GitHub: o DAG é a imagem que explica o projeto sem uma palavra.

## Ressalvas

O modelo assume uma foto mensal completa do quadro. HRIS que exporta só
movimentação exige reconstruir o snapshot antes da camada de staging, e isso é
um projeto em si.

`fct_quadro_mensal` é materializado como tabela porque todos os marts o
consultam. Com histórico de 10 anos e 20 mil pessoas (2,4 milhões de linhas),
troque para incremental com chave `matricula` e `id_competencia`.

A supressão por n mínimo protege a publicação, não o acesso. Quem tem o arquivo
DuckDB tem o dado no grão individual. Controle de acesso é camada de
infraestrutura, não de modelagem.
