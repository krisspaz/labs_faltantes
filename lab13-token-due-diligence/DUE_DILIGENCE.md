# Lab 13 — Token due diligence (Sesión 15)

**Objetivo:** auditar, no diseñar. Comparamos un meme coin de fair-launch (**PEPE**, kickoff) con una
emisión pública regulada de Tohkn (**MMLTI1**, homework) usando la misma rúbrica de 10 puntos.

Fecha del snapshot: **2026-10-05** (on-chain leído vía RPC; mercado vía DexScreener a las 22:03 UTC).
Datos crudos en `onchain/`; documentos oficiales de la emisión en `sources/`.

> **Rúbrica:** el session doc S15 no fue accesible al preparar esto. La rúbrica de §3 es nuestra
> (10 criterios binarios, 1 punto c/u). **Si la rúbrica oficial difiere, re-puntuar con ella:** los
> hallazgos de §1 y §2 son la evidencia y no cambian.

---

## 1. Kickoff — Meme coin: PEPE (Ethereum)

| Campo | Valor | Fuente |
|---|---|---|
| Ticker / nombre | PEPE / "Pepe" | `symbol()`, `name()` |
| Contrato | [`0x6982508145454Ce325dDbE47a25d4ec3d2311933`](https://etherscan.io/token/0x6982508145454Ce325dDbE47a25d4ec3d2311933) (Ethereum) | — |
| Supply | 420,689,899,645,071.70 PEPE (fijo, 18 decimales) | `totalSupply()` |
| Venue principal | Uniswap V2 PEPE/WETH, par `0xA43fe169…Cec9f` | `uniswapV2Pair()` + DexScreener |
| Precio | US$ 0.000004439 | DexScreener |
| Market cap = FDV | **US$ 1.837B** (todo el supply circula: no hay vesting ni treasury) | DexScreener |
| Liquidez par principal | US$ 32.37M | DexScreener |
| Volumen 24h (par principal) | US$ 1.63M | DexScreener |
| Txs 24h (par principal) | **471 ventas** / 349 compras (más presión vendedora) | DexScreener `txns.h24` |

> "Sellers 24h": DexScreener da el *número de txs de venta*, no de wallets vendedoras únicas. Contar
> wallets únicas requiere indexar los `Swap` del par. Lo reportamos como txs y lo marcamos.

### Funcionalidad on-chain

Selectores presentes en el bytecode (`cast code`): ERC-20 estándar + `burn(uint256)` + `blacklist(address,bool)`
(`0x404e5129`) + `setRule(bool,address,uint256,uint256)` (`0x3aa633aa`) + `Ownable`.

| Control | Existe en código | Estado hoy |
|---|---|---|
| Mint posterior | No (solo en el constructor) | — |
| Blacklist | **Sí**, `onlyOwner` | **Inutilizable:** `owner() = 0x000…000` (ownership renunciada) |
| Límite anti-ballena (`setRule`) | Sí, `onlyOwner` | `limited() = false`, `maxHoldingAmount = 0`: desactivado y ya no se puede activar |
| Pause / freeze / forced transfer | No | — |
| Upgradeable | No (no es proxy) | — |
| LP quemado | — | Solo 0.009% de los LP tokens del par V2 está en `0xdEaD`; la liquidez es de LPs que pueden retirarla |

**Lectura:** el contrato tenía poderes peligrosos (blacklist, límites de holding) usados en el lanzamiento contra
bots, pero la renuncia de ownership los neutralizó para siempre. Hoy el riesgo no está en el código: está en
el **mercado** (concentración, liquidez que puede salir y precio puramente narrativo). No hay emisor, ni
promesa de flujo, ni documento.

---

## 2. Homework — Emisión Tohkn: MMLTI1 (Polygon, ERC-3643)

### Cómo encontramos el contrato

1. `tohkn.com/es/issuances/mmlti1`: la página **no publica el address**. Solo dice Polygon + ERC-3643.
2. Descargamos los 4 documentos públicos de la emisión (`sources/`): DIR con anexos, certificación,
   aviso de oferta pública y términos.
3. Encontramos **dos addresses distintos** para "el contrato del Primer Tramo":

| Documento | Address | Dónde existe realmente |
|---|---|---|
| **DIR** (anexos, "Contrato Inteligente del Primer Tramo") | `0x6682b57FA1148b3831aE8610cd6Cbe961d610329` | **Polygon mainnet**: `name = "MIO3 MM Tokenized Senior Debt Note Tranch 1"`, `symbol = MMLTI1` |
| **Certificación** (tabla resumen y §5 riesgos, dice "en Polygon") | `0x40bC415Fb08b49DC6853F067E61A1a4FF7490559` | **Solo en BSC Testnet**, con `symbol = "MLTI1"` (sin la segunda M). En Polygon no tiene código |

Lo comprobamos consultando `eth_getCode` en Polygon, BSC, BSC Testnet y Ethereum con dos RPC.
**El contrato real es el del DIR.** La certificación cita el address del despliegue de prueba y le atribuye la red
equivocada. La propia certificación lo insinúa ("el DIR indica que fue desplegado inicialmente en BSC Testnet,
con migración pendiente a Polygon"), pero la migración ya ocurrió y el documento no se actualizó.

### Arquitectura on-chain (T-REX v4.1.1)

| Pieza | Address | Hallazgo |
|---|---|---|
| Token (proxy) | [`0x6682b57F…10329`](https://polygonscan.com/token/0x6682b57FA1148b3831aE8610cd6Cbe961d610329) | `version() = "4.1.1"`, 18 decimales, `paused() = false`. Desplegado el 2026-07-23 en el bloque 90,762,399 vía la TREX Factory (tx `0xafc8160c…ad616`) |
| ImplementationAuthority | `0x387b9CED…Ce18` | Decide qué código ejecutan token, IR y compliance. `owner = 0x0921785A…cAf46` |
| Owner + **único Agent** del token | `0xC7369964…62a59` | Es un **proxy actualizable** (`upgradeTo`), con `proxyOwner = 0x0921785A…` |
| `0x0921785A…cAf46` | — | **EOA** (sin código, nonce 202). Es el deployer y controla tanto el agent como las upgrades |
| Identity Registry | `0x303CD7C8…AF2F` | **`getClaimTopics() = []` y `getTrustedIssuers() = []`** |
| Modular Compliance | `0xC4Cab86a…B059` | 4 módulos (abajo) |
| ONCHAINID del token | `0x2B00C8fa…BCd3` | — |

**Módulos de compliance activos:**

| Módulo | Parámetro leído on-chain | vs. documentos |
|---|---|---|
| `SupplyLimitModule` | límite = **20,000 tokens** = US$ 2,000,000 a US$ 100/token | ✅ Coincide con "Primer Tramo hasta US$2M" |
| `TimeTransfersLimitsModule` | **20,000 tokens por ventana de 15,552,000 s (180 días)** | ⚠️ Los docs hablan de "restricción de comercialización de 180 días desde la adquisición". On-chain es un **tope de volumen por wallet** igual al supply total, **no un lock por holder**. Hasta hoy no hubo transferencias, así que no se pudo observar |
| `CountryRestrictModule` | ningún país restringido entre los probados (SV 222, US 840, CN 156, RU 643, KP 408, IR 364) | ⚠️ Los docs mencionan sanciones y listas restrictivas, pero on-chain no hay país bloqueado; el filtro es off-chain (KYC) |
| `MaxBalanceModule` | sin getter público; no pudimos leer el límite | ℹ️ Pendiente: leer el evento `MaxBalanceSet` |

### Actividad on-chain (escaneo completo hasta el bloque 95,020,246)

- **241 eventos `Transfer`, todos mints.** Suman exactamente **11,917 tokens** = `totalSupply()` (≈ US$ 1.19M, 59.6% del tramo).
- **0 transferencias entre holders, 0 burns, 0 pausas, 0 freezes, 0 recoveries.**
- Mints entre el 2026-09-16 y el 2026-10-05 (la oferta sigue abierta).
- **214 holders.** Mediana = 1 token (US$ 100); 116 holders tienen exactamente 1 token.
- **Concentración:** `0xc24e55ae…c58e` tiene **10,300 tokens (86.4%)**. Es una EOA con nonce 1 (solo ha recibido).
  Puede ser un inversionista institucional o una wallet ómnibus de custodia (los términos dicen que la custodia
  la hace MIO3), pero los documentos no lo identifican.
- **Agents:** un solo evento `AgentAdded`, para `0xC7369964…`. No hay agents adicionales.

### Funcionalidad del código vs. claims del DIR

| Claim (DIR / Términos / Certificación) | Código on-chain | Veredicto |
|---|---|---|
| "Polygon, ERC-3643" | T-REX v4.1.1 en Polygon | ✅ |
| Address del contrato del Primer Tramo | DIR ✅ / **Certificación ❌** (address de BSC testnet) | ⚠️ inconsistencia documental |
| Hasta US$2M en el Primer Tramo | `SupplyLimitModule` = 20,000 | ✅ |
| Whitelisting / KYC | El registry exige identidad registrada por el agent, pero **sin claim topics ni trusted issuers** | ⚠️ El KYC es 100% off-chain y depende de que el agent registre bien. El código no verifica ningún claim |
| Congelamiento, recall, quema | `freezePartialTokens`, `setAddressFrozen`, `forcedTransfer`, `recoveryAddress`, `burn` (T-REX, `onlyAgent`) | ✅ Existen. Implican poder unilateral del agent sobre los saldos |
| Pausa | `pause()` (`onlyAgent`) | ✅ |
| "Contratos inmutables una vez desplegados" | Token, IR y compliance son **proxies**. La ImplementationAuthority (owner EOA) puede cambiar el código. El agent también es un proxy actualizable por la misma EOA | ❌ **Contradice el código.** Son actualizables por una sola clave |
| "Custodia MPC, sin punto único de fallo" | El controlador on-chain es una **EOA**. Una wallet MPC se ve igual que una EOA, así que no se puede refutar ni confirmar on-chain | ❓ No verificable. Debería documentarse qué address es MPC |
| "Restricción de comercialización 180 días" | Límite de volumen 20k/180d por wallet, no lock | ⚠️ El código no implementa lo que dice el texto |
| "Auditorías externas independientes" | El DIR (§12.2.2) las afirma, pero **no cita firma ni informe**. La certificación lo confirma: "no se presenta el informe de auditoría formal" | ⚠️ Claim sin evidencia. Mitiga un poco que T-REX es un estándar auditado upstream |

---

## 3. Rúbrica de 10 puntos (misma para ambos)

1 punto = la protección o transparencia **existe y es verificable**.

| # | Criterio | PEPE | MMLTI1 |
|---|---|:-:|:-:|
| 1 | Contrato identificable y consistente con la documentación pública | 1 | **0** (dos addresses; la certificación apunta a testnet) |
| 2 | Supply fijo o con tope on-chain | 1 | 1 (SupplyLimit 20k) |
| 3 | Sin admin capaz de mint/burn arbitrario | 1 (renunciado) | 0 (el agent puede mint/burn) |
| 4 | Sin capacidad de congelar / blacklist activa | 1 (blacklist neutralizada) | 0 (freeze + forced transfer) |
| 5 | Código no actualizable o upgrade con timelock/multisig verificable | 1 | 0 (proxy + EOA) |
| 6 | Controles de cumplimiento (KYC/AML) aplicados on-chain | 0 | 0.5 (registry de identidad sí; claims/issuers vacíos) |
| 7 | Documento de emisión con derechos económicos claros (flujo, plazo, prelación) | 0 | 1 (6.20% anual, mensual, 24 meses) |
| 8 | Emisor identificado y regulado | 0 | 1 (MultiMoney EAD-0046, CNAD, PSAD MIO3) |
| 9 | Distribución no concentrada (top holder < 20%) | — (requiere indexer; no medido) → 0 | 0 (86.4%) |
| 10 | Liquidez/salida verificable | 1 (US$32M en DEX, sin restricciones) | 0 (0 transferencias; sin mercado secundario visible) |
| | **Total** | **6 / 10** | **3.5 / 10** |

**Cómo leer el resultado:** la rúbrica premia la *ausencia de poder sobre el holder* (puntos 3–5) y la
*claridad del derecho* (7–8). PEPE gana en lo primero porque no promete nada y nadie lo controla. MMLTI1 gana
en lo segundo pero pierde en inmutabilidad, consistencia documental y liquidez. No son "más seguro" vs "menos
seguro": son **riesgos de naturaleza distinta** (ver MEMO.md).

## 4. Reproducir

```bash
R=https://polygon.drpc.org; T=0x6682b57FA1148b3831aE8610cd6Cbe961d610329
cast call $T "symbol()(string)" --rpc-url $R
cast call $T "getImplementationAuthority()(address)" --rpc-url $R
cast call 0x303CD7C8003964165a292736a26A61229a4AAF2F "topicsRegistry()(address)" --rpc-url $R
cast code 0x40bC415Fb08b49DC6853F067E61A1a4FF7490559 --rpc-url https://bsc-testnet-rpc.publicnode.com   # address de la certificación
```
Logs completos del token: `onchain/token-logs.jsonl` · resumen: `onchain/mmlti1-summary.txt` · PEPE: `onchain/pepe-dexscreener.json`.
