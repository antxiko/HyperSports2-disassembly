# El código

## El programa principal no hace nada

INIT (0x4064) pone la pila en 0xE400, borra la RAM del juego, escribe un
`jp 0x4022` en el gancho H.KEYI, prepara el VDP y el PSG, carga doce valores de
arranque en 0xE053 — y luego cae en un `jr` a sí mismo en 0x40A0 y se queda ahí
para siempre.

Todo pasa dentro de la interrupción. Cada cuadro corre el sonido (0x7696), lee
los mandos (0x44AD) y le da al juego **un paso** (0x40AB). 0xE005 es el candado:
si el paso anterior no ha terminado, la interrupción solo mueve el sonido y se
va.

## La máquina de estados

0xE000 es el estado y 0xE001 el subestado. El estado indexa una tabla de once
palabras y el subestado reparte dentro de cada manejador con una cadena de
`djnz`, así que un manejador se lee como una lista de subestados numerados.

    0  título, cortinilla y rótulos      6  el fotograma de la prueba
    1  espera                            7  fin del intento
    2  cambio de prueba                  8  fin de la prueba
    3  preparar la partida               9  cambio de prueba
    4  montar la prueba                 10  la tabla de records
    5  preparar el intento

## El despachador, y sus diez tablas

Todos los saltos por índice pasan por las mismas siete instrucciones de 0x4046:

    add a,a
    pop hl          ; la direccion de retorno ES la tabla
    call HL_MAS_A
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    jp (hl)

La tabla de palabras va **pegada justo detrás del `call`**, y el despachador se
la saca de la pila. Hay diez (0x40C8, 0x4B80, 0x4BB1, 0x4CD0, 0x4DFE, 0x4EC4,
0x5054, 0x5151, 0x5297 y 0x547C), y todas están declaradas en
`src/hypersports2.nocode`. Un trazador que siga de largo tras un
`call DESPACHA` se come la tabla como instrucciones y da una cobertura falsa: el
tamaño de cada tabla lo fija su destino más bajo hacia delante, y todas cierran
clavadas contra él.

## Lo que corre detrás de un estado que no vuelve

Como el despachador salta y no vuelve, lo que tenga que correr después se
**empuja antes en la pila**:

    ld hl,04cc8h
    push hl
    ld a,(0e080h)
    call DESPACHA

Cuatro direcciones llegan al listado por ahí y por ningún otro sitio: 0x4CC8,
0x521C, 0x44E6 y 0x4F87. Dos de ellas estaban en las anotaciones como datos
hasta que se buscó el patrón a propósito: un `ld hl,NN` y un `push hl` con hasta
tres instrucciones en medio.

## Tres pruebas, unos mismos pasos

Cada prueba tiene su tabla de pasos —siete palabras el tiro con arco (0x5297),
once la halterofilia (0x5151)— y las dos **reutilizan los pasos del tiro al
plato** para lo que no cambia: guardar la marca (0x4FD6), mirar el listón
(0x4FEA), el final (0x501A) y acabar la prueba (0x50DC). Cuatro de los once
pasos de la halterofilia y cuatro de los siete del arco son los del plato,
apuntados desde otra tabla y sin tocar.

## El listado

`tools/mkasm.py` lo genera del trazado y de las anotaciones. En cada compilación
corren dos guardianes:

* `check_trace.py` y `check_datos_como_codigo.py`: ningún byte declarado como
  datos puede salir como instrucción. Esto el reensamblado no lo caza —los bytes
  son los mismos de todas formas, lo único que cambia es lo que decimos de
  ellos.
* `check_entradas.py`: ningún punto de entrada puede caer dentro de un rango de
  datos.

Y `presupuesto.py` se niega a pasar si sobra un solo byte de los 16.384.
