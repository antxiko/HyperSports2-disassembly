# Hallazgos

Todo lo de aquí está medido contra el binario. Donde hay una cifra, al lado está
la dirección de donde sale.

## Los tres secretos, y qué dispara exactamente cada uno

El cartucho esconde un premio en cada prueba. Ninguno sale al azar: los tres
cuelgan de un byte que se puede señalar con el dedo.

**Tiro al plato — el pulpo y el pájaro.** `SUELTA_EL_PLATO` (0x5757) sólo
escribe en la ranura las posturas 1, 2 y 3: los platos de 100, 500 y 1000. Las
posturas 4 y 5 salen de dos rutinas escondidas al final de la ROM,
`SUELTA_EL_PULPO` (0x761A) y `SUELTA_EL_PAJARO` (0x762F), que rellenan la
ranura a mano con nueve bytes escritos en el cartucho: la postura, la Y 0x60,
la X 0xE8 y una velocidad de 0xFC00 que los lleva hacia la izquierda.

0x4F59 las llama cuando una tanda se acaba con las tres ranuras vacías,
contando las tandas en 0xE19A: el pulpo en la primera y el pájaro en la
segunda. Pero la primera instrucción de 0x762F lee 0xE179, y lo único que llega
a marcar ese byte es 0x5AC1, **cuando el plato que se acaba de reventar era la
postura 4 —el pulpo— y 0xE178 dice que el disparo salió del cañón de arriba**.
0xE178 lo escribe `UN_DISPARO` (0x5A10): cero para el cañón de abajo (0xE0C0,
que apunta alrededor de la Y 0x90) y distinto de cero para el de arriba
(0xE0C4, alrededor de la 0x60). Así que darle al pulpo no basta: tiene que ser
con el cañón de arriba.

Y hay una forma de quedarse sin los dos. Cada vez que 0x58EF retira un plato
sin que 0xE179 esté puesto, 0x591D marca 0xE199; y con 0xE199 puesto, 0x4F59 no
llama a ninguna de las dos rutinas y 0x4F75 deja de subir la dificultad.

Lo que paga cada uno sale de la tabla que empieza en el `ret` de 0x5B0A, en
BCD: 01, 05, 10, **30** y 10 para las posturas 1 a 5. El pulpo vale 3000 y el
pájaro 1000, y el numerito que sale flotando es el patrón de la tabla de
0x5AA5: 0x14, 0x18, 0x1C, **0x3C** —el rótulo `3000`— y 0x1C.

**Tiro con arco — la manzana y el pingüino.** 0xE145 arranca en 3 (0x4C32).
`CUENTA_ATRAS_DEL_TIRO` (0x65D1) le quita uno al acabar un tiro, pero sólo
cuando la flecha se clavó en **el anillo 9**. El anillo 9 no es el aro de
fuera: 0x5CFF los numera del 0 en el borde al 9 en el centro, y la tabla de
0x5D37 paga 10 por el anillo 0 y 600 por el 9. El anillo 9 es la diana.

Al tercer centro 0xE145 llega a cero, y `REMATA_EL_PASO` (0x5C22) toma la otra
rama: en vez del remate de siempre copia las seis fichas de sprite de 0x5E59 a
0xE0C4 —la manzana y el pingüino—. Acertarle al pingüino (0x5E0F) deja el
patrón 0x7C, que es el rótulo `3000`, y 0x0030 en BCD en 0xE11D: otros 3000
puntos.

**Halterofilia — las flores.** Este no es un sprite. El jurado da el
levantamiento por bueno en 0x6F98, dejando puesto 0xE1A3; a partir de ahí
`WEIGHT_PASO_5` (0x523E) sube 0xE132 un punto por cada cuadro que el botón siga
pulsado. Cuando 0xE132 llega a 5, `REMATE_DEL_WEIGHT` (0x5065) rellena doce
casillas de la fila 16 con el tile 0x91 y doce de la 17 con el 0x92 —el arriate
sobre el podio— y 0x524B cobra encima 2000 puntos en BCD.

## Un patrón de sprite no tiene color: la ficha sí

Ninguno de los tres se podía dibujar sólo con la tabla de patrones. En el MSX1
el color de un sprite vive en su **ficha**, un byte por sprite, y una figura
suele ser varios sprites superpuestos.

El pingüino es el caso más claro: las seis fichas de 0x5E59 ponen **tres
sprites en la misma casilla**, el patrón 0x68 en el color 0x04, el 0x6C en 0x0F
y el 0x70 en 0x0A: azul, blanco y amarillo. Tres sprites de un color cada uno
para hacer un pájaro de tres colores. Y 0x5E35 cambia dos de esos patrones cada
ocho cuadros (el 0x68 por el 0x74 y el 0x70 por el 0x78): el pingüino anda.

Los platos y sus bichos no tienen ficha fija: 0x5108 busca su patrón **y su
color** en la tabla de parejas de 0x511D, indexada por la postura de la ranura.
Las posturas 1 a 3 son el mismo patrón 0x00 en tres colores —0x0F, 0x04 y
0x06— y de la 4 en adelante vienen 0x2C/0x0F para el pulpo y 0x30/0x04 y
0x38/0x04 para el pájaro, los dos patrones que 0x50FC alterna para que bata las
alas.

## Tres luces del jurado, y un byte que manda en cinco sitios

El levantamiento no lo decide la barra de potencia. Con la barra arriba,
`CUENTA_LAS_LUCES_DEL_JURADO` (0x6F78) enciende **una luz cada 0x20 cuadros** en
la columna 2, justo debajo del rótulo `JUDGE`, y a la tercera pone 0xE071 y
0xE1A3 a uno.

Ese 0xE1A3 se lee luego en cinco sitios distintos: decide si la marca se copia a
los puntos del intento (0x520B), si se puede subir la postura (0x5231), cuál de
dos bloques de dieciséis bytes va a la VRAM (0x50AF), qué patrón parpadea
(0x50C8) y si la cifra que se pinta es una u otra (0x5266). Un byte, cinco
consecuencias.

## El arco acierta con Pitágoras y sin raíz cuadrada

`QUE_ANILLO_HA_TOCADO` (0x5CCF) coge las dos distancias de la flecha al centro
de la diana —X 0xBC, Y 0x53—, eleva cada una al cuadrado con ocho sumas y
desplazamientos (0x5D0C), suma los dos cuadrados y compara eso contra la tabla
de 0x5D03.

Esa tabla son **los radios de los nueve anillos, ya elevados al cuadrado**: 1,
6, 16, 25, 64, 96, 144, 196 y 289. No se saca ninguna raíz. Y el último radio no
cabe en un byte, así que el bucle le pone el 1 de arriba a mano con un apaño que
merece leerse dos veces:

    xor a           ; el byte alto es 0...
    djnz L_5CF1
    inc a           ; ...menos en el noveno, que es 1

## Los platos no salen al azar: están escritos bit a bit

El lanzador (0x5738) lee hacia dónde sale cada plato de la tabla de 0x583E **bit
a bit**, y su altura de la de 0x5866 **de dos en dos bits**, cada una con su
propio contador. No hay ninguna semilla, ni un reloj, ni el registro de refresco
cerca: el mismo cartucho lanza los mismos platos en el mismo orden, siempre.

## Una octava de doce notas, y las demás doblando

El reproductor guarda exactamente doce periodos en 0x7832 —0x6A, 0x64, 0x5F,
0x59, 0x54, 0x50, 0x4B, 0x47, 0x43, 0x3F, 0x3C y 0x38— y saca todas las demás
octavas doblando el periodo en 0x7815, que es justo lo que significa bajar una
octava. Con el reloj del PSG (111.861 Hz entre el periodo), el 0x6A da 1.055 Hz
y el 0x38 da 1.998: el do y el si de la misma octava, con los once semitonos de
en medio cayendo donde tienen que caer.

## Ocho categorías de peso, y un ángulo en centésimas

En 0x7587 hay ocho nombres de catorce tiles cada uno —FLY, BANTAM, FEATHER,
LIGHT y MIDDLE WEIGHT, MIDDLE HEAVY, HEAVY WEIGHT y SUPER HEAVY— y en 0x6F48 sus
ocho pesos en BCD: 150, 165, 180, 195, 210, 225, 240 y 260 kilos.

El ángulo del arco, en la otra prueba, es un número de dos bytes en BCD que sube
0x28 con cada pulsación —o sea 0,28 grados, como enseña el `ANGLE 0.00` de la
fila 10— y da la vuelta cuando el byte de las centenas llega a 4.

## Dos tablas que empiezan en un `ret`

0x5AA6 y 0x5B0B se leen como tablas, pero el código que las indexa apunta un
byte antes, a 0x5AA5 y 0x5B0A — y esos dos bytes son el `ret` de la rutina de
encima. La entrada 0 de cada tabla es un 0xC9, y no se usa nunca: el índice
entra siempre desde 1. El listado las declara como lo que son, con el `equ` que
deja que todo ensamble.

## El mismo byte, escrito dos veces

`ELIGE_LA_CATEGORIA` (0x75F7) deja la categoría elegida con

    ld (hl),a
    ld (0e110h),a

y HL ya apuntaba a 0xE110. Tres bytes y trece ciclos por cuadro que no hacen
nada.

## No lleva la marca oculta de Konami

Muchos cartuchos de la casa esconden al final de la ROM su número de catálogo y
el título en katakana —lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX))—. Este no: los últimos
25 bytes son 0xFF de relleno, y no hay ningún 0xAA cerca que cierre la marca. El
RC-717 viene del catálogo, no del binario. Hyper Sports 1 (RC-715) tampoco la
lleva, mientras que sus primos Hyper Olympic 1 y 2 sí.
