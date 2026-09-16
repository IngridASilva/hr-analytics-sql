-- Custo realizado de cada desligamento.
with fonte as (
    select * from {{ source('hr_raw', 'fato_desligamento_custo') }}
)

select
    cast(matricula as integer)                  as matricula,
    cast(data_evento as date)                   as data_evento,
    date_trunc('month', cast(data_evento as date)) as competencia,
    tipo_desligamento,
    motivo_desligamento,
    cast(id_area as integer)                    as id_area,
    criticidade_area,
    cast(grade as integer)                      as grade,
    cast(salario as double)                     as salario,
    cast(meses_de_casa as double)               as meses_de_casa,
    cast(custo_rescisao as double)              as custo_rescisao,
    cast(custo_reposicao as double)             as custo_reposicao,
    cast(custo_total_desligamento as double)    as custo_total
from fonte
