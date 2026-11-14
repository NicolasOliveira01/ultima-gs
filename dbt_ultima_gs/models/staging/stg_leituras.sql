-- STG: leituras com os tipos corretos e sem linhas duplicadas.

with fonte as (

    select * from {{ source('raw', 'leituras_carregador') }}

),

tipado as (

    select
        -- identificação
        try_to_number(id_leitura)                                 as id_leitura,
        trim(id_sessao)                                           as id_sessao,
        trim(id_carregador)                                       as id_carregador,
        trim(id_usuario)                                          as id_usuario,
        try_to_timestamp_ntz(data_hora, 'YYYY-MM-DD HH24:MI:SS')  as data_hora,
        try_to_number(volta)                                      as volta,
        try_to_number(intervalo_ms)                               as intervalo_ms,

        -- pagamento
        try_to_decimal(valor_pago_brl, 10, 2)                     as valor_pago_brl,
        try_to_decimal(tarifa_kwh_brl, 10, 2)                     as tarifa_kwh_brl,
        try_to_decimal(kwh_pago, 10, 2)                           as kwh_pago,

        -- sensores
        try_to_number(leitura_pot_adc)                            as leitura_pot_adc,
        try_to_number(leitura_temp_adc)                           as leitura_temp_adc,
        try_to_decimal(temperatura_c, 5, 1)                       as temperatura_c,

        -- proteção térmica e potência
        upper(trim(estado))                                       as estado,
        try_to_decimal(potencia_pedida_kw, 6, 2)                  as potencia_pedida_kw,
        try_to_decimal(potencia_entregue_kw, 6, 2)                as potencia_entregue_kw,
        upper(trim(led_status))                                   as led_status,
        upper(trim(rele)) = 'LIGADO'                              as rele_ligado,

        -- energia
        try_to_decimal(energia_intervalo_kwh, 10, 3)              as energia_intervalo_kwh,
        try_to_decimal(kwh_entregue, 10, 2)                       as kwh_entregue,
        try_to_boolean(carga_concluida)                           as carga_concluida,

        -- auditoria
        _arquivo,
        _carregado_em

    from fonte

)

select * from tipado

-- se a mesma leitura foi carregada mais de uma vez, fica só a carga mais recente
qualify row_number() over (partition by id_leitura order by _carregado_em desc) = 1
