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


