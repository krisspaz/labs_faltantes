# Lab 12 — Vesting de clase (Sesión 14)

Economía on-chain de la clase: **un** deploy crea un ERC-20 de supply fijo 7_000 y un contrato
`ClassVesting` multi-beneficiary que lo custodia. 7 estudiantes × 1_000 = 7_000.

Stack: Foundry · Solidity 0.8.36 · OpenZeppelin Contracts v5.

## Parámetros

| Parámetro | Valor | En el código |
|---|---|---|
| Supply | 7_000 CLASS | `ClassToken.TOTAL_SUPPLY`, minteado al vesting en el constructor |
| Beneficiaries | 7 × 1_000 | `BENEFICIARY_COUNT`, `ALLOCATION` (revierte si ≠ 7, si hay duplicados o si hay `address(0)`) |
| Cliff unlock | 100 | `CLIFF_AMOUNT` |
| Post-cliff | 900 lineal durante 1 día | `LINEAR_AMOUNT`, `end - cliff = 86400` |
| Cliff | mié 23 Sep 2026 12:00 GT | `1790186400` (18:00 UTC) |
| Fully vested | jue 24 Sep 2026 12:00 GT | `1790272800` |

```
vested(t) = 0                                    si t < cliff
          = 100 + 900 · (t − cliff) / (end − cliff)  si cliff ≤ t < end
          = 1000                                 si t ≥ end
releasable = vested(now) − claimed[msg.sender]
```

## Por qué un contrato custom y no 7× OZ `VestingWallet`

`VestingWallet` libera linealmente desde `start`. No expresa "100 de golpe en el cliff + 900 lineales"
sin trucos, y además serían 7 deploys y 7 transferencias de fondeo. Con un solo contrato hay un solo
address que publicar y un `totalSupply` verificable de un vistazo.

## Seguridad: claim-only-own

`claim()` no recibe parámetros: siempre calcula y paga a `msg.sender`. No existe una función
que permita reclamar para otro address, así que nadie puede tocar la allocation de un compañero.
Tampoco hay owner, `mint`, `pause` ni `withdraw`: después del deploy nadie (ni el deployer)
puede mover los tokens fuera del calendario.

## Tests — 15/15 verdes ([`evidence/forge-test.txt`](evidence/forge-test.txt))

```bash
forge install && forge test -vv && forge test --gas-report
```

Cubren: supply 7k en el vesting, 1k por estudiante, timestamps absolutos GT, revert con ≠ 7 o duplicados,
0 antes del cliff, 100 en el cliff, 550 a mitad, 1000 al final, claim parcial + claim final = 1000,
claim-only-own, revert de un outsider, los 7 claims vacían el contrato, y dos fuzz
(vesting monotónico con tope 1000; cualquier secuencia de claims suma exactamente 1000).

## Simulación del ciclo completo en anvil ([`evidence/anvil-lifecycle.txt`](evidence/anvil-lifecycle.txt))

`./simulate.sh` levanta anvil 1 semana antes del cliff, despliega con 7 cuentas de prueba, avanza el reloj
y registra: claim antes del cliff → revert `NothingToClaim`; cliff + 6 h → claim de 325; outsider → revert
`NotBeneficiary`; fin → los 7 reclaman y cada uno queda en `claimed = 1000`; el vesting queda en 0.

> Esto es una simulación local, no el deploy de clase.

## Deploy de clase (una sola vez)

```bash
cast wallet import class-deployer --interactive
BENEFICIARIES=0x...,0x...,0x...,0x...,0x...,0x...,0x... \
forge script script/Deploy.s.sol --rpc-url $RPC_URL --account class-deployer --broadcast --verify
```

| | Valor |
|---|---|
| Red | _TODO_ |
| ClassVesting | _TODO_ |
| ClassToken | _TODO_ |
| Explorer | _TODO_ |

## Mi claim (homework)

```bash
V=<ClassVesting>; T=<ClassToken>; ME=<mi wallet>
cast call $V "allocation(address)(uint256)" $ME --rpc-url $RPC_URL   # 1000e18
cast call $V "releasable(address)(uint256)" $ME --rpc-url $RPC_URL   # > 0
cast send $V "claim()" --account mi-wallet --rpc-url $RPC_URL
cast call $V "claimed(address)(uint256)" $ME --rpc-url $RPC_URL      # 1000e18
cast call $T "totalSupply()(uint256)" --rpc-url $RPC_URL             # 7000e18
```

| Evidencia | Tx / link |
|---|---|
| Claim (releasable > 0) | _TODO_ |
| claimed = 1000 | _TODO_ |

## Comentarios de aprendizaje

- **Timestamps absolutos vs relativos:** `block.timestamp + 7 days` en el constructor solo coincide con
  "23 Sep 12:00 GT" si el deploy cae exactamente una semana antes, al segundo. Pasar `1790186400` fijo hace
  que el calendario no dependa de cuándo se mine el deploy. GT es UTC-6 sin horario de verano, así que
  12:00 GT = 18:00 UTC.
- **Redondeo:** la división entera de `900 · elapsed / 86400` trunca hacia abajo, así que un claim intermedio
  puede dejar "polvo" de wei. No se pierde: queda en `vested − claimed` y sale en el siguiente claim. El fuzz
  `testFuzz_ManyClaimsSumTo1000` lo verifica para secuencias arbitrarias.
- **Pull vs push:** el contrato no reparte; cada quien reclama (pull). Así nadie paga gas por los demás y una
  wallet perdida no bloquea al resto: sus tokens simplemente quedan sin reclamar.
- **Inmutabilidad como garantía:** al no haber admin, la confianza está en el código verificado. La contracara
  es que un address mal escrito en el deploy no se puede corregir: hay que redeployar todo. Por eso la regla
  de "lista de wallets antes del script".
