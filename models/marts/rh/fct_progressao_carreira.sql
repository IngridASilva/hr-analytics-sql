-- Tempo até a primeira promoção, por safra.
--
-- O número que a maioria das empresas não tem e que aparece em toda
-- entrevista de desligamento como "falta de perspectiva".
with quadro as (
    select * from {{ ref('fct_quadro_mensal') }}
),

primeira_promocao as (
    select
        matricula,
        safra_admissao,
        min(case when houve_promocao then mes_de_vida end)  as mes_primeira_promocao,
        max(mes_de_vida)                                     as meses_observados,
        max(num_promocoes)                                   as promocoes_totais
    from quadro
    group by 1, 2
)

select
    safra_admissao,
    count(*)                                                as pessoas_na_safra,
    count(mes_primeira_promocao)                            as com_promocao,
    round(
        count(mes_primeira_promocao) * 1.0 / nullif(count(*), 0), 4
    )                                                       as pct_promovidos,
    round(median(mes_primeira_promocao), 1)                 as mediana_meses_ate_promocao,
    round(avg(promocoes_totais), 2)                         as promocoes_medias,
    -- Quem passou de 36 meses sem nenhuma promoção. Recorte acionável:
    -- é a lista que o RH consegue levar para a conversa com o gestor.
    count(*) filter (
        where mes_primeira_promocao is null and meses_observados >= 36
    )                                                       as estagnados_36m
from primeira_promocao
group by 1
order by 1
