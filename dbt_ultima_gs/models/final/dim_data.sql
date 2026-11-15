-- FINAL: calendário com um dia por linha, da primeira à última leitura.
-- Necessário para análises por dia, semana e mês e para funções de tempo no DAX (ex.: DATEADD).

with limites as (

    select
        min(data_hora)::date as data_inicio,
        max(data_hora)::date as data_fim
    from {{ ref('stg_leituras') }}

),

-- gera uma sequência de números (0, 1, 2, ...) para criar os dias
sequencia as (

    select row_number() over (order by seq4()) - 1 as n
    from table(generator(rowcount => 3660))

),

dias as (

    select dateadd(day, s.n, l.data_inicio) as data
    from sequencia s
    cross join limites l
    where dateadd(day, s.n, l.data_inicio) <= l.data_fim

)

select
    data,
    year(data)                      as ano,
    month(data)                     as mes,
    decode(month(data),
        1, 'Janeiro', 2, 'Fevereiro', 3, 'Março', 4, 'Abril', 5, 'Maio', 6, 'Junho',
        7, 'Julho', 8, 'Agosto', 9, 'Setembro', 10, 'Outubro', 11, 'Novembro', 12, 'Dezembro'
    )                               as nome_mes,
    day(data)                       as dia,
    dayofweekiso(data)              as dia_semana_num,      -- 1 = segunda ... 7 = domingo
    decode(dayofweekiso(data),
        1, 'Segunda', 2, 'Terça', 3, 'Quarta', 4, 'Quinta',
        5, 'Sexta', 6, 'Sábado', 7, 'Domingo'
    )                               as dia_semana,
    weekiso(data)                   as semana_ano,
    dayofweekiso(data) in (6, 7)    as fim_de_semana

from dias
