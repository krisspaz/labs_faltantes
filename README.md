# Labs faltantes — CS031

Un folder por lab. Cada link de abajo es el que va en el carnet.

| Lab | Sesión | Entregable principal | Carpeta | Estado |
|---|---|---|---|---|
| **06** Forense Taproot vs Ethereum | S7 | [TX_FORENSICS.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab06-forensics-taproot-eth/TX_FORENSICS.md) | [lab06](https://github.com/krisspaz/labs_faltantes/tree/main/lab06-forensics-taproot-eth) | ✅ Completo |
| **09** ERC-20 Foundry | S10 | [README + evidencia](https://github.com/krisspaz/labs_faltantes/blob/main/lab09-erc20-foundry/README.md) | [lab09](https://github.com/krisspaz/labs_faltantes/tree/main/lab09-erc20-foundry) | ✅ Tests y anvil · ⏳ deploy Sepolia |
| **12** Vesting de clase | S14 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab12-class-vesting/README.md) | [lab12](https://github.com/krisspaz/labs_faltantes/tree/main/lab12-class-vesting) | ✅ Contrato, tests y simulación · ⏳ claim real desde mi wallet |
| **13** Token due diligence | S15 | [DUE_DILIGENCE.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab13-token-due-diligence/DUE_DILIGENCE.md) · [MEMO.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab13-token-due-diligence/MEMO.md) | [lab13](https://github.com/krisspaz/labs_faltantes/tree/main/lab13-token-due-diligence) | ✅ Completo |
| **15** IPFS + Pinata | S18 | [STORAGE.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab15-ipfs-pinata/STORAGE.md) | [lab15](https://github.com/krisspaz/labs_faltantes/tree/main/lab15-ipfs-pinata) | ✅ CID pineado en Pinata · resuelve en gateway Pinata y Filebase |
| **16** Pear · Hyperswarm · Hypercore | S19 | [P2P.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab16-p2p-hyperswarm/P2P.md) | [lab16](https://github.com/krisspaz/labs_faltantes/tree/main/lab16-p2p-hyperswarm) | ✅ Logs reales y kill-seeder · ✅ repetido entre 2 máquinas/redes (Mac ↔ runner) sin compañero |
| **17** Tor Browser + threat model | S20 | [THREAT.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab17-tor-threat/THREAT.md) | [lab17](https://github.com/krisspaz/labs_faltantes/tree/main/lab17-tor-threat) | ✅ Circuito real, nuevo circuito, contraste y THREAT.md |
| **18** Signal + WireGuard | S21 | [E2EE.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab18-signal-wireguard/E2EE.md) | [lab18](https://github.com/krisspaz/labs_faltantes/tree/main/lab18-signal-wireguard) | ✅ E2EE.md y tabla B · ⏳ Safety Number y túnel con compañero |
| **19** Nostr multi-relay | S22 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab19-nostr-relays/README.md) | [lab19](https://github.com/krisspaz/labs_faltantes/tree/main/lab19-nostr-relays) | ⏳ en clase |
| **20** Global Chess Passport (caso DID/VC) | S23 | [README (plantilla)](https://github.com/krisspaz/labs_faltantes/blob/main/lab20-chess-passport/README.md) | [lab20](https://github.com/krisspaz/labs_faltantes/tree/main/lab20-chess-passport) | ⏳ reporte escrito a mano por mí (sin IA, regla del lab) |
| **21** Cueva ZK + caso real | S24 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab21-cueva-zk/README.md) + fotos | [lab21](https://github.com/krisspaz/labs_faltantes/tree/main/lab21-cueva-zk) | ✅ tabla de rondas (aleatoria) · ⏳ foto + ficha + reflexión |
| **23** MPC + inventario post-cuántico | S26 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab23-mpc-postcuantico/README.md) + fotos | [lab23](https://github.com/krisspaz/labs_faltantes/tree/main/lab23-mpc-postcuantico) | ✅ promedio secreto + colusión · ⏳ foto A.2/A.4 + reflexión |
| **24** IA local con QV.AC | S27 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab24-ia-local/README.md) | [lab24](https://github.com/krisspaz/labs_faltantes/tree/main/lab24-ia-local) | ⏳ medir L1, L2 y nube con cronómetro |

Sesión 25 / Lab 22 no se impartió (handbook CS031, 2026-10-26). Labs 19–24 eran en clase; hechos en solitario fuera de clase.

## Clonar

```bash
git clone --recurse-submodules https://github.com/krisspaz/labs_faltantes.git
cd labs_faltantes/lab09-erc20-foundry && forge test     # 10/10
cd ../lab12-class-vesting && forge test                # 15/15
cd ../lab06-forensics-taproot-eth && ./verify.sh       # re-verifica las 4 txs
```
