-- O fato principal precisa ter uma linha por matrícula e competência.
-- Grão duplicado é a falha que mais silenciosamente dobra um indicador.
select
    matricula,
    competencia,
    count(*) as linhas
from {{ ref('fct_quadro_mensal') }}
group by 1, 2
having count(*) > 1
