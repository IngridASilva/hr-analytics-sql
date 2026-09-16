-- Estrutura organizacional. Uma linha por gerência.
with fonte as (
    select * from {{ source('hr_raw', 'dim_area') }}
)

select
    cast(id_area as integer)                as id_area,
    diretoria,
    gerencia,
    familia_cargo                           as familia_predominante,
    centro_custo,
    criticidade,
    sindicato,
    cast(mes_data_base as integer)          as mes_data_base_dissidio
from fonte
