-- FINAL: dimensão de carregadores (filtros por carregador, bairro e dono no Power BI).

select
    id_carregador,
    id_dono,
    bairro,
    cidade,
    latitude,
    longitude,
    potencia_nominal_kw,
    tarifa_kwh_brl,
    data_cadastro,
    id_carregador || ' - ' || bairro    as carregador_bairro   -- rótulo amigável para gráficos

from {{ ref('stg_carregadores') }}
