-- Catálogo de cargos com a faixa salarial de referência.
with fonte as (
    select * from {{ source('hr_raw', 'dim_cargo') }}
)

select
    id_cargo,
    familia_cargo,
    cast(grade as integer)                  as grade,
    nivel,
    cargo,
    cast(faixa_minima as double)            as faixa_minima,
    cast(faixa_mediana as double)           as faixa_mediana,
    cast(faixa_maxima as double)            as faixa_maxima
from fonte
