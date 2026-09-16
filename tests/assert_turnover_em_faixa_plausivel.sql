-- Guarda contra erro de denominador, que é a falha silenciosa mais comum em
-- métrica de turnover: um join que multiplica linhas infla o headcount médio
-- e derruba a taxa sem que nada pareça errado.
--
-- Nota sobre o limite inferior. A primeira versão deste teste usava 5% e
-- quebrou em nove linhas — todas de áreas com cerca de 20 pessoas e um único
-- desligamento no ano. Não era erro de dado: 1 saída em 21 pessoas é 4,8%, e
-- é perfeitamente plausível. O limite foi afrouxado para 1% e a exigência de
-- porte subiu para 30 pessoas, DEPOIS de investigar a causa.
--
-- Vale dizer por quê: afrouxar limite para o teste passar é como suíte de
-- testes vira decoração. Afrouxar porque o limite estava errado é manutenção.
-- A diferença está em ter olhado as nove linhas antes de mexer.
select
    competencia,
    gerencia,
    headcount_medio_12m,
    desligamentos_12m,
    turnover_total_12m
from {{ ref('fct_turnover_mensal') }}
where turnover_total_12m is not null
  and headcount_medio_12m >= 30
  and (turnover_total_12m < 0.01 or turnover_total_12m > 0.80)
