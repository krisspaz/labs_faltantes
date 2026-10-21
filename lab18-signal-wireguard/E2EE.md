# E2EE.md — Lab 18: Signal, WireGuard y acceso excepcional (Sesión 21)

## (a) Dispositivo comprometido a mitad del chat

Signal usa el **Double Ratchet**: cada mensaje tiene una llave nueva, y la cadena se reinicia con un
Diffie-Hellman cada vez que la conversación cambia de dirección.

- **Pasados (forward secrecy):** las llaves usadas se borran y la cadena solo avanza. Quien roba el estado hoy
  no recalcula las llaves de ayer. **Pero** el historial guardado en el teléfono queda en texto plano para quien
  controle el dispositivo desbloqueado: FS protege el tráfico capturado en la red, no la base de datos local.
- **Futuros (post-compromise security):** si el atacante copia el estado una vez y pierde el acceso, el siguiente
  paso DH mete material que no conoce y la sesión se "cura" en uno o dos turnos. Con malware persistente no hay
  cura: ve lo mismo que el usuario.

WireGuard renueva llaves efímeras en cada handshake (~2 min). Robar la private key estática permite
**suplantar** al peer después, pero no descifrar sesiones pasadas capturadas.

## (b) Qué tendría que romper un mandato de acceso excepcional

**Contra Signal:** el servidor no tiene llaves; solo puede entregar fecha de creación de la cuenta y última
conexión (signal.org/bigbrother). Leer mensajes exige **cambiar el cliente**: una llave de escrow o un
"participante fantasma". Ambas rompen la verificación del Safety Number (o la ocultan) y requieren distribuir
esa versión a todos por las tiendas de apps.

**Contra WireGuard:** no hay proveedor central. El mandato tendría que obligar al operador a entregar llaves
estáticas (inútiles para lo pasado, por el punto a) o interceptar en el endpoint, donde el tráfico ya está en
claro. En la práctica va contra el endpoint, no contra el protocolo.

*Keys Under Doormats* (Abelson et al., 2015) explica por qué ambas opciones son peligrosas: el acceso
excepcional **elimina la forward secrecy** porque las llaves deben conservarse, agrega complejidad donde los bugs
son críticos y crea un objetivo valioso (la llave maestra) que alguien intentará robar. No existe un acceso
"solo para los buenos".

## (c) Tor vs Signal vs WireGuard para el venture

Para nuestro venture de tokenización, **Tor** esconde la IP del usuario frente a la red y a nosotros (no su
identidad tras el login), **Signal** esconde el contenido de soporte y operación interna frente al servidor y la
red (no que dos números hablan), y **WireGuard** esconde contenido y destinos internos frente al ISP entre
nuestras máquinas (no frente al otro peer, que ve todo lo que cruza el túnel).

## Comentarios de aprendizaje

Las tres cifran el payload; la diferencia es **qué metadata queda expuesta y a quién**. En el túnel, el ISP ve
dos IPs intercambiando UDP 51820; el peer remoto ve los destinos internos y el contenido.

## Fuentes

- Marlinspike & Perrin, *The Double Ratchet Algorithm* (Signal, 2016): https://signal.org/docs/specifications/doubleratchet/
- Signal, *Government communication / bigbrother*: https://signal.org/bigbrother/
- Donenfeld, *WireGuard: Next Generation Kernel Network Tunnel* (NDSS 2017), §5 (handshake, rekeying)
- Abelson et al., *Keys Under Doormats: Mandating insecurity by requiring government access to all data and communications* (MIT CSAIL-TR-2015-026, 2015)
