// Parte A + B: unirse al topic de clase y mandar "ping desde {carnet}" a cada peer que conecte.
// Uso: node peer.js <carnet> [topicString]
const Hyperswarm = require('hyperswarm')
const crypto = require('crypto')

const carnet = process.argv[2] || 'anon'
const topicString = process.argv[3] || process.env.TOPIC || 'cs031-s19-20261005'
const topic = crypto.createHash('sha256').update(topicString).digest() // 32 bytes

const short = (buf) => buf.toString('hex').slice(0, 8)
const log = (...a) => console.log(new Date().toISOString(), `[${carnet}]`, ...a)

const swarm = new Hyperswarm()
log(`self=${short(swarm.keyPair.publicKey)} topic="${topicString}" sha256=${short(topic)}…`)

let everConnected = 0
swarm.on('connection', (socket, info) => {
  everConnected++
  const peer = short(info.publicKey)
  const raw = socket.rawStream || {}
  log(`connected peer=${peer} remote=${raw.remoteHost}:${raw.remotePort} initiator=${info.client}`)
  socket.write(`ping desde ${carnet}`)
  socket.on('data', (d) => log(`recv peer=${peer} payload="${d.toString()}"`))
  socket.on('error', (e) => log(`socket error peer=${peer} ${e.code || e.message}`))
  socket.on('close', () => log(`closed peer=${peer}`))
})

const t0 = Date.now()
swarm.join(topic, { server: true, client: true })
swarm.flush().then(() => log(`announced + lookup done in ${Date.now() - t0} ms, peers=${swarm.connections.size}`))

const timeoutMs = Number(process.env.TIMEOUT_MS || 60000)
setTimeout(() => {
  log(everConnected ? `done: ${everConnected} peer(s) seen` : `TIMEOUT: no peers after ${timeoutMs} ms`)
  swarm.destroy().then(() => process.exit(0))
}, timeoutMs)
process.on('SIGINT', () => swarm.destroy().then(() => process.exit(0)))
