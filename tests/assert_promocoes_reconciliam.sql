{{ config(severity='warn') }}

-- Reconciliação entre duas fontes que deveriam concordar.
--
-- `houve_promocao` no fato é detectado por comparação com o mês anterior
-- (lag do grade). O registro de movimentação é a fonte autoritativa. As duas
-- contagens não batem exatamente, e o motivo é conhecido: promoção que ocorre
-- no primeiro mês observado da pessoa não tem mês anterior para comparar.
--
-- Severidade `warn` de propósito. A divergência esperada é de poucas unidades
-- e não invalida nada; o que precisa acusar é ela crescer, porque aí não é
-- mais borda de janela, é mudança na carga.
--
-- Registrar a divergência conhecida em vez de escondê-la é o que permite
-- confiar no número: quem lê sabe de quanto é o erro e de onde ele vem.
with detectado as (
    select count(distinct matricula) as pessoas
    from {{ ref('fct_quadro_mensal') }}
    where houve_promocao
),

registrado as (
    select count(distinct matricula) as pessoas
    from {{ ref('stg_movimentacoes') }}
    where tipo_evento = 'Promoção'
)

select
    d.pessoas as detectado_por_lag,
    r.pessoas as registrado_em_movimentacao,
    r.pessoas - d.pessoas as divergencia
from detectado d
cross join registrado r
where abs(r.pessoas - d.pessoas) > greatest(10, r.pessoas * 0.05)
