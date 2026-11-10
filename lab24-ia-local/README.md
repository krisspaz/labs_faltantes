## LAB # 24

> Mediciones con el cronómetro del teléfono. Hecho en solitario: hago de Operador, Cronometrista y Juez, y califico la calidad antes de mirar los tiempos. Si algo no se pudo medir: «no se pudo» y por qué. Sin datos personales ni caras.

### A.1 Ficha del equipo

| Dato | Equipo 1 | Equipo 2 (si tienen) |
|---|---|---|
| Tipo (laptop / teléfono) y modelo | Laptop, MacBook Pro (Mac15,6), Apple M3 Pro | — (solo un equipo) |
| Sistema (macOS / Windows / Linux / iOS / Android) | macOS | — (solo un equipo) |
| Memoria total (RAM, GB) | 18 | — (solo un equipo) |
| L1: nombre exacto en la app y tamaño (B) | medpsy-4b-q4_k_m-imat, 4B | — (solo un equipo) |
| L1: memoria a 4 bits (§4.4) | 4 × 4 ÷ 8 = 2 GB (≈ 2.4–2.6 GB con margen) | — (solo un equipo) |
| L2: nombre exacto en la app y tamaño (B) | Qwen3.5-9B-Q4_K_M, 9B | — (solo un equipo) |
| L2: memoria a 4 bits (§4.4) | 9 × 4 ÷ 8 = 4.5 GB (≈ 5.4–5.9 GB con margen) | — (solo un equipo) |
| ¿Caben? (sí / justo / no) | Sí, los dos (18 GB de RAM) | — (solo un equipo) |
| Chat en la nube usado (N) | No se midió (ver nota en A.3) | — (solo un equipo) |

Cuenta de memoria: GB ≈ parámetros (en miles de millones) × 4 ÷ 8, más 20–30 % de margen.
Ejemplos: 1B → 0.5 GB · 2B → 1 GB · 4B → 2 GB · 8B → 4 GB (más margen en cada caso).

### Predicción (antes de medir)

- Más rápido: ____ porque ____
- Mejores respuestas: ____ porque ____

### A.2 Las tres instrucciones (copiar exactas, una conversación nueva por cada una)

1. **Resumir:** Resume en 3 viñetas, en español, este aviso: "La cooperativa Agro Cuchumatanes Prueba informa que la entrega de semillas de maíz se mueve del lunes 3 al jueves 6 por la lluvia. Traigan su tarjeta de socio. Quien no pueda llegar puede mandar a un familiar con una nota firmada. El fertilizante se entrega el mismo día, solo a socios al día con su cuota."
2. **Calcular:** Un modelo tiene 8 mil millones de parámetros y está cuantizado a 4 bits. ¿Cuántos GB de memoria necesita, aproximadamente, sin contar el margen? Explica la cuenta en dos líneas.
3. **Redactar:** Escribe un mensaje corto de WhatsApp (máximo 60 palabras), amable y en español de Guatemala, para avisarle a un cliente ficticio de Remesas Volcán Prueba que su envío está listo para recoger en agencia y que debe llevar su documento de identificación.

### A.3 Tabla de medición

Instrucciones exactas de A.2 (una conversación nueva por cada una; L1 y L2 sin internet).

| Config. | Instrucción | Primera palabra (s) | Total (s) | Tokens/s | Calidad (1–5) | Nota |
|---|---|---|---|---|---|---|
| L1 | 1 | no se pudo | no se pudo | no se pudo | — | ver nota |
| L1 | 2 | no se pudo | no se pudo | no se pudo | — | ver nota |
| L1 | 3 | no se pudo | no se pudo | no se pudo | — | ver nota |
| L2 | 1 | no se pudo | no se pudo | no se pudo | — | ver nota |
| L2 | 2 | no se pudo | no se pudo | no se pudo | — | ver nota |
| L2 | 3 | no se pudo | no se pudo | no se pudo | — | ver nota |
| N | 1 | no se pudo | no se pudo | no se pudo | — | ver nota |
| N | 2 | no se pudo | no se pudo | no se pudo | — | ver nota |
| N | 3 | no se pudo | no se pudo | no se pudo | — | ver nota |

**Nota: por qué no se pudo medir.** El modelo pequeño («Sencillo») no terminó ni siquiera una respuesta corta: a las 9:59 p. m. seguía en «Thinking…» con una instrucción enviada a las 7:29 p. m. (captura 02), y según mi cronómetro estuvo unas **5 horas** sin terminar. El asistente «QV.AC» pensó **154 s** y luego falló al correr un comando (captura 01). Con esos tiempos no pude completar las 9 corridas de A.2, y la nube no se midió.

Ganador en velocidad: no se pudo determinar con A.2 (en la prueba extra, «QV.AC» respondió en ~154 s y «Sencillo» no terminó en ~5 h) · Ganador en calidad: no se pudo calificar · ¿Acertó la predicción? no aplica

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
| L1 | 1 / 2 / 3 | Sin respuesta de A.2 que calificar |
| L2 | 1 / 2 / 3 | Sin respuesta de A.2 que calificar |
| N | 1 / 2 / 3 | No se midió |

### Reflexión (3 líneas)

**(a)** No pude completar la medición: el modelo local pequeño estuvo ~5 h «pensando» sin terminar, y el asistente «QV.AC» tardó 154 s y además dijo que guardó un archivo cuando el comando había fallado. En mi equipo (M3 Pro, 18 GB), la IA local fue demasiado lenta para usarla en clase.

**(b)** Con lo que vi, el modelo local pequeño no me bastaría ni para tareas cortas de mi venture, porque no terminó una respuesta. Tampoco me fiaría de él para nada que no pueda tener errores: el otro asistente afirmó un éxito que no ocurrió.

**(c)** Sin internet, solo mi dispositivo vio mis instrucciones (la instrucción no sale), aunque la app puede mandar estadísticas y vale revisarlo. En la nube las vio la empresa que corre el modelo (instrucción, respuesta, cuándo y desde dónde) y puede guardarlas según sus términos; un gobierno podría pedirle esos registros (§4.6).

### Evidencia (capturas de la app QV.AC, 3 nov 2026)

Prueba extra fuera de A.2 con la instrucción «dame una calculadora en python que sea como una calculadora científica».

- [01-qvac-calculadora.png](evidencia/01-qvac-calculadora.png) — 7:33 p. m.: el asistente «QV.AC» pensó 154 s, intentó correr un comando que falló («Couldn't run a command») y aun así dijo que «el archivo se guardó con éxito» antes de listar las funciones.
- [02-sencillo-pensando.png](evidencia/02-sencillo-pensando.png) — 9:59 p. m.: el asistente «Sencillo» (modelo pequeño), con la misma instrucción enviada a las 7:29 p. m., seguía en «Thinking…» después de unas 2.5 horas.
