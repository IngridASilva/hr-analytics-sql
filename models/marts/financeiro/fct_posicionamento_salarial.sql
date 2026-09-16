-- Dispersão salarial dentro de cada cargo. Grão: cargo × competência.
--
-- Compa-ratio alto também é sinalizado. Pagar muito acima da faixa não é
-- virtude: é perda de margem e criação de uma pessoa impossível de promover
-- sem quebrar a estrutura.
--
-- Nenhuma métrica é publicada para grupo com menos de 5 pessoas. Com n=3,
-- salário mediano deixa de ser estatística e vira exposição individual.
with quadro as (
    select * from {{ ref('fct_quadro_mensal') }}
),

agregado as (
    select
        competencia,
        id_cargo,
        cargo,
        familia_cargo,
        grade,
        count(*)                                        as n,
        round(median(salario), 2)                       as salario_mediano,
        round(quantile_cont(salario, 0.25), 2)          as salario_p25,
        round(quantile_cont(salario, 0.75), 2)          as salario_p75,
        round(avg(compa_ratio), 4)                      as compa_ratio_medio,
        count(*) filter (where compa_ratio < 0.80)      as abaixo_do_piso,
        count(*) filter (where compa_ratio > 1.20)      as acima_do_teto
    from quadro
    group by 1, 2, 3, 4, 5
)

select
    competencia,
    id_cargo,
    cargo,
    familia_cargo,
    grade,
    n,
    case when n < 5 then null else salario_mediano end      as salario_mediano,
    case when n < 5 then null else salario_p25 end          as salario_p25,
    case when n < 5 then null else salario_p75 end          as salario_p75,
    case when n < 5 then null else compa_ratio_medio end    as compa_ratio_medio,
    case when n < 5 then null
         else round((salario_p75 - salario_p25)
                    / nullif(salario_mediano, 0), 4)
    end                                                     as dispersao_interquartil,
    abaixo_do_piso,
    acima_do_teto,
    n < 5                                                   as suprimido_por_n_minimo
from agregado
