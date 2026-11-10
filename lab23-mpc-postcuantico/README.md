## LAB # 23 — Promedio secreto con MPC + inventario post-cuántico (Remesas Volcán Prueba) · Sesión 26

> Todo a mano en papel; aquí van las fotos (A.2 y A.4) y la reflexión. Solo salarios ficticios
> (Q4,000–Q9,000). Nunca un salario o ingreso real. Sin caras ni PII.
> Hecho en solitario (sin trío): ____ (fecha y motivo).

### Cómo correrlo solo (variante sin trío)

Hago de las 3 personas (P1, P2, P3). Escribo 3 tarjetas con salarios ficticios, las volteo y las barajo sin verlas.
Por cada tarjeta: la miro, la parto en 3 piezas que sumen el salario (dos inventadas, pueden ser negativas;
la tercera = salario − las otras dos) y la vuelvo a voltear. Reparto las piezas en 3 columnas, sumo cada columna
(suma parcial), sumo las 3 parciales y divido entre 3. Al final volteo las tarjetas y compruebo.

Límite de hacerlo solo: yo vi las 3 tarjetas, así que el "nadie sabía ningún salario" aquí es simulado.
La aritmética y la colusión sí se pueden comprobar.

### A.2 Tabla del promedio secreto (foto)

![A.2](a2-promedio.jpg)

Salarios ficticios del session doc (A.1): Ana Q5,500 · Beto Q7,300 · Caro Q8,400. Piezas generadas al azar
(`secrets` de Python); lo hice solo, haciendo de las 3 personas.

- Ana: 4,400 + 3,100 + (−2,000) = 5,500
- Beto: (−2,700) + (−1,800) + 11,800 = 7,300
- Caro: 800 + 700 + 6,900 = 8,400

| Integrante | Pieza que se quedó | Pieza recibida 1 | Pieza recibida 2 | Suma parcial |
|---|---|---|---|---|
| Ana | 4,400 | −2,700 (de Beto) | 800 (de Caro) | 2,500 |
| Beto | −1,800 | 3,100 (de Ana) | 700 (de Caro) | 2,000 |
| Caro | 6,900 | −2,000 (de Ana) | 11,800 (de Beto) | 16,700 |

Total = 2,500 + 2,000 + 16,700 = **21,200** · Promedio = **7,066.67** · ¿Coincide con las tarjetas? Sí (5,500 + 7,300 + 8,400 = 21,200)

**Colusión (Ana + Beto contra Caro):** juntaron sus dos salarios y el total → Caro = 21,200 − 5,500 − 7,300 = **8,400**. ¿Correcto? Sí.

### A.4 Inventario post-cuántico (foto)

![A.4](a4-inventario.jpg)

| Elemento (de A.3) | Qué protege | Años secreto/válido | Riesgo | Tipo | Prioridad | Acción |
|---|---|---|---|---|---|---|
| ____ | ____ | ____ | alto/bajo | cosechar ahora / falsificar firma después / bajo | 1–3 | ____ |
| ____ | ____ | ____ | ____ | ____ | ____ | ____ |
| ____ | ____ | ____ | ____ | ____ | ____ | ____ |
| ____ | ____ | ____ | ____ | ____ | ____ | ____ |
| ____ | ____ | ____ | ____ | ____ | ____ | ____ |
| ____ | ____ | ____ | ____ | ____ | ____ | ____ |

Al menos una acción "borrar el dato" donde aplique. Cuándo llega la computadora cuántica: desconocido.

### Reflexión (3 líneas)

**(a)** ____
**(b)** ____
**(c)** ____
