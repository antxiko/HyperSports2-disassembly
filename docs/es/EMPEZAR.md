# Empezar

Desensamblado comentado de **Hyper Sports 2**, el RC-717 de Konami para MSX: un
cartucho de 16 KB que se mapea en la página 1 (0x4000-0x7FFF). Vuelve a
ensamblar dando la ROM exacta, byte a byte, y los 16.384 bytes están todos
explicados.

## El cartucho no está aquí

Ningún repositorio distribuye el juego. Pon tu propio volcado en la raíz como
`hypersports2.rom`, 16384 bytes, sha256

    f4273f5290edb8b55a319bdfc40d99c0f7863a4cbd93b75519508cb129d288f6

`make comprueba` lo verifica.

## Qué hace cada orden

    make            traza el flujo, genera el listado, lo reensambla y pasa los tests
    make verify     la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     que no queda un byte sin explicar, y que ningún dato sale como código
    make densidad   cuánto está comentado, rutina por rutina
    make textos     lee los textos del cartucho, que son listas de tiles y no ASCII
    make web        rehace esta web desde la ROM y las anotaciones

## Cómo está montado

El listado no se edita a mano. `tools/mkasm.py` lo genera a partir de un trazado
del flujo y de un fichero de anotaciones ancladas a dirección, de modo que los
comentarios sobreviven a un retrazado:

* `src/hypersports2.entries` — los puntos de entrada que el trazador no puede
  deducir solo: el gancho de la interrupción, las diez tablas de despacho
  pegadas a su `call` y las cuatro direcciones de retorno que este cartucho
  empuja en la pila en vez de llamar. Cada una con su motivo escrito al lado.
* `src/hypersports2.nocode` — esas diez tablas de palabras. Un trazador que siga
  de largo se las come como instrucciones y da una cobertura que no se ha
  ganado.
* `src/hypersports2.notes` — una línea por anotación: `L` bautiza una rutina,
  `C` comenta una instrucción, `B` un bloque, `D` un rango de datos y `F` la
  anchura de la estructura que lleva dentro.

## Qué significan las cifras

`make sanity` imprime el presupuesto: 6.956 bytes de código trazado y 9.428 de
datos en rangos con nombre, 0 sin explicar, 16.384 en total. `make densidad`
imprime la densidad de comentario: 3.680 instrucciones, 828 comentarios de
línea, 22,5 %, y ni una rutina por debajo del 10 %.

Todas las cifras de esta web salen de esas dos órdenes, no de una estimación.
