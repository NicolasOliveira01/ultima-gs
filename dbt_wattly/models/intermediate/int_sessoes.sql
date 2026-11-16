-- INT: uma linha por sessão de carga, com as regras de negócio do carregador.

with leituras as (

    select * from {{ ref('stg_leituras') }}

),

-- 1. prepara cada leitura: minutos simulados e marcação do início de cada pausa
leituras_preparadas as (

    select
        *,

        -- minutos de carga simulados no intervalo (1 s real = 6 min)
        intervalo_ms * {{ var('aceleracao') }} / 60000.0 as minutos_intervalo,

        -- 1 quando a carga ENTRA em pausa (a leitura anterior não estava pausada)
        iff(
            estado = 'PAUSADO'
            and coalesce(lag(estado) over (partition by id_sessao order by volta), '') <> 'PAUSADO',
            1, 0
        ) as inicio_pausa

    from leituras

),

-- 2. agrupa as leituras em sessões
sessoes as (

    select
        id_sessao,
        any_value(id_carregador)                                as id_carregador,
        any_value(id_usuario)                                   as id_usuario,

        -- tempo
        min(data_hora)                                          as inicio,
        max(data_hora)                                          as fim,
        sum(minutos_intervalo)                                  as duracao_min,

        -- pagamento (o mesmo valor em todas as leituras: pega uma vez só)
        any_value(valor_pago_brl)                               as valor_pago_brl,
        any_value(tarifa_kwh_brl)                               as tarifa_kwh_brl,
        any_value(kwh_pago)                                     as kwh_pago,

        -- energia
        max(kwh_entregue)                                       as kwh_entregue,

        -- proteção térmica
        sum(iff(estado = 'NORMAL',   minutos_intervalo, 0))     as minutos_normal,
        sum(iff(estado = 'REDUZIDO', minutos_intervalo, 0))     as minutos_reduzido,
        sum(iff(estado = 'PAUSADO',  minutos_intervalo, 0))     as minutos_pausado,
        sum(inicio_pausa)                                       as qtd_pausas,
        max(temperatura_c)                                      as temperatura_max_c,
        avg(temperatura_c)                                      as temperatura_media_c,

        count(*)                                                as qtd_leituras,
        boolor_agg(carga_concluida)                             as carga_concluida

    from leituras_preparadas
    group by id_sessao

)

-- 3. métricas derivadas
select
    *,
    iff(carga_concluida, 'CONCLUIDA', 'EM_ANDAMENTO')                as status_sessao,

    -- energia entregue além do que foi pago (o último ciclo passa um pouco do limite)
    iff(carga_concluida, greatest(kwh_entregue - kwh_pago, 0), 0)    as kwh_excedente,

    -- fração do tempo da carga em REDUZIDO ou PAUSADO (0 a 1)
    div0(minutos_reduzido + minutos_pausado, duracao_min)             as pct_tempo_alerta

from sessoes
