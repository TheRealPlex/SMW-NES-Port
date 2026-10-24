# Arquitectura del motor 0.2

| Módulo | Responsabilidad |
| --- | --- |
| `main.s` | Reset, MMC3, NMI, mando, bucle principal y paletas |
| `physics.s` | Posiciones y velocidades con fracciones, colisión por eje, salto y reaparición |
| `level.s` | Consultas de sólidos, ring de nametables, cámara, carga inicial y SRAM |
| `entities.s` | Cuatro caminantes con identidad persistente, pisotón y daño |
| `render.s` | Metasprites de 16×16 y buffer OAM |
| `audio.s` | Efectos originales por canal de pulso |
| `generate_assets.py` | CHR 2bpp y nivel columnar, ambos originales |
| `test_level.json` | Geometría editable del único nivel de prueba |

## Cartucho y memoria

iNES 1.0 mapper 4 (MMC3), submapper sin especificar, mirroring vertical, NTSC. PRG-ROM 64 KiB en ocho bancos de 8 KiB. El código y los datos actuales caben en los dos bancos fijos finales, `$C000–$FFFF`; los primeros 48 KiB están reservados para crecimiento. No se usan IRQ de scanline todavía. Esto sacrifica espacio inicial para mantener un punto de arranque sencillo y estable. No depende de instrucciones ilegales ni de hardware de emulador.

CHR-ROM de 8 KiB: fondo `$0000`, sprites `$1000`. MMC3 se inicializa explícitamente para estas correspondencias y para WRAM legible/escribible. Cero-page contiene estado y temporales; OAM sombra en `$0200`; BSS desde `$0300`, con límites comprobados por el validador. WRAM con batería en `$6000–$7FFF`; solo los primeros cuatro bytes se usan ahora.

SRAM: `$6000=$50`, `$6001=$31`, `$6002=completed` (0/1), `$6003=completed XOR $FF`. Firma y complemento detectan datos iniciales inválidos; no constituyen un sistema de guardado robusto contra cortes durante escritura. No se guardan checkpoint, enemigos ni un mapa mundial.

## Vídeo y tiempo

Nivel de 128×15 metatiles de 16×16. Cada metatile referencia cuatro tiles de 8×8 y un indicador de solidez; la representación de colisión y la visual leen los mismos datos. El nivel inicial ocupa 1,920 bytes y no está comprimido. Es un formato propio, no el formato de SNES.

Las dos nametables forman un ring horizontal de 512 píxeles. Al cambiar de columna de cámara se prepara una columna de 30 tiles. El NMI la sube con incremento PPU de 32, hace DMA de OAM y restablece scroll y PPUCTRL. La cámara conserva toda su coordenada mundial de 16 bits; solo la dirección PPU usa el ring. La reaparición reconstruye ambas nametables con rendering apagado.

Se midieron **1,114 ciclos como máximo desde entrada NMI hasta la instrucción RTI**, incluidos DMA y la columna, durante las pruebas locales; no incluye la propia RTI ni la latencia previa de interrupción. Frente a aproximadamente 2,273 ciclos de VBlank NTSC, hay margen para este hito. No es un perfil exhaustivo de todos los futuros estados del juego. La prueba de 3,600 fotogramas comprueba estabilidad, no todas las combinaciones posibles de sprites/ciclos.

En este hito las paletas de fondo comparten colores y los atributos son cero; se respeta la cuadrícula real de atributos. Cada actor usa cuatro sprites de 8×8. No hay framebuffer, imágenes SNES pegadas a pantalla ni código 65816 ejecutándose en NES.

## Fuentes técnicas

- [MMC3, NESdev](https://www.nesdev.org/wiki/MMC3).
- [Registros PPU, NESdev](https://www.nesdev.org/wiki/PPU_registers).
- [Scroll PPU, NESdev](https://www.nesdev.org/wiki/PPU_scrolling).
- [Herramientas cc65](https://cc65.github.io/).
