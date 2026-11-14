-- STG: cadastro dos carregadores com os tipos corretos e sem linhas duplicadas.

with fonte as (

    select * from {{ source('raw', 'carregadores') }}

)

select
    trim(id_carregador)                         as id_carregador,
    trim(id_dono)                               as id_dono,
    trim(bairro)                                as bairro,
    trim(cidade)                                as cidade,
    try_to_decimal(latitude, 9, 6)              as latitude,
    try_to_decimal(longitude, 9, 6)             as longitude,
    try_to_decimal(potencia_nominal_kw, 5, 2)   as potencia_nominal_kw,
    try_to_decimal(tarifa_kwh_brl, 10, 2)       as tarifa_kwh_brl,
    try_to_date(data_cadastro, 'YYYY-MM-DD')    as data_cadastro,
    _arquivo,
    _carregado_em

from fonte

-- se o mesmo carregador foi carregado mais de uma vez, fica só a carga mais recente
qualify row_number() over (partition by id_carregador order by _carregado_em desc) = 1
