## LAB # 20 — Global Chess Passport (Algorand + World Chess) · Sesión 23


### A.1 Encabezado

| Campo | Respuesta |
|---|---|
| Integrante | Kristopher Paz (individual, sin trío) |
| Caso | Algorand + World Chess — Global Chess Passport |
| Estado real | **Hecho:** whitepaper publicado el 24 abr 2025 [2][3]; alianza renovada por 2 años el 21 oct 2025, con el GCP anunciado como *próximo* y basado en Rocca [4][5]; repo de demo Apache-2.0 con datos *mock* y DID `did:key` [6]. La página oficial dice que está "en desarrollo a pequeña escala para probar su factibilidad" [1]. **Promesa:** emisores como FIDE, Chess.com o Lichess, el anclaje on-chain y la divulgación selectiva. No hay lanzamiento público, cifras de usuarios ni adopción por la FIDE. |

### A.2 Sección 1 — Triángulo

| Credencial | Emisor | Holder | Verificador |
|---|---|---|---|
| "Rating ≥ 2000" | World Chess (el único emisor comprometido); la FIDE aparece solo como emisor *posible* [2] | El jugador, en su billetera (Rocca), atada a su DID [4] | Plataforma u organizador de torneo [2] |
| "Buena conducta" | La plataforma que detecta trampa (World Chess hoy; otras serían promesa) [2] | El jugador | Otra plataforma o torneo |

El emisor firma una vez y deja de participar (§4.5). Verificar no es creer: la firma prueba que World Chess lo dijo, no que el dato sea cierto. Ojo: con divulgación selectiva tipo SD-JWT, "≥ 2000" solo se demuestra sin mostrar el rating exacto si el emisor firma un dato booleano aparte o si se usa ZK (§4.7).

### A.3 Sección 2 — Quién ve qué

| Actor | ¿Qué ve? | ¿Qué no ve? | Fuente |
|---|---|---|---|
| Emisor | Todo lo que firmó (rating, sanciones) | Dónde y cuándo se presenta la credencial | [2], §4.10 |
| Jugador (holder) | Todo: credenciales, divulgaciones, llave | — | [2] |
| Verificador | Emisor, DID, tipo, índice de estado y solo los datos revelados | Los datos ocultos (solo sus huellas) | §4.10 |
| Cadena pública | Anclaje de la DID y un "registro de datos verificable"; los datos personales quedan off-chain. **No especifican qué va on-chain**, y la demo con `did:key` no usa cadena | Rating, conducta, KYC | [2][6] |
| Quien roba la frase de 24 palabras | La llave privada, así que puede presentarse como el jugador hasta que el emisor revoque | No se sabe si la frase también restaura las credenciales | [2], §4.10 |

La cadena pública y lo off-chain son cosas distintas. Según el whitepaper, la DID quedaría "anclada en blockchain" y Algorand pagaría las comisiones agrupando transacciones [2]. Los datos personales, en cambio, irían off-chain por la tensión con el "derecho al olvido" del GDPR [2]. Ese diseño no está probado: la demo usa `did:key` y Ed25519, que se resuelven sin cadena [6]. Además, las fuentes no mencionan ASA ni NFT para el pasaporte, así que no podemos decir qué ve hoy un explorador de Algorand. La cadena nunca debería ver el rating ni las sanciones; si viera el índice de revocación, eso también sería correlacionable (§4.9).

### A.4 Sección 3

| Pregunta | Respuesta | Cita | §4 |
|---|---|---|---|
| ¿Pueden mostrar solo un dato? | **No se sabe** | "Compartir el título o rating verificado manteniendo privado lo demás", con ZK o divulgación selectiva "donde sea posible" (*should*); no nombran formato [2] | §4.7 |
| ¿Quién revoca y cómo se entera el verificador? | El emisor revoca (ej. por trampa), pero **el mecanismo no está especificado** (¿lista de estado? ¿on-chain?) | Cualquier verificador "puede consultar el estado"; piden apelación [2] | §4.9 |
| ¿Dos plataformas pueden unir el historial? | **Sí**, si se usa una sola DID | "Un jugador podría tener varias DIDs": es opcional, no está en el diseño [2] | §4.10 / D7 |

### A.5 Qué se rompe y cambio de diseño

1. **Falla 1, revocación por error:** el anti-trampa de una plataforma da un falso positivo y el emisor revoca "buena conducta". Como "lo que hacen en una plataforma tiene consecuencias en otra" [2], el jugador queda vetado en todos los torneos que verifican, y el mecanismo de apelación no está definido.
2. **Falla 2, una DID que une todo:** el campo `sub` es idéntico en cada presentación (§4.7). Dos plataformas que comparen datos unen partidas, sanciones y KYC del mismo jugador.
3. **Cambio de diseño:** una DID por plataforma (por pareja), con credenciales emitidas a cada una con su índice en una Bitstring Status List grande [W3C]. Así, revocar pasa primero por el propósito *suspension*, con plazo de apelación, antes de *revocation*. Ataca la falla 2 (no hay `sub` común), mitiga la falla 1 (la suspensión es reversible) y usa los conceptos de §4.7–4.9.

**Fuentes:**
[1] https://algorand.co/universal-chess-passport ·
[2] https://algorand.co/hubfs/Website-2024/PDFs/Algorand-Whitepaper-Identity%20and%20Verifiable%20Credential%20System%20for%20Chess-4.pdf ·
[3] https://algorand.co/blog/world-chess-and-the-algorand-foundation-propose-leveling-the-playing-field-with-a-chess-passport ·
[4] https://algorand.co/blog/algorand-and-world-chess-renewed-strategic-partnership-features-an-innovative-web3-business-model ·
[5] https://www.investegate.co.uk/announcement/rns/world-chess--chss/two-year-partnership-with-algorand-foundation-ltd-/9181839 ·
[6] https://github.com/algorandfoundation/chess-passport ·
[W3C] https://www.w3.org/TR/vc-bitstring-status-list/
