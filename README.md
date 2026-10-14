# Labs faltantes — CS031

Un folder por lab. Cada link de abajo es el que va en el carnet.

| Lab | Sesión | Entregable principal | Carpeta | Estado |
|---|---|---|---|---|
| **06** Forense Taproot vs Ethereum | S7 | [TX_FORENSICS.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab06-forensics-taproot-eth/TX_FORENSICS.md) | [lab06](https://github.com/krisspaz/labs_faltantes/tree/main/lab06-forensics-taproot-eth) | ✅ Completo |
| **09** ERC-20 Foundry | S10 | [README + evidencia](https://github.com/krisspaz/labs_faltantes/blob/main/lab09-erc20-foundry/README.md) | [lab09](https://github.com/krisspaz/labs_faltantes/tree/main/lab09-erc20-foundry) | ✅ Tests y anvil · ⏳ deploy Sepolia |
| **12** Vesting de clase | S14 | [README](https://github.com/krisspaz/labs_faltantes/blob/main/lab12-class-vesting/README.md) | [lab12](https://github.com/krisspaz/labs_faltantes/tree/main/lab12-class-vesting) | ✅ Contrato, tests y simulación · ⏳ claim real desde mi wallet |
| **13** Token due diligence | S15 | [DUE_DILIGENCE.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab13-token-due-diligence/DUE_DILIGENCE.md) · [MEMO.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab13-token-due-diligence/MEMO.md) | [lab13](https://github.com/krisspaz/labs_faltantes/tree/main/lab13-token-due-diligence) | ✅ Completo |
| **15** IPFS + Pinata | S18 | [STORAGE.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab15-ipfs-pinata/STORAGE.md) | [lab15](https://github.com/krisspaz/labs_faltantes/tree/main/lab15-ipfs-pinata) | ⏳ falta correr `run-lab.sh` con cuenta Pinata |
| **16** Pear · Hyperswarm · Hypercore | S19 | [P2P.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab16-p2p-hyperswarm/P2P.md) | [lab16](https://github.com/krisspaz/labs_faltantes/tree/main/lab16-p2p-hyperswarm) | ✅ Logs reales y kill-seeder · ⏳ repetir kickoff con un compañero |
| **17** Tor Browser + threat model | S20 | [THREAT.md](https://github.com/krisspaz/labs_faltantes/blob/main/lab17-tor-threat/THREAT.md) | [lab17](https://github.com/krisspaz/labs_faltantes/tree/main/lab17-tor-threat) | ✅ Circuito real, nuevo circuito, contraste y THREAT.md |

## Clonar

```bash
git clone --recurse-submodules https://github.com/krisspaz/labs_faltantes.git
cd labs_faltantes/lab09-erc20-foundry && forge test     # 10/10
cd ../lab12-class-vesting && forge test                # 15/15
cd ../lab06-forensics-taproot-eth && ./verify.sh       # re-verifica las 4 txs
```
