# Preguntas abiertas

El binario está explicado hasta el último byte y vuelve a dar la ROM. Eso no
quiere decir que se entienda todo. Lo que queda abierto, dicho claro:

## Las seis fichas de sprite del tirador

`COLOCA_LAS_SEIS_FICHAS` (0x5E4D) copia con un `ldir` los 24 bytes de 0x5E59 a
0xE0C4, sin una sola cuenta de por medio: seis fichas de sprite con la X en 0xE4
y 0xE8, en el borde derecho de la pantalla, y los patrones 0x64, 0x68, 0x6C,
0x70 y 0x18. Dibujados desde la ROM, el 0x68 y el 0x74 son una figura con los
brazos abiertos, y el 0x70 y el 0x78 parecen piernas; `ALTERNA_DOS_PATRONES`
(0x5E35) cambia entre las dos parejas cada ocho cuadros. Tiene toda la pinta de
una figura corriendo, pero el momento en que sale a pantalla no se ha cazado, y
esta web no afirma lo que es.

## Qué guarda 0xE075

`ELIGE_LA_CATEGORIA` (0x75F7) recorre en redondo las ocho categorías de peso, y
al dar la vuelta no vuelve a cero: coge el valor de 0xE075. Cuál es esa
categoría, y quién la escribe, no está cerrado.

## Los dos motores del arco

0xE147 elige entre dos rutinas que mueven lo mismo: `AVANZA_Y_REMATA` (0x5DE8) y
`ANDA_DE_UN_LADO_A_OTRO` (0x5BDB). Las dos están comentadas por lo que hacen,
instrucción a instrucción, pero cuál corre en qué situación no se ha visto pasar.

## El cuarto registro de gráficos y el tercer fondo

La tabla de 0x6C3A tiene **cuatro** registros de tres punteros; la de 0x42A0,
que lleva los fondos de la tabla de nombres, tiene **tres** palabras. El cuarto
registro de gráficos es la pantalla de records, que nunca pide fondo — pero si
0xE080 y 3 llegara a valer 3 con `CAMBIA_DE_PRUEBA` en marcha, la tabla de
fondos se leería una palabra más allá de su final, en 0x42A6, que es la primera
instrucción de `APAGA_EL_PRIMER_SPRITE`. Leyendo la máquina de estados no parece
alcanzable: la comprobación del bit 2 de 0x41FB sube 0xE080 por encima de ese
valor antes. No está probado corriéndolo.

## Qué hace la demo

El bit 6 de 0xE002 marca la demo, y 0xE1AB hace que un disparo solo se apunte
sin reventar nada. Cuánto dura la demo, y qué juega, no se ha cronometrado.

## El tercero de los tres alfabetos

`tools/textos.py` lee el texto del cartucho con tres bases de tile: la 0x21, la
0x51 y la 0xD1 valen todas por `A`. Las dos primeras son las dos mitades de la
fuente del marcador; dónde se usa la tercera no se ha fijado más allá del
`PUSH SPACE KEY TO START` del título.

---

Si puedes cerrar alguna, el listado está montado para que la respuesta sea una
línea en `src/hypersports2.notes` y un `make`.
