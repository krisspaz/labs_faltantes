# Lab 15 — IPFS + Pinata: CID + pin + resolve (Sesión 18)

- [STORAGE.md](STORAGE.md): política de datos (clasificación, pin vs never-permanent, 15-2026, promesas)
- `evidence/lab-log.md`: pin activo + resolve por 3 gateways (lo genera `run-lab.sh`)
- Gateway: <GATEWAY_URL>

## Correr

1. En Pinata: API Keys → New Key → solo `pinFileToIPFS` y `pinList` → copiar el **JWT**.
2. `cp .env.example .env` y pegar el JWT en `PINATA_JWT=`. `.env` está en `.gitignore`.
3. `./run-lab.sh`: sube `venture-hello.json`, verifica el pin, lo resuelve y llena CID, gateway y fecha en STORAGE.md y este README.
4. Opcional: screenshot del dashboard de Pinata con el archivo "Pinned" en `evidence/`.

El JWT nunca se imprime ni se commitea. Si se filtra: revocarlo en Pinata y crear otro.

## Comentarios de aprendizaje

- **Qué pasa si unpinneamos:** el CID sigue siendo válido (es un hash), pero el contenido deja de resolver cuando
  ningún nodo lo tiene. El CID no promete disponibilidad; el pin sí, y solo mientras se pague.
- **Gateway vs protocolo:** Pinata, ipfs.io y dweb.link son tres servidores HTTP distintos que devuelven los
  mismos bytes para el mismo CID. El contenido no "vive" en ninguno: lo identifica su hash.
