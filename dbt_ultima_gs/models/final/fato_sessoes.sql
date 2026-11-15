-- FINAL: fato de sessões (1 linha por carga).
-- Base para receita, ticket médio, duração das cargas, pausas e tempo em alerta.

select
    id_sessao,
    id_carregador,
    id_usuario,
    inicio::date            as data,          -- liga com dim_data
    hour(inicio)            as hora_inicio,   -- para análise por horário
    inicio,
    fim,
    status_sessao,
    valor_pago_brl,
    tarifa_kwh_brl,
    kwh_pago,
    kwh_entregue,
    kwh_excedente,
    duracao_min,
    minutos_normal,
    minutos_reduzido,
    minutos_pausado,
    pct_tempo_alerta,
    qtd_pausas,
    temperatura_max_c,
    temperatura_media_c,
    qtd_leituras

from {{ ref('int_sessoes') }}
