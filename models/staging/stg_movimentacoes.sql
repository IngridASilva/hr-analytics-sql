-- Eventos de carreira e remuneração. Grão: evento.
with fonte as (
    select * from {{ source('hr_raw', 'fato_movimentacao') }}
)

select
    cast(matricula as integer)              as matricula,
    cast(data_evento as date)               as data_evento,
    date_trunc('month', cast(data_evento as date)) as competencia,
    tipo_evento,
    cast(id_area as integer)                as id_area,
    cast(grade as integer)                  as grade,
    cast(salario_anterior as double)        as salario_anterior,
    cast(salario_novo as double)            as salario_novo,
    cast(variacao_pct as double)            as variacao_pct,
    cast(salario_novo as double) - cast(salario_anterior as double) as impacto_massa,
    detalhe
from fonte
