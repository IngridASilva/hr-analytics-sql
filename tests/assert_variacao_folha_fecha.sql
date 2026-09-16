-- Teste de reconciliação: a soma dos quatro componentes tem que reproduzir a
-- variação total da massa.
--
-- Como `impacto_quadro` é resíduo por construção, este teste não valida a
-- aritmética — valida que ninguém quebrou a construção do resíduo ao editar o
-- modelo. É barato e pega refatoração malfeita.
select
    competencia,
    variacao_total,
    impacto_dissidio + impacto_merito + impacto_promocao + impacto_quadro as soma_componentes
from {{ ref('fct_variacao_folha') }}
where abs(
    variacao_total
    - (impacto_dissidio + impacto_merito + impacto_promocao + impacto_quadro)
) > 0.01
