{#
  Envia os CSVs do computador para o stage RAW.STAGE_IOT (comando PUT).
  Simula o gateway IoT depositando os arquivos dos carregadores na nuvem.

  Uso (dentro da pasta dbt_ultima_gs):
    dbt run-operation subir_arquivos_stage
#}
{% macro subir_arquivos_stage() %}

  {% set pasta = var('pasta_dados') %}
  {% set arquivos = ['leituras_carregador.csv', 'carregadores.csv'] %}

  {% for arquivo in arquivos %}

    {% set comando %}
      put 'file://{{ pasta }}/{{ arquivo }}' @ultima_gs.raw.stage_iot
        auto_compress = true
        overwrite     = true
    {% endset %}

    {% set resultado = run_query(comando) %}

    {# a 7ª coluna do retorno do PUT é o status: UPLOADED ou SKIPPED #}
    {{ log(arquivo ~ " -> " ~ resultado.rows[0][6], info=True) }}

  {% endfor %}

{% endmacro %}
