# Validación 0.3

Herramientas ejecutadas: ca65/ld65 (cc65 2.19), Python 3 y FCEUX 2.6.5 con PPU nueva, NTSC, bajo Xvfb. Las capturas de esta versión proceden de `gui.savescreenshotas` en el frontend real, tras cuadros a velocidad normal; no son mockups ni imágenes reconstruidas a partir del mapa. El recorte visible del frontend es 256×224. El helper RGB usado por los tests antiguos 0.2 no se usa para estas imágenes: mostraba colores de sprites incorrectos en esta configuración de PPU.

| Categoría | Alcance |
| --- | --- |
| Compilación | ca65 y ld65 ejecutados; ROM nativa reproducible |
| Validación estática | Cabecera, MMC3, PRG/CHR, batería, vectores, bancos, límites RAM y patrones |
| Ejecución real en emulador | FCEUX; mapa, escenarios, poderes, Yoshi, vuelo, plataformas, SRAM y NMI |
| Jugabilidad automatizada | Fixtures aislados y prueba independiente de mando sin escribir RAM |
| Jugabilidad humana | No realizada |
| Mesen / NES física | No ejecutados; compatibilidad todavía por comprobar |

## Pruebas actuales

`tests/adventure.lua` usa símbolos del binario compilado, entradas reales del mando y **fixtures de RAM explícitos** para aislar estados y colocar al personaje, enemigos u objetos. Comprueba bloqueo de caminos, banco correcto, transformación, reserva, proyectil de fuego, giro, carrera con P-meter, despegue, inclinación, planeo, montura, lengua, desmontaje, daño de Yoshi, estrella, 1-Up, globo, bloque golpeado mediante salto, plataformas móviles, checkpoint, muerte, metas, desbloqueos y traslado de Yoshi entre regiones. Las metas se activan mediante el código real del juego, después de posicionar al jugador por fixture; esto no representa un recorrido íntegro de esos escenarios.

Las comprobaciones de streaming comparan las nametables leídas por `ppu.readbyte` contra el mapa mutable de WRAM tras avanzar más allá de 2,048 px y retroceder. Miden tiles, no todos los atributos ni la sincronización de IRQ de todos los cuadros.

`persistence_v03.lua` arranca **otro proceso de FCEUX** tras el cierre normal del primero, sin savestate ni escrituras RAM. Comprueba que el juego carga de SRAM la máscara 14 escrita al completar las tres regiones. La firma y complemento detectan algunos guardados inválidos; no garantizan atomicidad frente a cortes de energía.

`adventure_traversal.lua` enciende un tercer proceso, navega el mapa, recoge suministros en la casa y monta a Yoshi mediante el mando. Consulta el estado y la geometría para guiar sus botones; **no escribe RAM**. Su resultado exacto, máximo recorrido y muertes están en `test-results.txt`; no equivale a una evaluación humana ni certifica todas las rutas.

`motion_compare.lua` conserva la comparación diferencial con la telemetría real SNES: 12 casos, 1,514 cuadros y 13,626 valores. Se aíslan enemigos, poderes y plataformas para conservar el alcance original: Mario pequeño sobre suelo plano, aceleración/frenado/salto/control aéreo. No prueba la equivalencia de Yoshi, capa, natación, pendientes o colisiones complejas contra SMW.

`make test` ejecuta estas pruebas. Los scripts `gameplay.lua`, `persistence.lua`, `traversal.lua` y `run_emulator.sh` anteriores se conservan como historia de 0.2; no validan el binario 0.3 ni forman parte del objetivo actual.

## Fallos corregidos

- Interferencia del NMI con PPUADDR durante cargas con rendering apagado: causaba una columna corrupta visible tras avanzar o reconstruir pantalla. Se protege el acceso PPU durante la reconstrucción y se sigue liberando la señal de frame.
- Retención de coordenadas de 16 bits y streaming correcto al superar 2,048 px.
- Distancia a Yoshi entre páginas, plataformas que cambiaban dirección durante el transporte y superposición de la montura.
- Rellenos decorativos de la referencia tratados erróneamente como sólidos, pendientes y dibujo de colinas.

Los resultados exactos y el máximo de ciclos NMI observado están en `test-results.txt`; el hash del binario está en `static-results.json`. La medida NMI llega hasta antes de RTI e incluye DMA. No es un perfil exhaustivo de CPU ni una certificación de hardware.

Faltan prueba manual, evaluación auditiva, temporización IRQ en Mesen, perfiles del peor caso y flashcart MMC3 NTSC con batería. El siguiente paso recomendado es completar la geometría/entidades de la primera región y medir las mecánicas avanzadas frente a SNES.
