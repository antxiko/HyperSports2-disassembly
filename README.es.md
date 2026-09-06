# Hyper Sports 2 (Konami, RC-717) — desensamblado comentado

Desensamblado comentado del cartucho de 16 KB para MSX, reproducible byte a
byte.

**[Leer el trabajo →](https://antxiko.github.io/HyperSports2-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que no queda un byte sin explicar
    make densidad   # cuánto está comentado, rutina por rutina
    make textos     # lee los textos del cartucho, que son listas de tiles y no ASCII
    make web        # rehace la web

La ROM **no se distribuye aquí**. Va en la raíz como `hypersports2.rom`, 16384
bytes, sha256

    f4273f5290edb8b55a319bdfc40d99c0f7863a4cbd93b75519508cb129d288f6

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 6.956 bytes, 3.680 instrucciones |
| datos identificados | 9.428 bytes en 151 rangos con nombre |
| comentado | 828 comentarios de línea, 22,5 % |
| rutinas flojas (por debajo del 10 %) | 0 de 500 |

Las anotaciones viven aparte del listado, ancladas a la dirección que
describen, de modo que sobreviven a un retrazado. Lo que hay en el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 314 |
| comentarios anclados | 829 |
| rangos de datos con explicación | 151 |

## Qué hay aquí

- `src/hypersports2.asm` — el listado; generado, no editado a mano
- `src/hypersports2.notes` — las anotaciones, ancladas a dirección
- `src/hypersports2.entries` — los puntos de entrada, cada uno justificado
- `src/hypersports2.nocode` — las diez tablas de despacho pegadas a su `call`
- `docs/` — la web, en inglés y en castellano
- `tools/` — el trazador, el generador del listado, los recorredores de datos y
  los tres intérpretes (flujos por rachas, listas de tiles y el guión del
  título) que dibujan las imágenes de la web desde la ROM

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué hace falta y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | tiro al plato, tiro con arco y halterofilia |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, el mapa de memoria y la pantalla |
| [El código](docs/es/EL-CODIGO.md) | la máquina de estados, el despachador y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | qué se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que sigue sin cerrar |

Ver `AVISO-LEGAL.md`.
