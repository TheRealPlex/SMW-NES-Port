# Validación del motor 0.2

Fecha local: 24 de octubre de 2026. Compilador: ca65/ld65 del paquete cc65 2.19 de Ubuntu. Emulador: FCEUX 2.6.5, core PPU nuevo, NTSC. Render real bajo Xvfb/Mesa; capturas mediante lectura RGB exacta del framebuffer emulado (`emu.getscreenpixel`), sin dibujar overlays, convertidas a PNG sin pérdidas. La caché de snapshots de la interfaz de FCEUX retenía algunos cuadros de blanking en turbo; por eso se utiliza esta lectura directa y se rechazan imágenes uniformes. No se utilizó un emulador escrito para este proyecto.

| Categoría | Resultado y límite |
| --- | --- |
| Compilación | ca65 y ld65 ejecutados; ROM real de 73,744 bytes |
| Validación estática | Cabecera, mapper, tamaño PRG/CHR, vectores, reset SEI, límites RAM y tamaño del nivel comprobados |
| Ejecución en emulador | Arranque visible, sprites, controles, VRAM, SRAM y presupuesto NMI comprobados en FCEUX |
| Jugabilidad automatizada | Mecánicas aisladas y recorrido completo mediante mando; capturas y trazas reales |
| Jugabilidad humana | No realizada |
| Mesen | No ejecutado en este entorno; instrucciones en README |
| NES física / flashcart | No realizada; compatibilidad de hardware no certificada |

`test-results.txt` conserva los resultados exactos de la versión entregada. `static-results.json` conserva su hash SHA-256 y configuración. Los scripts completos están en `tests/`; las capturas representativas están en `docs/screenshots/`.

## Qué comprueban los scripts

`gameplay.lua` lee símbolos de la ROM compilada; controla el mando y usa **fixtures de RAM explícitos** para posicionar al jugador, aislar enemigos y probar casos concretos. Comprueba arranque, enemigos iniciales, caminar/correr, fricción, cambio de dirección, salto corto/largo, suelo, techo, paredes, aterrizaje en plataforma estática, cámara reversible, pausa, checkpoint y retroceso, pisotón, daño, conservación de entidad fuera de pantalla, reaparición de entidad y límites del mundo. Las verificaciones VRAM comparan tiles realmente leídos de PPU con los datos del nivel, en ambos sentidos, después del checkpoint y en la última pantalla. Se registran 3,600 cuadros adicionales de estabilidad y el máximo de ciclos NMI.

El fixture de guardado pone el indicador a cero en RAM antes de que la meta escriba 1 mediante código del juego. `persistence.lua` se ejecuta en **un segundo proceso de FCEUX**, tras cerrar normalmente el primero, y verifica que 1 se cargó de SRAM. No usa savestates para demostrar persistencia.

`traversal.lua` ejecuta un tercer proceso, enciende de nuevo la consola emulada y recorre el nivel **sin escribir RAM**: solo consulta geometría y estado para decidir entradas de mando. Completó el recorrido sin muertes en esta versión. Es evidencia de que existe una ruta jugable, no de que una persona lo haya probado ni de que todas las rutas sean correctas.

## Fallos corregidos durante el hito

- El cálculo inicial del número de columna perdía bits de la coordenada mundial más allá de 512 px. Se corrigió y se añadieron comprobaciones directas de VRAM.
- Se corrigieron las entradas de la tabla de salto después de comprobar la referencia binaria.
- Los caminantes ahora rebotan en los extremos para impedir desbordamientos de coordenadas.
- Se ajustaron secuencias de prueba que no respetaban la fricción, la zona muerta de cámara o el retardo de un cuadro de entrada del emulador.

## Problemas conocidos y siguiente validación

Pueden existir casos de esquina entre bloques, fallos de entidades no cubiertos por cuatro instancias o diferencias de temporización en otro core. Reaparición usa blanking de pantalla y no una transición terminada. No hay animación de muerte, menú de archivos ni contador de progreso en pantalla. El guardado solo es un indicador de la meta del laboratorio. El audio se programó y se ejecutó, pero no se hizo una evaluación auditiva.

Próxima validación: ejecutar esta misma ROM en Mesen, recorrerla manualmente, comprobar los ocho sprites por scanline y probar una placa/flashcart MMC3 NTSC con WRAM de batería. El siguiente desarrollo será completar power-ups y plataformas móviles antes de Yoshi y vuelo.

## Comparación con la ROM SNES

Además de las pruebas anteriores, `make test` incluye la misma comparación que `make motion`: los 12 casos diferenciales documentados en `motion-verification.md`. Sus resultados están en `motion-results.txt`; la línea base anterior, en `motion-baseline.txt`. La recreación independiente desde encendido en Snes9x reprodujo la referencia numérica byte por byte. Esto verifica ese subconjunto físico; no demuestra fidelidad de los niveles o gráficos de la ROM de laboratorio.
