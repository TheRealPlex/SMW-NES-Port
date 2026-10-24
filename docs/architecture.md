# Arquitectura 0.3

| Módulo | Responsabilidad |
| --- | --- |
| main.s | Reset, mando, NMI, IRQ MMC3, paletas y bucle |
| physics.s | Integración de movimiento, colisiones, salto, daño y reaparición |
| abilities.s | Poderes, Yoshi, capa, proyectiles, objetos y plataformas |
| level.s | Metatiles, pendientes, cámara de 16 bits, streaming y actualizaciones VRAM |
| world.s | Mapa, selección de bancos, progreso, temporizador y SRAM |
| entities.s | Ocho actores persistentes, Rex/Koopa/caparazones e interacciones |
| render.s | Metasprites de tamaño variable, montura y buffer OAM |
| audio.s | Melodía y efectos APU originales |
| generate_assets.py | Dibujo CHR 2bpp y conversión de datos al formato NES |

MMC3, iNES 1.0, NTSC, mirroring vertical. Ocho bancos PRG de 8 KiB: 0–3 contienen los cuatro mapas, seleccionados en $8000 por R6; banco 4 permanece en $A000 por R7 y contiene tablas/HUD/mapa mundial. Banco 5 libre. Bancos 6 y 7 contienen código y datos fijos en $C000–$FFFF. CHR-ROM de 8 KiB, fondo $0000 y sprites $1000. No hay instrucciones 65816 ni framebuffer SNES.

Zeropage para estado/temporales, OAM sombra $0200 y BSS desde $0300, límites verificados durante el build. WRAM $6000–$7FFF con batería: firma $50/$33, máscara de regiones completadas $6002, complemento $6003 y cursor $6004. El mapa mutable activo ocupa $6800–$76FF: 256 columnas × 15 metatiles de 16 px. Cada región incluye otros 1,024 bytes de atributos. No hay compresión todavía. Los valores transitorios del mapa WRAM no se interpretan como progreso al arrancar.

La carga de banco copia el mapa a WRAM; monedas y bloques usados se modifican allí. El NMI sube una columna preparada de tiles/atributos y una actualización puntual de metatile, además de HUD/paletas/OAM. Dos nametables forman el ring horizontal de 512 px. La cámara mundial es de 16 bits; las pruebas verifican lecturas reales de PPU más allá de 2,048 px y al retroceder.

Las primeras cuatro filas de tiles son HUD fijo. La IRQ MMC3 cambia al scroll del escenario debajo del HUD. Durante la reconstrucción con rendering apagado, NMI no modifica PPUADDR/scroll: esto evita corrupción de columnas durante la carga. La señal de frame se libera igualmente para impedir bloqueo al reconstruir.

Hay 44 metatiles de fondo (176 patrones), letras/dígitos y un recuadro de reserva; 180 patrones de sprites y 32 metasprites. Mario usa cabeza y cuerpo con paletas diferentes; Yoshi se dibuja como montura separada con posición propia. Se respeta OAM de 64 sprites, pero el recorte por ocho sprites en una línea no está resuelto mediante un gestor general. No se usa RAM/PPU inexistente ni extensiones exclusivas de emulador.

Presupuesto NMI observado: ver `test-results.txt`; la medición incluye el DMA desde entrada NMI hasta antes de RTI. No certifica todos los estados posibles ni toda la duración del bucle principal. La IRQ añade trabajo durante rendering y requiere validación adicional en Mesen/hardware.
