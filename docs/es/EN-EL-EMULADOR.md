# En el emulador

El listado y todas las cifras de esta web salen del binario y se reproducen con
`make`. Aquí no hay nada medido a ojo. El emulador está para comprobar que lo
que dice el listado es lo que hace el cartucho.

## Cómo se corre

    openmsx -machine Philips_VG_8020 -cart hypersports2.rom

Con una máquina MSX1 basta: el cartucho se mapea en la página 1 y lo mueve todo
desde la interrupción de cada cuadro.

## Qué mirar

| dirección | qué guarda |
|---|---|
| 0xE000 | el estado; 0xE001 el subestado |
| 0xE005 | el candado que impide que la interrupción se reentre |
| 0xE036 | distinto de cero mientras suene alguno de los tres canales |
| 0xE080 | la prueba: 0 plato, 1 arco, 2 halterofilia, 3 records |
| 0xE1A1 | el paso dentro de la prueba |
| 0xE1A3 | en la halterofilia, el levantamiento dado por bueno |
| 0xE063 | los puntos, tres bytes en BCD |

Para confirmar un tiempo, un punto de ruptura en la entrada de la rutina y otro
en su `ret`, y la diferencia de `machine_info time` — por 3579545 para tenerlo
en ciclos de Z80.

## Una sesión que comprueba las pruebas

`tools/omsx_capturas.tcl` arranca el cartucho, pulsa teclas por la matriz y hace
capturas. Su registro escribe al lado de cada foto la hora, el PC y el estado,
así que una captura se puede atar al listado:

    t=   21.91  foto tiro_03.png  PC=0x58F3  estado=2
    t=   44.92  foto tiro_05.png  PC=0x445A  estado=2

El primer PC cae dentro de `MIRA_LOS_IMPACTOS` (0x58E3), que es del tiro al
plato; el segundo, dentro del ayudante que prepara la escritura al VDP, con el
arco en pantalla. Eso es lo que fija el orden de 0xE080: primero el plato,
después el arco — y los rótulos `ANGLE 0.00` y `WIND` confirman qué prueba es
cuál sin tener que razonarlo.

## Trampas ya pagadas

* Lanzado con `-script`, el emulador arranca con el renderer `uninitialized`, y
  `screenshot` devuelve un **PNG en negro con código de retorno cero**. Hay que
  encenderlo a mano con `set renderer SDLGL-PP`.
* Con `set throttle off` la máquina corre a toda pastilla y el renderer se salta
  cuadros: la captura hay que pedirla con el acelerador **puesto** y con
  `after realtime`, que es reloj de pared.
* `type space` escribe la palabra "space". El disparo está en la fila 8 de la
  matriz de teclado: `keymatrixdown 8 0x01` para la barra, y 0x10, 0x20, 0x40 y
  0x80 para las cuatro flechas.
* Las rutas de salida de cualquier guión Tcl tienen que ser rutas de Windows,
  nunca `/tmp`.
