#!/usr/bin/env bash
# Lab 15: sube venture-hello.json a Pinata, verifica el pin y lo resuelve por 2 gateways.
# Requiere .env con PINATA_JWT (scope mínimo: pinFileToIPFS + pinList). Nunca imprime el JWT.
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo "Falta .env (copia .env.example y pon PINATA_JWT)"; exit 1; }
set -a; source .env; set +a
[ -n "${PINATA_JWT:-}" ] || { echo "PINATA_JWT vacío en .env"; exit 1; }
GW="${PINATA_GATEWAY:-gateway.pinata.cloud}"
FILE=venture-hello.json
OUT=evidence/lab-log.md
NOW=$(date -u +%FT%TZ)

echo "== 1. Upload ($FILE)"
RESP=$(curl -fsS -X POST https://api.pinata.cloud/pinning/pinFileToIPFS \
  -H "Authorization: Bearer $PINATA_JWT" \
  -F "file=@$FILE" \
  -F 'pinataMetadata={"name":"cs031-lab15-venture-hello"}' \
  -F 'pinataOptions={"cidVersion":1}')
CID=$(echo "$RESP" | jq -r .IpfsHash)
echo "$RESP" | jq '{IpfsHash, PinSize, Timestamp, isDuplicate}' > evidence/upload-response.json
echo "CID: $CID"

echo "== 2. Pin activo (pinList, sin keys)"
curl -fsS "https://api.pinata.cloud/data/pinList?hashContains=$CID&status=pinned" \
  -H "Authorization: Bearer $PINATA_JWT" \
  | jq '{count, rows: [.rows[] | {ipfs_pin_hash, size, date_pinned, date_unpinned, name: .metadata.name}]}' \
  > evidence/pin-list.json
cat evidence/pin-list.json

echo "== 3. Resolve por gateway"
resolve() {
  local url=$1
  echo "\$ curl -sS -D - $url"
  curl -sS -m 120 -D - "$url" -o evidence/resolved-body.tmp | grep -iE '^(HTTP|content-type|x-ipfs-path|etag|x-ipfs-roots)' || true
  if cmp -s evidence/resolved-body.tmp "$FILE"; then echo "(body idéntico a $FILE)"; else echo "(body DIFERENTE o no resolvió)"; fi
  rm -f evidence/resolved-body.tmp
}
{
  echo "# Lab 15 — log de ejecución ($NOW)"
  echo
  echo "- Provider: Pinata · CID: \`$CID\` · archivo: \`$FILE\` ($(wc -c < $FILE | tr -d ' ') bytes)"
  echo "- SHA-256 local del archivo: \`$(shasum -a 256 $FILE | cut -d' ' -f1)\`"
  echo
  echo "## Pin (pinList)"; echo; echo '```json'; cat evidence/pin-list.json; echo '```'
  echo
  echo "## Resolve: gateway de Pinata"; echo; echo '```'; resolve "https://$GW/ipfs/$CID"; echo '```'
  echo
  echo "## Resolve: gateway público independiente (ipfs.io)"; echo; echo '```'; resolve "https://ipfs.io/ipfs/$CID"; echo '```'
  echo
  echo "## Resolve: dweb.link (subdomain gateway)"; echo; echo '```'; resolve "https://$CID.ipfs.dweb.link/"; echo '```'
} | tee "$OUT"

sed -i '' "s|<CID>|$CID|g; s|<GATEWAY_URL>|https://$GW/ipfs/$CID|g; s|<FECHA>|$NOW|g" STORAGE.md README.md 2>/dev/null || true
echo; echo "Listo. Revisa $OUT y STORAGE.md. Chat de lab: \"CID: ${CID:0:12}…  resolve: sí\""
