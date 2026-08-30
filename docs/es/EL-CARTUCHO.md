# El cartucho

16.384 bytes que se mapean en la página 1 del MSX, 0x4000-0x7FFF. La cabecera de
0x4000 es la de siempre: la marca `AB` y, de los cuatro vectores, solo INIT
relleno, apuntando a 0x4064.

## En qué se van los 16 KB

| | bytes | parte |
|---|---:|---:|
| código trazado | 6.956 | 42,46 % |
| datos identificados | 9.428 | 57,54 % |
| sin explicar | 0 | 0,00 % |

Los datos no son un pegote: son 151 rangos con nombre, cada uno cerrado contra
lo que lo lee. Esta tabla la imprime `make sanity`, y falla si sobra un solo
byte.

## El chip de vídeo

`MANDA_LOS_REGISTROS_DEL_VDP` (0x4476) manda por la BIOS, uno a uno, los ocho
bytes de 0x4487. Dejan la máquina en SCREEN 2 con sprites de 16x16 y reparten la
memoria así:

| tabla | dirección |
|---|---|
| nombres | 0x3800 |
| colores | 0x0000 |
| patrones | 0x2000 |
| atributos de sprite | 0x3B00 |
| patrones de sprite | 0x1800 |

El borde es negro. Patrones y colores tienen sus tres tercios independientes, y
el cartucho lo aprovecha: la fuente va a los tres, y cada prueba solo cambia los
dos de abajo.

## Cómo se guardan los gráficos

Nada se guarda como pantalla. Hay tres intérpretes:

* **El flujo por rachas** (0x43FB). Manda un byte de cuenta: el 0x00 lo acaba,
  el 0x80 trae otra dirección de VRAM en los dos bytes siguientes, con el bit 7
  puesto copia `n & 0x7F` bytes literales, y sin él repite `n` veces el byte que
  sigue. Entrando por 0x43F5 el flujo trae su destino delante.
* **La lista de tiles** (0x4050). Dos bytes con la casilla de la tabla de
  nombres y detrás los tiles; el 0xFE salta a otra casilla y el 0xFF acaba.
* **El guión del título** (0x423C). Cada byte es una cuenta: con el bit 7
  rellena ocho casillas con el byte que sigue, y sin él repite esas mismas ocho
  —un tile entero— esa cantidad de veces.

Todas las imágenes de esta web salen de ejecutar esos tres en Python, en
`tools/graficos.py`. Si un rango o un formato estuvieran mal, lo que saldría
sería ruido.

## Dónde viven los gráficos de cada prueba

La tabla de 0x6C3A tiene **cuatro registros de tres punteros**: patrones a la
VRAM 0x2A00, colores a la 0x0A00 y sprites a la 0x1800, indexados por (0xE080)
y 3 por seis. El cuarto registro es la pantalla de records, que comparte sus
sprites con el tiro con arco. Los fondos están en otro sitio: tres palabras en
0x42A0, directos a la tabla de nombres desde la fila 8.

## El sonido

Tres canales de doce bytes cada uno desde 0xE010: el contador de la nota, lo que
dura, el estado —que es el número del efecto que suena, con el bit 7 para las
órdenes largas y el bit 6 para el ruido—, el puntero al flujo, la octava, el
volumen de fondo, el volumen que suena, la cuenta del apagado, la altura y el
desafine.

`CORRE_EL_SONIDO` (0x7696) les da un paso a los tres cada cuadro y deja en
0xE036 el `or` de los tres estados: esa es la bandera de "algo está sonando" que
espera medio cartucho. Hay 48 efectos y melodías cortas en la tabla de 0x78AC, y
la tabla de tonos es una octava de doce periodos —las demás salen doblando.

## La RAM

0xE000 es el estado y 0xE001 el subestado; 0xE003 el contador de cuadros y
0xE004 la espera general. De 0xE043 a 0xE048 está el mando tal como se lee y
como estaba. 0xE063 guarda los puntos en BCD, 0xE080 la prueba, y en 0xE0C0
están las fichas de sprite que suben al VDP de una tacada. La pila arranca en
0xE400.
