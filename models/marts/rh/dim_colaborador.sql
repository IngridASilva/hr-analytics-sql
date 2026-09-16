-- Dimensão de pessoa, sem nome e sem documento.
select
    matricula,
    pseudonimo,
    genero,
    raca_cor,
    escolaridade,
    estado_civil,
    num_dependentes,
    uf,
    cidade,
    distancia_km,
    data_admissao,
    data_desligamento,
    tipo_desligamento,
    motivo_desligamento,
    status,
    safra_admissao
from {{ ref('stg_colaboradores') }}
