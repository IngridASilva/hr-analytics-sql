-- Foto mensal do quadro. Grão: matrícula × competência.
--
-- Este é o fato mais importante do modelo e é SEMIADITIVO: soma ao longo de
-- área, não ao longo do tempo. Somar doze meses devolve doze vezes o quadro,
-- e é o erro mais comum em modelagem de RH.
with fonte as (
    select * from {{ source('hr_raw', 'fato_headcount_mensal') }}
)

select
    cast(id_mes as integer)                 as id_competencia,
    cast(data_referencia as date)           as competencia,
    cast(matricula as integer)              as matricula,
    cast(id_area as integer)                as id_area,
    id_cargo,
    familia_cargo,
    cast(grade as integer)                  as grade,
    cast(id_gestor as integer)              as id_gestor,
    modelo_trabalho,
    cast(salario as double)                 as salario,
    cast(compa_ratio as double)             as compa_ratio,
    cast(performance as integer)            as performance,
    cast(meses_de_casa as double)           as meses_de_casa,
    cast(meses_sem_promocao as double)      as meses_sem_promocao,
    cast(num_promocoes as integer)          as num_promocoes,
    cast(idade as integer)                  as idade,
    cast(horas_extras as double)            as horas_extras
from fonte
