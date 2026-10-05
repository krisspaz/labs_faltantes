# TX_FORENSICS.md — Lab 06: Forense Taproot vs Ethereum (Sesión 7)

Comparamos el **mismo primitivo** (un HTLC de atomic swap con Lightning) implementado en dos cadenas:

- **Ethereum:** contrato **EtherSwap** histórico de Boltz (2020–2021), un swap `lock` → `claim`.
- **Bitcoin:** un **Reverse Swap Taproot** con la plantilla de `boltz-core`, lockup P2TR → claim por *script-path*.

Las 4 txs están en `raw/` (hex crudo + JSON) y se re-verifican con `./verify.sh` (salida en `raw/verify-output.txt`).

---

## 1. Ethereum — Boltz EtherSwap

**Contrato:** [`0x9f6FEa1C76FC1961eED97c00124eF7D7a7b3d9Ea`](https://etherscan.io/address/0x9f6fea1c76fc1961eed97c00124ef7d7a7b3d9ea)
(Etherscan lo etiqueta *EtherSwap*). Lo identificamos así:

- `version()` = 1.
- El bytecode contiene exactamente los selectores de EtherSwap v1: `lock` `0x0899146b`, `claim` `0xc3c37fbc`,
  `refund` `0x35cd4ccb`, `swaps` `0xeb84e7f2`.
- Se desplegó en el bloque **10,918,877** (23 Sep 2020). Lo encontramos por búsqueda binaria de `eth_getCode` en un nodo de archivo.
- Tiene solo 29 txs en total, entre Sep 2020 y Mar 2021: Boltz abandonó Ethereum L1 por el costo del gas (ver §3).

### Tx 1 — Lock

| Campo | Valor |
|---|---|
| Hash | [`0x3061cd37ce12acbaa816a6ce1e8779ecbf26e27c5980d5d3b9acf40d517c3748`](https://etherscan.io/tx/0x3061cd37ce12acbaa816a6ce1e8779ecbf26e27c5980d5d3b9acf40d517c3748) |
| Bloque / hora | 12,063,470 · 2021-03-18 15:28:41 UTC |
| From → To | `0xb34817a3…09426` (usuario) → EtherSwap |
| Value | 0.02213081 ETH |
| Tipo | legacy (type 0, EIP-155, `v=0x26` → chainId 1). Anterior a London/EIP-1559 |
| Gas | used 46,849 = gasLimit · 165 gwei · **fee 0.007730085 ETH** |
| Calldata `lock(bytes32,address,uint256)` | `preimageHash = 0x712071d5…aad54`, `claimAddress = 0x89aDC1d1…DD83c` (Boltz), `timelock = 12,064,183` (bloque absoluto, +713 bloques ≈ 2.6 h) |
| Evento | `Lockup(preimageHash indexed, amount, claimAddress, refundAddress indexed, timelock)` (topic0 `0x15b4b820…`) |

Raw (RLP firmado):
```
0xf8d00585266ac4320082b701949f6fea1c76fc1961eed97c00124ef7d7a7b3d9ea874e9fdabca44400b8640899146b712071d518bf6c5407f5e606c32cfe654541c72a3879dbc5edf293e8934aad5400000000000000000000000089adc1d19ccf3e5e74550cdb831594013cfdd83c0000000000000000000000000000000000000000000000000000000000b815b726a0dcdfb6078f9dbbb15a0c037c9fe437501255cf5b6a1f05223dbd43e5331491e6a063ddb1e8939bf5ec199c532a3af67dda11e4ea3873a435e4744234c76718ae08
```

### Tx 2 — Claim

| Campo | Valor |
|---|---|
| Hash | [`0x7ec4aac5fd922aa914a2c40093e515103539f151b02d98cea23cec98ecc555ef`](https://etherscan.io/tx/0x7ec4aac5fd922aa914a2c40093e515103539f151b02d98cea23cec98ecc555ef) |
| Bloque / hora | 12,063,476 · 2021-03-18 15:29:25 UTC (**+6 bloques, 44 s** después del lock) |
| From → To | `0x89aDC1d1…DD83c` (Boltz, el `claimAddress`) → EtherSwap |
| Gas | used 25,006 · 170 gwei · **fee 0.00425102 ETH** |
| Calldata `claim(bytes32,uint256,address,uint256)` | **`preimage = 0xbd512a8b…5ee78b`**, amount 0.02213081 ETH, refundAddress `0xb34817a3…`, timelock 12,064,183 |
| Evento | `Claim(preimageHash indexed, preimage)` (topic0 `0x5664142a…`) |

Raw:
```
0xf8e910852794ca240082a4d8949f6fea1c76fc1961eed97c00124ef7d7a7b3d9ea80b884c3c37fbcbd512a8b7207d4d04ee7ddc7224961cfeb55f06641b2446fa8a86a3b115ee78b000000000000000000000000000000000000000000000000004e9fdabca44400000000000000000000000000b34817a34a965e426bbcbbffad085aa7b6a094260000000000000000000000000000000000000000000000000000000000b815b725a0c76f5109e310a973e0f538ef52065bfd261934d617d0a747260ce6f3af869ee8a03d54e6bf6b914bdeefb0091a0e0322deeacab334e9c5807d675de45bbac9a6cc
```

**Lectura:** es un *submarine swap* (ETH on-chain → Lightning). El usuario bloquea ETH con el hash de su factura
Lightning. Boltz paga la factura, con eso obtiene el preimage y lo usa para reclamar el ETH.

### Segunda verificación ETH

1. **Dos RPC independientes** (`eth.drpc.org` y `eth-mainnet.public.blastapi.io`) devuelven el **mismo raw RLP** para ambas txs.
2. `keccak256(raw)` recalculado localmente = el hash de la tx, en ambas.
3. **Coherencia criptográfica:** `sha256(preimage del Claim) = 712071d5…aad54` = `preimageHash` del Lockup.
4. Cruce con la vista humana de Etherscan: métodos *Lock*/*Claim*, bloques y montos coinciden.

---

## 2. Bitcoin — Reverse Swap Taproot (plantilla Boltz)

**Cómo la encontramos:** escaneamos los bloques crudos más recientes (`scan.py`, con un parser propio) buscando
gastos P2TR por *script-path* cuyo script revelado fuera exactamente:

```
OP_SIZE 32 OP_EQUALVERIFY OP_HASH160 <20B> OP_EQUALVERIFY <32B x-only pubkey> OP_CHECKSIG
```

Es, byte a byte, el `claimLeaf` de [`boltz-core/lib/swap/ReverseSwapTree.ts`](https://github.com/BoltzExchange/boltz-core/blob/master/lib/swap/ReverseSwapTree.ts).

> **Atribución:** es una *inferencia por plantilla*, no una prueba. Cualquiera que use la librería
> open-source `boltz-core` produce el mismo script. En ETH, en cambio, la atribución es directa por el
> address del contrato. Esta asimetría ya es un hallazgo forense (§3, privacidad).

### Tx 3 — Lockup (fondea el HTLC)

| Campo | Valor |
|---|---|
| txid | [`03010ef205d925708c005585865bd90c4595750c85a50bbbcfbefa06c66d63db`](https://mempool.space/tx/03010ef205d925708c005585865bd90c4595750c85a50bbbcfbefa06c66d63db) |
| Bloque / hora | 970,072 · 2026-10-05 19:55:07 UTC |
| Input | 1 × P2TR `bc1p4s4hv…h3dhma` (938,681 sat), gastado por **key-path**: witness = 1 elemento de 64 B (firma Schnorr) |
| Outputs | **#0: 25,700 sat → `bc1pqtqgwx…xczf7l` (el HTLC)** · #1: 912,810 sat → `bc1pnku2dz…sn2tka` (cambio) |
| Tamaño | 205 B · weight 616 · 154 vB · **fee 171 sat (1.11 sat/vB)** |

```
0200000000010167a6f9d3bdeff74cb8f43ef398942481e91c0ee7fc963f9e856fd338cfd2d5fd0100000000feffffff02646400000000000022512002c0871a6d4ac57d9f21fec01d40a158275aa0062e5bdc58761ff80bdd76c442aaed0d00000000002251209db8a6894216a4f1c651e3ddf03e799d375bf9ab489c63e31dc1cf9fda40c34301407741612b1e01dff5ee09fe56aca07334904893fd6ce4ed6f53756a8a80fa8b2165554fa96a234f24e1b4ebdf1db3e3343fde495ddb5b52bbbafbe01d25d4544d03cd0e00
```

### Tx 4 — Claim (script-path)

| Campo | Valor |
|---|---|
| txid | [`34039191b23050737ec5d379fba5a9759be32804e9bf74292f74f8a044fe3117`](https://mempool.space/tx/34039191b23050737ec5d379fba5a9759be32804e9bf74292f74f8a044fe3117) |
| Bloque | **970,072, el mismo bloque que el lockup**: gastó un output todavía no confirmado (0-conf) |
| Input | `03010ef2…:0` (25,700 sat) |
| Witness (4 elementos) | `[0]` firma Schnorr 64 B · `[1]` **preimage** `586c574a…cce854` (32 B) · `[2]` script del claim leaf (61 B) · `[3]` **control block** 65 B = `0xc0` (leaf version) + internal key 32 B + **1 hash hermano** 32 B |
| Output | 25,340 sat → `bc1qfxvzcs…x7y6hf` (P2WPKH, wallet del usuario) |
| Tamaño | 311 B · weight 557 · 139.25 vB · **fee 360 sat (2.59 sat/vB)** |

```
02000000000101db636dc606fabecfbb0ba5850c7595450cd95b868555008c7025d905f20e01030000000000fdffffff01fc6200000000000016001449982c43dd6848f9df7ea676248a4c6255d3040604403c158180a590c03d7a7d5a1bd1ffeff43db48acf296440440747d357335be9ee9c6d74a20ddd08a359382e2f53b61e3c36e08bcec62945c0d55049741b3ad30f20586c574a05b933d719b805f978d4377c9dfa6439c52495f30bf45b40c2cce8543d82012088a9149e3bb037d5286075b94cac817c5b0179611298a2882003a8ffeb954020ec7648bc336b1b0b5b091c4f4641f5cb481e23616c084c56b0ac41c022dc81c95b54e335df592f4d0f51f4a2284431ca9f09f60eff6b6e398f574fbf27700f817549b95dbd99641b7529f0ada976d212b7452ab641d04e029d3cf0b700000000
```

Script revelado (ASM): `OP_SIZE OP_PUSHBYTES_1 20 OP_EQUALVERIFY OP_HASH160 9e3bb037d5286075b94cac817c5b0179611298a2 OP_EQUALVERIFY 03a8ffeb954020ec7648bc336b1b0b5b091c4f4641f5cb481e23616c084c56b0 OP_CHECKSIG`

**Lectura:** es un *reverse swap* (Lightning → BTC on-chain). Alguien (Boltz, según la plantilla) bloquea BTC
contra el hash de una factura Lightning, y el usuario reclama revelando el preimage. `sha256(preimage) =
6720b3c6…10f8b5` es el *payment hash* de esa factura.

### Segunda verificación BTC

1. **Dos exploradores independientes** (mempool.space y blockstream.info) devuelven el **mismo hex** para ambas txs.
2. El **txid se recalcula localmente** (doble SHA-256 de la tx sin witness) desde ese hex y coincide, en ambas.
3. **Coherencia criptográfica:** `HASH160(preimage del witness) = 9e3bb037…98a2` = el hash dentro del script.
4. **Enlace on-chain:** `/outspend/0` del lockup apunta exactamente al claim.

---

## 3. Comparación (6 dimensiones)

| Dimensión | Ethereum (EtherSwap) | Bitcoin (Taproot) |
|---|---|---|
| **Modelo de estado** | Cuenta + storage del contrato: `swaps[keccak(preimageHash, amount, claim, refund, timelock)] = true` mientras está activo. Hay un estado global que el contrato muta | UTXO: el "contrato" *es* el output P2TR. No hay estado global; gastarlo destruye el HTLC |
| **Qué se publica al bloquear** | **Todo, en claro:** preimageHash, claimAddress, refundAddress, monto y timelock, en calldata y en el evento `Lockup`. Cualquiera sabe que es un swap de Boltz antes de que termine | **Nada distinguible:** un output P2TR de 25,700 sat igual a cualquier pago Taproot. Los términos (hash, claves, timeout) están ocultos en el tweak |
| **Qué se publica al reclamar** | Preimage en calldata + evento `Claim` | Script-path: solo la hoja usada (claim). La hoja de refund y su timeout **siguen ocultos** (solo aparece su hash en el control block). Por key-path (MuSig2 cooperativo) no se revelaría *nada*: 1 firma de 64 B, como el input del lockup |
| **Costo** | Lock + claim = 71,855 gas = **0.01198 ETH ≈ 54% del monto swappeado** (0.0221 ETH) con gas a 165–170 gwei | Lockup 171 + claim 360 = **531 sat ≈ 2.1% del monto** (25,700 sat). El fee del lockup además paga el output de cambio |
| **Tamaño / unidad de cobro** | Gas por cómputo + storage: del lock (46,849), 21k son el costo base de toda tx y ~20k el SSTORE de un slot nuevo; el claim recupera parte con el refund de gas al borrar el slot | Weight: los datos de witness pagan ¼. El claim pesa 311 B pero se cobra como 139.25 vB |
| **Timing / finalidad** | Claim 6 bloques (44 s) después del lock. Timelock en **altura absoluta de bloque** (+713) | Lockup y claim en el **mismo bloque**: el claim gastó un output 0-conf y su fee más alto (2.59 vs 1.11 sat/vB) ayudó a minar el paquete (~1.81 sat/vB combinado, *CPFP*) |
| **Linkabilidad** | Lock y claim comparten `preimageHash` en los topics indexados: se enlazan con una sola query de logs | Se enlazan por outpoint (input → output), como cualquier gasto. El preimage revelado enlaza además con el pago Lightning, igual que en ETH |
| **Atribución** | Directa: el address del contrato **es** Boltz | Solo por plantilla del script, y solo porque se usó el script-path |

## 4. Conclusión

Para un HTLC de swap, **Taproot es estrictamente mejor en privacidad y costo; Ethereum es mejor en
expresividad y auditabilidad.**

- **Privacidad:** en ETH el swap se anuncia con todos sus términos desde el `lock`. En Taproot, el lockup es
  indistinguible y el claim cooperativo también lo sería. Lo que observamos aquí (script-path) es el *peor
  caso* de Taproot, y aun así oculta la rama de refund. Que la atribución BTC sea solo una inferencia por
  plantilla, mientras la de ETH es trivial, es la evidencia más clara de esta diferencia.
- **Costo:** con el gas de marzo 2021, pagar ~54% de fee por un swap de 0.02 ETH hace inviable el producto en L1.
  Eso explica por qué el contrato tiene solo 29 txs y Boltz migró a Rootstock y L2s. En BTC, el mismo
  primitivo costó ~2%, y gran parte de eso es el piso de fee del claim.
- **Contraparte:** la privacidad de Taproot depende de la *cooperación* (key-path con MuSig2). Cuando el cliente
  no coopera o usa el camino de emergencia, se revela el script, como aquí. En ETH no hay camino privado: la
  transparencia es el modelo, y a cambio cualquiera puede verificar el estado `swaps[]` del contrato sin
  reconstruir nada.

**Criterio:** para swaps de montos pequeños y alta frecuencia, el diseño correcto es Taproot con claim
cooperativo por defecto y script-path solo como fallback. Un contrato en Ethereum L1 tiene sentido solo si
necesitas lógica que Script no puede expresar (p. ej. ERC-20, que EtherSwap no cubría y por eso existía el
ERC20Swap aparte) y el monto justifica el gas.

## 5. Comentarios de aprendizaje

- **"Raw" significa cosas distintas:** en ETH, el raw es un RLP con firma (v, r, s) y el hash es `keccak256(raw)`.
  En BTC, el raw incluye el witness pero el txid lo excluye (`sha256d` sin marker/flag/witness). Por eso lo
  recalculamos localmente y no confiamos solo en lo que dice el explorer.
- **El control block como evidencia negativa:** 65 bytes = 33 + 32 nos dice que el árbol tenía exactamente
  otra hoja (la de refund), sin decirnos qué contenía. En forense Taproot, los tamaños delatan estructura.
- **Mismo hash, dos funciones:** ETH guarda `sha256(preimage)` (el payment hash de Lightning tal cual). El
  script BTC guarda `HASH160(preimage)` = `ripemd160(sha256(preimage))`, 20 bytes en lugar de 32, más barato en
  bytes. Ambos se anclan al mismo payment hash de Lightning: esa es la "atomicidad" cross-chain.
- **Nodos de archivo importan:** el primer RPC (publicnode) devolvía `eth_getCode` vacío en bloques viejos, y la
  búsqueda binaria daba un "deploy" falso de hoy. La segunda verificación no es burocracia: atrapó un dato
  incorrecto en el propio proceso.
- **No es el lab de Rootstock:** aquí no desplegamos nada; todo es análisis de txs reales de mainnet.

## Reproducir

```bash
./verify.sh                 # re-verifica las 4 txs contra 2 fuentes por cadena
python3 scan.py 15          # re-escanea los últimos N bloques BTC buscando la plantilla (lento, ~1.5 MB/bloque)
```
