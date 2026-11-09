# Breathing Toolbox

Toolbox em MATLAB para análise do movimento da caixa torácica e do abdome durante a respiração, a partir de marcadores reflexivos (captura de movimento). A partir das coordenadas dos marcadores, calcula volumes, variáveis de coordenação e variáveis temporais de cada ciclo respiratório e gera animações geométricas do movimento.

## Visão geral do fluxo

1. Formato de entrada
2. Pré-processamento dos dados
3. Cálculo do volume
4. Corte dos ciclos respiratórios
5. Cálculo das variáveis
6. Visualização geométrica

---

## 1º Passo - Formato de entrada

Formatos aceitos:

- `.c3d`
- `.txt` (com cabeçalho), lido pela função `Import89.m`
- `.xls`

**Informação de entrada necessária:** frequência de amostragem do sinal.

## 2º Passo - Pré-processamento dos dados

- **Verificação da ordem dos marcadores:** a matriz de entrada precisa ter os marcadores nomeados na sequência correta. Uma forma de checar é fazer uma verificação gráfica antes da análise (ver as figuras dos modelos abaixo).
- **Checagem de NaN e interpolação:** valores ausentes são identificados e o sinal é interpolado, quando necessário.
- **Filtragem do sinal:** a frequência de corte pode ser definida de três formas:
  - a critério do usuário;
  - com um valor padrão pré-estabelecido (simplifica o uso por pessoas leigas);
  - por análise espectral, usando o valor sugerido pela função `Analise_espectral_filtro.m`.

## 3º Passo - Cálculo do volume

Para o cálculo, os marcadores devem estar nomeados seguindo a ordem das imagens (verificado no passo anterior).

| Modelo | Método | Função | Observação |
|---|---|---|---|
| 32 marcadores | Tetraedros | `volume_32.m` | |
| 89 marcadores | Prisma | `volume_89.m` | marcadores nomeados de 0 a 88 |

> Adicione aqui as figuras dos modelos (por exemplo em `docs/modelo_32.png`, `docs/modelo_89_frente.png` e `docs/modelo_89_costas.png`) e referencie com `![Modelo 32 marcadores](docs/modelo_32.png)`.

## 4º Passo - Corte dos ciclos respiratórios

Os ciclos respiratórios são cortados de mínimo a mínimo pela função `corte.m`, que tem duas saídas:

- ciclo respiratório **normalizado**;
- ciclo respiratório **não normalizado**.

Usar um ou outro é importante na etapa seguinte.

## 5º Passo - Cálculo das variáveis

### Volume (`var_derived_volume.m`)

Pode ser calculado a partir do ciclo normalizado ou do não normalizado.

- Tidal volume inspiratório
- Percentual de contribuição inspiratório
- Percentual de contribuição da caixa torácica

### Coordenação (`var_derived_phaseangle.m`)

Calculada usando o **ciclo médio**. Isso aproxima a curva de um padrão senoidal e reduz a chance de ruído no sinal, que poderia ser interpretado como uma mudança de fase aparente entre inspiração e expiração.

- Phase angle

### Temporais (`var_derived_time.m`)

Calculadas a partir do ciclo **não normalizado**.

- Tempo total do ciclo
- Tempo inspiratório
- Tempo inspiratório / tempo total
- Defasagem dos picos respiratórios (Tlag), em frames
- Tlag em relação ao tempo total do ciclo e em graus

## 6º Passo - Visualização geométrica

- Animação do movimento de 32 marcadores em `.mp4`: `create_animation.m`
- Animação do movimento de 89 marcadores em `.mp4`: **a fazer**

---

## Resumo das funções

| Função | Etapa | Descrição |
|---|---|---|
| `Import89.m` | Entrada | Importa arquivos `.txt` com cabeçalho |
| `Analise_espectral_filtro.m` | Pré-processamento | Análise espectral para escolha da frequência de filtragem |
| `volume_32.m` | Volume | Volume pelo método dos tetraedros (32 marcadores) |
| `volume_89.m` | Volume | Volume pelo método do prisma (89 marcadores) |
| `corte.m` | Ciclos | Corte dos ciclos de mínimo a mínimo (normalizado e não normalizado) |
| `var_derived_volume.m` | Variáveis | Tidal volume e percentuais de contribuição |
| `var_derived_phaseangle.m` | Variáveis | Phase angle (coordenação) |
| `var_derived_time.m` | Variáveis | Variáveis temporais e Tlag |
| `create_animation.m` | Visualização | Animação `.mp4` do modelo de 32 marcadores |


