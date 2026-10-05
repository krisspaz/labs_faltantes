// Downloader: busca el core por su discoveryKey, baja bloque a bloque (con throttle para poder
// matar al seeder a mitad) y reporta qué pasó si los peers desaparecen.
// Uso: node download.js <key> <archivoSalida> [msPorBloque]
const Hyperswarm = require('hyperswarm')
const Corestore = require('corestore')
const fs = require('fs')
const os = require('os')
const path = require('path')
const crypto = require('crypto')

const short = (b) => b.toString('hex').slice(0, 8)
const log = (...a) => console.log(new Date().toISOString(), '[downloader]', ...a)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function main () {
  const [key, out, delay = '100'] = process.argv.slice(2)
  const store = new Corestore(fs.mkdtempSync(path.join(os.tmpdir(), 'dl-')))
  const core = store.get({ key: Buffer.from(key, 'hex') })
  await core.ready()

  const swarm = new Hyperswarm()
  swarm.on('connection', (conn, info) => {
    log(`connected peer=${short(info.publicKey)} remote=${conn.rawStream?.remoteHost}:${conn.rawStream?.remotePort}`)
    conn.on('close', () => log(`peer closed peer=${short(info.publicKey)} (peers left=${core.peers.length})`))
    store.replicate(conn)
  })
  const done = core.findingPeers()
  swarm.join(core.discoveryKey, { server: false, client: true })
  swarm.flush().then(done)

  await core.update({ wait: true })
  log(`core length=${core.length} blocks`)

  const t0 = Date.now()
  const chunks = []
  for (let i = 0; i < core.length; i++) {
    try {
      chunks.push(await core.get(i, { timeout: 15000 }))
    } catch (e) {
      log(`STALLED at block ${i}/${core.length} after ${Date.now() - t0} ms: ${e.code || e.message} (peers=${core.peers.length})`)
      log(`partial: ${chunks.length} blocks (${chunks.reduce((n, c) => n + c.length, 0)} bytes)`)
      await swarm.destroy(); process.exit(2)
    }
    if (i % 8 === 0) log(`block ${i}/${core.length} peers=${core.peers.length}`)
    await sleep(Number(delay))
  }
  const data = Buffer.concat(chunks)
  fs.writeFileSync(out, data)
  log(`COMPLETE ${data.length} bytes in ${Date.now() - t0} ms sha256=${crypto.createHash('sha256').update(data).digest('hex').slice(0, 16)}…`)
  await swarm.destroy(); process.exit(0)
}
main()
