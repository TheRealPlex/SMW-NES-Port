# SMW → NES — motor de físicas 0.2

Motor **NES nativo**, escrito en 6502 con ca65/ld65. La versión 0.2 corrige las físicas comparándolas con la ejecución de la ROM SNES original. **Todavía no reconstruye el contenido de Super Mario World**: el escenario, los gráficos y los enemigos visibles siguen siendo el laboratorio original de prueba.

La versión actual contiene un único recorrido original de prueba de 2,048 × 240 píxeles, un protagonista pequeño con arte provisional original, cuatro enemigos caminantes y una meta. No incorpora niveles, gráficos ni audio extraídos de Nintendo.

## Jugar

ROM estable: [`roms/smw-nes-physics-v0.2.nes`](roms/smw-nes-physics-v0.2.nes).

Abrí el archivo `.nes` en Mesen y configurá el mando 1:

| Control NES | Acción |
| --- | --- |
| Izquierda / derecha | Caminar; cambiar de dirección |
| B + dirección | Correr |
| A | Saltar; mantenerlo aumenta la altura |
| Start | Pausar / continuar |
| Select | Volver al punto de inicio o checkpoint activo |

El cartel del centro activa un checkpoint para esta sesión. La bandera final guarda un indicador de recorrido completado y cambia la paleta del protagonista. El personaje todavía puede moverse después de llegar. Cerrar el emulador normalmente permite conservar la SRAM; un savestate no es necesario. Para borrar este progreso de prueba, eliminá el guardado de batería correspondiente desde el emulador. El checkpoint no se conserva entre sesiones.

**Mesen y hardware físico: pendientes de prueba.** La ejecución y automatización realizadas aquí corresponden a FCEUX 2.6.5 con su PPU nueva, NTSC.

## Compilar y probar

En Ubuntu/Debian, con acceso a paquetes:

```sh
sudo apt-get update
sudo apt-get install cc65 make python3 fceux xvfb xauth ripgrep
export PATH="$PATH:/usr/games"
make
make check
make test
make motion  # comparación diferencial aislada
```

Resultado: `build/smw-nes-physics-v0.2.nes` (73,744 bytes). La compilación **no necesita la ROM SNES**, conexión de red ni paquetes Python externos. `make test` utiliza FCEUX y tres procesos de emulación: mecánicas, reapertura del guardado y recorrido completo por entradas del mando. Deja capturas, trazas CSV y resultados en `build/`.

GitHub Actions compila, valida, ejecuta las pruebas y publica artefactos de este material original. Su resultado remoto debe consultarse en la pestaña Actions; los resultados locales conservados están en [`docs/test-results.txt`](docs/test-results.txt).

## Verificación contra SMW

En 12 secuencias controladas, el motor NES coincide con Snes9x durante **1,514 cuadros y 13,626 valores**: desplazamientos relativos, subpíxeles, velocidades, P-meter y estado aéreo. Se verifican aceleración, frenado, giro, carrera sostenida, salto corto/largo y control aéreo sobre suelo plano. La versión anterior difería en 7,913 valores. El protocolo y los límites están en [`docs/motion-verification.md`](docs/motion-verification.md). La referencia se puede regenerar con una ROM local; ningún archivo comercial se incluye en la CI.

## Implementado

- Inicialización PPU/APU, MMC3 y mando; 64 KiB PRG, 8 KiB CHR, 8 KiB WRAM con batería.
- Movimiento con aceleración, fricción, carrera, salto variable y colisiones de suelo, paredes y techo.
- Cámara horizontal en ambos sentidos y carga de columnas durante VBlank.
- Cuatro caminantes, rebote al pisarlos, daño, reaparición e invulnerabilidad temporal.
- Checkpoint, pausa, meta y guardado mínimo con firma y complemento.
- Animaciones básicas y efectos originales de salto, golpe, daño y meta.

## Pendiente y límites

No hay Super/Fire/Cape Mario, Yoshi, capa, vuelo, plataformas móviles, objetos transportables, bloques activables, monedas, tuberías transitables, puertas, pendientes, agua, scroll vertical, mapa de Dinosaur Land, salidas secretas ni música. Las tuberías y bloques visibles son obstáculos sólidos. Los enemigos son un tipo genérico provisional, no todas las especies de SMW. No hay conversor de niveles de SMW ni niveles comerciales adaptados.

La equivalencia cuadro por cuadro se ha comprobado **solo para el subconjunto de suelo plano y saltos documentado**. No se ha comprobado para otras superficies, colisiones o mecánicas. Los enemigos eliminados permanecen eliminados durante la sesión; el daño reinicia al personaje pequeño. Los sprites pueden recortarse al entrar por los bordes y no se ha implementado un administrador general del límite de ocho sprites por línea.

Próximo hito: reconstruir una sección reconocible de un nivel de SMW con su geometría y colocación de objetos, y comprobar colisiones y cámara contra esa referencia. Después, ampliar los estados y mecánicas mediante pruebas equivalentes. Las 96 salidas siguen siendo una meta de largo plazo. La ROM 0.1 se conserva en `roms/smw-nes-phase1.nes` y en el historial Git.

## Referencia, arquitectura y evidencias

- [`docs/reference-identification.json`](docs/reference-identification.json): identificación de la ROM aportada, hashes y comprobaciones.
- [`docs/physics.md`](docs/physics.md): constantes verificadas, procedencia y diferencias.
- [`docs/architecture.md`](docs/architecture.md): mapa de módulos, memoria y presupuesto.
- [`docs/testing.md`](docs/testing.md): alcance real de pruebas y fixtures.

La referencia aportada resultó coherente con **Super Mario World, Norteamérica, revisión interna 0, LoROM, 512 KiB, sin cabecera de copiador**, CRC32 `B19ED489`. El checksum interno coincide; esto no equivale a una comparación con una base externa de dumps autenticados.

El archivo SNES y el desensamblado de referencia permanecen fuera de este repositorio y de las entregas. `.gitignore` excluye `.sfc` y `.smc`. Los recursos del binario fueron dibujados o sintetizados por los generadores de este proyecto. El nombre Super Mario World y sus personajes pertenecen a sus titulares; este proyecto no tiene afiliación oficial.
