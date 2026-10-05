# Memo: fair-launch vs emisión regulada (PEPE vs MMLTI1)

**Para:** equipo · **Fecha:** 2026-10-05 · **Base:** DUE_DILIGENCE.md (on-chain + documentos oficiales)

## La pregunta

¿Qué le cuesta a un inversionista confiar en cada token, y en quién deposita esa confianza?

## PEPE: confianza cero en personas, confianza total en el mercado

PEPE es un fair-launch puro: 420.69 billones de tokens minteados una vez, sin vesting, sin treasury y con la
ownership renunciada. Su código tiene una `blacklist` y un límite anti-ballenas, que fueron reales al lanzar,
pero `owner() = 0x0` los volvió letra muerta. Nadie puede congelar, mintear, actualizar ni pausar. En ese
sentido es el token más "honesto" que se puede tener: lo que ves en el contrato es todo lo que hay.

El problema es que eso es *todo* lo que hay. No existe un derecho económico: ni flujo, ni emisor, ni
documento, ni recurso. El valor (US$1.84B de market cap) es puramente narrativo y depende de la
liquidez de un par de Uniswap V2 (US$32M) que los LPs pueden retirar, porque casi nada del LP está quemado.
En el día del snapshot hubo más txs de venta que de compra (471 vs 349). El riesgo de PEPE no es que alguien
te robe; es que el precio vaya a cero y nadie te deba nada.

## MMLTI1: confianza total en personas, protegida por la ley

MMLTI1 es lo opuesto. Promete algo concreto: deuda senior de MultiMoney al 6.20% anual, pago mensual, a 24
meses, bajo la LEAD salvadoreña, con emisor registrado (EAD-0046) y PSAD autorizado (MIO3). Eso es un derecho
exigible fuera de la cadena, algo que PEPE nunca tendrá.

Pero el contrato le da al emisor un poder casi total sobre el holder. Con ERC-3643 (T-REX v4.1.1), un solo
agent puede mintear, quemar, congelar, forzar transferencias y recuperar tokens. Además, todo el sistema es
**actualizable**: token, identity registry y compliance son proxies cuyo código decide una ImplementationAuthority
controlada por una única EOA (`0x0921…`), la misma que controla al agent. Eso es legítimo para un valor
regulado (un juez puede ordenar un recall y el emisor debe poder cumplir), pero contradice el DIR, que llama
a los contratos "inmutables una vez desplegados".

La due diligence encontró además fricciones entre el papel y el código:

1. **Dos addresses para el mismo contrato.** El DIR apunta al contrato real en Polygon; la certificación
   cita uno que solo existe en BSC Testnet (con el ticker mal escrito, "MLTI1"). Un inversionista que
   verificara con la certificación no encontraría nada en Polygon.
2. **KYC sin verificación on-chain.** El identity registry no tiene claim topics ni trusted issuers. "Estar
   whitelisted" significa solo que el agent te registró. El cumplimiento vive en el back-office de MIO3, no en el código.
3. **La "restricción de 180 días" no es un lock.** On-chain es un tope de 20,000 tokens transferibles por
   wallet cada 180 días, igual al supply total del tramo. Aún no hubo transferencias que lo pongan a prueba.
4. **Auditoría afirmada, no publicada.** El DIR menciona auditorías externas sin firma ni informe; la propia
   certificación lo señala.
5. **Concentración y liquidez.** Una sola wallet tiene el 86.4% de lo emitido (no identificada en los docs) y no
   ha habido ni una transferencia secundaria. La salida depende del emisor (redención a vencimiento o anticipada).

El riesgo de MMLTI1 no es la volatilidad: es la **contraparte y la operación**. Pagas 6.2% por confiar en que
MultiMoney pagará, en que MIO3 opera bien sus llaves y su KYC, y en que el regulador hará cumplir los
documentos si algo falla.

## Comparación directa

| | Fair-launch (PEPE) | Emisión regulada (MMLTI1) |
|---|---|---|
| Qué compras | Un número en un ledger y una narrativa | Un crédito contra un emisor regulado |
| Quién puede tocar tu saldo | Nadie | El agent (freeze, forced transfer, burn) |
| Quién puede cambiar el código | Nadie | Una EOA vía ImplementationAuthority |
| Dónde está el enforcement | En el código | En la ley y el back-office; el código es el brazo ejecutor |
| Liquidez | Alta, instantánea, sin permisos | Ninguna observada; salida vía emisor |
| Rúbrica (10 pts) | 6 | 3.5 |

## Conclusión

La rúbrica mide sobre todo *poder del emisor sobre el holder*, y ahí PEPE gana. Pero sería un error leer
"6 > 3.5" como "PEPE es mejor inversión". Son productos con riesgos de naturaleza opuesta:

- **PEPE:** riesgo de mercado extremo, cero riesgo de contraparte, cero recurso.
- **MMLTI1:** riesgo de mercado bajo (cupón fijo), riesgo de contraparte y operativo alto, recurso legal real.

Lo que sí es criticable en MMLTI1 es la **brecha entre lo que dicen los documentos y lo que hace el código**:
inmutabilidad, address, lock de 180 días y auditoría. En una emisión regulada, el documento es el producto. Si
el DIR describe un contrato distinto del desplegado, el inversionista no puede hacer due diligence por sí mismo
y depende por completo de la certificación, que en este caso apunta a una testnet.

**Recomendación al emisor** (lo que subiría el puntaje sin cambiar el modelo regulado):

1. Publicar el address correcto en la página de la emisión y corregir la certificación.
2. Mover la ImplementationAuthority y el agent a un multisig con timelock y documentarlo.
3. Corregir "inmutable" por "actualizable bajo X controles".
4. Publicar el informe de auditoría.
5. Implementar on-chain el lock de 180 días que promete el texto, o aclarar que es una restricción off-chain.
