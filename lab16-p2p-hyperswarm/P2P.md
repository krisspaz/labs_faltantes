# P2P.md — Lab 16: Pear · Hyperswarm · Hypercore (Sesión 19)

> **Alcance honesto de la evidencia.** Todos los logs de `logs/` son reales. Los del 2026-10-05 son dos peers
> **en la misma Mac**, así que la "IP remota" es la IP LAN de la propia máquina (`10.196.207.47`). No tuve
> compañero, así que el 2026-11-09 repetí el lab entre **dos máquinas y dos redes distintas**: mi Mac (red
> residencial en Guatemala) y un runner de GitHub Actions (Azure, EE. UU.) que yo controlo. Ver la
> [sección 9](#9-repetición-entre-dos-máquinas-y-dos-redes-2026-11-09).

## 1. Qué construimos

| Pieza | Archivo | Qué hace |
|---|---|---|
| Descubrimiento + mensaje | `peer.js` | `topic = sha256("cs031-s19-YYYYMMDD")` (32 bytes) → `swarm.join(topic, {server, client})` → al conectar manda `ping desde {carnet}` y loggea peer id truncado, IP:puerto remoto y payload |
| Seeder | `seed.js` | parte el archivo en bloques de 16 KiB, los mete en un Hypercore (log append-only firmado) y lo anuncia en la DHT por su `discoveryKey` |
| Downloader | `download.js` | busca el core por `discoveryKey`, baja bloque a bloque con throttle (para poder matar al seeder a mitad) y verifica el SHA-256 |

Stack: Node.js v24 (el fallback que permite el lab) con `hyperswarm@4.17.2`, `hypercore@11.37.2`,
`corestore@7.13.0`. Son los mismos módulos que usa Pear por debajo.

## 2. Diagrama: topic → DHT → holepunch → exchange

```
 peer A                        HyperDHT (Kademlia, UDP)                       peer B
 ──────                        ────────────────────────                       ──────
 topic = sha256("cs031-s19-20261005")
   │  1. bootstrap ──────────► node1/2/3.hyperdht.org:49737
   │                           (solo para entrar a la red; no guardan datos)
   │  2. ANNOUNCE(topic, pubKeyA) ─► los ~20 nodos DHT más cercanos a hash(topic)
   │                                guardan "A está en este topic"
   │                                                                  3. LOOKUP(topic)
   │                                nodos cercanos ◄─────────────────── B pregunta
   │                                responden: pubKeyA + IP:puerto ───► B
   │  4. B pide a esos nodos que reenvíen su handshake a A (señalización)
   │  ◄════════════ 5. UDP holepunch: ambos se mandan paquetes a la vez ════════════►
   │                   (si los NAT no lo permiten → relay a través de otro peer DHT)
   │  ◄════════════ 6. stream cifrado Noise (UDX), autenticado con pubKeys ═════════►
   │  7. exchange: "ping desde peerA" / "ping desde peerB"
   │     o Hypercore: el downloader pide bloque i, A responde bloque i + prueba Merkle
```

En el kickoff exitoso (`logs/kickoff-peer*.log`): B arrancó, hizo lookup, encontró a A y conectó en
**4.2 s** (`21:01:36.8 → 21:01:41.0`). Los pings llegaron en ~20 ms. A es `initiator=false`, B `initiator=true`.

## 3. Infraestructura que sí usamos (P2P no significa cero infraestructura)

- **Bootstrap nodes de HyperDHT:** `node1.hyperdht.org` (88.99.3.86), `node2.hyperdht.org` (142.93.90.113) y
  `node3.hyperdht.org` (138.68.147.8), todos en el puerto UDP 49737. Están hardcodeados en
  `node_modules/hyperdht/lib/constants.js`. Sin ellos, un peer nuevo no sabe a quién preguntar. Son un
  punto centralizado de *entrada*, no de *datos*: si caen, los peers que ya están en la red siguen funcionando.
- **Nodos DHT de terceros:** cualquier peer de HyperDHT con IP pública funciona como nodo. Ellos guardaron el
  anuncio "pubKey X está en el topic" y reenviaron el handshake. Ven el topic hash y nuestra IP pública.
- **Relays:** HyperDHT puede retransmitir a través de otro peer cuando el holepunch falla (NAT simétrico, CGNAT).
  En nuestro caso no hizo falta: la conexión fue directa porque los dos procesos compartían red.
- **Lo que no usamos:** ningún servidor nuestro, ninguna cuenta, ningún pinning service. Si cerramos los
  procesos, el "servicio" deja de existir.

## 4. Primer intento fallido (dato del lab)

`logs/attempt1-simultaneous-peer*.log`: los dos procesos arrancaron con 1 s de diferencia. Cada uno hizo su
lookup *antes* de que el anuncio del otro se propagara, y el anuncio no se re-consulta de inmediato, así que
ambos terminaron con `peers=0` por timeout. Al arrancar B unos 8 s después de que A terminara su `flush()`
(anuncio completo), conectaron al primer intento. Lección: la DHT es *eventualmente* consistente, y "nadie en
el topic" puede significar solo "todavía no".

## 5. Transferencia de archivo + kill-seeder

Archivo: `sample.txt`, 541,646 bytes (texto sintético generado por script, sin PII ni copyright), en 34 bloques
de 16 KiB. SHA-256 `92d9dc2d38e4aac5…`. Core key `ab019ce0…37214`.

| Exp. | Setup | Qué pasó | Logs |
|---|---|---|---|
| 1 | 1 seeder, sin throttle | **Completo** en 312 ms, hash igual al original | `exp1-*` |
| 2 | 1 seeder, 300 ms/bloque, `kill -INT` al seeder tras el bloque 8 | Bajó 9 bloques (147,456 bytes) y se colgó en el bloque 9. El downloader **no** se enteró del cierre hasta ~13 s después (timeout de keepalive) y abortó con `REQUEST_TIMEOUT` a los 15 s. Archivo parcial, inútil | `exp2-*` |
| 3 | seeder + **reseeder** (replicó los 34 bloques y se puso a servir), mismo kill | El downloader estaba conectado a ambos (`peers=2`). Al morir el original hubo una pausa de ~15 s (el request en vuelo esperó el timeout) y luego siguió con el reseeder. **Completo** en 23.8 s, hash correcto | `exp3-*` |

**Qué vio el downloader:** el peer id del seeder, su IP:puerto (`10.196.207.47:49737`), la longitud del core
(34) antes de bajar nada y cada bloque verificado contra la key. Un seeder malicioso no puede inyectar
bloques falsos, porque Hypercore firma el árbol Merkle con la key del autor. Lo que **sí** puede hacer es
desaparecer.

**Conclusión del experimento:** la disponibilidad en P2P es exactamente igual a "¿hay algún seeder vivo
ahora?". El contenido es verificable sin confiar en nadie, pero no es persistente sin que alguien (un usuario
o un nodo pagado) decida seguir sirviéndolo. Es el mismo trade-off de IPFS sin pin (Lab 15), sin el gateway
HTTP de por medio.

## 6. Liability: host centralizado vs usuarios que seedean

| | Host centralizado (S3, Pinata, YouTube) | Usuarios que seedean / corren el runtime (Hyperswarm, BitTorrent) |
|---|---|---|
| Quién almacena | el operador | cada peer que tiene una copia |
| Quién distribuye | el operador | cada peer que sube bloques: el seeder es el "distribuidor" |
| Takedown | uno, al operador (notice-and-takedown) | no hay a quién: hay que ir peer por peer |
| Quién ve a quién | el operador ve a todos los usuarios | **cada peer ve la IP de su contraparte**; los nodos DHT ven el topic |
| Exposición legal | concentrada en el operador | repartida: el usuario que seedea puede ser responsable directo |

**Napster (2001):** tenía un índice central de qué archivos tenía cada usuario. Ese índice era conocimiento y
control, y por eso fue responsable por infracción contributiva y vicaria. Lo apagaron apagando el servidor.

**Grokster (MGM v. Grokster, 2005):** ya no había índice central (FastTrack/Gnutella). La Corte Suprema de EE. UU.
igual lo hizo responsable con la doctrina de **inducción**: promovió activamente el uso infractor (marketing
dirigido a ex-usuarios de Napster, un modelo de negocio basado en volumen de infracción, y ningún filtro).
Lección: descentralizar la arquitectura no te protege si tu *conducta* induce la infracción.

**BitTorrent:** el protocolo es neutral y tiene usos legítimos masivos (distribución de ISOs de Linux,
updates de juegos). El riesgo legal se movió a (a) trackers e indexadores que facilitan contenido infractor
(The Pirate Bay) y (b) **los usuarios que seedean**, cuyas IPs aparecen en el swarm y son lo que monitorean
los titulares de derechos. Exactamente eso observamos aquí: el peer ve nuestra IP.

**Para un venture sobre Hyperswarm/Pear:** publicar el runtime y el protocolo se parece a BitTorrent
(neutral). Operar un índice o directorio de topics, o promocionar un uso infractor, se parece a Napster o
Grokster. Y nuestros usuarios quedan expuestos con su IP. P2P **no** promete anonimato.

## 7. Oración 15-2026

Bajo el **Decreto 15-2026** (Ley Integral contra el Lavado de Dinero y el Financiamiento del Terrorismo,
vigente desde el 17 Sep 2026, que incorpora a los Proveedores de Servicios de Activos Virtuales —PSAV— como
sujetos obligados ante la IVE), un canal P2P sin servidor no exime al venture de sus obligaciones KYC/reporte si
custodia, intercambia o transfiere activos virtuales por cuenta de terceros: la ausencia de un servidor central
quita un punto de takedown, pero no quita al sujeto obligado.

## 8. Comentarios de aprendizaje: qué vio nuestro peer de nosotros

- **IP y puerto:** `remote=10.196.207.47:49737/49738` en la prueba local (IP LAN). Entre redes distintas
  (sección 9) el runner vio mi IP pública real (`181.174.x.x:14450`). Es el mismo dato que usa un titular de derechos para identificar
  seeders.
- **Identidad:** una public key estable por proceso (`self=9fa13197…`) que no está ligada a nuestro nombre,
  salvo porque el payload decía `ping desde {carnet}`: la capa de aplicación nos des-anonimizó sola.
- **Topic:** cualquiera que conozca el string `cs031-s19-…` calcula el mismo hash y entra. El topic es un
  punto de encuentro, no un control de acceso. Para privacidad hay que cifrar el payload o usar un topic secreto.
- **Tiempos:** unos 4.2–4.6 s de DHT lookup/announce y unos 20 ms de mensaje una vez conectados. El costo está en
  descubrir, no en transmitir.
- **Muerte de peers:** se detecta tarde (~13 s), no al instante. Las apps P2P necesitan timeouts y reintentos
  hacia otros peers como parte del diseño, no como caso borde.

## 9. Repetición entre dos máquinas y dos redes (2026-11-09)

Sin compañero, el segundo peer fue un runner de GitHub Actions
([`.github/workflows/lab16-remote-peer.yml`](../.github/workflows/lab16-remote-peer.yml)): Ubuntu, Node 24 y
el mismo `peer.js` / `download.js` de este folder. Corre al hacer push a la rama `lab16-remote-peer` y no usa
secretos. La key del Hypercore es pública: solo da lectura. Topic: `cs031-s19-20261109` (sha256 `d3275081…`).

Logs: [`logs/remote/`](logs/remote/) (Mac) y [`logs/remote/runner/`](logs/remote/runner/) (runner).
Mi IP pública aparece tachada (`181.174.x.x`) y la corrida de Actions se borró porque sus logs eran públicos.

**Mensaje P2P (los dos lados):**

| Hora (UTC) | Lado | Evento |
|---|---|---|
| 22:14:03 | Mac `3308c200` | join; announce + lookup en 5998 ms, peers=0 |
| 22:14:18 | runner `f552fb97` | join |
| 22:14:21.305 | runner | `connected peer=3308c200 remote=181.174.x.x:14450 initiator=true` |
| 22:14:21.357 | Mac | `connected peer=f552fb97 remote=132.196.19.238:36971 initiator=false` |
| 22:14:21.360 | Mac | `recv payload="ping desde gh-runner"` |
| 22:14:21.405 | runner | `recv payload="ping desde kris-mac"` |

Aquí cada lado vio la **IP pública** del otro, no una IP LAN: el runner vio la IP de mi ISP y yo la de Azure.
El runner tardó unos 3 s en conectar desde que entró y el holepunch funcionó sin relay.

**Archivo + kill-seeder entre redes** (`sample.txt`, 541,646 B, 34 bloques de 16 KiB; seeder en la Mac):

| Descarga (runner) | Throttle | Resultado |
|---|---|---|
| 1 | 100 ms/bloque | `COMPLETE 541646 bytes in 7404 ms`, sha256 `92d9dc2d…` |
| 2 | 1000 ms/bloque | `kill -9` al seeder a las 22:14:51 → el runner ve `peer closed` a las 22:14:59 (unos 8 s después) y `STALLED at block 11/34 ... REQUEST_TIMEOUT (peers=0)`, con 11 bloques (180,224 B) |

No había segundo seeder, así que la descarga 2 quedó incompleta. Coincide con el exp2 local: sin otro seeder,
el contenido deja de estar disponible. Los 11 bloques que bajó siguen verificados contra la key (Merkle), pero
no forman el archivo completo.

**Qué aprendí de hacerlo entre redes:** la DHT y el holepunch funcionaron entre una red residencial y un
datacenter sin configurar puertos. Lo que el peer ve de mí deja de ser una IP LAN inofensiva y pasa a ser mi
IP pública, que es exactamente el dato con el que se identifica a un seeder. Por eso tuve que tacharla antes de
publicar estos logs.

## Fuentes

- Decreto 15-2026: [Consortium Legal](https://consortiumlegal.com/en/2026/09/29/virtual-asset-service-providers-decree-15-2026-guatemala/),
  [CriptoNoticias](https://www.criptonoticias.com/regulacion/guatemala-servicios-criptomonedas-ley-antilavado/),
  [Pirani](https://www.piranirisk.com/es/hub-regulatorio/ley-15-2026-antilavado-guatemala-que-es-a-quien-aplica)
- MGM Studios, Inc. v. Grokster, Ltd., 545 U.S. 913 (2005); A&M Records, Inc. v. Napster, Inc., 239 F.3d 1004 (9th Cir. 2001)
