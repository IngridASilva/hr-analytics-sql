-- ===========================================================================
-- Consultas de exemplo.
--
-- Vivem em analyses/ porque não são modelos: não devem virar tabela no banco.
-- `dbt compile` resolve as referências e imprime o SQL final em
-- target/compiled, pronto para colar em qualquer cliente.
-- ===========================================================================


-- 1. Em que mês da carreira as pessoas saem?
--    Se o pico está no mês 14, o orçamento certo é integração e carreira
--    inicial. Se está no mês 40, é remuneração. São conversas diferentes.
select
    mes_de_vida,
    sum(expostos)                                       as expostos,
    sum(saidas_voluntarias_no_mes)                      as saidas,
    round(sum(saidas_voluntarias_no_mes) / nullif(sum(expostos), 0), 4) as hazard
from {{ ref('fct_sobrevivencia_safra') }}
where mes_de_vida between 1 and 36
group by 1
order by hazard desc
limit 10;


-- 2. Quanto do crescimento da folha veio de negociação coletiva?
--    A pergunta que o controller sempre faz e que quase nenhum relatório de
--    RH responde.
select
    date_trunc('year', competencia)                     as ano,
    round(sum(impacto_dissidio), 2)                     as dissidio,
    round(sum(impacto_merito), 2)                       as merito,
    round(sum(impacto_promocao), 2)                     as promocao,
    round(sum(impacto_quadro), 2)                       as quadro,
    round(sum(impacto_dissidio) / nullif(sum(variacao_total), 0), 4) as pct_dissidio
from {{ ref('fct_variacao_folha') }}
group by 1
order by 1;


-- 3. Quais gerências combinam turnover alto e custo alto de reposição?
--    Prioriza por dinheiro, não por taxa. Área com 40% de turnover em cargo
--    barato dói menos que 15% em cargo crítico.
with ultimo as (
    select max(competencia) as competencia from {{ ref('fct_turnover_mensal') }}
)
select
    t.gerencia,
    t.headcount_fim_mes,
    t.turnover_voluntario_12m,
    round(t.custo_desligamentos, 2)                     as custo_12m
from {{ ref('fct_turnover_mensal') }} t
inner join ultimo u on u.competencia = t.competencia
where t.turnover_voluntario_12m is not null
order by t.custo_desligamentos desc
limit 10;


-- 4. Onde a estrutura salarial está mais dispersa?
--    Dispersão interquartil alta no mesmo cargo indica critério inconsistente
--    de contratação ou de mérito. É o ponto de partida de uma revisão de
--    faixas.
with ultimo as (
    select max(competencia) as competencia from {{ ref('fct_posicionamento_salarial') }}
)
select
    p.cargo,
    p.n,
    p.salario_mediano,
    p.dispersao_interquartil,
    p.abaixo_do_piso,
    p.acima_do_teto
from {{ ref('fct_posicionamento_salarial') }} p
inner join ultimo u on u.competencia = p.competencia
where not p.suprimido_por_n_minimo
order by p.dispersao_interquartil desc
limit 15;


-- 5. Safras que não conseguem promover ninguém.
--    Cruzamento direto com o driver mais preditivo do modelo de turnover.
select
    safra_admissao,
    pessoas_na_safra,
    pct_promovidos,
    mediana_meses_ate_promocao,
    estagnados_36m
from {{ ref('fct_progressao_carreira') }}
where pessoas_na_safra >= 20
order by pct_promovidos asc
limit 12;
