# Lab 19 — Nostr: una nota firmada en varios relays (Sesión 22)

> Se hace y se entrega **en clase**. nak 0.21.2 (Homebrew, formula oficial de github.com/fiatjaf/nak).
> La nsec **nunca** sale de la terminal: ni aquí, ni en chat, ni en capturas.

## Guía rápida (en clase)

```bash
# 1. Llave de test (solo en esta terminal)
export NOSTR_SECRET_KEY=$(nak key generate)
PUB=$(nak key public $NOSTR_SECRET_KEY); nak encode npub $PUB      # anotar npub

# 2. Firmar y verificar, sin internet
nak event -c 'CS031 Lab 19 · nota de prueba' -t t=cs031lab19 > nota1.json
cat nota1.json                       # 7 campos: id, pubkey, created_at, kind, tags, content, sig
cat nota1.json | nak verify && echo válida   # nak no imprime nada si es válida (exit 0)
sed 's/prueba/prueba!/' nota1.json > alterada.json   # cambia el content, id y sig quedan iguales
cat alterada.json | nak verify       # falla: invalid .id, expected id::<nuevo> got id::<viejo> (exit≠0)

# 3. Publicar en 4 relays y pedirla de vuelta
cat nota1.json | nak event relay.damus.io nos.lol nostr.wine <relay-de-clase>
ID=$(jq -r .id nota1.json)
for r in relay.damus.io nos.lol nostr.wine <relay-de-clase>; do echo "== $r"; nak req -i $ID $r; done

# 4. Tras el ban del instructor: nota #2 (solo 3 relays)
nak event -c 'CS031 Lab 19 · nota de prueba #2' -t t=cs031lab19 relay.damus.io nos.lol <relay-de-clase>

# 5. Cerrar la terminal (la llave se va) y borrar nota1.json/alterada.json si no se entregan
```

## Entregable (carnet)

**npub de test:** `⏳ npub1...` · **id nota 1:** `⏳`

| Relay | ¿Aceptó nota 1? (respuesta) | ¿La devolvió? | ¿Aceptó la #2 tras el ban? |
|---|---|---|---|
| relay.damus.io | ⏳ OK / `...` | ⏳ | ⏳ |
| nos.lol | ⏳ | ⏳ | ⏳ |
| nostr.wine | ⏳ rechazo: `...` (relay de pago) | ⏳ no | — (no se publicó) |
| relay de clase | ⏳ | ⏳ | ⏳ `blocked: ...` |

**Firma:** la original es válida y la alterada es inválida, porque el `id` es el SHA-256 del evento serializado
(pubkey, created_at, kind, tags, content). Si cambias una letra del content, el hash ya no coincide con el `id`
(`invalid .id`). Y aunque recalcularas el id, la `sig` Schnorr firmaba el id viejo, así que sin la nsec no hay
firma válida.

**Reflexión:**
- Mi nota quedó en ⏳ de 4 relays; nostr.wine la rechazó con `⏳`.
- El ban me quitó el relay de clase (no acepta mis notas nuevas) pero no la nota #2 en damus y nos.lol ni mi identidad: la npub sigue siendo la misma en todos lados.
- Si mi venture tuviera una cuenta Nostr, la nsec la guardaría en un firmador remoto NIP-46 (bunker) en un dispositivo dedicado, con un responsable designado y respaldo cifrado (NIP-49, `ncryptsec`) en una bóveda offline, porque la nsec no se puede rotar: si se filtra, la identidad queda comprometida para siempre.
