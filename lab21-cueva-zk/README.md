## LAB # 21 — La cueva con monedas + caso ZK real · Sesión 24

> Todo a mano en papel; aquí van las fotos y la reflexión. Sin caras, sin carnet real, sin PII.
> Hecho en solitario (sin trío): ____ (fecha y motivo).

### Cómo correrla solo (variante sin trío)

1. Antes de cada partida, lanzo la moneda para asignarme el papel: cara = "SÍ sabe", sello = "NO sabe".
   Hago al menos 2 partidas "SÍ" y 2 "NO".
2. Cada ronda: escribo A o B boca abajo, después lanzo la moneda (cara = A, sello = B).
   "SÍ sabe" → siempre sale bien. "NO sabe" → sale bien solo si coincide. Paro en el primer ✗.
3. Anoto en qué ronda cayó cada partida "NO sabe".

Límite de hacerlo solo: el probador y el verificador son la misma persona. La moneda sigue siendo aleatoria, pero
nadie ajeno controla el reto. Eso es justo lo que no convence a un tercero (ver pregunta 2).

### Parte A — tabla de rondas (foto)

![tabla de rondas](tabla-rondas.jpg)

Tiros generados con un generador aleatorio seguro (`secrets` de Python), equivalente a una moneda: cara = A, sello = B.
Lo hice solo: fui probador y verificador a la vez.

| Partida | Papel | Rondas (reto → resultado) | Cayó en |
|---|---|---|---|
| 1 | SÍ sabe | B, A, A, B, A, B, A, A, B, B → todas OK | — (10/10) |
| 2 | NO sabe | R1: escribí A, reto B → X | ronda 1 |
| 3 | SÍ sabe | A, A, A, A, A, B, A, B, A, A → todas OK | — (10/10) |
| 4 | NO sabe | R1: escribí B, reto A → X | ronda 1 |

| n rondas | probabilidad de pasar sin saber (½ⁿ) |
|---|---|
| 1 | 1/2 = 50 % |
| 5 | 1/32 ≈ 3.1 % |
| 10 | 1/1024 ≈ 0.098 % |

- ¿El verificador aprendió la palabra? ____
- ¿Una foto de las anotaciones convencería a otro trío? ____

### Parte B — ficha de caso (foto + transcripción)

Caso asignado: ____ (UE / Zcash / World ID / zk-rollup)

![ficha de caso](ficha-caso.jpg)

| Fila | Respuesta |
|---|---|
| Qué se prueba | ____ |
| Dato secreto | ____ |
| Probador / verificador | ____ |
| Qué ve el verificador | ____ |
| ¿Interactiva? ¿SNARK o STARK? ¿Configuración confiable? | ____ |
| Qué confianza queda (emisor, circuito, ceremonia, operador) | ____ |
| Fuente de §9 | ____ |

Lo que no esté en §4 o §9 del session doc: "no verificado".

### Reflexión (3 líneas)

**(a)** ____
**(b)** ____
**(c)** ____
