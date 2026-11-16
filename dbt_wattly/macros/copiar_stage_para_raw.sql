{#
  Carrega os arquivos do stage RAW.STAGE_IOT nas tabelas da camada RAW (comando COPY INTO).
  Além das colunas do CSV, preenche as colunas de auditoria:
    _arquivo      -> nome do arquivo de origem (metadata$filename)
    _carregado_em -> momento da carga

  Uso (dentro da pasta dbt_wattly):
    dbt run-operation copiar_stage_para_raw
#}
{% macro copiar_stage_para_raw() %}

  {# ---------- leituras dos carregadores (21 colunas no CSV) ---------- #}
  {% set copy_leituras %}
    copy into wattly.raw.leituras_carregador
    from (
        select
            $1,  $2,  $3,  $4,  $5,  $6,  $7,  $8,  $9,  $10, $11,
            $12, $13, $14, $15, $16, $17, $18, $19, $20, $21,
            metadata$filename,
            current_timestamp()
        from @wattly.raw.stage_iot
    )
    file_format = (format_name = 'wattly.raw.ff_csv')
    pattern     = '.*leituras_carregador.*'
  {% endset %}

  {# ---------- cadastro dos carregadores (9 colunas no CSV) ---------- #}
  {% set copy_carregadores %}
    copy into wattly.raw.carregadores
    from (
        select
            $1, $2, $3, $4, $5, $6, $7, $8, $9,
            metadata$filename,
            current_timestamp()
        from @wattly.raw.stage_iot
    )
    file_format = (format_name = 'wattly.raw.ff_csv')
    pattern     = '.*carregadores.*'
  {% endset %}

  {# ---------- executa e mostra o resultado de cada carga ---------- #}
  {% for nome, comando in [('leituras_carregador', copy_leituras), ('carregadores', copy_carregadores)] %}
    {% set resultado = run_query(comando) %}
    {{ log("COPY INTO raw." ~ nome ~ ":", info=True) }}
    {% for linha in resultado.rows %}
      {{ log("   " ~ (linha.values() | join(" | ")), info=True) }}
    {% endfor %}
  {% endfor %}

{% endmacro %}
