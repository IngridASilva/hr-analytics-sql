-- Curva de sobrevivência por safra de admissão.
-- Grão: safra × mês de vida.
--
-- Responde a pergunta que a taxa anual de turnover não responde: em que
-- momento da carreira as pessoas saem. Se o vale está no mês 14, o problema é
-- integração e carreira inicial, não remuneração — e são orçamentos
-- diferentes.
--
-- Trata censura à direita: uma safra recente não teve tempo de chegar ao mês
-- 24, e contar isso como sobrevivência infla a curva.
with pessoas as (
    select * from {{ ref('stg_colaboradores') }}
),

ultima_competencia as (
    select max(competencia) as fim_da_base
    from {{ ref('fct_quadro_mensal') }}
),

base as (
    select
        p.safra_admissao,
        p.matricula,
        p.tipo_desligamento,
        case
            when p.data_desligamento is null then null
            else datediff('month', p.safra_admissao, p.competencia_saida)
        end                                             as mes_de_saida,
        datediff('month', p.safra_admissao, u.fim_da_base) as meses_observados
    from pessoas p
    cross join ultima_competencia u
    where p.safra_admissao >= date '2021-01-01'
),

meses as (
    select unnest(generate_series(0, 48)) as mes_de_vida
),

expandido as (
    select
        b.safra_admissao,
        m.mes_de_vida,
        count(*)                                        as safra_total,
        -- Só entra no denominador quem teve tempo de chegar neste mês de vida.
        count(*) filter (where b.meses_observados >= m.mes_de_vida) as expostos,
        count(*) filter (
            where b.meses_observados >= m.mes_de_vida
              and (b.mes_de_saida is null or b.mes_de_saida > m.mes_de_vida)
        )                                               as sobreviventes,
        count(*) filter (
            where b.mes_de_saida = m.mes_de_vida
              and b.tipo_desligamento = 'Voluntário'
        )                                               as saidas_voluntarias_no_mes,
        count(*) filter (where b.mes_de_saida = m.mes_de_vida) as saidas_no_mes
    from base b
    cross join meses m
    group by 1, 2
)

select
    safra_admissao,
    mes_de_vida,
    safra_total,
    expostos,
    sobreviventes,
    saidas_no_mes,
    saidas_voluntarias_no_mes,
    case when expostos = 0 then null
         else round(sobreviventes / expostos, 4)
    end                                                 as taxa_sobrevivencia,
    case when expostos = 0 then null
         else round(saidas_no_mes / expostos, 4)
    end                                                 as hazard_do_mes
from expandido
where expostos > 0
