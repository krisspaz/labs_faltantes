# Lab 09 — ERC-20 con Foundry (Sesión 10)

ERC-20 `LabToken` (LAB) sobre OpenZeppelin Contracts v5, Solidity `0.8.36`, con **fee-on-transfer** opcional.

## Contrato — `src/LabToken.sol`

- Supply fijo: 1,000,000 LAB minteado al deployer en el constructor. No hay `mint` público.
- Fee-on-transfer: `feeBps` (default 1%, tope duro `MAX_FEE_BPS` = 5%) que va al `treasury`.
- Exenciones: el deployer y el treasury no pagan fee; el owner puede marcar otras cuentas (p. ej. un pool de liquidez).
- Implementado con un override de `_update` (el hook único de OZ v5). Mint y burn nunca cobran fee.

## Correr

```bash
forge install          # forge-std + openzeppelin-contracts (submódulos)
forge build
forge test -vv
forge test --gas-report
```

## Tests (10/10 verdes) — [`evidence/forge-test.txt`](evidence/forge-test.txt)

| Tipo | Archivo | Qué prueba |
|---|---|---|
| Unit | `test/LabToken.t.sol` | metadata, fee 1%, exención, allowance, reverts (`ERC20InsufficientBalance`, `FeeTooHigh`, `OwnableUnauthorizedAccount`) |
| Fuzz (1000 runs) | `testFuzz_TransferConservesValue` | para cualquier monto y fee ≤ 5%: alice + bob + treasury se conserva y la fee es exactamente `amount * bps / 10_000` |
| Invariant (256 runs × 50 calls) | `test/LabToken.invariant.t.sol` | con un handler que hace transfer/approve/transferFrom: `totalSupply` constante y suma de balances = supply |

Gas report: [`evidence/gas-report.txt`](evidence/gas-report.txt). Deploy cuesta ~1.61M gas.

## Deploy

### Anvil (local) — [`evidence/anvil-deploy.txt`](evidence/anvil-deploy.txt)

```bash
anvil
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key <key #0 de anvil>
```

- Address: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- Tx: `0xadad02301d4bc9efe8440d9dd69e49243f23a58de5ed233db72075f54a7b747a` (block 1, status 1)
- `totalSupply()` = 1e24 (1,000,000 × 10^18), `feeBps()` = 100

### Sepolia (pendiente)

```bash
cast wallet import lab-deployer --interactive          # la key no toca disco en texto plano
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --account lab-deployer --broadcast \
  --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

Hash Sepolia: _TODO_ · Etherscan: _TODO_

## Comentarios

- **Por qué `_update` y no `transfer`:** en OZ v5 `transfer`, `transferFrom`, `_mint` y `_burn` pasan todos por `_update`. Con un solo override la fee cubre todos los caminos, incluido `transferFrom`, que en v4 era fácil olvidar.
- **Fee-on-transfer rompe supuestos:** quien recibe `amount` en realidad recibe `amount - fee`. Un protocolo que hace `transferFrom(user, this, amount)` y acredita `amount` sin medir el delta de balance queda insolvente. Por eso Uniswap V2 tiene funciones `...SupportingFeeOnTransferTokens`, y por eso existen las exenciones.
- **Invariant vs fuzz:** el fuzz prueba una sola llamada con inputs aleatorios. El invariant prueba *secuencias* de llamadas y comprueba que una propiedad global (conservación de supply) nunca se rompe. Es el test que atraparía un redondeo que crea o destruye tokens.
- **Centralización:** el owner puede subir la fee hasta 5%. El tope está hardcodeado justo para acotar ese poder; un token "honesto" lo documenta o renuncia a ownership (`renounceOwnership`).
