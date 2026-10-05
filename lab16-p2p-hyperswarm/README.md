# Lab 16 — Pear · Hyperswarm · Hypercore: P2P sin servidor (Sesión 19)

- **Informe:** [P2P.md](P2P.md) (diagrama, infraestructura, liability, 15-2026, comentarios)
- **Logs del kickoff:** [`logs/kickoff-peerA.log`](logs/kickoff-peerA.log), [`logs/kickoff-peerB.log`](logs/kickoff-peerB.log) e intento fallido `logs/attempt1-*`
- **Kill-seeder:** `logs/exp1-*` (completo), `logs/exp2-*` (seeder muerto → stall), `logs/exp3-*` (con reseeder → completo)

```bash
npm install
node peer.js <carnet> "cs031-s19-YYYYMMDD"      # Parte A+B
node seed.js sample.txt                          # imprime la key
node seed.js --reseed <key>                      # segundo seeder opcional
node download.js <key> out.txt 300               # 300 ms/bloque para poder matar al seeder a mitad
```

Node.js v24 · hyperswarm 4.17.2 · hypercore 11.37.2 · corestore 7.13.0
