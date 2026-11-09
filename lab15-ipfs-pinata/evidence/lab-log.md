# Lab 15 — log de ejecución (2026-11-09T22:31:12Z)

- Provider: Pinata · CID: `bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm` · archivo: `venture-hello.json` (175 bytes)
- SHA-256 local del archivo: `124438e31f9d8dff9dec6fc9073c8d5ce9437468765a27b8ec348e4df70a648b`

## Pin (pinList)

```json
{
  "count": 1,
  "rows": [
    {
      "ipfs_pin_hash": "bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm",
      "size": 175,
      "date_pinned": "2026-11-09T22:31:13.773Z",
      "date_unpinned": null,
      "name": "cs031-lab15-venture-hello"
    }
  ]
}
```

## Resolve: gateway de Pinata

```
$ curl -sS -D - https://gateway.pinata.cloud/ipfs/bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
HTTP/2 200 
content-type: application/json
etag: "bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm"
x-ipfs-path: /ipfs/bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
x-ipfs-roots: bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
(body idéntico a venture-hello.json)
```

## Resolve: gateway público independiente (ipfs.io)

```
$ curl -sS -D - https://ipfs.io/ipfs/bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
HTTP/2 429 
content-type: text/plain; charset=utf-8
(body DIFERENTE o no resolvió)
```

## Resolve: dweb.link (subdomain gateway)

```
$ curl -sS -D - https://bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm.ipfs.dweb.link/
HTTP/2 429 
content-type: text/plain; charset=utf-8
(body DIFERENTE o no resolvió)
```

## Resolve: gateway independiente (Filebase), 2026-11-09T22:33:44Z

```
$ curl -sS -D - https://ipfs.filebase.io/ipfs/bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
HTTP/2 200 
content-type: application/json
etag: "bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm"
x-ipfs-path: /ipfs/bafkreiasiq4ogh45rx7z33dpzedtzdk45fbxi2dwlit3r3burzg7octerm
(body idéntico a venture-hello.json)
```

Nota: ipfs.io y dweb.link devolvieron 429 con el texto "This IPFS gateway is switching to a service worker gateway only" (gatewaychanges.ipfs.io). No es falla del pin: el gateway de Pinata y el de Filebase sirven los mismos bytes.
