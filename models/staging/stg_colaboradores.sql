-- Cadastro. Uma linha por pessoa.
--
-- `nome` fica de fora desta camada de propósito. Nenhum modelo analítico
-- precisa dele, e o que não é selecionado não vaza para dashboard nem para
-- extração ad hoc.
with fonte as (
    select * from {{ source('hr_raw', 'dim_colaborador') }}
)

select
    cast(matricula as integer)              as matricula,
    hash_documento                          as pseudonimo,
    cast(data_nascimento as date)           as data_nascimento,
    genero,
    raca_cor,
    escolaridade,
    estado_civil,
    cast(num_dependentes as integer)        as num_dependentes,
    uf,
    cidade,
    cast(distancia_km as double)            as distancia_km,
    cast(data_admissao as date)             as data_admissao,
    cast(data_desligamento as date)         as data_desligamento,
    tipo_desligamento,
    motivo_desligamento,
    status,
    -- Safra de admissão: a chave de toda análise de sobrevivência.
    date_trunc('month', cast(data_admissao as date))    as safra_admissao,
    date_trunc('month', cast(data_desligamento as date)) as competencia_saida
from fonte
