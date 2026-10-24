# Verificación diferencial de movimiento — motor 0.2

Se ejecutó la ROM SNES proporcionada en **Snes9x libretro 1.61**, y la implementación NES en **FCEUX 2.6.5, PPU nueva, NTSC**. La comparación no utiliza un simulador de físicas escrito para generar el resultado esperado.

## Resultado

12 secuencias, **1,514 fotogramas y 13,626 valores numéricos**. La versión inicial difería en 7,913 valores; la 0.2 coincide en todos los valores de estas secuencias. Los informes exactos son `motion-baseline.txt` y `motion-results.txt`.

| Secuencia | Cuadros |
| --- | ---: |
| Caminar derecha / izquierda | 100 + 100 |
| Correr derecha / izquierda hasta cargar P-meter | 150 + 150 |
| Frenar desde carrera | 160 |
| Invertir dirección corriendo | 160 |
| Soltar el botón de correr | 155 |
| Salto corto / mantenido | 72 + 82 |
| Saltar después de cargar carrera | 187 |
| Cambiar dirección en el aire | 88 |
| Soltar los controles en el aire | 110 |

En cada cuadro se comparan nueve campos: desplazamiento X acumulado, desplazamiento Y respecto del suelo, fracciones X/Y, fracción de velocidad X, velocidad X/Y, P-meter y estado aéreo.

## Fixture y límites de la prueba

La ejecución SNES llega mediante mando desde el encendido hasta el inicio de **Yoshi's Island 1**. Se captura un estado en memoria para repetir casos. Al iniciar cada caso se reinician velocidad, fracciones y P-meter; Mario es pequeño, sin objeto ni Yoshi, sobre suelo plano no resbaladizo. Se desactivan sprites mediante WRAM y se mantiene el entero X en 48 antes de cada paso, preservando su fracción; el desplazamiento que produce cada paso se acumula en el registro. Esto evita que obstáculos o límites del nivel contaminen la medición. El suelo original está en Y=352.

En NES se ejecuta el código 6502 real dentro de FCEUX. Un callback prepara los mismos estados e inyecta los botones de cada caso al entrar en `UpdatePlayer`. El suelo del laboratorio está en Y=192; se comparan diferencias respecto del suelo, no coordenadas absolutas incompatibles entre mapas. La colocación X y los inputs son fixtures explícitos, no un recorrido natural del nivel. Las colisiones laterales de SMW, pendientes, agua, agacharse, spin jump, enemigos, capa y Yoshi **no están cubiertos por esta equivalencia**.

El callback toma la muestra al entrar en la siguiente actualización, cuando el paso anterior ha terminado. Los enemigos NES permanecen desactivados para esta medición. Las otras pruebas de jugabilidad, control real del mando, cámara y recorrido completo se ejecutan por separado.

## Reproducir

La CI compara el código NES con la telemetría numérica ya capturada, sin necesitar ni distribuir la ROM comercial:

```sh
make motion
```

Para regenerar independientemente la referencia desde una copia local de la misma ROM y un core externo Snes9x 1.61:

```sh
python3 tools/capture_snes_motion.py \
  --core /ruta/snes9x_libretro.so \
  --rom /ruta/SMW.sfc \
  --output /tmp/smw-motion-reference.json
cmp tests/fixtures/smw-motion-reference.json /tmp/smw-motion-reference.json
```

Esta regeneración se ejecutó y produjo el mismo archivo, byte por byte. El script registra SHA-256 de ROM y core, emula el arranque, conserva el savestate solo en memoria y escribe únicamente telemetría. No parchea ni exporta la ROM. `tools/libretro_reference.py` es un frontend mínimo de la API libretro, no un emulador SNES propio. La API consultada es [libretro.h](https://github.com/libretro/libretro-common/blob/master/include/libretro.h); los símbolos WRAM provienen del mapa USA de SMWDisX identificado en `physics.md`.
