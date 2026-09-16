-- Custo de folha por área e competência, com a composição aberta.
--
-- A coluna `fator_custo_sobre_salario` costuma ser a primeira surpresa numa
-- reunião de orçamento: encargos, provisões e benefícios levam o custo real a
-- cerca de 1,9 vez o salário, e o fator é maior nas áreas de salário baixo
-- porque benefício é valor fixo e portanto regressivo.
with folha as (
    select * from {{ ref('stg_folha_mensal') }}
),

areas as (
    select * from {{ ref('stg_areas') }}
),

agregado as (
    select
        f.competencia,
        f.id_area,
        a.diretoria,
        a.gerencia,
        a.centro_custo,
        count(distinct f.matricula)         as headcount,
        sum(f.salario)                      as salario_base,
        sum(f.valor_horas_extras)           as horas_extras,
        sum(f.remuneracao_bruta)            as remuneracao_bruta,
        sum(f.encargos)                     as encargos,
        sum(f.provisao_13o)                 as provisao_13o,
        sum(f.provisao_ferias)              as provisao_ferias,
        sum(f.beneficios)                   as beneficios,
        sum(f.custo_total)                  as custo_total
    from folha f
    inner join areas a on a.id_area = f.id_area
    group by 1, 2, 3, 4, 5
)

select
    *,
    round(custo_total / nullif(salario_base, 0), 4)     as fator_custo_sobre_salario,
    round(custo_total / nullif(headcount, 0), 2)        as custo_medio_por_pessoa,
    round(
        custo_total / nullif(
            lag(custo_total) over (partition by id_area order by competencia), 0
        ) - 1, 4
    )                                                   as variacao_mes_anterior,
    round(
        custo_total / nullif(
            lag(custo_total, 12) over (partition by id_area order by competencia), 0
        ) - 1, 4
    )                                                   as variacao_mesmo_mes_ano_anterior
from agregado
