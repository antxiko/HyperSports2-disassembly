# El juego

Tres pruebas, y en este orden, escritas en la ROM en 0x4791 como tres filas de
dieciséis tiles: **SKEET SHOOTING**, **ARCHERY** y **WEIGHT LIFTING**. El byte
0xE080 dice cuál está en marcha, y sus dos bits bajos indexan todas las tablas
que reparten por prueba.

## Tiro al plato

Dos miras y un reloj. `LANZA_UN_PLATO` (0x5738) suelta un plato cada 0x18
cuadros por la ranura que esté libre de las tres de 0xE100; cada ranura son
dieciséis bytes con la postura del plato, su X y su Y de 16 bits y sus dos
velocidades. `CAEN_LOS_PLATOS` les suma la gravedad, y la gravedad es mayor
cuanto más alto está el plato, así que el arco se cierra al caer.

El disparo sale con el bit 3 del mando para el cañón de arriba y con los bits 2
y 4 para el de abajo. `MIRA_LOS_IMPACTOS` (0x58E3) recorre las tres ranuras y,
por cada perdigón, admite seis puntos de margen en X y otros seis en Y — y solo
las posturas 0 a 3 se pueden reventar.

## Tiro con arco

Los marcadores son tres, y la pantalla los nombra: `ANGLE` en la fila 10, `WIND`
abajo y `SCORE` a su lado.

* El **ángulo** sube 0,28 grados con cada pulsación del botón y da la vuelta a
  los 4,00 (0x5B42, en BCD, con el byte de las centenas comparado contra 4).
* El **viento** tampoco es azar: `SIGUIENTE_VIENTO` (0x5BB8) recorre en redondo
  los dieciséis valores de 0x5BCB, el bit 7 para el lado y el nibble bajo para
  la fuerza. Según sube la flecha, `CORRIGE_LA_DERIVA` (0x5B8C) la va torciendo
  un punto por cada tramo de la tabla de 0x5BB0.
* El **acierto** lo decide `QUE_ANILLO_HA_TOCADO` (0x5CCF) contra una diana
  centrada en la X 0xBC y la Y 0x53 —las dos constantes que se ven en la
  pantalla— y cada anillo paga lo que diga la tabla de diez palabras en BCD de
  0x5D37: 10, 100, 170, 210, 250, 290, 320, 350, 400 y 600.

## Halterofilia

Primero se elige categoría. `ELIGE_LA_CATEGORIA` (0x75F7) pasa por las ocho con
cualquier dirección y la acepta con el botón; `PINTA_LA_CATEGORIA` (0x756D)
escribe su nombre, catorce tiles sacados de 0x7587, en el cartel
`CHOOSE CLASS`, y `PINTA_LOS_KILOS` (0x6F25) pone su peso en el de `KG`: 150,
165, 180, 195, 210, 225, 240 y 260 kilos.

Luego la barra `POWER` de la fila 23 (0x6E24), que la tabla de 0x6E77 le va
restando cada cuadro y el mando le suma. La barra sube por las 36 alturas de
0x6ED4, y una vez arriba se encienden **las tres luces del jurado** en la
columna 2, una cada 0x20 cuadros (0x6F78). A la tercera el levantamiento vale, y
0x6FA2 deja caer los dos discos de la barra desde la Y 0x4A, dos puntos por
cuadro.

## El marcador, y lo que se arrastra

La parte de arriba es la misma en las tres pantallas: `SCORE`, `HI`, `YOU`,
`WORLD RECORD`, `QUALIFY` y las tres filas de `1st TRY`, `2nd TRY` y `3rd TRY`,
pintadas con el flujo de 0x4749 y la lista de rótulos de 0x4712 encima. Los
puntos son tres bytes en BCD desde 0xE063 y topan en 999999.

Detrás de la tercera prueba viene la pantalla de records, y luego vuelta a
empezar: 0xE080 cuenta 0, 1, 2 y 3, y en el 3 manda la tabla de records —salvo
que el bit 2 de ese mismo byte se la salta una vuelta sí y otra no.
