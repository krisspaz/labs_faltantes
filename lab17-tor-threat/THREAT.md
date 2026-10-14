# THREAT.md — Lab 17: Solo HTTPS vs Tor vs I2P (Sesión 20)

> **Supuesto (igual que Lab 15/16):** el venture es una plataforma de tokenización con usuarios verificados (KYC),
> que opera como PSAV y por tanto es **Persona Obligada** ante la IVE bajo el Decreto 15-2026.

## Data flow elegido: login → orden de compra de un token

1. El usuario abre `app.venture.gt`, hace login (email + contraseña + 2FA).
2. Coloca una **orden de compra**: monto en GTQ/USD, token, wallet de destino.
3. El backend valida KYC, límites y reglas de monitoreo, registra la orden y la ejecuta.

Activos: credenciales y sesión, monto/destino de la orden, la identidad KYC ligada a la cuenta, y la IP/ubicación
del usuario (metadata que dice dónde está y cuándo opera).

## Tabla de tres columnas

| Fila | Solo HTTPS | Tor Browser (clearnet vía exit) | I2P (in-net) |
|---|---|---|---|
| **IP del usuario** | La ven ISP, red local y el venture (logs, WAF, CDN) | Solo el guard. El venture ve la IP de un exit | Ningún peer individual; los túneles de salida/entrada esconden ambos extremos |
| **Destino** | ISP/red local lo ven por DNS + SNI (`app.venture.gt`) | ISP ve "Tor". El exit ve el dominio y la IP del venture | Nadie fuera del túnel ve que el destino es el venture. Requiere que el venture tenga un eepsite (no lo tiene) |
| **Payload** (orden, monto, wallet) | Cifrado por TLS hasta el venture | Cifrado por TLS dentro de Tor; el exit no lo lee | Cifrado extremo a extremo dentro de I2P (garlic routing) |
| **Exit / relay malicioso** | No aplica; el riesgo equivalente es un proxy corporativo con CA instalada | Ve dominio, timing y volumen. No ve payload si hay HTTPS + HSTS. Puede bloquear o degradar el servicio | No hay exit para un servicio in-net. Un router malicioso ve solo tráfico cifrado de túneles ajenos |
| **Login** | Ata la sesión a la identidad KYC **y** a la IP real | **Igual queda atado a la identidad KYC.** Tor oculta la IP, no quién soy: al iniciar sesión, el anonimato frente al venture desaparece | Igual: login + KYC identifican al usuario aunque la red no lo haga |
| **Costo para el usuario** | Ninguno | Latencia mayor, CAPTCHAs, y es probable que el WAF/antifraude del venture bloquee o marque las IPs de exit; geolocalización inútil para 2FA basado en riesgo | Instalar un router I2P, esperar que se integre, latencia alta; sin outproxy confiable no llega a clearnet |
| **Qué sigue viendo el venture** (y debe ver como Persona Obligada) | Todo: identidad KYC, orden, monto, wallet, IP, device | Identidad KYC, orden, monto, wallet, device; pierde la IP real. **Como Persona Obligada debe** conservar los registros de la transacción y la identidad del cliente, y puede requerir IP/geolocalización como señal de riesgo (jurisdicciones de alto riesgo). Tor no elimina esa obligación; la volvería difícil de cumplir | Lo mismo que con Tor, más la necesidad de operar un eepsite (fuera de alcance del lab) |

**Lectura:** el payload ya está protegido por HTTPS en las tres columnas. Lo que cambia es la **metadata**
(quién habla con quién, desde dónde, cuándo). Para un servicio con KYC, Tor protege al usuario frente a la red
y frente a terceros, no frente al venture. Esa es la decisión de producto: aceptar o no tráfico Tor, y con qué
controles adicionales (p. ej. pedir 2FA fuerte en lugar de bloquear).

## Adversarios

- **Red local** (Wi-Fi del café, red de la universidad): con solo HTTPS sabe que el usuario usa el venture y a qué
  hora. Con Tor solo sabe que usa Tor, lo cual por sí solo puede llamar la atención o estar bloqueado.
- **ISP:** lo mismo que la red local, pero de forma persistente y con datos de suscriptor (nombre, dirección).
  Puede ser obligado a entregarlos.
- **El sitio (el venture mismo):** siempre ve la identidad KYC y la orden. Es el adversario frente al cual Tor
  no sirve de nada una vez que el usuario hace login. Desde el lado del usuario, el riesgo es una brecha del venture.
- **Gobierno con visibilidad parcial:** puede pedir registros al venture (y el venture, como Persona Obligada,
  los tiene) o al ISP. Si observa **ambos extremos** (el enlace del usuario al guard y el tráfico que entra al
  venture) puede hacer **correlación end-to-end** por timing y volumen. Ese es el límite de diseño de Tor: es de
  baja latencia, no mezcla ni retrasa paquetes, así que no protege contra quien ve las dos puntas.

## Tres cosas que Tor NO protege en este flow

1. **El login y el KYC.** Iniciar sesión revela quién soy. Tor oculta la IP, no la identidad de la cuenta.
2. **Un exit malicioso frente a fallas de HTTPS.** Si un subdominio no tiene HSTS, o hay un redirect en HTTP,
   el exit puede hacer SSL stripping. También ve SNI/dominio y puede censurar.
3. **Fingerprinting y correlación.** Tor Browser homogeniza el fingerprint, pero si el usuario cambia el tamaño
   de la ventana, instala extensiones o usa el mismo navegador para otras cuentas, se le puede reconocer.
   Y la correlación end-to-end (punto anterior) queda fuera del modelo de amenazas de Tor.

(Una cuarta: la wallet de destino. La orden manda tokens a una dirección on-chain pública y permanente; ninguna
red de anonimato desvincula eso.)

## I2P conceptual

I2P está diseñado para servicios **dentro** de la red (eepsites), no para salir a clearnet. Cada participante
construye túneles unidireccionales (salida e entrada separados) y usa *garlic routing* (varios mensajes cifrados
juntos). Sin un exit, no existe el problema del exit malicioso, pero el venture tendría que **publicar un servicio
in-net**, algo que la mayoría de reguladores y bancos corresponsales no esperan de un PSAV. Para salir a clearnet
se depende de pocos outproxies voluntarios, peor que la red de exits de Tor. Conclusión: I2P es más interesante
para comunicación entre pares que para una app regulada con KYC. No lo instalé; el análisis sale de la intro
oficial (geti2p.net/en/about/intro).

## Comentarios de aprendizaje

- **Payload vs metadata:** HTTPS ya protegía el payload. Tor e I2P protegen la metadata: quién, desde dónde, cuándo.
  En un threat model hay que preguntar primero a quién le estamos escondiendo qué.
- **Qué sigue viendo el venture:** todo lo que importa para su obligación legal: identidad, monto, destino. Tor
  le quita la IP real, que es una señal antifraude, no un dato que tenga que entregar por defecto.
- **El guard que no cambia** (Parte A) fue lo menos intuitivo: más rotación no significa más privacidad. Fijar el
  guard reduce la probabilidad de caer alguna vez en uno malicioso.

## Fuentes

- Tor Project, *Tor Browser User Manual — circuit display*: https://tb-manual.torproject.org/managing-identities/
- Tor Project, *Guard nodes*: https://support.torproject.org/about/entry-guards/
- Dingledine, Mathewson, Syverson, *Tor: The Second-Generation Onion Router* (2004), §3 (threat model, end-to-end correlation)
- I2P, *Intro*: https://geti2p.net/en/about/intro
