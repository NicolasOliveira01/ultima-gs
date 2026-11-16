{#
  Por padrão o dbt junta o schema do profile com o schema do model (ex.: RAW_STG).
  Esta macro faz o dbt usar exatamente o schema configurado no dbt_project.yml (ex.: STG).
  O dbt chama esta macro sozinho; ela não precisa ser executada.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
