#!/usr/bin/env bash
# Genera llaves y config WireGuard FUERA del repo (~/.wg-lab18). Solo imprime la llave pública.
# Uso:
#   ./wg/setup-peer.sh keys                                   # genera llaves, imprime tu PublicKey
#   ./wg/setup-peer.sh conf <mi-ip> <peer-ip> <peer-pubkey> [peer-endpoint:51820]
#      ej: ./wg/setup-peer.sh conf 10.18.0.1 10.18.0.2 'AbC...=' 192.168.1.50:51820
#   sudo wg-quick up ~/.wg-lab18/wg-lab18.conf  /  sudo wg-quick down ~/.wg-lab18/wg-lab18.conf
set -euo pipefail
DIR="$HOME/.wg-lab18"
mkdir -p "$DIR" && chmod 700 "$DIR"
umask 077

case "${1:-}" in
  keys)
    [[ -f "$DIR/private.key" ]] || wg genkey > "$DIR/private.key"
    wg pubkey < "$DIR/private.key" > "$DIR/public.key"
    echo "Tu PublicKey (esta sí se comparte):"
    cat "$DIR/public.key"
    ;;
  conf)
    MY_IP="$2"; PEER_IP="$3"; PEER_PUB="$4"; PEER_EP="${5:-}"
    {
      echo "[Interface]"
      echo "PrivateKey = $(cat "$DIR/private.key")"
      echo "Address = $MY_IP/32"
      echo "ListenPort = 51820"
      echo
      echo "[Peer]"
      echo "PublicKey = $PEER_PUB"
      echo "AllowedIPs = $PEER_IP/32        # solo el otro peer, no full-tunnel"
      [[ -n "$PEER_EP" ]] && echo "Endpoint = $PEER_EP"
      echo "PersistentKeepalive = 25"
    } > "$DIR/wg-lab18.conf"
    echo "Config escrita en $DIR/wg-lab18.conf (fuera del repo)."
    ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
