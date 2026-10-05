// Seeder: mete un archivo en un Hypercore (bloques de 16 KiB) y lo sirve por Hyperswarm.
// Uso: node seed.js <archivo> [storageDir]
//      node seed.js --reseed <key> [storageDir]   (segundo seeder: replica el core completo y lo sirve)
const Hyperswarm = require('hyperswarm')
const Corestore = require('corestore')
const fs = require('fs')

const BLOCK = 16 * 1024
const short = (b) => b.toString('hex').slice(0, 8)
const log = (...a) => console.log(new Date().toISOString(), '[seeder]', ...a)

async function main () {
  const reseed = process.argv[2] === '--reseed'
  const store = new Corestore(reseed ? (process.argv[4] || './store-reseeder') : (process.argv[3] || './store-seeder'))
  const core = reseed ? store.get({ key: Buffer.from(process.argv[3], 'hex') }) : store.get({ name: 'file' })
  await core.ready()

  const swarm = new Hyperswarm()
  swarm.on('connection', (conn, info) => {
    log(`connected peer=${short(info.publicKey)} remote=${conn.rawStream?.remoteHost}`)
    store.replicate(conn)
  })

  if (!reseed) {
    const file = process.argv[2]
    if (core.length === 0) {
      const data = fs.readFileSync(file)
      const blocks = []
      for (let i = 0; i < data.length; i += BLOCK) blocks.push(data.subarray(i, i + BLOCK))
      await core.append(blocks)
      log(`appended ${file} (${data.length} bytes) in ${blocks.length} blocks`)
    }
  }

  const done = core.findingPeers()
  swarm.join(core.discoveryKey, { server: true, client: true })
  swarm.flush().then(done)

  if (reseed) {
    await core.update({ wait: true })
    await core.download({ start: 0, end: core.length }).done()
    log(`reseeder has full copy: ${core.contiguousLength}/${core.length} blocks`)
  }

  log(`seeding key=${core.key.toString('hex')} length=${core.length}`)
  log(`discoveryKey=${short(core.discoveryKey)}… (lo que se anuncia en la DHT, no la key)`)
  process.on('SIGINT', async () => { log('SIGINT: seeder killed'); process.exit(0) })
}
main()
