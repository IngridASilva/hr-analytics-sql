-- Fato principal do modelo. Grão: matrícula × competência.
-- Materializado como tabela porque é consultado por todos os demais marts.
select * from {{ ref('int_quadro_enriquecido') }}
