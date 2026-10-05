import urllib.request, re, io, sys, hashlib, json
API = "https://mempool.space/api"
PAT = re.compile(r"^82012088a914[0-9a-f]{40}8820[0-9a-f]{64}ac$")
def get(p, raw=False):
    with urllib.request.urlopen(API + p, timeout=60) as r: return r.read() if raw else r.read().decode()
def varint(s):
    n = s.read(1)[0]
    if n < 0xfd: return n
    return int.from_bytes(s.read({0xfd:2,0xfe:4,0xff:8}[n]), "little")
def parse_tx(s):
    start = s.tell(); ver = s.read(4); seg = False
    if s.read(1)[0] == 0: s.read(1); seg = True
    else: s.seek(-1, 1)
    nin = varint(s); ins = []
    for _ in range(nin):
        prev = s.read(32)[::-1].hex(); vout = int.from_bytes(s.read(4), "little")
        s.read(varint(s)); s.read(4); ins.append((prev, vout))
    for _ in range(varint(s)): s.read(8); s.read(varint(s))
    wits = []
    if seg:
        for _ in range(nin): wits.append([s.read(varint(s)).hex() for _ in range(varint(s))])
    s.read(4)
    return ins, wits
tip = int(get("/blocks/tip/height")); found = []
for h in range(tip, tip - int(sys.argv[1]), -1):
    bh = get(f"/block-height/{h}"); raw = get(f"/block/{bh}/raw", raw=True)
    s = io.BytesIO(raw); s.read(80); n = varint(s)
    for _ in range(n):
        a = s.tell(); ins, wits = parse_tx(s); b = s.tell()
        for i, w in enumerate(wits):
            if len(w) == 4 and PAT.match(w[2]) and w[3][:2] in ("c0", "c1"):
                # txid = hash del tx sin witness: lo pedimos al API por posición es caro; calculamos desde la API del input
                found.append({"height": h, "prevout": ins[i], "preimage": w[1], "script": w[2]})
    print(h, "found so far", len(found), file=sys.stderr)
    if len(found) >= 3: break
print(json.dumps(found, indent=1))
