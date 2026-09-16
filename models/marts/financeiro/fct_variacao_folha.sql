-- Decomposição da variação da massa salarial. Grão: competência.
--
-- Responde a pergunta que o controller sempre faz: quanto do aumento veio de
-- reajuste e quanto veio de gente nova. Quase nenhum relatório de RH entrega
-- isso, e é o que transforma o painel em ferramenta de Finanças.
--
-- Os três primeiros componentes vêm dos eventos registrados. O quarto é
-- resíduo por construção: o que não veio de reajuste individual veio de
-- movimentação de quadro. Tratar o resíduo como categoria nomeada, e não como
-- "outros", é o que faz a cascata fechar e ser auditável.
with massa as (
    select
        competencia,
        sum(salario)                                    as massa_salarial,
        count(distinct matricula)                       as headcount
    from {{ ref('stg_folha_mensal') }}
    group by 1
),

eventos as (
    select
        competencia,
        sum(impacto_massa) filter (where tipo_evento = 'Dissídio')  as impacto_dissidio,
        sum(impacto_massa) filter (where tipo_evento = 'Mérito')    as impacto_merito,
        sum(impacto_massa) filter (where tipo_evento = 'Promoção')  as impacto_promocao
    from {{ ref('stg_movimentacoes') }}
    group by 1
),

variacao as (
    select
        m.competencia,
        m.massa_salarial,
        m.headcount,
        lag(m.massa_salarial) over (order by m.competencia) as massa_mes_anterior,
        lag(m.headcount)      over (order by m.competencia) as headcount_mes_anterior,
        coalesce(e.impacto_dissidio, 0)                     as impacto_dissidio,
        coalesce(e.impacto_merito, 0)                       as impacto_merito,
        coalesce(e.impacto_promocao, 0)                     as impacto_promocao
    from massa m
    left join eventos e on e.competencia = m.competencia
)

select
    competencia,
    massa_salarial,
    massa_mes_anterior,
    headcount,
    headcount - headcount_mes_anterior                  as variacao_headcount,
    massa_salarial - massa_mes_anterior                 as variacao_total,
    impacto_dissidio,
    impacto_merito,
    impacto_promocao,
    (massa_salarial - massa_mes_anterior)
        - impacto_dissidio - impacto_merito - impacto_promocao  as impacto_quadro,
    round(
        (massa_salarial - massa_mes_anterior)
        / nullif(massa_mes_anterior, 0), 4
    )                                                   as variacao_pct
from variacao
where massa_mes_anterior is not null
