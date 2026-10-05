# STORAGE.md — Política de datos del venture (Lab 15, Sesión 18)

> **Supuesto:** el venture es una plataforma fintech/tokenización con usuarios verificados (KYC),
> documentos de emisión públicos y registros on-chain. Si el venture del equipo es otro, ajustar las
> filas de la tabla; la lógica de clasificación no cambia.

## Artefacto del lab

| Campo | Valor |
|---|---|
| Archivo | `venture-hello.json` (175 bytes, sin PII) |
| CID | `<CID>` |
| Provider de pin | Pinata (API key con scope mínimo: `pinFileToIPFS` + `pinList`, guardada en `.env`, gitignored) |
| Gateway | <GATEWAY_URL> |
| Fecha | <FECHA> |
| Evidencia | `evidence/lab-log.md` (pinList + `curl` contra 3 gateways), `evidence/upload-response.json` |

**Si unpinneamos, esperamos que** el CID siga siendo válido como identificador pero deje de resolver en cuanto
el garbage collector de Pinata borre los bloques y ningún otro nodo los tenga en caché o pinneados. Los
gateways públicos pueden servirlo unas horas o días desde su caché. Después, una petición a `/ipfs/<CID>`
hace timeout. Nada garantiza que desaparezca: si alguien lo pinneó por su cuenta, sigue vivo.

## Clasificación: sensibilidad × durabilidad

| Dato del venture | Sensibilidad | Durabilidad requerida | Destino |
|---|---|---|---|
| Documentos KYC (DPI, pasaporte, selfie, comprobante de domicilio) | **Alta (PII)** | Retención legal ~5 años, luego borrar | **Never-permanent**: storage cifrado location-addressed (S3/GCS con KMS) y acceso por rol |
| Perfil de usuario (nombre, email, teléfono) | Alta (PII) | Mientras la cuenta exista | **Never-permanent**: base de datos (Postgres) con borrado real |
| Logs de transacciones y reportes a IVE | Alta (regulatoria) | 5+ años, inmutables para auditoría | Location-addressed WORM (object lock). Nunca IPFS público |
| Relación wallet ↔ identidad | Alta (des-anonimiza on-chain) | Retención legal | **Never-permanent**, separada del resto y cifrada |
| Documentos de emisión públicos (DIR, términos, aviso de oferta) | Baja (públicos por ley) | Larga: el inversionista debe poder verificar la versión exacta | **IPFS + pin** (2 providers). El CID va en el contrato o en el metadata del token |
| Metadata de tokens (nombre, imagen, JSON ERC-721/1155) | Baja | Tan larga como el token | **IPFS + pin** |
| Assets del sitio web (logos, landing) | Baja | Media; cambia seguido | **Location-addressed** (Vercel/CDN). Versionar no aporta |
| Hash del reporte de auditoría de smart contracts | Baja | Permanente | **Raro candidato a permanencia** (Arweave o anclaje on-chain del hash) |
| Analytics y telemetría | Media (pseudónima) | Corta (90 días) | Location-addressed con TTL |

**Regla:** IPFS solo recibe lo que ya es **público por diseño** y que queremos que sea **verificable por su
contenido**. Ningún dato personal va a IPFS público, ni cifrado: el cifrado de hoy puede romperse mañana, y en
IPFS no podemos garantizar el borrado.

## Disponibilidad vs borrado

IPFS separa dos cosas que en la nube van juntas. El **CID** da *integridad*: quien tenga los bytes puede
probar que son los correctos. El **pin** da *disponibilidad*: alguien se compromete a servirlos. Pero no
existe una operación de "borrar del mundo". Unpinnear solo retira *nuestra* copia; cualquier nodo, gateway o
persona que los haya bajado puede volver a publicarlos con el mismo CID. Para documentos públicos eso es
deseable (el inversionista no depende de nosotros). Para datos personales es incompatible con el derecho de
supresión y con la retención mínima que exige la regulación. Por eso nuestra política de disponibilidad (pin
en 2 providers, con monitoreo de que el gateway resuelva) solo aplica a la clase pública. La política de
borrado (eliminación verificable al vencer la retención) solo es posible en storage location-addressed que
controlamos.

**Gateway vs protocolo:** `https://<gateway>/ipfs/<CID>` es un servidor HTTP centralizado que habla IPFS por
nosotros. Si Pinata cae, su gateway cae, pero el contenido sigue en la red si otro nodo lo tiene. Por eso
el log verifica el mismo CID en `ipfs.io` y `dweb.link`: el CID es el identificador, el gateway es solo una
puerta.

## Oración 15-2026

Como PSAV sujeto al **Decreto 15-2026** (Ley Integral contra el Lavado de Dinero y el Financiamiento del
Terrorismo, vigente desde el 17 Sep 2026), el venture debe conservar la debida diligencia y los registros
de transacciones para la IVE: esos registros van a storage controlado, auditable y borrable al vencer la
retención, nunca a un medio permanente y público como IPFS.

## Promesas

**Tres promesas que NO haremos:**
1. "Tus datos personales quedan en la blockchain/IPFS para siempre y seguros." No subimos PII a IPFS.
2. "Si borras tu cuenta, desaparece todo rastro de IPFS." No podemos garantizar el borrado de algo ya publicado por contenido.
3. "IPFS es gratis y no depende de nadie." Depende de que alguien pague el pin; si dejamos de pagar, deja de resolver.

**Una promesa que SÍ hacemos:**
- Todo documento público de una emisión tendrá un CID publicado, y mantendremos un pin activo en al menos
  dos providers mientras el token exista. Cualquiera podrá verificar que el documento que lee es,
  byte por byte, el que se aprobó.

## Nota opcional: Arweave (contraste, sin upload)

Arweave cobra una sola vez y financia el almacenamiento con un endowment que asume que el costo de
almacenamiento sigue bajando. Es "pay once, store forever": el opuesto de un pin, que es una suscripción.
Solo tendría sentido para el raro candidato a permanencia (hash del reporte de auditoría), nunca para algo
que algún día debamos borrar.
