-- Nenhuma métrica de remuneração pode escapar da supressão por n mínimo.
-- Basta uma escapar para o controle inteiro perder sentido.
select
    competencia,
    cargo,
    n
from {{ ref('fct_posicionamento_salarial') }}
where n < 5
  and (salario_mediano is not null
       or salario_p25 is not null
       or compa_ratio_medio is not null)
