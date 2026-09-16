-- Calendário no grão mês, derivado do calendário diário da origem.
-- A camada analítica inteira trabalha em competência; manter grão dia aqui
-- só multiplicaria linha sem servir a nenhum modelo.
with dias as (
    select * from {{ source('hr_raw', 'dim_calendario') }}
)

select distinct
    cast(id_mes as integer)                     as id_competencia,
    date_trunc('month', cast(data as date))     as competencia,
    cast(ano as integer)                        as ano,
    cast(mes as integer)                        as mes,
    nome_mes,
    ano_mes,
    trimestre,
    semestre
from dias
