-- Ninguém pode aparecer no quadro depois do mês em que foi desligado.
select
    q.matricula,
    q.competencia,
    c.data_desligamento
from {{ ref('fct_quadro_mensal') }} q
inner join {{ ref('dim_colaborador') }} c on c.matricula = q.matricula
where c.data_desligamento is not null
  and q.competencia > date_trunc('month', c.data_desligamento)
