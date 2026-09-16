-- Um registro por desligamento, com o contexto do último mês trabalhado.
--
-- A data de desligamento vem do cadastro; o restante vem da última foto do
-- quadro. Ler salário e área direto do cadastro daria o valor de hoje, não o
-- da saída, e é como análise de turnover produz número errado sem alertar.
with pessoas as (
    select *
    from {{ ref('stg_colaboradores') }}
    where data_desligamento is not null
),

ultimo_mes as (
    select *
    from {{ ref('int_quadro_enriquecido') }}
    qualify row_number() over (
        partition by matricula order by competencia desc
    ) = 1
),

custos as (
    select * from {{ ref('stg_custo_desligamento') }}
)

select
    p.matricula,
    p.data_desligamento,
    p.competencia_saida                          as competencia,
    p.tipo_desligamento,
    p.motivo_desligamento,
    p.safra_admissao,
    p.genero,
    p.raca_cor,
    u.id_area,
    u.diretoria,
    u.gerencia,
    u.criticidade,
    u.grade,
    u.familia_cargo,
    u.id_gestor,
    u.modelo_trabalho,
    u.salario                                    as salario_na_saida,
    u.compa_ratio                                as compa_ratio_na_saida,
    u.performance                                as performance_na_saida,
    u.meses_de_casa,
    u.meses_sem_promocao,
    u.num_promocoes,
    c.custo_rescisao,
    c.custo_reposicao,
    c.custo_total                                as custo_total_desligamento,
    p.tipo_desligamento = 'Voluntário'           as eh_voluntario
from pessoas p
left join ultimo_mes u on u.matricula = p.matricula
left join custos     c on c.matricula = p.matricula
