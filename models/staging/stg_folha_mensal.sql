-- Custo mensal por pessoa. Mesmo grão do quadro, o que permite relacionar os
-- dois sem multiplicação de linhas.
with fonte as (
    select * from {{ source('hr_raw', 'fato_folha_mensal') }}
)

select
    cast(id_mes as integer)                 as id_competencia,
    cast(data_referencia as date)           as competencia,
    cast(matricula as integer)              as matricula,
    cast(id_area as integer)                as id_area,
    cast(grade as integer)                  as grade,
    cast(salario as double)                 as salario,
    cast(valor_horas_extras as double)      as valor_horas_extras,
    cast(remuneracao_bruta as double)       as remuneracao_bruta,
    cast(encargos as double)                as encargos,
    cast(provisao_13o as double)            as provisao_13o,
    cast(provisao_ferias as double)         as provisao_ferias,
    cast(beneficios_total as double)        as beneficios,
    cast(custo_total as double)             as custo_total
from fonte
