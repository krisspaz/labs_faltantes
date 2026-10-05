#!/usr/bin/env bash
# Re-verifica las 4 txs del forense contra fuentes independientes. Requiere: curl, jq, python3, cast (Foundry).
set -euo pipefail
BTC_LOCK=03010ef205d925708c005585865bd90c4595750c85a50bbbcfbefa06c66d63db
BTC_CLAIM=34039191b23050737ec5d379fba5a9759be32804e9bf74292f74f8a044fe3117
ETH_LOCK=0x3061cd37ce12acbaa816a6ce1e8779ecbf26e27c5980d5d3b9acf40d517c3748
ETH_CLAIM=0x7ec4aac5fd922aa914a2c40093e515103539f151b02d98cea23cec98ecc555ef
ETH_RPC_A=${ETH_RPC_A:-https://eth.drpc.org}
ETH_RPC_B=${ETH_RPC_B:-https://eth-mainnet.public.blastapi.io}
sha(){ python3 -c "import hashlib,sys;print(hashlib.sha256(bytes.fromhex(sys.argv[1])).hexdigest())" "$1"; }
h160(){ python3 -c "import hashlib,sys;print(hashlib.new('ripemd160',hashlib.sha256(bytes.fromhex(sys.argv[1])).digest()).hexdigest())" "$1"; }

echo "== BTC: verificación 1 (mempool.space) vs verificación 2 (blockstream.info)"
for t in $BTC_LOCK $BTC_CLAIM; do
  a=$(curl -fsS https://mempool.space/api/tx/$t/hex); b=$(curl -fsS https://blockstream.info/api/tx/$t/hex)
  [ "$a" = "$b" ] && echo "  ${t:0:12}… hex idéntico ($(( ${#a} / 2 )) bytes)" || { echo "  ${t:0:12}… DIFIERE"; exit 1; }
  # el txid es sha256d del tx sin witness: lo recalculamos localmente desde el hex
  python3 - "$a" "$t" <<'PY'
import sys,hashlib,io
raw=bytes.fromhex(sys.argv[1]); s=io.BytesIO(raw)
def vi(s):
    n=s.read(1)[0]
    return n if n<0xfd else int.from_bytes(s.read({0xfd:2,0xfe:4,0xff:8}[n]),'little')
ver=s.read(4); assert s.read(2)==b'\x00\x01'
body_start=s.tell(); nin=vi(s)
for _ in range(nin): s.read(36); s.read(vi(s)); s.read(4)
for _ in range(vi(s)): s.read(8); s.read(vi(s))
body=raw[body_start:s.tell()]; lock=raw[-4:]
txid=hashlib.sha256(hashlib.sha256(ver+body+lock).digest()).digest()[::-1].hex()
print("  txid recalculado localmente:", "OK" if txid==sys.argv[2] else "FAIL "+txid)
PY
done
W=$(curl -fsS https://mempool.space/api/tx/$BTC_CLAIM | jq -r '.vin[0].witness[1]')
S=$(curl -fsS https://mempool.space/api/tx/$BTC_CLAIM | jq -r '.vin[0].witness[2]')
echo "  preimage (witness[1]) hash160 = $(h160 $W); en el script: ${S:12:40}"
echo "  sha256(preimage) = $(sha $W)  ← payment hash de la factura Lightning"
SP=$(curl -fsS https://mempool.space/api/tx/$BTC_LOCK/outspend/0 | jq -r .txid)
echo "  output 0 del lockup lo gasta: ${SP:0:12}… ($( [ "$SP" = "$BTC_CLAIM" ] && echo OK || echo FAIL))"

echo "== ETH: verificación 1 ($ETH_RPC_A) vs verificación 2 ($ETH_RPC_B)"
for t in $ETH_LOCK $ETH_CLAIM; do
  a=$(cast tx $t --raw --rpc-url $ETH_RPC_A); b=$(cast tx $t --raw --rpc-url $ETH_RPC_B)
  [ "$a" = "$b" ] && echo "  ${t:0:12}… raw idéntico" || { echo "  ${t:0:12}… DIFIERE"; exit 1; }
  echo "  keccak(raw) = $(cast keccak $a | cut -c1-14)… ($( [ "$(cast keccak $a)" = "$t" ] && echo 'hash OK' || echo FAIL))"
done
P=$(cast receipt $ETH_CLAIM --json --rpc-url $ETH_RPC_A | jq -r '.logs[0].data' | cut -c3-)
H=$(cast receipt $ETH_LOCK --json --rpc-url $ETH_RPC_A | jq -r '.logs[0].topics[1]' | cut -c3-)
echo "  sha256(preimage del Claim) = $(sha $P)"
echo "  preimageHash del Lockup    = $H ($( [ "$(sha $P)" = "$H" ] && echo OK || echo FAIL))"
