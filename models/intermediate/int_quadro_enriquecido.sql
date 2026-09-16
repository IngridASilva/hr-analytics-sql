-- Quadro mensal com dimensões anexadas e os marcadores de ciclo de vida.
--
-- Concentrar aqui as flags de primeiro e último mês evita que cada mart
-- refaça a mesma janela. É o tipo de duplicação que passa despercebida até
-- alguém mudar a regra em um lugar só.
with quadro as (
    select * from {{ ref('stg_quadro_mensal') }}
),

pessoas as (
    select * from {{ ref('stg_colaboradores') }}
),

areas as (
    select * from {{ ref('stg_areas') }}
),

cargos as (
    select * from {{ ref('stg_cargos') }}
),

marcado as (
    select
        q.*,
        min(q.competencia) over (partition by q.matricula) as primeira_competencia,
        max(q.competencia) over (partition by q.matricula) as ultima_competencia,
        lag(q.grade)   over (partition by q.matricula order by q.competencia) as grade_anterior,
        lag(q.salario) over (partition by q.matricula order by q.competencia) as salario_anterior,
        lag(q.id_area) over (partition by q.matricula order by q.competencia) as area_anterior
    from quadro q
)

select
    m.id_competencia,
    m.competencia,
    m.matricula,
    m.id_area,
    a.diretoria,
    a.gerencia,
    a.centro_custo,
    a.criticidade,
    m.id_cargo,
    c.cargo,
    c.nivel,
    m.familia_cargo,
    m.grade,
    m.id_gestor,
    m.modelo_trabalho,
    m.salario,
    m.compa_ratio,
    m.performance,
    m.meses_de_casa,
    m.meses_sem_promocao,
    m.num_promocoes,
    m.idade,
    m.horas_extras,
    p.genero,
    p.raca_cor,
    p.escolaridade,
    p.data_admissao,
    p.data_desligamento,
    p.tipo_desligamento,
    p.safra_admissao,
    -- Meses completos desde a admissão. Base da curva de sobrevivência.
    datediff('month', p.safra_admissao, m.competencia) as mes_de_vida,
    m.competencia = m.primeira_competencia              as eh_primeira_competencia,
    m.competencia = m.ultima_competencia                as eh_ultima_competencia,
    coalesce(m.grade   > m.grade_anterior, false)       as houve_promocao,
    coalesce(m.id_area <> m.area_anterior, false)       as houve_transferencia,
    m.salario_anterior                                  as salario_mes_anterior
from marcado m
inner join pessoas p on p.matricula = m.matricula
inner join areas   a on a.id_area   = m.id_area
left  join cargos  c on c.id_cargo  = m.id_cargo
