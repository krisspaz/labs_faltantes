#!/usr/bin/env bash
# Simulación local del ciclo completo en anvil (NO es el deploy de clase).
# Arranca la cadena 1 semana antes del cliff y avanza el reloj con evm_setNextBlockTimestamp.
set -uo pipefail
CLIFF=1790186400; END=1790272800; RPC=http://127.0.0.1:8545
LOG=$(mktemp); OUT=evidence/anvil-lifecycle.txt; mkdir -p evidence; : > $OUT
anvil --timestamp $((CLIFF - 7*86400)) > "$LOG" 2>&1 & ANVIL=$!; trap 'kill $ANVIL' EXIT
until cast block-number --rpc-url $RPC >/dev/null 2>&1; do sleep 0.3; done
PKS=($(sed -n '/Private Keys/,/Wallet/p' "$LOG" | grep -E '^\([0-9]\)' | awk '{print $2}'))
ADDRS=($(sed -n '/Available Accounts/,/Private Keys/p' "$LOG" | grep -E '^\([0-9]\)' | awk '{print $2}'))
log(){ echo "$@" | tee -a $OUT; }
q(){ cast call "$@" --rpc-url $RPC; }
try_claim(){ cast send $V 'claim()' --private-key "$1" --rpc-url $RPC 2>&1 | grep -oE 'NothingToClaim|NotBeneficiary|0x[0-9a-f]{8}' | head -1; }
send_claim(){ cast send $V 'claim()' --private-key "$1" --rpc-url $RPC --json | jq -r '"tx=" + .transactionHash + " status=" + .status'; }
warp(){ cast rpc evm_setNextBlockTimestamp $1 --rpc-url $RPC >/dev/null; cast rpc evm_mine --rpc-url $RPC >/dev/null; }

log "== Simulación local en anvil (NO es el deploy de clase) — $(date -u +%FT%TZ) =="
BEN=$(IFS=,; echo "${ADDRS[*]:1:7}")
log "beneficiaries (anvil #1..#7): $BEN"
BENEFICIARIES=$BEN forge script script/Deploy.s.sol --rpc-url $RPC --broadcast --private-key ${PKS[0]} >/dev/null 2>&1
RUN=broadcast/Deploy.s.sol/31337/run-latest.json
V=$(jq -r '.transactions[0].contractAddress' $RUN); T=$(q $V 'token()(address)')
log "ClassVesting: $V"; log "ClassToken:   $T"
log "deploy tx: $(jq -r '.receipts[0].transactionHash' $RUN)"
log "totalSupply: $(q $T 'totalSupply()(uint256)')"
log "balanceOf(vesting): $(q $V 'allocation(address)(uint256)' ${ADDRS[1]} >/dev/null; q $T 'balanceOf(address)(uint256)' $V)"
log "cliff: $(q $V 'cliff()(uint64)') = $(TZ=America/Guatemala date -r $CLIFF)"
log "end:   $(q $V 'end()(uint64)') = $(TZ=America/Guatemala date -r $END)"
for i in 1 2 3 4 5 6 7; do log "allocation(student$i ${ADDRS[$i]}): $(q $V 'allocation(address)(uint256)' ${ADDRS[$i]})"; done

log ""; log "-- t = cliff - 7d (antes del cliff) --"
log "releasable(student1): $(q $V 'releasable(address)(uint256)' ${ADDRS[1]})"
log "claim student1 -> revert: $(try_claim ${PKS[1]})"

warp $((CLIFF + 6*3600))
log ""; log "-- t = cliff + 6h (esperado 100 + 900/4 = 325) --"
log "releasable(student1): $(q $V 'releasable(address)(uint256)' ${ADDRS[1]})"
log "claim student1: $(send_claim ${PKS[1]})"
log "balanceOf(student1): $(q $T 'balanceOf(address)(uint256)' ${ADDRS[1]})"
log "claim outsider (anvil #8) -> revert: $(try_claim ${PKS[8]})"
log "claimed(student2) tras claim de student1: $(q $V 'claimed(address)(uint256)' ${ADDRS[2]})"

warp $((END + 60))
log ""; log "-- t = end + 1min --"
for i in 1 2 3 4 5 6 7; do log "student$i claim: $(send_claim ${PKS[$i]}) claimed=$(q $V 'claimed(address)(uint256)' ${ADDRS[$i]})"; done
log "claim student1 otra vez -> revert: $(try_claim ${PKS[1]})"
log "balanceOf(vesting) final: $(q $T 'balanceOf(address)(uint256)' $V)"
