# Lab 18 — Signal + Safety Number y túnel WireGuard (Sesión 21)

- **Informe:** [E2EE.md](E2EE.md) (FS/PCS, acceso excepcional + Keys Under Doormats, Tor vs Signal vs WireGuard)
- **Safety Number:** [`evidence/safety-number-tachado.png`](evidence/safety-number-tachado.png) · Signal Desktop oficial instalado y vinculado: [`evidence/signal-instalado.png`](evidence/signal-instalado.png)
- **WireGuard:** [`evidence/wg-show.txt`](evidence/wg-show.txt), [`evidence/ping.txt`](evidence/ping.txt), [`evidence/wg-capture.png`](evidence/wg-capture.png) (opcional)

Stack: Signal Desktop/móvil oficial (signal.org/download) · wireguard-tools v1.0.20260223 + wireguard-go (Homebrew) · tcpdump/Wireshark.

## Parte A — Safety Number

Verificado con ⏳ (carnet ___) en persona por ⏳ QR / dígitos, marcado como **verified** el ⏳ fecha.

**¿Qué detecta un Safety Number que no coincide?** Un **man-in-the-middle en el intercambio de llaves**: que el
servidor (o quien lo controle) haya entregado una identity key distinta de la de mi compañero, para que yo cifre
hacia el atacante. También aparece si mi compañero reinstaló Signal o cambió de teléfono (por eso se re-verifica,
no se asume ataque).

## Parte B — servidor sabe / servidor no lee

| Dato | ¿El servidor lo sabe? | Por qué (diseño / fuente) |
|---|---|---|
| Texto del mensaje | **No lo lee** | E2EE con Signal Protocol; el servidor solo transporta ciphertext |
| Que la cuenta existe | **Sí** | Registro con número de teléfono; bigbrother: entregan fecha de creación |
| Cuándo se conectó el dispositivo | **Sí** (última conexión, a nivel de día) | Necesario para entregar mensajes; es lo segundo que entregan en bigbrother |
| Tamaño aproximado | **Sí, en tránsito** | Ve el tamaño del ciphertext (con padding), no lo guarda como registro |
| Quién envió | **No, en general** | Sealed sender: el remitente va dentro del sobre cifrado; el servidor ve el destinatario y un delivery token |
| IP mientras está conectado | **Sí, en tránsito** | TCP/TLS la expone; Signal afirma no guardarla (no aparece en bigbrother) |
| Lista de contactos / grupos | **No lo lee** | Contact discovery en enclave SGX con hashes; grupos privados con estado cifrado (zkgroup) |

**Contraste bigbrother:** "lo que el servidor ve en tránsito" (IP, tamaño, destinatario, horarios) es más que
"lo que el proveedor guarda y puede entregar": en las respuestas publicadas en signal.org/bigbrother solo
entregan **fecha de creación de la cuenta y fecha de última conexión**. La diferencia es una decisión de
retención, no una imposibilidad técnica: un proveedor menos cuidadoso podría loggear todo lo de tránsito.

**Chat de lab:** `safety number verified: ⏳ sí/no` · `el servidor no puede leer el texto ni quién envió (sealed sender) pero sí sabe que mi cuenta existe, cuándo me conecté y mi IP en tránsito`

## Túnel WireGuard

Topología: ⏳ laptop (10.18.0.1) ↔ laptop de compañero (10.18.0.2) en red con permiso / o VPS propio.
Solo se intercambiaron llaves **públicas**. Las privadas viven en `~/.wg-lab18/` (fuera del repo, `chmod 700`).

```bash
./wg/setup-peer.sh keys                                          # cada peer; comparten solo la PublicKey
./wg/setup-peer.sh conf 10.18.0.1 10.18.0.2 '<pubkey-peer>' <ip-lan-peer>:51820
sudo wg-quick up ~/.wg-lab18/wg-lab18.conf
sudo wg show > evidence/wg-show.txt; ping -c 4 10.18.0.2 | tee evidence/ping.txt
sudo tcpdump -i en0 -w evidence/wg.pcap udp port 51820         # opcional, abrir en Wireshark
sudo wg-quick down ~/.wg-lab18/wg-lab18.conf                     # bajar el túnel al terminar
```

`AllowedIPs = 10.18.0.2/32` (solo el otro peer, no full-tunnel).

Evidencia: `latest handshake: ⏳` · `transfer: ⏳ received, ⏳ sent` · ping ⏳/4 respuestas.
En la captura: Handshake Initiation (tipo 1, 148 B) → Handshake Response (tipo 2, 92 B) → Transport Data (tipo 4) con payload ilegible.

**Mi ISP / la red ve** dos IPs intercambiando UDP en el puerto 51820, el tamaño y la frecuencia de los paquetes,
y que es WireGuard (el formato del handshake es reconocible). **El otro peer del túnel ve** mi IP real y el
contenido descifrado de todo lo que mando a 10.18.0.2, incluido el ICMP del ping.

> Si la red bloquea UDP 51820: pegar el `wg show` sin handshake (`latest handshake` ausente, `0 B received`),
> la red y la hora. No se evadió el bloqueo.
