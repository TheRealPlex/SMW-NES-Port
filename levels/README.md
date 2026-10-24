# Datos de niveles

`island1_geometry.json` contiene 256 columnas × 15 filas de metatiles **propios del motor NES**, no punteros ni gráficos SNES. Es una reconstrucción parcial de las primeras 16 de las 20 pantallas horizontales de Yoshi's Island 1 de la ROM identificada en `docs/reference-identification.json`. El recorte vertical desplaza las coordenadas 176 píxeles. Hay sustituciones y simplificaciones; la meta de esta compilación es añadida.

La referencia se estudió ejecutando la ROM local en Snes9x y leyendo Map16 expandido. Los símbolos comprobados en SMWDisX USA son `Map16TilesLow=$7EC800`, `Map16TilesHigh=$7FC800` y `LevelScrLength=$5D`. Cada pantalla horizontal usa 16×27 entradas (432 bytes por plano). Índice comprobado: `(x // 16) * 432 + fila * 16 + (x % 16)`. Los 16 bits Map16 se tradujeron a tipos nativos: suelo, relleno, decoración no sólida, pendientes, tubos, bloques y monedas. No se dedujeron direcciones del nombre del archivo.

La distinción entre relleno decorativo y suelo sólido es necesaria: varios Map16 de dibujo bajo plataformas no tienen colisión. Las pendientes se reducen a 45 grados y no representan todos los contactos SNES. La adaptación de 240 px no conserva toda la altura del nivel.

`tools/generate_assets.py` consume este archivo y añade fondos, enemigos/objetos de prueba y final nativo. La casa, el segundo recorrido y el castillo son layouts propios inspirados en los temas del juego. No están extraídos del ROM ni deben describirse como copias exactas de esos niveles.

La compilación es reproducible sin la ROM comercial. Los dumps de RAM, savestates, desensamblados y archivo `.sfc` permanecen fuera de las entregas. Los datos reconstruidos mantienen una relación con el diseño del juego de referencia; la licencia del código no concede derechos sobre ese diseño o los personajes.
