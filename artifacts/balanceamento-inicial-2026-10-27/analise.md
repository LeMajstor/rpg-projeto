# Estudo de balanceamento inicial — 27/10/2026

## Estudo dos dois JSONs e nova referência — D78, 27/10/2026

**Meta solicitada:** no primeiro nível, monstros iniciais caem em 3–4 golpes e protagonista em 5–6. Atualiza a referência anterior de 4–5 recebidos de D70. Comparar inicialmente acertos normais; críticos podem encurtar e esquivas podem acrescentar tentativas. Os lotes restauram HP por amostra e não medem uma luta com ATB.

Fontes, escolhidas pelo horário interno de exportação: `exports/damage-lab/danos-execucao-003-seed-232-1000x.json` (aliado → monstro) e `danos-execucao-014-seed-214-1000x.json` (monstro → aliado). O primeiro nome está desatualizado: o conteúdo registra execução **12, semente 214**, não execução 3/semente 232. O segundo registra execução 14/semente 214. Conferência independente das 2000 amostras: dano, esquiva/crítico, HP/MP e resumos coerentes com as condições.

| Direção | ATQ efetivo / DEF alvo | HP do alvo | Dano normal | Crítico | Esquivas observadas |
| --- | --- | ---: | --- | --- | --- |
| Aliado → monstro | 52 / 40 | 40 | 26–32 (894 acertos) | 53–65 (88) | 18/1000 |
| Monstro → aliado | 35 / 55 | 50 | 12–15 (917 acertos) | 25–30 (36) | 47/1000 |

Aliado: ATQ próprio 42 + Bronze 10 = 52; DEF própria 45 + Bronze 10 = 55; HP 50, CRI 5 + arma 5% = 10%, EVA 5. Monstro: ATQ 35, DEF 40, HP 40, CRI 3%, EVA 3. Críticos 2× e variação ±10%. Atualmente o monstro cai em dois acertos normais ou um crítico; o aliado cai quase sempre em quatro acertos normais (cinco são possíveis com danos baixos).

**Recomendações para teste, sem aprovação de valores nem alteração de código/dados:**

| Campo | Experimento A: ajustar HP | Experimento B: preservar HP e reduzir ATQ |
| --- | ---: | ---: |
| HP do aliado | 70 | 50 |
| ATQ próprio do aliado | 42 (+10 = 52) | 20 (+10 = 30) |
| DEF própria do aliado | 45 (+10 = 55) | 45 (+10 = 55) |
| HP do monstro | 90 | 40 |
| ATQ do monstro | 35 | 29 |
| DEF do monstro | 40 | 40 |
| Dano normal aliado → monstro | 26–32: 3–4 acertos | 12–14: 3–4 acertos |
| Dano normal monstro → aliado | 12–15: 5–6 acertos | 9–11: 5–6 acertos |

Ambos mantêm armas, fórmula, variação, crítico e EVA do caso atual. A altera apenas dois HP; B mantém HP do caso atual e altera apenas os dois ataques. Esses exemplos usam 40 HP do monstro do JSON atual; não tornam esse valor definitivo nem substituem automaticamente a preferência histórica de 30 HP registrada em D68.

Cálculo de referência: `base = ATQ efetivo² / (ATQ efetivo + DEF efetiva do alvo)`, potência 1×. Considerar o arredondamento: para o monstro cair em 3–4 acertos normais, dois danos máximos precisam ficar abaixo do HP e quatro mínimos precisam alcançá-lo; conferir ainda se três golpes conseguem alcançar o HP para haver variação. Para o aliado cair em 5–6, quatro máximos devem ficar abaixo do HP e seis mínimos devem alcançá-lo; conferir a possibilidade de morte no quinto. Crítico/esquiva não podem garantir essas mesmas contagens em toda tentativa.

Distribuições teóricas adicionais, calculadas pela variação uniforme e chances configuradas, acumulando dano e sem cura/ATB: A exige em média **3,51 tentativas** contra o monstro e **5,91** contra o aliado; B, **3,57** e **5,51**. São estimativas matemáticas, não novas execuções do laboratório nem validação de uma batalha real. Estudo detalhado em `artifacts/balanceamento-inicial-2026-10-27/analise.md`.


## Distribuições teóricas

As probabilidades abaixo integram os intervalos de arredondamento da distribuição uniforme de dano. A cada tentativa, a esquiva é verificada antes do crítico. O HP acumula dano neste cálculo hipotético; o laboratório exportado restaura HP/MP por amostra. Assumem-se tentativas independentes, sem cura, ATB, efeitos ou respostas do outro participante.

### atual: aliado → monstro

```json
{
  "label": "atual: aliado → monstro",
  "attack": 52,
  "defense": 40,
  "target_hp": 40,
  "base": 29.391304347826086,
  "normal_damage": [
    26,
    32
  ],
  "critical_damage": [
    53,
    65
  ],
  "normal_hits": {
    "mean": 2.0,
    "percent_on_attempt": {
      "2": 100.0
    }
  },
  "all_attempts": {
    "mean": 1.95876,
    "percent_on_attempt": {
      "1": 9.7,
      "2": 84.972,
      "3": 5.09,
      "4": 0.229,
      "5": 0.009
    }
  }
}
```

### atual: monstro → aliado

```json
{
  "label": "atual: monstro → aliado",
  "attack": 35,
  "defense": 55,
  "target_hp": 50,
  "base": 13.61111111111111,
  "normal_damage": [
    12,
    15
  ],
  "critical_damage": [
    25,
    30
  ],
  "normal_hits": {
    "mean": 4.00121,
    "percent_on_attempt": {
      "4": 99.879,
      "5": 0.121
    }
  },
  "all_attempts": {
    "mean": 4.11892,
    "percent_on_attempt": {
      "2": 0.081,
      "3": 7.407,
      "4": 75.372,
      "5": 15.046,
      "6": 1.886,
      "7": 0.189,
      "8": 0.017,
      "9": 0.001
    }
  }
}
```

### HP ajustado: aliado → monstro

```json
{
  "label": "HP ajustado: aliado → monstro",
  "attack": 52,
  "defense": 40,
  "target_hp": 90,
  "base": 29.391304347826086,
  "normal_damage": [
    26,
    32
  ],
  "critical_damage": [
    53,
    65
  ],
  "normal_hits": {
    "mean": 3.66332,
    "percent_on_attempt": {
      "3": 33.668,
      "4": 66.332
    }
  },
  "all_attempts": {
    "mean": 3.50901,
    "percent_on_attempt": {
      "2": 7.51,
      "3": 40.3,
      "4": 46.416,
      "5": 5.353,
      "6": 0.396,
      "7": 0.024,
      "8": 0.001
    }
  }
}
```

### HP ajustado: monstro → aliado

```json
{
  "label": "HP ajustado: monstro → aliado",
  "attack": 35,
  "defense": 55,
  "target_hp": 70,
  "base": 13.61111111111111,
  "normal_damage": [
    12,
    15
  ],
  "critical_damage": [
    25,
    30
  ],
  "normal_hits": {
    "mean": 5.75962,
    "percent_on_attempt": {
      "5": 24.038,
      "6": 75.962
    }
  },
  "all_attempts": {
    "mean": 5.91214,
    "percent_on_attempt": {
      "3": 0.067,
      "4": 2.797,
      "5": 24.754,
      "6": 54.069,
      "7": 15.299,
      "8": 2.624,
      "9": 0.346,
      "10": 0.039,
      "11": 0.004
    }
  }
}
```

### ATQ ajustado: aliado → monstro

```json
{
  "label": "ATQ ajustado: aliado → monstro",
  "attack": 30,
  "defense": 40,
  "target_hp": 40,
  "base": 12.857142857142858,
  "normal_damage": [
    12,
    14
  ],
  "critical_damage": [
    23,
    28
  ],
  "normal_hits": {
    "mean": 3.73032,
    "percent_on_attempt": {
      "3": 26.968,
      "4": 73.032
    }
  },
  "all_attempts": {
    "mean": 3.57092,
    "percent_on_attempt": {
      "2": 6.456,
      "3": 36.801,
      "4": 50.428,
      "5": 5.853,
      "6": 0.434,
      "7": 0.026,
      "8": 0.001
    }
  }
}
```

### ATQ ajustado: monstro → aliado

```json
{
  "label": "ATQ ajustado: monstro → aliado",
  "attack": 29,
  "defense": 55,
  "target_hp": 50,
  "base": 10.011904761904763,
  "normal_damage": [
    9,
    11
  ],
  "critical_damage": [
    18,
    22
  ],
  "normal_hits": {
    "mean": 5.36249,
    "percent_on_attempt": {
      "5": 63.751,
      "6": 36.249
    }
  },
  "all_attempts": {
    "mean": 5.51191,
    "percent_on_attempt": {
      "3": 0.14,
      "4": 5.861,
      "5": 48.787,
      "6": 34.933,
      "7": 8.665,
      "8": 1.411,
      "9": 0.181,
      "10": 0.02,
      "11": 0.002
    }
  }
}
```
