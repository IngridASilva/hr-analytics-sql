-- Turnover por área e competência, com janela móvel de 12 meses.
--
-- Duas decisões que mudam o número e quase nunca são explicitadas:
--
-- 1. O denominador é o headcount MÉDIO do período, não o final. Usar o final
--    subestima a taxa em empresa que cresce e superestima em empresa que
--    encolhe, e nenhuma das duas distorções é pequena.
-- 2. A janela é móvel de 12 meses, não acumulada no ano. Turnover acumulado
--    no ano é ruído puro em janeiro e só fica legível em novembro.
with quadro as (
    select * from {{ ref('fct_quadro_mensal') }}
),

saidas as (
    select * from {{ ref('int_desligamentos') }}
),

quadro_mes as (
    select
        competencia,
        id_area,
        diretoria,
        gerencia,
        count(distinct matricula)                       as headcount_fim_mes,
        count(distinct matricula) filter (
            where eh_primeira_competencia
        )                                               as admissoes
    from quadro
    group by 1, 2, 3, 4
),

saidas_mes as (
    select
        competencia,
        id_area,
        count(*)                                        as desligamentos,
        count(*) filter (where eh_voluntario)           as desligamentos_voluntarios,
        count(*) filter (where not eh_voluntario)       as desligamentos_involuntarios,
        sum(custo_total_desligamento)                   as custo_desligamentos
    from saidas
    where id_area is not null
    group by 1, 2
),

combinado as (
    select
        q.competencia,
        q.id_area,
        q.diretoria,
        q.gerencia,
        q.headcount_fim_mes,
        q.admissoes,
        coalesce(s.desligamentos, 0)                    as desligamentos,
        coalesce(s.desligamentos_voluntarios, 0)        as desligamentos_voluntarios,
        coalesce(s.desligamentos_involuntarios, 0)      as desligamentos_involuntarios,
        coalesce(s.custo_desligamentos, 0)              as custo_desligamentos
    from quadro_mes q
    left join saidas_mes s
        on s.competencia = q.competencia
       and s.id_area     = q.id_area
),

janela as (
    select
        *,
        -- 11 meses antes mais o corrente = janela de 12.
        avg(headcount_fim_mes) over (
            partition by id_area
            order by competencia
            rows between {{ var('janela_turnover_meses') - 1 }} preceding and current row
        )                                               as headcount_medio_12m,
        sum(desligamentos) over (
            partition by id_area
            order by competencia
            rows between {{ var('janela_turnover_meses') - 1 }} preceding and current row
        )                                               as desligamentos_12m,
        sum(desligamentos_voluntarios) over (
            partition by id_area
            order by competencia
            rows between {{ var('janela_turnover_meses') - 1 }} preceding and current row
        )                                               as desligamentos_voluntarios_12m,
        count(*) over (
            partition by id_area
            order by competencia
            rows between {{ var('janela_turnover_meses') - 1 }} preceding and current row
        )                                               as meses_na_janela
    from combinado
)

select
    competencia,
    id_area,
    diretoria,
    gerencia,
    headcount_fim_mes,
    admissoes,
    desligamentos,
    desligamentos_voluntarios,
    desligamentos_involuntarios,
    custo_desligamentos,
    round(headcount_medio_12m, 2)                       as headcount_medio_12m,
    desligamentos_12m,
    desligamentos_voluntarios_12m,
    meses_na_janela,
    -- Janela incompleta não vira taxa. Publicar 12 meses de turnover com 3
    -- meses de dado é o jeito mais rápido de perder a confiança do usuário.
    case
        when meses_na_janela < {{ var('janela_turnover_meses') }} then null
        when headcount_medio_12m = 0 then null
        else round(desligamentos_12m / headcount_medio_12m, 4)
    end                                                 as turnover_total_12m,
    case
        when meses_na_janela < {{ var('janela_turnover_meses') }} then null
        when headcount_medio_12m = 0 then null
        else round(desligamentos_voluntarios_12m / headcount_medio_12m, 4)
    end                                                 as turnover_voluntario_12m
from janela
