# Hallazgos

Todo lo de aquí está medido contra el binario. Donde hay una cifra, al lado está
la dirección de donde sale.

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
