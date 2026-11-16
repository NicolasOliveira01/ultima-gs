-- FINAL: fato de leituras (1 linha por ciclo do carregador).
-- Base para temperatura e estado da proteção térmica ao longo do tempo.
-- O valor pago NÃO entra aqui: ele se repete em toda leitura e duplicaria a receita.

select
    id_leitura,
    id_sessao,
    id_carregador,
    data_hora,
    data_hora::date                                   as data,   -- liga com dim_data
    hour(data_hora)                                   as hora,
    volta,
    temperatura_c,
    estado,
    led_status,
    rele_ligado,
    potencia_pedida_kw,
    potencia_entregue_kw,
    energia_intervalo_kwh,
    kwh_entregue,
    intervalo_ms * {{ var('aceleracao') }} / 60000.0  as minutos_intervalo

from {{ ref('stg_leituras') }}
