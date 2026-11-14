-- =====================================================================
-- ULTIMA_GS - setup do Snowflake
-- Cria warehouse, database, schemas das camadas, file format, stage
-- e as tabelas da camada RAW. Pode ser executado mais de uma vez.
-- =====================================================================

use role sysadmin;

-- ---------------------------------------------------------------------
-- 1. Warehouse (processamento) - pequeno e com auto-suspend para economizar
-- ---------------------------------------------------------------------
create warehouse if not exists wh_ultima_gs
    warehouse_size = 'XSMALL'
    auto_suspend   = 60          -- desliga após 60 s sem uso
    auto_resume    = true
    initially_suspended = true;

use warehouse wh_ultima_gs;

-- ---------------------------------------------------------------------
-- 2. Database e schemas (uma camada por schema)
-- ---------------------------------------------------------------------
create database if not exists ultima_gs;
use database ultima_gs;

create schema if not exists raw;     -- dado bruto, exatamente como chegou do IoT
create schema if not exists stg;     -- dado limpo e tipado (dbt)
create schema if not exists int;     -- regras de negócio / agregações (dbt)
create schema if not exists final;   -- tabelas fato e dimensão para o Power BI (dbt)

use schema raw;

-- ---------------------------------------------------------------------
-- 3. File format dos CSVs
-- ---------------------------------------------------------------------
create file format if not exists raw.ff_csv
    type                         = csv
    field_delimiter              = ','
    skip_header                  = 1
    field_optionally_enclosed_by = '"'
    encoding                     = 'UTF8'
    empty_field_as_null          = true
    null_if                      = ('', 'NULL');

-- ---------------------------------------------------------------------
-- 4. Stage interno: "caixa de entrada" onde o gateway IoT deposita os arquivos
-- ---------------------------------------------------------------------
create stage if not exists raw.stage_iot
    file_format = raw.ff_csv
    comment     = 'Arquivos enviados pelos carregadores (simulação do gateway IoT)';

-- ---------------------------------------------------------------------
-- 5. Tabelas RAW: tudo varchar (a conversão de tipos é feita na STG)
--    + colunas de auditoria (_arquivo, _carregado_em)
-- ---------------------------------------------------------------------
create table if not exists raw.leituras_carregador (
    id_leitura            varchar,
    id_sessao             varchar,
    id_carregador         varchar,
    id_usuario            varchar,
    data_hora             varchar,
    volta                 varchar,
    intervalo_ms          varchar,
    valor_pago_brl        varchar,
    tarifa_kwh_brl        varchar,
    kwh_pago              varchar,
    leitura_pot_adc       varchar,
    leitura_temp_adc      varchar,
    temperatura_c         varchar,
    estado                varchar,
    potencia_pedida_kw    varchar,
    potencia_entregue_kw  varchar,
    energia_intervalo_kwh varchar,
    kwh_entregue          varchar,
    led_status            varchar,
    rele                  varchar,
    carga_concluida       varchar,
    _arquivo              varchar,
    _carregado_em         timestamp_ntz default current_timestamp()
)
comment = 'Leituras enviadas pelos carregadores (1 linha por ciclo do Arduino)';

create table if not exists raw.carregadores (
    id_carregador       varchar,
    id_dono             varchar,
    bairro              varchar,
    cidade              varchar,
    latitude            varchar,
    longitude           varchar,
    potencia_nominal_kw varchar,
    tarifa_kwh_brl      varchar,
    data_cadastro       varchar,
    _arquivo            varchar,
    _carregado_em       timestamp_ntz default current_timestamp()
)
comment = 'Cadastro dos carregadores (vem do app)';

-- ---------------------------------------------------------------------
-- 6. Conferência
-- ---------------------------------------------------------------------
show schemas in database ultima_gs;
show tables  in schema   ultima_gs.raw;
show stages  in schema   ultima_gs.raw;
