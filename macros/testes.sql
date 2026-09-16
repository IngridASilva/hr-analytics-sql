{# ---------------------------------------------------------------------------
   Testes genéricos próprios.

   Poderiam vir do pacote dbt_utils, mas escrever os dois usados aqui evita
   uma dependência externa para ganhar duas funções. Em projeto de portfólio
   isso também mostra que você sabe o que o pacote faz.
   -------------------------------------------------------------------------- #}

{% test dbt_utils_positivo(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <= 0
{% endtest %}


{% test dbt_utils_entre(model, column_name, minimo, maximo) %}
select
    {{ column_name }} as valor
from {{ model }}
where {{ column_name }} is not null
  and ({{ column_name }} < {{ minimo }} or {{ column_name }} > {{ maximo }})
{% endtest %}
