## LAB # 24

> Plantilla prellenada. Lo que va como `____` lo lleno con mediciones reales (cronómetro del teléfono). Hecho en solitario: hago de Operador, Cronometrista y Juez, y califico la calidad antes de mirar los tiempos. Si algo no se pudo medir: «no se pudo» y por qué. Sin datos personales ni caras.

### A.1 Ficha del equipo

| Dato | Equipo 1 | Equipo 2 (si tienen) |
|---|---|---|
| Tipo (laptop / teléfono) y modelo | Laptop, MacBook Pro (Mac15,6), Apple M3 Pro | ____ |
| Sistema (macOS / Windows / Linux / iOS / Android) | macOS | ____ |
| Memoria total (RAM, GB) | 18 | ____ |
| L1: nombre exacto en la app y tamaño (B) | medpsy-4b-q4_k_m-imat, 4B | ____ |
| L1: memoria a 4 bits (§4.4) | 4 × 4 ÷ 8 = 2 GB (≈ 2.4–2.6 GB con margen) | ____ GB |
| L2: nombre exacto en la app y tamaño (B) | Qwen3.5-9B-Q4_K_M, 9B | ____ |
| L2: memoria a 4 bits (§4.4) | 9 × 4 ÷ 8 = 4.5 GB (≈ 5.4–5.9 GB con margen) | ____ GB |
| ¿Caben? (sí / justo / no) | Sí, los dos (18 GB de RAM) | ____ |
| Chat en la nube usado (N) | ____ | ____ |

Cuenta de memoria: GB ≈ parámetros (en miles de millones) × 4 ÷ 8, más 20–30 % de margen.
Ejemplos: 1B → 0.5 GB · 2B → 1 GB · 4B → 2 GB · 8B → 4 GB (más margen en cada caso).

### Predicción (antes de medir)

- Más rápido: ____ porque ____
- Mejores respuestas: ____ porque ____

### A.3 Tabla de medición

Instrucciones exactas de A.2 (una conversación nueva por cada una; L1 y L2 sin internet).

| Config. | Instrucción | Primera palabra (s) | Total (s) | Tokens/s | Calidad (1–5) | Nota |
|---|---|---|---|---|---|---|
| L1 | 1 | ____ | ____ | ____ / no muestra | ____ | ____ |
| L1 | 2 | ____ | ____ | ____ / no muestra | ____ | ____ |
| L1 | 3 | ____ | ____ | ____ / no muestra | ____ | ____ |
| L2 | 1 | ____ | ____ | ____ / no muestra | ____ | ____ |
| L2 | 2 | ____ | ____ | ____ / no muestra | ____ | ____ |
| L2 | 3 | ____ | ____ | ____ / no muestra | ____ | ____ |
| N | 1 | ____ | ____ | ____ / no muestra | ____ | ____ |
| N | 2 | ____ | ____ | ____ / no muestra | ____ | ____ |
| N | 3 | ____ | ____ | ____ / no muestra | ____ | ____ |

Ganador en velocidad: ____ · Ganador en calidad: ____ · ¿Acertó la predicción? ____

### A.4 Rúbrica de calidad (el Juez califica sin mirar los tiempos)

| Puntaje | Qué significa |
|---|---|
| 5 | Correcta, completa, clara y en buen español; la usarían tal cual |
| 4 | Correcta, con un detalle menor; la usarían con un retoque |
| 3 | Útil pero incompleta, o con un error que se nota |
| 2 | Errores importantes, inventa datos o no sigue la instrucción (más de 3 viñetas o más de 60 palabras) |
| 1 | Incorrecta, sin sentido, en otro idioma o no respondió |

Qué revisar:
- **Instrucción 1:** jueves 6, tarjeta de socio, familiar con nota firmada, fertilizante solo a socios al día.
- **Instrucción 2:** clave 8 × 4 ÷ 8 = **4 GB** (≈ 5 GB con margen). Otra cifra no pasa de 2.
- **Instrucción 3:** máximo 60 palabras, tono amable y guatemalteco, sin inventar montos ni direcciones.

Razón corta por respuesta:

| Config. | Instr. | Razón de la calificación |
|---|---|---|
| L1 | 1 / 2 / 3 | ____ |
| L2 | 1 / 2 / 3 | ____ |
| N | 1 / 2 / 3 | ____ |

### Reflexión (3 líneas)

**(a)** Ganó en velocidad ____ y en calidad ____, por ____ s y ____ puntos. Mi predicción ____ (acertó / falló) porque ____.

**(b)** El modelo local más pequeño que probé (____) bastaría para ____ de mi venture (por ejemplo, tareas cortas y repetitivas como resumir avisos), pero no para ____ (por ejemplo, cálculos o textos que no pueden tener errores).

**(c)** Sin internet, solo mi dispositivo vio mis instrucciones (la instrucción no sale), aunque la app puede mandar estadísticas y vale revisarlo. En la nube las vio la empresa que corre el modelo (instrucción, respuesta, cuándo y desde dónde) y puede guardarlas según sus términos; un gobierno podría pedirle esos registros (§4.6).

### Evidencia (capturas de la app QV.AC, 3 nov 2026)

Prueba extra fuera de A.2 con la instrucción «dame una calculadora en python que sea como una calculadora científica».

- [01-qvac-calculadora.png](evidencia/01-qvac-calculadora.png) — 7:33 p. m.: el asistente «QV.AC» pensó 154 s, intentó correr un comando que falló («Couldn't run a command») y aun así dijo que «el archivo se guardó con éxito» antes de listar las funciones.
- [02-sencillo-pensando.png](evidencia/02-sencillo-pensando.png) — 9:59 p. m.: el asistente «Sencillo» (modelo pequeño), con la misma instrucción enviada a las 7:29 p. m., seguía en «Thinking…» después de unas 2.5 horas.
