# Física: comprobaciones y alcance

La referencia es [SMWDisX](https://github.com/IsoFrieze/SMWDisX), commit `30643c7595a7d097d731de69476f8059c7cf98c3`, símbolos USA `SMW_U.sym`. Se consultó `bank_00.asm` y se comprobaron los bytes siguientes **contra el archivo proporcionado**, usando el mapeo LoROM. El desensamblado no se incluye en la entrega.

| Símbolo / dirección SNES | Offset en archivo sin cabecera | Dato comprobado / uso |
| --- | --- | --- |
| `DATA_00D2BD`, `$00D2BD` | `$0052BD` | Tabla de impulsos; entradas pares para salto normal |
| `MarioAccel_`, `$00D345` | `$005345` | Primeros valores: `FE80 FE80 0180 0180` |
| `DATA_00D535`, `$00D535` | `$005535` | Límites iniciales: `EC 14 DC 24 DC 24 D0 30` |
| `DATA_00D7A5`, `$00D7A5` | `$0057A5` | Primeras entradas de gravedad: `06`, `03` |

El detalle reproducible está en `physics-reference-check.json`. Para repetirlo con una copia local de la referencia y del mapa de símbolos:

```sh
python3 tools/verify_physics_reference.py /ruta/SMW.sfc /ruta/SMWDisX/SMW_U.sym
```

`CODE_00DC4F` del desensamblado muestra la integración NTSC: el byte alto de velocidad se interpreta en unidades de 1/16 píxel por fotograma, sumando su fracción a la posición. El motor NES utiliza esta escala Q4.4 y un byte adicional de fracción para la aceleración horizontal. Las posiciones X tienen 16 bits enteros y ocho de fracción; Y tiene ocho bits enteros y ocho de fracción porque este nivel tiene una sola pantalla de alto.

Límites actuales: caminar `±$14` (1.25 px/cuadro), correr `±$24` (2.25); aceleración `±$0180` en unidades de velocidad 8.8; impulso normal por `abs(vx)>>3`: `B0 AE AB A9 A6 A4 A1 9F`; gravedad 3 con A mantenido, 6 sin A. El máximo de caída de esta implementación se limita a `$40` (4 px/cuadro). La fricción terrestre usa 1 unidad de velocidad/cuadro; no hay arrastre automático en el aire.

**Estas coincidencias no prueban fidelidad completa.** El motor no reproduce aún el P-meter, topes especiales de pendiente, superficies resbaladizas, agua, carga de objetos, giro, spin jump, órdenes completas de actualización ni todos los detalles de gravedad del original. Las colisiones son originales, rectangulares y separadas por eje; no son una traducción de las rutinas de SMW. No hay traza diferencial de ejecución de SNES. La selección de arte y las dimensiones del personaje son provisionales.

Las trazas de prueba registran posiciones, velocidades y cámara por fotograma en `build/movement.csv`. El salto corto alcanzó Y=158 y el mantenido Y=127 partiendo de Y=192 en el escenario aislado: es una comprobación de altura variable de esta versión, no una medición comparativa de SNES.
