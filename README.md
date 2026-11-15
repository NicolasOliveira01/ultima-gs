# ultima-gs · Big Data e visualização

Global Solution 2026/2 · CitizenTech

## Ideia do projeto

Plataforma para **donos de carregadores de carro elétrico compartilharem o carregador** com outros
motoristas e serem pagos por isso. O motorista paga pelo app e o carregador entrega a energia
equivalente ao valor pago.

Cada carregador tem um **sistema embarcado** (Arduino/Tinkercad) que mede a energia entregue, corta a
carga quando o valor pago é atingido e **reduz ou pausa a carga se o conector superaquecer**.

**Nesta área**, os dados gerados pelos carregadores são organizados e transformados em indicadores para:

- **o dono:** acompanhar faturamento e horários de maior uso;
- **a plataforma:** identificar carregadores com superaquecimento que precisam de manutenção.

## Origem dos dados

Os dados são **simulados (mock)**, pois o Tinkercad não se conecta à internet. Eles seguem **a mesma
lógica do código do Arduino**. Na solução real, viriam dos carregadores pela internet.

| Arquivo | Conteúdo | Linhas |
|---|---|---|
| `csv/leituras_carregador.csv` | 1 linha por ciclo do carregador: temperatura, estado, potência e energia entregue | 20.000 |
| `csv/carregadores.csv` | cadastro dos carregadores: bairro, dono, tarifa e potência | 8 |


## Colunas

### `leituras_carregador.csv` (1 linha por ciclo do carregador)

| Coluna | Descrição |
|---|---|
| `id_leitura` | identificador único da leitura |
| `id_sessao` | sessão de carga (do pagamento até o fim da carga) |
| `id_carregador` | carregador que gerou a leitura |
| `id_usuario` | motorista que pagou pela carga |
| `data_hora` | momento da leitura (cada ciclo = 6 min de carga simulados) |
| `volta` | número do ciclo dentro da sessão (0 = momento do pagamento) |
| `intervalo_ms` | tempo real desde a leitura anterior, em milissegundos |
| `valor_pago_brl` | valor pago no app (R$); repete em todas as leituras da sessão |
| `tarifa_kwh_brl` | preço do kWh definido pelo dono (R$) |
| `kwh_pago` | energia comprada: valor pago ÷ tarifa |
| `leitura_pot_adc` | valor bruto do sensor de potência (0 a 1023) |
| `leitura_temp_adc` | valor bruto do sensor de temperatura (0 a 1023) |
| `temperatura_c` | temperatura do conector em °C |
| `estado` | proteção térmica: `NORMAL`, `REDUZIDO` ou `PAUSADO` |
| `potencia_pedida_kw` | potência que o carro está puxando (kW) |
| `potencia_entregue_kw` | potência entregue após a proteção térmica (100%, 50% ou 0) |
| `energia_intervalo_kwh` | energia entregue neste ciclo: potência × tempo |
| `kwh_entregue` | energia acumulada na sessão até esta leitura |
| `led_status` | LED aceso: `VERDE`, `AMARELO` ou `VERMELHO` |
| `rele` | `LIGADO` (energia liberada) ou `DESLIGADO` (energia cortada) |
| `carga_concluida` | `true` na leitura em que a energia paga foi atingida |

### `carregadores.csv` (1 linha por carregador)

| Coluna | Descrição |
|---|---|
| `id_carregador` | identificador do carregador |
| `id_dono` | dono do carregador (um dono pode ter mais de um) |
| `bairro` / `cidade` | localização do carregador |
| `latitude` / `longitude` | coordenadas aproximadas (para mapa) |
| `potencia_nominal_kw` | potência máxima do carregador (7,4 ou 3,7 kW) |
| `tarifa_kwh_brl` | preço do kWh cobrado pelo dono (R$) |
| `data_cadastro` | data em que o carregador entrou na plataforma |

# Caminho do cado

## CSV → Stage

Primeira etapa da ingestão: os CSVs são enviados do computador para o **stage** `ULTIMA_GS.RAW.STAGE_IOT`,
uma área de arquivos dentro do Snowflake que funciona como "caixa de entrada". Isso simula o carregador
enviando seus dados para a nuvem.

O envio é feito pela macro dbt [`subir_arquivos_stage`](dbt_ultima_gs/macros/subir_arquivos_stage.sql),
que executa um `PUT` para cada arquivo da pasta `csv/`. Os arquivos são compactados (`.gz`) e, se já
existirem no stage, substituídos.

```powershell
cd dbt_ultima_gs
dbt run-operation subir_arquivos_stage
```

Para conferir no Snowflake: `list @ultima_gs.raw.stage_iot;`

> Nesta etapa os dados ainda **não estão em tabelas**: apenas os arquivos chegaram ao stage.

## Stage → Source

Segunda etapa da ingestão: os arquivos do stage são carregados nas tabelas da camada **RAW**
(`RAW.LEITURAS_CARREGADOR` e `RAW.CARREGADORES`). Elas são a **source** do dbt, ou seja, o ponto de
partida das transformações.

A carga é feita pela macro [`copiar_stage_para_raw`](dbt_ultima_gs/macros/copiar_stage_para_raw.sql),
que executa um `COPY INTO` para cada tabela. Os dados entram **exatamente como estão no CSV** (tudo
como texto) e cada linha recebe duas colunas de auditoria:

| Coluna | Conteúdo |
|---|---|
| `_arquivo` | arquivo de origem da linha |
| `_carregado_em` | data e hora da carga |

```powershell
cd dbt_ultima_gs
dbt run-operation copiar_stage_para_raw
```

> O Snowflake registra os arquivos já carregados: executar de novo com os mesmos arquivos **não duplica** os dados.

## Source → STG

Primeira camada de transformação, feita com **models do dbt** em
[`models/staging`](dbt_ultima_gs/models/staging). Os models leem as tabelas RAW (source) e criam
**views** no schema `STG`:

| Model | Origem | Conteúdo |
|---|---|---|
| `stg_leituras` | `RAW.LEITURAS_CARREGADOR` | leituras dos carregadores |
| `stg_carregadores` | `RAW.CARREGADORES` | cadastro dos carregadores |

O que muda em relação à RAW:

- **Tipos corretos:** texto vira número, data ou verdadeiro/falso. As funções `try_` transformam
  valores inválidos em nulo em vez de interromper o processamento.
- **Padronização:** espaços removidos e textos em maiúsculas; `rele` vira `rele_ligado` (verdadeiro/falso).
- **Sem duplicidade:** se a mesma linha for carregada mais de uma vez, fica só a carga mais recente.
- **Testes:** `unique` e `not_null` garantem que cada leitura e cada carregador aparecem uma única vez.

```powershell
cd dbt_ultima_gs
dbt build --select staging
```

## STG → INT

Camada de **regras de negócio**, em [`models/intermediate`](dbt_ultima_gs/models/intermediate). O model
`int_sessoes` agrupa as leituras da `stg_leituras` e gera **uma linha por sessão de carga** (view no schema `INT`).

**Por que é necessário:** cada carga tem cerca de 50 leituras, e o valor pago se repete em todas.
Somar a receita direto nas leituras multiplicaria o valor. Agrupando por sessão, cada carga é contada uma vez.

| Coluna | Regra |
|---|---|
| `inicio` / `fim` / `duracao_min` | primeira e última leitura; duração em minutos de carga simulados |
| `valor_pago_brl` | valor da sessão, contado uma única vez |
| `kwh_pago` / `kwh_entregue` | energia comprada e energia efetivamente entregue |
| `minutos_normal` / `minutos_reduzido` / `minutos_pausado` | tempo da carga em cada estado da proteção térmica |
| `pct_tempo_alerta` | fração do tempo em REDUZIDO ou PAUSADO (0 a 1) |
| `qtd_pausas` | quantas vezes a carga **entrou** em PAUSADO (eventos de superaquecimento) |
| `temperatura_max_c` / `temperatura_media_c` | temperatura máxima e média do conector na carga |
| `kwh_excedente` | energia entregue além da paga (o último ciclo passa um pouco do limite) |
| `status_sessao` | `CONCLUIDA` ou `EM_ANDAMENTO` |

```powershell
cd dbt_ultima_gs
dbt build --select intermediate
```

## INT → FINAL

Camada consumida pelo **Power BI**, em [`models/final`](dbt_ultima_gs/models/final). Os dados são
organizados em **tabelas fato e dimensão** (modelo estrela), criadas como **tabelas** no schema `FINAL`
para o dashboard consultar mais rápido.

| Tabela | Tipo | 1 linha por | Uso no dashboard |
|---|---|---|---|
| `fato_sessoes` | fato | carga | receita, ticket médio, duração, pausas e tempo em alerta |
| `fato_leituras` | fato | ciclo do carregador | temperatura e estado ao longo do tempo |
| `dim_carregador` | dimensão | carregador | filtros por carregador, bairro e dono |
| `dim_data` | dimensão | dia | filtros por dia, semana e mês; funções de tempo no DAX |

```
                ┌──────────────┐
                │   dim_data   │
                └──────────────┘
                  1 │      │ 1
          ┌─────────┘      └─────────┐
        N │                          │ N
┌──────────────┐               ┌──────────────┐
│ fato_sessoes │               │ fato_leituras│
└──────────────┘               └──────────────┘
        N │                          │ N
          └─────────┐      ┌─────────┘
                  1 │      │ 1
              ┌──────────────────┐
              │  dim_carregador  │
              └──────────────────┘
```

- O **valor pago fica só na `fato_sessoes`**. Na `fato_leituras` ele se repetiria e duplicaria a receita.
- As fatos têm `data` (para ligar com o calendário) e `hora` (para análise por horário).
- A `dim_data` traz nome do mês, dia da semana e indicador de fim de semana em português.
- **Testes** garantem chaves únicas e que todo carregador, data e sessão das fatos existe na tabela relacionada.

```powershell
cd dbt_ultima_gs
dbt build --select final
```
