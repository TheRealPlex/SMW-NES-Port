# Física del motor 0.2

Esta versión sustituye la aproximación inicial por un subconjunto de movimiento comprobado contra ejecución de la ROM SNES. Véase [`motion-verification.md`](motion-verification.md) para el protocolo y sus límites: 12 secuencias / 1,514 cuadros / 13,626 valores coincidentes. No se afirma equivalencia de todo el motor.

La documentación consultada es [SMWDisX](https://github.com/IsoFrieze/SMWDisX), commit `30643c7595a7d097d731de69476f8059c7cf98c3`, `bank_00.asm` y símbolos USA. Las comprobaciones binarias iniciales están en `physics-reference-check.json`. ROM y desensamblado se mantienen fuera del repositorio.

Cambios comprobados mediante trazas de la ROM original:

- Integrar la velocidad del cuadro anterior **antes** de calcular la siguiente velocidad. La versión inicial se adelantaba un cuadro.
- Mantener las fracciones de posición Y al tocar el suelo; no ponerlas a cero. El valor de velocidad Y en reposo es 6 con botón de salto suelto, aunque la colisión mantenga la posición sobre el suelo.
- Conservar la fracción de velocidad horizontal y alternar aceleración/freno al llegar al límite, en lugar de recortarla de inmediato. Caminar/correr no siempre tienen exactamente el mismo byte de velocidad en cada cuadro.
- Frenado de giro: aceleración normal de 1.5 unidades de velocidad, giro andando de 2.5, giro corriendo de 5. Una unidad equivale a 1/16 píxel/cuadro.
- Límites nominales: caminar 20, correr 36, correr con P-meter lleno 48. La oscilación observada alrededor del límite se conserva.
- P-meter: tope 112, aumento de 2 a velocidad de carrera en el suelo o durante un salto iniciado con P-meter lleno; descenso de 1 en los demás casos comprobados.
- Impulsos normales por `abs(vx)>>3`: `B0 AE AB A9 A6 A4 A1 9F`. Se escoge el impulso antes de actualizar la velocidad horizontal.
- Gravedad: primero limitar la velocidad positiva previa a 64, después sumar 3 si se mantiene salto o 6 si se suelta. Por eso la velocidad de caída registrada puede llegar a 67 o 70; el motor inicial la recortaba incorrectamente a 64 después de sumar.

La integración utiliza velocidad Q4.4 y una fracción adicional de ocho bits para la aceleración horizontal. Posición X: 16 bits enteros más ocho fraccionarios. Posición Y: ocho bits enteros más ocho fraccionarios en este laboratorio de una pantalla de alto.

La versión 0.3 añade colisiones de pendientes básicas, poderes, capa y Yoshi, sin ampliar todavía la equivalencia diferencial a esas mecánicas. Faltan agua, superficies resbaladizas, agacharse, spin jump y transporte de objetos. El resultado diferencial sigue siendo específico de los casos planos documentados; no afirma equivalencia de SMW completo.
