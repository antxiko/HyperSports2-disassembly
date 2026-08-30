; ==========================================================================
; HYPER SPORTS 2 - Konami - MSX1 - cartucho RC-717 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
L_5D11:	equ 0x05d11

; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l5aa5h:	equ 0x05aa5
l5b0ah:	equ 0x05b0a

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La cabecera que lee la BIOS: "AB", INIT=0x4064
;   y a cero STATEMENT, DEVICE y TEXT. La BIOS mapea el cartucho en la pagina
;   1 (0x4000-0x7FFF) y salta a 0x4064 al terminar de arrancar
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 04064h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x40a2  (146 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS TRES UTILIDADES QUE USA TODO EL CARTUCHO: escribir un byte en la
; VRAM, y sumar A a HL o a DE sin signo. El puerto de datos del VDP
; vive en el C alternativo, que 0x445A deja puesto.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
VPOKE:		; Escribe A en la VRAM DE
	call PREPARA_ESCRITURA		;4010   ; Manda la direccion y deja el puerto en el C alternativo
	exx			;4013
	out (c),a		;4014   ; El byte, por el registro alternativo
	exx			;4016
	ret			;4017
HL_MAS_A:		; HL = HL + A, sin signo
	add a,l			;4018   ; El acarreo sube al byte alto
	ld l,a			;4019
	ret nc			;401a
	inc h			;401b
	ret			;401c
DE_MAS_A:		; DE = DE + A, sin signo
	add a,e			;401d   ; Lo mismo con DE
	ld e,a			;401e
	ret nc			;401f
	inc d			;4020
	ret			;4021

; ----------------------------------------------------------------------
; ######################################################################
; LA INTERRUPCION (gancho H.KEYI). Aqui corre el juego entero: INIT la
; engancha y se queda en un `jr $` para siempre. Cada fotograma toca
; el sonido (0x7696), lee los mandos (0x44AD) y da UN PASO del juego
; (0x40AB). E005 es el candado: si el paso anterior no ha terminado,
; esta interrupcion solo mueve el sonido y se va.
; ######################################################################
; ----------------------------------------------------------------------
INTERRUPCION:		; Cada fotograma: sonido, mandos y un paso del juego
	call 0013eh		;4022   ; BIOS RDVDP - Reads VDP status register | Leer el estado del VDP baja la peticion de interrupcion
	di			;4025
	call CORRE_EL_SONIDO		;4026   ; El sonido va SIEMPRE, aunque el fotograma anterior siga a medias
	ld hl,0e005h		;4029
	bit 0,(hl)		;402c   ; Candado echado: el paso anterior no ha acabado
	jr nz,L_403C		;402e
	inc (hl)			;4030
	ei			;4031   ; Con el candado puesto ya se admiten interrupciones: solo entrara el sonido
	call LEE_Y_APUNTA_EL_MANDO		;4032
	call PASO_DEL_JUEGO		;4035   ; Un paso del juego
	xor a			;4038
	ld (0e005h),a		;4039
L_403C:
	call 0013eh		;403c   ; BIOS RDVDP - Reads VDP status register
	di			;403f
	or a			;4040
	call m,CORRE_EL_SONIDO		;4041   ; Y si el VDP avisa de colision o de sprites de mas, otra pasada de sonido
	ei			;4044
	ret			;4045

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL DESPACHADOR. Se le llama con el indice en A y la tabla de palabras
; va PEGADA detras del CALL: el `pop hl` recoge la direccion de retorno,
; que es justo el principio de la tabla. Salta con `jp (hl)` y no vuelve
; nunca al call. Lo usan DIEZ tablas en todo el cartucho.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
DESPACHA:		; Salta al destino A de la tabla que va detras del CALL
	add a,a			;4046
	pop hl			;4047   ; La direccion de retorno ES la tabla
	call HL_MAS_A		;4048
	ld e,(hl)			;404b
	inc hl			;404c
	ld d,(hl)			;404d
	ex de,hl			;404e
	jp (hl)			;404f
PINTA_LISTA:		; Pinta una lista de tiles: palabra de VRAM delante, 0xFE arranca otra y 0xFF acaba
	ex de,hl			;4050
	ld e,(hl)			;4051   ; Los dos primeros bytes son la casilla donde empieza
	inc hl			;4052
	ld d,(hl)			;4053
	ex de,hl			;4054
	inc de			;4055
PINTA_LISTA_TILE:		; Siguiente tile de la lista
	ld a,(de)			;4056
	inc de			;4057
	ld b,a			;4058
	inc b			;4059   ; 0xFF: se acabo
	ret z			;405a
	inc b			;405b   ; 0xFE: sigue en otra casilla
	jr z,PINTA_LISTA		;405c
	call VPOKE		;405e
	inc hl			;4061
	jr PINTA_LISTA_TILE		;4062

; ----------------------------------------------------------------------
; ######################################################################
; INIT. Pila en 0xE400, la RAM del juego (0xE000-0xE3FF) a cero,
; `jp 0x4022` en el gancho H.KEYI, el VDP y el PSG (0x4466), los doce
; valores de arranque a 0xE053, y a esperar interrupciones para
; siempre en 0x40A0.
; ######################################################################
; ----------------------------------------------------------------------
INIT:		; Arranque desde la cabecera: RAM, gancho, VDP y a esperar
	di			;4064
	im 1		;4065
	ld a,0c3h		;4067   ; 0xC3 = jp: el gancho H.KEYI queda como `jp 0x4022`
	ld (0fd9ah),a		;4069
	ld hl,INTERRUPCION		;406c
	ld (0fd9bh),hl		;406f
	ld sp,0e400h		;4072
	ld hl,0e000h		;4075
	ld de,0e001h		;4078
	ld bc,003ffh		;407b
	ld (hl),l			;407e   ; `ld (hl),l` con HL en 0xE000 escribe un cero: un byte menos que `ld (hl),0`
	ldir		;407f
	ld a,001h		;4081   ; Candado echado mientras dura el arranque
	ld (0e005h),a		;4083
	call ARRANCA_EL_VDP_Y_LA_VRAM		;4086
	xor a			;4089
	ld (0e005h),a		;408a
	ld hl,040a2h		;408d   ; Los doce valores de arranque, a 0xE053
	ld de,0e053h		;4090
	ld bc,0000ch		;4093
	ldir		;4096
	ld hl,0e080h		;4098
	dec (hl)			;409b   ; E080 arranca en 0xFF: la prueba, que el primer paso sube a 0
	call 0013eh		;409c   ; BIOS RDVDP - Reads VDP status register
	ei			;409f
ESPERA_ETERNA:		; Aqui se queda el programa principal; el juego es la interrupcion
	jr ESPERA_ETERNA		;40a0

; ----------------------------------------------------------------------
; DATOS valores_iniciales: Los bytes que 0x408D copia a 0xE053 con un ldir de
;   doce. OJO: la copia pide DOCE y aqui solo hay nueve, asi que los tres
;   ultimos los toma del codigo que empieza en 0x40AB
;   0x40a2..0x40ab  (9 bytes)
DATA_valores_iniciales:
	defb 010h,002h,0f2h,000h,035h,000h,000h,043h,000h	; 40a2  ....5..C.

; ======================================================================
; CODIGO 0x40ab..0x40c8  (29 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL JUEGO. `ld bc,(0xE000)` trae de una sola vez el ESTADO en
; C y el SUBESTADO en B, y por eso los estados de abajo reparten con
; `djnz`: el subestado es la cuenta. Fuera del estado 3, y con el bit 6
; de E002 a cero, se empuja 0x44E6 para que corra detras del estado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DEL_JUEGO:		; Cuenta el fotograma y ejecuta el estado de E000 con su subestado en B
	ld hl,0e003h		;40ab   ; E003, el contador de fotogramas
	inc (hl)			;40ae
	ld bc,(0e000h)		;40af   ; C = E000 (el estado) y B = E001 (el subestado), de una sola lectura
	ld a,c			;40b3
	cp 003h		;40b4   ; En el estado 3 no se empuja nada
	jr z,L_40C5		;40b6
	ex af,af'			;40b8
	ld a,(0e002h)		;40b9
	and 040h		;40bc
	ld hl,044e6h		;40be   ; La direccion que correra DESPUES del estado, empujada en la pila
	jr nz,L_40C4		;40c1
	push hl			;40c3
L_40C4:
	ex af,af'			;40c4
L_40C5:
	call DESPACHA		;40c5   ; Y la tabla de once estados, justo detras

; ----------------------------------------------------------------------
; DATOS tabla_de_40C8: Las 11 palabras del despacho de 0x40C5, pegadas detras
;   de su call: 0x40DE 0x4112 0x4119 0x4132 0x4157 0x4162 0x4176 0x418B 0x41A7
;   0x41E2 0x4211. Cierra clavada contra su destino mas bajo hacia delante
;   0x40c8..0x40de  (22 bytes)
DATA_tabla_de_40C8:
	defw 040deh	; 40c8  -> ESTADO_00_ESPERA
	defw 04112h	; 40ca  -> ESTADO_01_ESPERA
	defw 04119h	; 40cc  -> ESTADO_02
	defw 04132h	; 40ce  -> ESTADO_03
	defw 04157h	; 40d0  -> ESTADO_04
	defw 04162h	; 40d2  -> ESTADO_05
	defw 04176h	; 40d4  -> ESTADO_06_EN_JUEGO
	defw 0418bh	; 40d6  -> ESTADO_07_FIN_DE_INTENTO
	defw 041a7h	; 40d8  -> ESTADO_08_FIN_DE_PRUEBA
	defw 041e2h	; 40da  -> ESTADO_09_CAMBIA_DE_PRUEBA
	defw 04211h	; 40dc  -> ESTADO_10

; ======================================================================
; CODIGO 0x40de..0x42a0  (450 bytes)
; ======================================================================


ESTADO_00_ESPERA:		; Subestado 0: cada dos fotogramas mira si 0x4A84 ha terminado; luego pinta la lista de 0x47F6
	djnz ESTADO_00_SUB1		;40de
	ld a,(0e003h)		;40e0
	rra			;40e3   ; Uno de cada dos fotogramas
	ret nc			;40e4
	call SUBE_EL_LOGOTIPO		;40e5
	ret nz			;40e8
	ld de,047f6h		;40e9   ; La lista que toque, y a esperar
	call PINTA_LISTA		;40ec
	xor a			;40ef
	jr ESPERA_A_Y_SIGUE		;40f0
ESTADO_00_SUB1:		; Subestado 1: espera a que E004 llegue a cero y apaga E007
	djnz ESTADO_00_SUB2		;40f2
	ld hl,0e004h		;40f4   ; E004, lo que queda de espera
	dec (hl)			;40f7
	ret nz			;40f8
	xor a			;40f9
	ld (0e007h),a		;40fa   ; E007 a cero
	jr SUBESTADO_SIGUIENTE		;40fd
ESTADO_00_SUB2:		; Subestado 2: 0x437E y al subestado siguiente
	djnz ESTADO_00_SUB3		;40ff   ; Al 3 si el subestado no es el 2
	call PINTA_LOS_ROTULOS		;4101
	xor a			;4104   ; Sin espera: al estado siguiente de golpe
	jr ESPERA_A_Y_ESTADO		;4105
ESTADO_00_SUB3:		; Subestado 3: borra la pantalla, 0x421B y los registros del VDP
	call BORRA_LA_PANTALLA		;4107   ; Pantalla limpia, titulo montado y VDP puesto
	call MONTA_LA_PANTALLA		;410a
	call MANDA_LOS_REGISTROS_DEL_VDP		;410d
	jr SUBESTADO_SIGUIENTE		;4110
ESTADO_01_ESPERA:		; Espera los fotogramas de E004 y pasa de estado
	ld hl,0e004h		;4112   ; E004, los fotogramas que quedan
	dec (hl)			;4115
	ret nz			;4116
	jr ESPERA_A_Y_ESTADO		;4117
ESTADO_02:		; Subestado 0: 0x4DF4 y, con E081 puesto, al estado 0
	djnz ESTADO_02_SUB1		;4119   ; Al subestado 1 si no es el 0
	call FOTOGRAMA_CON_VUELTA		;411b
	ld a,(0e081h)		;411e   ; E081 lo pone la prueba al acabar el intento
	and a			;4121
	ret z			;4122
VUELVE_AL_ESTADO_0:		; E000 = 0 y el subestado a cero
	xor a			;4123   ; El estado vuelve a cero
	jp L_41A2		;4124
ESTADO_02_SUB1:		; Subestado 1: 0x4DD0
	call CAMBIA_DE_PRUEBA		;4127
ESPERA_A_Y_SIGUE:		; Deja A en E004 y sube el subestado
	ld (0e004h),a		;412a   ; E004 se carga con lo que traiga A
SUBESTADO_SIGUIENTE:		; E001 + 1
	ld hl,0e001h		;412d   ; E001 es el subestado
	inc (hl)			;4130
	ret			;4131
ESTADO_03:		; Subestado 0: agota E004 y llama a 0x426D
	djnz ESTADO_03_SUB1		;4132   ; Al subestado 1 si no es el 0
	ld hl,0e004h		;4134
	dec (hl)			;4137
	ret nz			;4138
	call PREPARA_LA_PARTIDA		;4139
ESPERA_A_Y_ESTADO:		; Deja A en E004 y pasa al estado siguiente
	ld (0e004h),a		;413c
ESTADO_SIGUIENTE:		; E000 + 1 y el subestado a cero
	ld hl,0e000h		;413f   ; E000 es el estado
	inc (hl)			;4142
SUBESTADO_A_CERO:		; E001 = 0
	xor a			;4143   ; Y el subestado arranca de cero
	ld (0e001h),a		;4144
	ret			;4147
ESTADO_03_SUB1:		; Sonido 0x9C, 80 fotogramas de espera y 0x437B
	ld a,09ch		;4148   ; El sonido de arranque de la prueba
	call SUENA_SI_SE_PUEDE		;414a
	ld a,050h		;414d   ; Ochenta fotogramas
	ld (0e004h),a		;414f
L_4152:
	call MONTA_EL_TITULO		;4152
	jr SUBESTADO_SIGUIENTE		;4155
ESTADO_04:		; Borra la pantalla, monta la prueba (0x4B48) y su marcador (0x42FD)
	call BORRA_LA_PANTALLA		;4157
	call MONTA_LA_PRUEBA		;415a
	call PINTA_EL_MARCADOR		;415d
	jr ESTADO_SIGUIENTE		;4160
ESTADO_05:		; Subestado 0: 0x4288 y al estado siguiente
	djnz ESTADO_05_SUB1		;4162
	call PINTA_EL_FONDO_DE_LA_PRUEBA		;4164
	jr ESTADO_SIGUIENTE		;4167
ESTADO_05_SUB1:		; Baja el intento (E072), 0x4B86 y apaga E081
	ld hl,0e072h		;4169   ; E072, los intentos que quedan
	dec (hl)			;416c
	call PREPARA_EL_INTENTO		;416d
	xor a			;4170
	ld (0e081h),a		;4171   ; E081 a cero: el intento arranca limpio
	jr SUBESTADO_SIGUIENTE		;4174
ESTADO_06_EN_JUEGO:		; El fotograma de la prueba: 0x434F y 0x4CC8; cuando E081 avisa, se acaba el intento
	call PARPADEA_EL_INTENTO		;4176
	call UN_FOTOGRAMA_DE_LA_PRUEBA		;4179
	ld hl,0e081h		;417c   ; E081 lo pone la prueba cuando el intento ha terminado
	ld a,(hl)			;417f
	or a			;4180
	ret z			;4181
	dec (hl)			;4182
	call BORRA_LOS_INTENTOS		;4183
	call COBRA_LOS_PUNTOS		;4186
	jr ESPERA_A_Y_ESTADO		;4189
ESTADO_07_FIN_DE_INTENTO:		; Sin intentos que queden (E072 a cero) se va al estado 9; si quedan, al 5
	ld hl,0e072h		;418b   ; E072, los intentos que quedan
	ld a,(hl)			;418e
	dec hl			;418f
	dec hl			;4190
	and a			;4191
	jr nz,L_4198		;4192
	call MIRA_SI_SIGUE		;4194   ; Sin intentos, se mira si hay continuacion
	ret nz			;4197
L_4198:
	ld a,(0e072h)		;4198
	or a			;419b
	ld a,009h		;419c   ; Estado 9 si se acabaron los intentos...
	jr z,L_41A2		;419e
	ld a,005h		;41a0   ; ...y estado 5 si queda alguno
L_41A2:
	ld (0e000h),a		;41a2
	jr SUBESTADO_A_CERO		;41a5
ESTADO_08_FIN_DE_PRUEBA:		; Limpia los dos bits altos de E002, deja la prueba en 2 y vuelve al estado 0
	ld hl,0e002h		;41a7
	ld a,(hl)			;41aa
	and 03fh		;41ab   ; Se quedan los seis bits bajos de E002
	ld (hl),a			;41ad
	ld a,002h		;41ae
	ld (0e080h),a		;41b0   ; E080, la prueba en curso
	jp VUELVE_AL_ESTADO_0		;41b3
MIRA_SI_SIGUE:		; Con creditos y sin la otra bandera, gasta uno, pinta el rotulo y suena; si el sonido sigue, espera
	ld a,(hl)			;41b6
	and a			;41b7
	ret z			;41b8   ; Sin creditos no hay nada que decidir
	inc hl			;41b9
	ld a,(hl)			;41ba
	and a			;41bb
	jr nz,NO_SIGUE		;41bc
	ld de,0e082h		;41be
	ex de,hl			;41c1
	ld a,(hl)			;41c2
	dec a			;41c3
	jr z,ESPERA_AL_SONIDO		;41c4
	inc (hl)			;41c6
	ld de,047eah		;41c7   ; El rotulo de 0x47EA
	call PINTA_LISTA		;41ca
	ld a,0a2h		;41cd   ; Su sonido
	call SUENA_SI_SE_PUEDE		;41cf
	xor a			;41d2
	inc a			;41d3   ; Devuelve NZ: hay que seguir esperando
	ret			;41d4
ESPERA_AL_SONIDO:		; Hasta que el canal de E012 calle, no se apaga la bandera
	ld a,(0e012h)		;41d5   ; Mientras el canal de E012 suene, se espera
	and a			;41d8
	ret nz			;41d9
	dec de			;41da
	ld (de),a			;41db   ; Las dos banderas a cero
	ld (0e082h),a		;41dc
	ret			;41df
NO_SIGUE:		; Devuelve Z: no hay continuacion
	xor a			;41e0
	ret			;41e1
ESTADO_09_CAMBIA_DE_PRUEBA:		; Con E070 a cero se va al estado 8; si no, espera al sonido y pasa a la prueba siguiente
	ld a,(0e070h)		;41e2
	or a			;41e5
	ld a,008h		;41e6   ; Sin nada en E070, al estado 8
	jr z,L_4208		;41e8
	djnz ESTADO_09_SUB1		;41ea
	ld a,(0e012h)		;41ec   ; Con el canal sonando todavia, se espera
	and a			;41ef
	ret nz			;41f0
	ld hl,0e080h		;41f1
	ld a,(hl)			;41f4
	and 003h		;41f5   ; Los dos bits bajos de E080: la prueba, de 0 a 3
	cp 003h		;41f7   ; Pasada la tercera se mira el bit 2, y si no esta puesto se cambia de estado
	jr nz,L_4201		;41f9
	bit 2,(hl)		;41fb
	jp z,ESTADO_SIGUIENTE		;41fd
	inc (hl)			;4200
L_4201:
	ld a,0a5h		;4201   ; El sonido de cambio de prueba
	call SUENA_SI_SE_PUEDE		;4203
AL_ESTADO_4:		; E000 = 4: a montar la prueba
	ld a,004h		;4206   ; Estado 4: a montar la prueba
L_4208:
	jr L_41A2		;4208
ESTADO_09_SUB1:		; Sube la prueba (E080) y pasa al subestado siguiente
	ld hl,0e080h		;420a   ; E080, la prueba en curso
	inc (hl)			;420d
	jp SUBESTADO_SIGUIENTE		;420e
ESTADO_10:		; Un fotograma de 0x5469; cuando E081 avisa, al estado 4
	call FOTOGRAMA_DE_LA_TABLA_DE_RECORDS		;4211   ; Un fotograma de la tabla de records
	ld a,(0e081h)		;4214   ; Y E081 avisa de que ha terminado
	and a			;4217
	ret z			;4218
	jr AL_ESTADO_4		;4219
MONTA_LA_PANTALLA:		; Los graficos comunes: la fuente, el flujo de 0x4521, el color y el guion del titulo
	call PREPARA_LA_CORTINILLA		;421b   ; La cortinilla y los patrones comunes
	call CARGA_LOS_PATRONES		;421e
PINTA_EL_FONDO_DEL_TITULO:		; El flujo de 0x4521, el cian de 0x180 casillas de color y, detras, el guion del logotipo
	ld de,04521h		;4221   ; El flujo comprimido de 0x4521, con su direccion delante
	call DESCOMPRIME_CON_DIRECCION		;4224
	ld a,070h		;4227   ; 0x70 en 0x180 casillas de color: cyan sobre transparente
	ld hl,01600h		;4229
	ld bc,00180h		;422c
	call RELLENA_VRAM		;422f
GUION_DEL_TITULO:		; Recorre el guion de 0x4A2E: cada byte es una cuenta y, segun su bit 7, copia ocho bytes o rellena
	ld hl,04600h		;4232   ; La VRAM de destino la deja 0x445A
	ld de,04a2eh		;4235
	call PREPARA_ESCRITURA		;4238
L_423B:
	inc de			;423b
L_423C:
	ld a,(de)			;423c
	or a			;423d   ; El 0x00 acaba el guion
	jr z,GUION_FIN		;423e
	ld b,a			;4240
	inc de			;4241
L_4242:
	push bc			;4242
	bit 7,b		;4243   ; Bit 7 de la cuenta: relleno en vez de copia
	ld bc,00008h		;4245   ; Ocho bytes por vuelta: un tile entero
	jr nz,GUION_RELLENA		;4248
	call COPIA_A_VRAM_BUCLE		;424a
	pop bc			;424d
	dec b			;424e
	jr z,L_423C		;424f
	ld a,e			;4251   ; Y la VRAM retrocede ocho: las copias van hacia atras
	sub 008h		;4252
	ld e,a			;4254
	jr nc,L_4258		;4255
	dec d			;4257
L_4258:
	jr L_4242		;4258
GUION_RELLENA:		; Rellena ocho casillas con el mismo byte
	ld a,(de)			;425a
	call RELLENA_SIN_PREPARAR		;425b
	pop bc			;425e
	dec b			;425f
	ld a,b			;4260
	cp 080h		;4261   ; La cuenta se pasa de 0x80: se acabo este tramo
	jr z,L_423B		;4263
	jr L_4242		;4265
GUION_FIN:		; Y al acabar, el flujo comprimido de 0x4862
	ld de,04862h		;4267
	jp DESCOMPRIME_CON_DIRECCION		;426a
PREPARA_LA_PARTIDA:		; Carga los graficos, borra los 0x9C bytes de E063 y deja un intento
	call CARGA_LA_FUENTE		;426d
	ld hl,0e063h		;4270
	ld bc,0009ch		;4273   ; 0x9C bytes de E063 a cero, de un ldir que se copia a si mismo
	ld d,h			;4276
	ld e,l			;4277
	inc e			;4278
	ld (hl),000h		;4279
	ldir		;427b
	ld hl,00001h		;427d   ; E070 = 1 y E071 = 0
	ld (0e070h),hl		;4280
	ld a,l			;4283
	ld (0e072h),a		;4284   ; E072, los intentos que quedan
	ret			;4287
PINTA_EL_FONDO_DE_LA_PRUEBA:		; Descomprime en la tabla de nombres, desde la fila 8, el flujo que le toque a la prueba (los dos bits bajos de E080)
	ld a,(0e080h)		;4288
	and 003h		;428b   ; Los dos bits bajos: la prueba, de 0 a 3
	ld bc,00200h		;428d
	ld hl,042a0h		;4290   ; La tabla de tres palabras
	add a,a			;4293
	call HL_MAS_A		;4294
	ld e,(hl)			;4297
	inc hl			;4298
	ld d,(hl)			;4299
	ld hl,03900h		;429a   ; La tabla de nombres desde la fila 8; el bit de escritura lo pone SETWRT
	jp DESCOMPRIME_EN_HL		;429d

; ----------------------------------------------------------------------
; DATOS tabla_de_tres_palabras: Tres palabras que 0x4290 indexa por dos, y
;   cada una es la lista que pinta en la VRAM 0x3900
;   0x42a0..0x42a6  (6 bytes)
DATA_tabla_de_tres_palabras:
	defw 06c52h	; 42a0  -> DATA_flujo_6C52
	defw 064c5h	; 42a2  -> DATA_flujo_64C5
	defw 06d2bh	; 42a4  -> DATA_flujo_6D2B

; ======================================================================
; CODIGO 0x42a6..0x444b  (421 bytes)
; ======================================================================


APAGA_EL_PRIMER_SPRITE:		; Pone 0xD0 en la primera Y de la tabla de sprites: en el MSX eso apaga ese sprite y todos los que van detras
	ld hl,03b00h		;42a6
	ld a,0d0h		;42a9   ; 0xD0 en la Y: el VDP deja de dibujar desde ahi
	call VPOKE		;42ab
	xor a			;42ae
	ret			;42af

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS MARCADORES, EN BCD DE TRES BYTES. 0x42C0 compara dos numeros de
; tres bytes restandolos con `sbc` desde el byte bajo, y 0x42B0 usa
; esa comparacion para quedarse con el mayor: si el nuevo gana, un
; `lddr` lo copia encima. Sumar es 0x42F1, con `daa` detras de cada
; `adc` para que siga siendo BCD.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
GUARDA_SI_ES_MAYOR:		; Compara los tres bytes y, si el de DE gana, lo copia sobre el de HL y repinta
	ld b,003h		;42b0
	call COMPARA_N_BCD		;42b2
	ret c			;42b5   ; Con acarreo no gana: no se toca nada
	push af			;42b6
	lddr		;42b7   ; El lddr copia los tres bytes de una vez
	call PINTA_LOS_NUMEROS		;42b9
	pop af			;42bc
	ret			;42bd
COMPARA_TRES_BCD:		; Tres bytes; 0x42C0 entra con la longitud ya en B
	ld b,003h		;42be
COMPARA_N_BCD:		; Resta (DE) menos (HL) byte a byte con acarreo: el acarreo final dice quien gana
	ld c,b			;42c0
	xor a			;42c1   ; El xor a deja el acarreo limpio para el primer sbc
	ex de,hl			;42c2
L_42C3:
	ld a,(de)			;42c3   ; Byte a byte, restando con acarreo
	sbc a,(hl)			;42c4
	inc hl			;42c5
	inc de			;42c6
	djnz L_42C3		;42c7   ; B bytes
	ex de,hl			;42c9
	dec hl			;42ca
	dec de			;42cb
	ret nc			;42cc
	ld a,(de)			;42cd   ; Sin acarreo hay empate o gana DE; el add/ccf lo convierte en la respuesta
	add a,001h		;42ce
	ccf			;42d0
	ret			;42d1
COBRA_LOS_PUNTOS:		; Suma a los puntos lo que haya en E087
	ld de,0e087h		;42d2
SUMA_A_LOS_PUNTOS:		; Suma los tres bytes de DE a los de E063 y topa en 999999
	ld hl,0e063h		;42d5
	call SUMA_TRES_BCD		;42d8   ; Tres bytes en BCD
	dec hl			;42db
	dec hl			;42dc
	dec hl			;42dd
	ld de,0e060h		;42de
	jr nc,L_42EC		;42e1
	ld a,099h		;42e3   ; Al pasarse, los tres bytes se clavan en 0x99: 999999 es el tope
	ld (de),a			;42e5
	inc de			;42e6
	ld (de),a			;42e7
	inc de			;42e8
	ld (de),a			;42e9
	dec de			;42ea
	dec de			;42eb
L_42EC:
	call GUARDA_SI_ES_MAYOR		;42ec   ; Y con el record, por si hay que cambiarlo
	jr PINTA_LOS_NUMEROS		;42ef
SUMA_TRES_BCD:		; Tres bytes de DE sobre (HL), con daa: sigue siendo BCD
	ld b,003h		;42f1   ; Tres bytes
	xor a			;42f3
L_42F4:
	ld a,(de)			;42f4
	inc de			;42f5
	adc a,(hl)			;42f6
	daa			;42f7   ; El daa deja la suma en BCD
	ld (hl),a			;42f8
	inc hl			;42f9
	djnz L_42F4		;42fa
	ret			;42fc
PINTA_EL_MARCADOR:		; El fondo del marcador (flujo 0x4749), sus rotulos (lista 0x4712) y los numeros
	ld de,04749h		;42fd
	call DESCOMPRIME_CON_DIRECCION		;4300   ; El fondo del marcador
	ld de,04712h		;4303
	call PINTA_LISTA		;4306   ; Y encima sus rotulos
	call REPINTA_LOS_INTENTOS		;4309
	call PINTA_LAS_MARCAS		;430c
PINTA_LOS_NUMEROS:		; Los puntos en la fila 1 y el record en la fila 2, seis cifras cada uno
	ld de,0e062h		;430f   ; E062, el byte alto de los puntos
	ld hl,03827h		;4312   ; Fila 1, columna 7
	call PINTA_SEIS_CIFRAS		;4315
	ld hl,03847h		;4318   ; Fila 2, columna 7: el record
	ld de,0e065h		;431b
PINTA_SEIS_CIFRAS:		; Tres bytes en BCD, dos cifras por byte, del alto al bajo
	ld b,003h		;431e
PINTA_CIFRAS_SIN_CEROS:		; C a cero mientras haya que comerse los ceros de la izquierda
	ld c,000h		;4320
PINTA_LAS_CIFRAS_DE_DE:		; Las cifras BCD del numero de DE en la casilla HL, B bytes, con C decidiendo si los ceros de delante se pintan
	ld a,(de)			;4322
	rra			;4323   ; Cuatro rra: el nibble alto
	rra			;4324
	rra			;4325
	rra			;4326
	and 00fh		;4327
	jr z,L_432D		;4329   ; Mientras salgan ceros y C valga 0, no se pinta nada
	ld c,0ffh		;432b
L_432D:
	add a,010h		;432d   ; 0x10 es el tile del '0'
	and c			;432f
	call VPOKE		;4330
	inc hl			;4333
	djnz PINTA_LA_CIFRA_BAJA		;4334
	ld c,0ffh		;4336   ; La ultima cifra se pinta siempre, aunque sea un cero
PINTA_LA_CIFRA_BAJA:		; El nibble bajo del mismo byte
	inc b			;4338
	ld a,(de)			;4339
	and 00fh		;433a
	jr z,L_4340		;433c
	ld c,0ffh		;433e
L_4340:
	add a,010h		;4340   ; 0x10 es el tile del cero
	and c			;4342   ; Con C a cero, la cifra se apaga
	call VPOKE		;4343
	dec de			;4346
	inc hl			;4347
	djnz PINTA_LAS_CIFRAS_DE_DE		;4348
	ret			;434a
BORRA_LOS_INTENTOS:		; Los rotulos de intento, apagados
	ld c,000h		;434b
	jr L_435A		;434d
PARPADEA_EL_INTENTO:		; El rotulo del intento en curso, encendido o apagado segun el bit 4 del contador
	ld a,(0e003h)		;434f
	bit 4,a		;4352   ; Bit 4 del contador: 16 fotogramas si y 16 no
	ld c,000h		;4354
	jr nz,L_435A		;4356
	ld c,0ffh		;4358
L_435A:
	ld b,0a4h		;435a
	ld a,(0e072h)		;435c   ; E072, el intento en el que se esta
	ld hl,0387dh		;435f
	cpl			;4362
	and 003h		;4363   ; Los intentos van de abajo arriba: 3 menos el que queda
	ld d,a			;4365
BAJA_UNA_FILA:		; Suma 32 a HL: una fila de la tabla de nombres
	ld a,020h		;4366   ; Cada rotulo, una fila mas abajo (32 casillas)
	call HL_MAS_A		;4368   ; La fila de mas abajo
	dec d			;436b   ; D filas
	jr nz,BAJA_UNA_FILA		;436c
	call PINTA_O_BORRA		;436e
	ld b,0a2h		;4371   ; El tile 0xA2 en la fila 5, columna 6
	ld hl,038a6h		;4373
PINTA_O_BORRA:		; El tile de B, o el 0 si C lo apaga
	ld a,b			;4376
	and c			;4377
	jp VPOKE		;4378
MONTA_EL_TITULO:		; El guion del titulo y, detras, los rotulos de la pantalla
	call GUION_DEL_TITULO		;437b
PINTA_LOS_ROTULOS:		; Borra la pantalla y pinta las dos listas del titulo y las tres filas de 0x4791
	call BORRA_LA_PANTALLA		;437e
	ld de,0480ch		;4381   ; La lista de 0x480C
	call PINTA_LISTA		;4384
	ld de,047c1h		;4387   ; Y la de 0x47C1
	call PINTA_LISTA		;438a
	ld hl,03968h		;438d   ; Fila 11, columna 8
TRES_FILAS_DE_DIECISEIS:		; Tres filas de dieciseis tiles seguidos desde 0x4791, dos filas de separacion entre ellas
	ld b,003h		;4390
	ld de,04791h		;4392
L_4395:
	push bc			;4395
	ld c,010h		;4396   ; Dieciseis tiles por fila
	call COPIA_256		;4398
	ld a,040h		;439b   ; 0x40 son dos filas de la tabla de nombres
	call HL_MAS_A		;439d
	pop bc			;43a0
	djnz L_4395		;43a1
	ret			;43a3
RELLENA_256:		; Igual que 0x43B2 pero con B a cero: 256 casillas
	ld b,000h		;43a4
	jr RELLENA_VRAM		;43a6
BORRA_LA_PANTALLA:		; Apaga los sprites y deja las 768 casillas de la tabla de nombres a cero
	call APAGA_EL_PRIMER_SPRITE		;43a8
	ld hl,07800h		;43ab   ; VRAM 0x3800 con el bit de escritura
	ld bc,00300h		;43ae   ; Las 24 filas de 32
RELLENA_CON_CERO:		; Rellena BC casillas de la VRAM HL con ceros
	xor a			;43b1
RELLENA_VRAM:		; Rellena BC casillas de la VRAM HL con el valor de A
	call PREPARA_ESCRITURA		;43b2
RELLENA_SIN_PREPARAR:		; Rellena con el valor que ya viene en A, sin volver a mandar la direccion al VDP
	ex af,af'			;43b5   ; El valor viaja en el A alternativo para que los exx no lo pisen
L_43B6:
	ex af,af'			;43b6
	exx			;43b7
	out (c),a		;43b8   ; El puerto de datos del VDP viaja en el C alternativo
	exx			;43ba
	ex af,af'			;43bb
	dec bc			;43bc   ; Hasta agotar BC
	ld a,b			;43bd
	or c			;43be
	jr nz,L_43B6		;43bf
	ex af,af'			;43c1
	ret			;43c2
SIGUIENTE_BYTE_DEL_FLUJO:		; Coge el byte que toca del flujo y lo repite
	ld a,(de)			;43c3   ; El byte que se repite viene del flujo
	inc de			;43c4
	jr RELLENA_SIN_PREPARAR		;43c5
COPIA_256:		; Copia con B a cero: 256 bytes
	ld b,000h		;43c7
COPIA_A_VRAM:		; Copia BC bytes de DE a la VRAM HL
	call PREPARA_ESCRITURA		;43c9
COPIA_A_VRAM_BUCLE:		; El bucle, con la direccion ya puesta
	ld a,(de)			;43cc
	exx			;43cd
	out (c),a		;43ce   ; Byte a byte al puerto de datos
	exx			;43d0
	inc de			;43d1
	dec bc			;43d2   ; Y BC contando
	ld a,b			;43d3
	or c			;43d4
	jr nz,COPIA_A_VRAM_BUCLE		;43d5
	ret			;43d7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL FORMATO COMPRIMIDO. Un byte de cuenta manda: el 0x00 acaba, el
; 0x80 arranca otra direccion de VRAM (que viene en las dos siguientes),
; con el bit 7 puesto se copian n&0x7F bytes tal cual, y sin el se
; repite n veces el byte que sigue. Entrando por 0x43F5 el flujo trae
; su direccion delante; por 0x43FB, la direccion ya esta en HL.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CARGA_LA_FUENTE:		; Los patrones de 0x4523 en la VRAM 0x2200, su color, y los dos flujos de 0x466E y 0x46F5
	ld de,04523h		;43d8
	ld hl,02200h		;43db   ; VRAM 0x2200: los tiles 0x40 en adelante del primer tercio
	call DESCOMPRIME_EN_HL		;43de
	ld a,080h		;43e1   ; 0x80 en 0x180 casillas de color
	ld hl,00200h		;43e3
	ld bc,00180h		;43e6
	call RELLENA_VRAM		;43e9
	ld de,0466eh		;43ec
	call DESCOMPRIME_CON_DIRECCION		;43ef
	ld de,046f5h		;43f2
DESCOMPRIME_CON_DIRECCION:		; El flujo trae delante los dos bytes de la VRAM de destino
	ex de,hl			;43f5
	ld e,(hl)			;43f6   ; Los dos primeros bytes del flujo son la VRAM
	inc hl			;43f7
	ld d,(hl)			;43f8
	ex de,hl			;43f9
	inc de			;43fa
DESCOMPRIME_EN_HL:		; Descomprime el flujo de DE en la VRAM HL
	call PREPARA_ESCRITURA		;43fb
DESCOMPRIME_SIGUIENTE:		; Siguiente cuenta del flujo
	ld a,(de)			;43fe
	and 07fh		;43ff   ; Los siete bits bajos son la cuenta
	ld c,a			;4401
	ld a,(de)			;4402
	inc de			;4403
	jr nz,L_440A		;4404   ; Con la cuenta a cero solo quedan el 0x00 y el 0x80
	cp c			;4406   ; Iguales: era un 0x00 y se acabo. Distintos: era un 0x80, otra direccion
	jr nz,DESCOMPRIME_CON_DIRECCION		;4407
	ret			;4409
L_440A:
	ld b,000h		;440a
	cp c			;440c   ; El bit 7 decide: copia literal o relleno
	push af			;440d
	call nz,COPIA_A_VRAM_BUCLE		;440e
	pop af			;4411
	call z,SIGUIENTE_BYTE_DEL_FLUJO		;4412
	jr DESCOMPRIME_SIGUIENTE		;4415
RELLENA_TRES_TERCIOS:		; Lo mismo tres veces, subiendo 0x800: los tres tercios de la pantalla
	ld d,003h		;4417
L_4419:
	push bc			;4419
	push de			;441a
	call RELLENA_VRAM		;441b
	ld de,00800h		;441e   ; Un tercio son 0x800 bytes mas arriba
	add hl,de			;4421
	pop de			;4422
	pop bc			;4423   ; Los tres, o los dos
	dec d			;4424
	jr nz,L_4419		;4425
	ret			;4427
CARGA_LOS_PATRONES:		; El flujo de 0x4523 en los tres tercios y el de 0x444B en la tabla de color
	ld de,04523h		;4428   ; El flujo de la fuente
	ld hl,02080h		;442b   ; Los tiles 0x10 en adelante del primer tercio
	call DESCOMPRIME_TRES_TERCIOS		;442e
	ld hl,00080h		;4431   ; Y su color, que sale del flujo de 0x444B
	ld de,0444bh		;4434
DESCOMPRIME_TRES_TERCIOS:		; El mismo flujo en los tres tercios, subiendo 0x800 cada vez
	ld b,003h		;4437   ; Tres tercios
	jr L_443D		;4439
DESCOMPRIME_DOS_TERCIOS:		; Igual, pero solo en dos
	ld b,002h		;443b   ; O solo dos
L_443D:
	push bc			;443d
	push de			;443e
	call DESCOMPRIME_EN_HL		;443f
	ld de,00800h		;4442
	add hl,de			;4445   ; Otro tercio
	pop de			;4446
	pop bc			;4447
	djnz L_443D		;4448
	ret			;444a

; ----------------------------------------------------------------------
; DATOS colores_de_la_fuente: Flujo comprimido SIN direccion delante: los
;   colores de los tiles 0x10 a 0x3F, que 0x4434 mete en los tres tercios
;   desde la VRAM 0x0080
;   0x444b..0x445a  (15 bytes)
DATA_colores_de_la_fuente:
	defb 078h,0f0h,078h,0f0h,070h,0f0h,008h,060h,008h,040h,008h,0d0h,008h,0a0h,000h	; 444b  x.x.p..`.@.....

; ======================================================================
; CODIGO 0x445a..0x4487  (45 bytes)
; ======================================================================


PREPARA_ESCRITURA:		; Manda la direccion HL al VDP y deja el puerto de datos en el C alternativo
	ex af,af'			;445a
	call 00053h		;445b   ; BIOS SETWRT - Enables VDP to write | La BIOS sabe la direccion base de la VRAM
	exx			;445e
	ld a,(00006h)		;445f   ; 0x0006 guarda el puerto de datos del VDP de esta maquina: no se supone
	ld c,a			;4462
	exx			;4463
	ex af,af'			;4464
	ret			;4465
ARRANCA_EL_VDP_Y_LA_VRAM:		; Calla el PSG, espera a que pare el sonido, borra los 16 KB de VRAM y manda los ocho registros
	ld a,0b8h		;4466   ; 0xB8 en el registro 7 del PSG: los tres canales callados
	call ESCRIBE_LA_MEZCLA		;4468
	call SUENA_Y_ESPERA		;446b
	ld bc,04000h		;446e   ; 0x4000 bytes: la VRAM entera a cero
	ld e,c			;4471
	ld d,c			;4472
	call RELLENA_CON_CERO		;4473
MANDA_LOS_REGISTROS_DEL_VDP:		; Los ocho valores de 0x4487, uno por uno, con WRTVDP
	ld hl,04487h		;4476
	ld d,008h		;4479   ; Ocho registros, del 0 al 7
	ld c,000h		;447b
L_447D:
	ld b,(hl)			;447d
	call 00047h		;447e   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;4481
	inc c			;4482
	dec d			;4483
	jr nz,L_447D		;4484
	ret			;4486

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho valores que 0x4476 manda al VDP uno por
;   uno con WRTVDP: R0=02 SCREEN 2, R1=E2, R2=0E nombres en 0x3800, R3=7F
;   colores en 0x0000, R4=07 patrones en 0x2000, R5=76 atributos de sprite en
;   0x3B00, R6=03 patrones de sprite en 0x1800, R7=E1 borde negro
;   0x4487..0x448f  (8 bytes)
DATA_registros_del_vdp:
	defb 002h	; 4487
	defb 0e2h	; 4488
	defb 00eh	; 4489
	defb 07fh	; 448a
	defb 007h	; 448b
	defb 076h	; 448c
	defb 003h	; 448d
	defb 0e1h	; 448e

; ======================================================================
; CODIGO 0x448f..0x4521  (146 bytes)
; ======================================================================


LEE_EL_MANDO:		; Junta en B lo que diga el teclado y lo que diga el joystick del puerto 1
	call LEE_EL_TECLADO		;448f
	push af			;4492
	ld e,08fh		;4493   ; 0x8F en el registro 15: el puerto 1
	call LEE_EL_JOYSTICK		;4495
	ld b,a			;4498
	pop af			;4499
	or b			;449a
	ld b,a			;449b
	ret			;449c
LEE_EL_JOYSTICK:		; El registro 15 del PSG elige el puerto y el 14 lo lee; llega al reves y sin los dos bits altos
	ld a,00fh		;449d
	call 00093h		;449f   ; BIOS WRTPSG - Writes data to PSG-register | El 15 elige el puerto
	ld a,00eh		;44a2
	di			;44a4
	call 00096h		;44a5   ; BIOS RDPSG - Reads value from PSG-register | Y el 14 trae las cuatro flechas y los dos disparos
	ei			;44a8
	cpl			;44a9   ; Un cpl: en el PSG lo pulsado es un cero
	and 03fh		;44aa
	ret			;44ac
LEE_Y_APUNTA_EL_MANDO:		; Lee el mando y deja en E046, E047 y E048 lo pulsado, lo de antes y lo que acaba de pulsarse
	call LEE_EL_MANDO		;44ad
	ld hl,0e048h		;44b0
	call LO_RECIEN_PULSADO		;44b3
	ld a,b			;44b6
LO_RECIEN_PULSADO:		; Guarda lo de ahora y lo de antes, y con un xor y un and deja solo los bits que acaban de bajar
	ld c,(hl)			;44b7
	ld (hl),a			;44b8
	xor c			;44b9   ; Lo que ha cambiado
	and (hl)			;44ba   ; Y de eso, lo que esta puesto: lo recien pulsado
	dec hl			;44bb
	ld (hl),c			;44bc
	dec hl			;44bd
	ld (hl),a			;44be
	dec hl			;44bf
	ret			;44c0
LEE_EL_TECLADO:		; Las filas 7 y 8 del teclado, corridas hasta caer en los mismos bits que el joystick
	ld a,007h		;44c1
	call 00141h		;44c3   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | Fila 7: la flecha de arriba
	cpl			;44c6   ; Un cpl: en el teclado lo pulsado tambien es un cero
	rrca			;44c7
	and 020h		;44c8
	ld e,a			;44ca
	ld a,008h		;44cb
	call 00141h		;44cd   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | Fila 8: las otras tres flechas y el espacio
	cpl			;44d0
	rrca			;44d1
	rrca			;44d2
	ld b,a			;44d3
	and 004h		;44d4
	or e			;44d6
	ld c,a			;44d7
	ld a,b			;44d8
	rrca			;44d9   ; Otras dos vueltas: los dos disparos
	rrca			;44da
	ld b,a			;44db
	and 018h		;44dc   ; Los dos bits de las flechas de abajo
	or c			;44de
	ld c,a			;44df
	ld a,b			;44e0
	rrca			;44e1   ; Y el ultimo, el de la derecha
	and 003h		;44e2
	or c			;44e4
	ret			;44e5
EL_MANDO_DEL_TITULO:		; Lee mando y teclado y, si acaba de pulsarse algo, arranca la partida o se lleva al estado 3
	ld e,08fh		;44e6   ; El joystick del puerto 1
	call LEE_EL_JOYSTICK		;44e8
	ld d,a			;44eb
	call LEE_EL_TECLADO		;44ec   ; Y encima, el teclado
	or d			;44ef
	ld hl,0e040h		;44f0   ; E040 lo de ahora y E041 lo de antes
	ld c,(hl)			;44f3
	ld (hl),a			;44f4
	inc hl			;44f5
	ld (hl),c			;44f6
	ld b,a			;44f7
	xor c			;44f8   ; Y de ahi, lo recien pulsado
	and b			;44f9
	ret z			;44fa
	ld b,a			;44fb
	xor a			;44fc
	ld (0e004h),a		;44fd
	inc a			;4500
	ld hl,0e000h		;4501
	cp (hl)			;4504   ; Solo cuando el estado es 1
	jr nz,L_4517		;4505
	ld a,b			;4507
	cp 010h		;4508   ; Por debajo del 0x10 no vale: hace falta el disparo
	ret c			;450a
	ld a,040h		;450b
	ld (0e002h),a		;450d   ; 0x40 en E002: queda abierto el sonido
	ld hl,00003h		;4510   ; Estado 3 y submodo a cero
	ld (0e000h),hl		;4513
	ret			;4516
L_4517:
	ld (hl),a			;4517
	call SUENA_Y_ESPERA		;4518
	call PINTA_EL_FONDO_DEL_TITULO		;451b
	jp L_4152		;451e

; ----------------------------------------------------------------------
; DATOS flujo_4521: Flujo comprimido con su direccion de VRAM delante: 384
;   bytes de VRAM
;   0x4521..0x466e  (333 bytes)
DATA_flujo_4521:
	defb 000h,076h,08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h	; 4521  .v..."ccc"...8..
	defb 0d1h,07eh,000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h	; 4531  .~.>c..<p..>c...
	defb 063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h	; 4541  c>...6ff....`~c.
	defb 063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h	; 4551  c>.>c`~cc>..c...
	defb 018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h	; 4561  ...>cc>cc>.>cc?.
	defb 063h,03eh,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,000h,000h,018h,018h,000h,000h	; 4571  c><B....B<......
	defb 018h,018h,010h,000h,090h,000h,000h,000h,026h,02ch,038h,028h,02eh,000h,000h,000h	; 4581  ........&,8(....
	defb 070h,080h,0b8h,088h,070h,004h,000h,001h,07eh,004h,000h,0c1h,01ch,036h,063h,063h	; 4591  p...p...~....6cc
	defb 07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h,03eh,063h,060h,060h	; 45a1  .cc.~cc~cc~.>c``
	defb 060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch,000h,07fh,060h,060h,07eh	; 45b1  `c>.|fcccf|..``~
	defb 060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h,03eh,063h,060h,067h	; 45c1  ``...``~```.>c`g
	defb 063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h,000h,03ch,005h,018h,081h	; 45d1  cc?.ccc.ccc.<...
	defb 03ch,009h,000h,088h,063h,066h,06ch,078h,07ch,06eh,067h,000h,006h,060h,093h,07fh	; 45e1  <...cflx|ng..`..
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,073h,07bh,07fh,06fh,067h,063h	; 45f1  .cw..kcc.cs{.ogc
	defb 000h,03eh,005h,063h,0a3h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h,000h,03eh	; 4601  .>.c.>.~ccc~``.>
	defb 063h,063h,063h,06fh,066h,03dh,000h,07eh,063h,063h,062h,07ch,066h,063h,000h,03eh	; 4611  cccof=.~ccb|fc.>
	defb 063h,060h,03eh,003h,063h,03eh,000h,07eh,006h,018h,001h,000h,006h,063h,082h,03eh	; 4621  c`>.c>.~.....c.>
	defb 000h,004h,063h,08bh,036h,01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h,022h,009h	; 4631  ..c.6...cckk.w".
	defb 000h,087h,066h,066h,07eh,03ch,018h,018h,018h,010h,000h,0a0h,000h,000h,000h,054h	; 4641  ..ff~<.........T
	defb 038h,07ch,038h,054h,000h,000h,000h,054h,038h,07ch,038h,054h,000h,000h,000h,054h	; 4651  8|8T...T8|8T...T
	defb 038h,07ch,038h,054h,000h,000h,000h,054h,038h,07ch,038h,054h,000h	; 4661  8|8T...T8|8T.

; ----------------------------------------------------------------------
; DATOS rle_466E: Flujo comprimido con su direccion de VRAM delante: 368 bytes
;   de VRAM
;   0x466e..0x46f5  (135 bytes)
DATA_rle_466E:
	defb 0b8h,023h,098h,000h,000h,002h,037h,042h,032h,00ah,073h,000h,001h,001h,063h,055h	; 466e  .#....7B2.s...cU
	defb 055h,055h,053h,000h,001h,001h,053h,065h,045h,045h,043h,030h,000h,003h,000h,003h	; 467e  UUS...SeEEC0....
	defb 0ffh,005h,000h,085h,003h,007h,00fh,01eh,01ch,003h,000h,085h,0e0h,0f0h,0f8h,03ch	; 468e  ...............<
	defb 01ch,00ah,01ch,08eh,01eh,00fh,007h,003h,000h,000h,01ch,01ch,03ch,0f8h,0f0h,0e0h	; 469e  ............<...
	defb 000h,000h,030h,000h,088h,0f0h,0f0h,0f8h,0fch,07fh,03fh,00fh,003h,004h,000h,004h	; 46ae  ..0.......?.....
	defb 0ffh,088h,00fh,00fh,01fh,03fh,0feh,0fch,0f0h,0c0h,008h,0f0h,008h,00fh,040h,000h	; 46be  .....?........@.
	defb 038h,000h,098h,000h,03ch,066h,0c3h,0c3h,0c3h,066h,03ch,082h,0c6h,06ch,038h,038h	; 46ce  8...<f...f<..l88
	defb 06ch,0c6h,082h,008h,00ch,07eh,07fh,07fh,07eh,00ch,008h,008h,000h,088h,010h,030h	; 46de  l....~..~......0
	defb 07eh,0feh,0feh,07eh,030h,010h,000h	; 46ee

; ----------------------------------------------------------------------
; DATOS rle_46F5: Flujo comprimido con su direccion de VRAM delante: 368 bytes
;   de VRAM
;   0x46f5..0x4712  (29 bytes)
DATA_rle_46F5:
	defb 0b8h,003h,048h,0f0h,060h,070h,004h,08ah,004h,080h,002h,000h,002h,00ah,004h,080h	; 46f5  ..H.`p..........
	defb 004h,08ah,004h,080h,010h,08ah,078h,000h,018h,080h,010h,0f0h,000h	; 4705  ......x......

; ----------------------------------------------------------------------
; DATOS lista_4712: Los rotulos fijos del marcador: HI, YOU, SCORE, WORLD
;   RECORD y QUALIFY. Descifrada con tools/textos.py (el numero de tile no es
;   el ASCII): «HI / YOU /  ....SCORE......WORLD RECORD... / QUALIFY»
;   0x4712..0x4749  (55 bytes)
DATA_lista_4712:
	defb 023h,038h,028h,029h,0feh,043h,038h,069h,05fh,065h,0feh,000h,038h,000h,08fh,081h	; 4712  #8().C8i_e..8...
	defb 080h,080h,063h,053h,05fh,062h,055h,080h,080h,080h,082h,081h,080h,067h,05fh,062h	; 4722  ..cS_bU......g_b
	defb 05ch,054h,000h,062h,055h,053h,05fh,062h,054h,080h,082h,090h,0feh,070h,038h,061h	; 4732  \T.bUS_bT....p8a
	defb 065h,051h,05ch,059h,056h,069h,0ffh	; 4742

; ----------------------------------------------------------------------
; DATOS rle_4749: Flujo comprimido con su direccion de VRAM delante: 224 bytes
;   de VRAM
;   0x4749..0x4791  (72 bytes)
DATA_rle_4749:
	defb 020h,038h,083h,000h,08fh,083h,00ah,000h,082h,083h,083h,00eh,000h,086h,083h,090h	; 4749   8..............
	defb 000h,000h,08fh,083h,00ah,000h,082h,083h,084h,00eh,080h,086h,085h,090h,000h,000h	; 4759  ................
	defb 08fh,084h,00ah,080h,081h,085h,010h,000h,084h,090h,000h,000h,08fh,01ch,000h,084h	; 4769  ................
	defb 090h,000h,000h,08fh,01ch,000h,084h,090h,000h,000h,08fh,01ch,000h,084h,090h,000h	; 4779  ................
	defb 000h,08ch,01ch,08dh,082h,08eh,000h,000h	; 4789  ........

; ----------------------------------------------------------------------
; DATOS nombres_de_las_pruebas: Tres filas de dieciseis tiles que 0x4392 sube
;   tal cual a la VRAM, dos filas de separacion entre ellas: SKEET SHOOTING,
;   ARCHERY y WEIGHT LIFTING. Descifradas con tools/textos.py (el numero de
;   tile no es el ASCII)
;   0x4791..0x47c1  (48 bytes)
DATA_nombres_de_las_pruebas:
	defb 03ch,000h,033h,02bh,025h,025h,034h,000h,033h,028h,02fh,02fh,034h,029h,02eh,027h	; 4791  <.3+%%4.3(//4).'
	defb 03ch,000h,021h,032h,023h,028h,025h,032h,039h,000h,000h,000h,000h,000h,000h,000h	; 47a1  <.!2#(%29.......
	defb 03ch,000h,037h,025h,029h,027h,028h,034h,000h,02ch,029h,026h,034h,029h,02eh,027h	; 47b1  <.7%)'(4.,)&4).'

; ----------------------------------------------------------------------
; DATOS lista_47C1: La otra mitad del titulo, esta si en formato lista para
;   PINTA_LISTA: PUSH SPACE KEY TO START y KONAMI 1984
;   0x47c1..0x47ea  (41 bytes)
DATA_lista_47C1:
	defb 064h,03ah,0e0h,0e5h,0e3h,0d8h,000h,0e3h,0e0h,0d1h,0d3h,0d5h,000h,0dbh,0d5h,0e9h	; 47c1  d:..............
	defb 000h,0e4h,0dfh,000h,0e3h,0e4h,0d1h,0e2h,0e4h,0feh,00ah,039h,01ah,02bh,02fh,02eh	; 47d1  ...........9.+/.
	defb 021h,02dh,029h,000h,011h,019h,018h,014h,0ffh	; 47e1  !-)......

; ----------------------------------------------------------------------
; DATOS lista_47EA: GAME OVER. Descifrada con tools/textos.py (el numero de
;   tile no es el ASCII): «GAME OVER»
;   0x47ea..0x47f6  (12 bytes)
DATA_lista_47EA:
	defb 08ch,039h,027h,021h,02dh,025h,000h,02fh,036h,025h,032h,0ffh	; 47ea  .9'!-%./6%2.

; ----------------------------------------------------------------------
; DATOS lista_47F6: El rotulo VIDEO CARTRIDGE del arranque. Descifrada con
;   tools/textos.py (el numero de tile no es el ASCII): «. VIDEO CARTRIDGE .»
;   0x47f6..0x480c  (22 bytes)
DATA_lista_47F6:
	defb 066h,039h,020h,000h,036h,029h,024h,025h,02fh,000h,023h,021h,032h,034h,032h,029h	; 47f6  f9 .6)$%/.#!242)
	defb 024h,027h,025h,000h,020h,0ffh	; 4806

; ----------------------------------------------------------------------
; DATOS lista_480C: El logotipo HYPER SPORTS 2, que son tiles y no letras:
;   cinco filas de codigos de tile con sus saltos de casilla. Descifrada con
;   tools/textos.py (el numero de tile no es el ASCII): «01 / 25.....ABCD. /
;   26EFGHIJKLMN. / 24OPQRSTUVWX... / 24YZ............ / 34789 / ..»
;   0x480c..0x4862  (86 bytes)
DATA_lista_480C:
	defb 02ch,038h,0c0h,0c1h,0feh,04bh,038h,0c2h,0c5h,0cch,0cdh,0ceh,0cfh,0d0h,0d1h,0d2h	; 480c  ,8...K8.........
	defb 0d3h,0d4h,0f4h,0feh,06ah,038h,0c2h,0c6h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch	; 481c  ....j8..........
	defb 0ddh,0deh,0f5h,0feh,089h,038h,0c2h,0c4h,0dfh,0e0h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h	; 482c  .....8..........
	defb 0e7h,0e8h,0f6h,0f8h,0f9h,0feh,0a8h,038h,0c2h,0c4h,0e9h,0eah,0ebh,0ech,0edh,0eeh	; 483c  .......8........
	defb 0efh,0f0h,0f1h,0f2h,0f3h,0f7h,0fah,0fbh,0feh,0c8h,038h,0c3h,0c4h,0c7h,0c8h,0c9h	; 484c  ..........8.....
	defb 0feh,0e9h,038h,0cah,0cbh,0ffh	; 485c

; ----------------------------------------------------------------------
; DATOS flujo_del_titulo: Flujo comprimido con su direccion de VRAM delante,
;   481 bytes de VRAM: lo suelta 0x4267 con un `jp` al descompresor
;   0x4862..0x4a2f  (461 bytes)
DATA_flujo_del_titulo:
	defb 000h,066h,005h,000h,09bh,001h,003h,007h,000h,010h,020h,060h,0c0h,0c0h,080h,080h	; 4862  .f........ `....
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,003h,001h	; 4872  .....?....?.....
	defb 008h,0ffh,086h,00fh,01fh,03eh,07eh,0fch,0fch,008h,0ffh,002h,0fdh,002h,0f0h,006h	; 4882  .....>~.........
	defb 0ffh,002h,000h,003h,0ffh,082h,0f8h,0c0h,003h,000h,082h,0feh,0e0h,004h,000h,084h	; 4892  ................
	defb 0ffh,07fh,03eh,018h,004h,000h,082h,0f8h,0c0h,006h,000h,002h,01fh,003h,03fh,0abh	; 48a2  ..>...........?.
	defb 07eh,0feh,0feh,0bfh,0bfh,01fh,01fh,00fh,00fh,00fh,007h,00fh,01fh,0bfh,0feh,0fch	; 48b2  ~...............
	defb 0f8h,0f0h,0e0h,0dfh,09fh,03fh,03eh,03eh,07ch,07ch,07fh,0feh,0ffh,0ffh,00fh,00fh	; 48c2  .....?>>||......
	defb 01fh,01fh,0feh,01fh,01fh,0bfh,0bfh,03eh,07eh,07fh,07fh,003h,0ffh,003h,000h,09ch	; 48d2  .......>~.......
	defb 0feh,0fch,0bfh,03fh,07fh,07ch,07ch,0f8h,0f8h,0fbh,0fch,0feh,0ffh,01fh,01eh,03eh	; 48e2  ...?.||........>
	defb 03eh,0fch,0ffh,0f0h,0e0h,0e1h,0c1h,0c3h,083h,087h,0fch,0fch,003h,0f8h,003h,0f0h	; 48f2  >...............
	defb 081h,007h,003h,00fh,003h,01fh,083h,03fh,0c0h,0c0h,003h,081h,086h,003h,003h,007h	; 4902  .......?........
	defb 0ffh,0ffh,0f8h,003h,0f0h,084h,0e0h,0e0h,0feh,0fch,003h,001h,088h,003h,003h,007h	; 4912  ................
	defb 0ffh,0fch,0fch,0f8h,0f8h,003h,0ffh,082h,0fdh,001h,003h,003h,09dh,0f7h,0e7h,0efh	; 4922  ................
	defb 0f3h,0f7h,0f7h,0e3h,0e1h,0e0h,0c0h,0c0h,0fch,0f8h,0e0h,0f0h,0f8h,0fch,07eh,03fh	; 4932  ..............~?
	defb 0f8h,0f8h,0f3h,0f7h,0e7h,0c7h,0cfh,08fh,000h,000h,003h,0ffh,082h,08fh,080h,003h	; 4942  ................
	defb 000h,093h,01fh,09fh,0bfh,03ch,03ch,078h,000h,000h,0f0h,0f9h,0fdh,03dh,03bh,07bh	; 4952  .....<<x.....=;{
	defb 000h,000h,07fh,0ffh,0ffh,003h,0c7h,0a2h,000h,000h,08fh,0cfh,0dfh,0deh,09eh,0bch	; 4962  ................
	defb 000h,000h,0f8h,0fch,0feh,01eh,01ch,03ch,000h,000h,07fh,07fh,0ffh,00fh,00fh,01fh	; 4972  .......<........
	defb 000h,000h,0fdh,0fbh,0fbh,083h,007h,007h,000h,000h,003h,0ffh,083h,0c7h,0c0h,080h	; 4982  ................
	defb 003h,0ffh,09ah,0feh,0feh,0fch,0f8h,0f8h,09fh,00fh,000h,000h,03ch,03fh,07fh,03fh	; 4992  ............<?.?
	defb 0fch,0feh,03eh,03ch,07ch,0f9h,0f9h,0f3h,07fh,07fh,0ffh,0f0h,0f0h,003h,0e0h,083h	; 49a2  ..><|...........
	defb 0f3h,0f7h,0e7h,003h,00fh,082h,007h,003h,003h,08fh,08ah,01eh,01eh,0feh,0fch,0f8h	; 49b2  ................
	defb 03dh,03dh,07bh,07bh,079h,003h,0f0h,08ah,0f8h,0f8h,0f0h,0c0h,0e0h,0f0h,078h,03ch	; 49c2  =={{y.........x<
	defb 01eh,01eh,003h,03ch,0a1h,07ch,078h,0f8h,00fh,007h,000h,000h,01eh,01fh,03fh,01fh	; 49d2  ...<.|x.......?.
	defb 0feh,0ffh,01fh,03eh,03eh,0fch,0fch,0f8h,000h,0feh,000h,000h,0fch,000h,000h,0f8h	; 49e2  ...>>...........
	defb 000h,000h,0e0h,000h,000h,0f0h,004h,000h,0aeh,080h,0c0h,0c0h,080h,0feh,000h,000h	; 49f2  ................
	defb 0f8h,000h,000h,0f0h,000h,000h,0ffh,003h,007h,00fh,00fh,01fh,01fh,000h,000h,0fch	; 4a02  ................
	defb 0feh,0ffh,09fh,01fh,01fh,03eh,07eh,001h,003h,00fh,01fh,03fh,03fh,07fh,07fh,0fch	; 4a12  .....>~....??...
	defb 0f0h,0e0h,080h,000h,0fch,0f8h,0f8h,080h,0c0h,047h,081h,0a4h,000h	; 4a22  .........G...

; ----------------------------------------------------------------------
; DATOS guion_del_titulo: El guion que 0x423C recorre byte a byte: una cuenta
;   y, segun su bit 7, copia ocho bytes o los rellena; el 0x00 del final lo
;   cierra. Es lo que va montando la pantalla del titulo detras del flujo
;   comprimido de 0x4862
;   0x4a2f..0x4a65  (54 bytes)
DATA_guion_del_titulo:
	defb 08ch,0f0h,009h,0f0h,0f4h,0f0h,0f0h,0f4h	; 4a2f  ........
	defb 0f0h,0f0h,0f4h,00ah,0f0h,0f0h,0f4h,0f0h	; 4a37  ........
	defb 0f0h,0f4h,0f0h,0f0h,00ah,0f4h,0f0h,0f0h	; 4a3f  ........
	defb 0f6h,0f0h,0f0h,0f6h,0f0h,00bh,0f0h,0f6h	; 4a47  ........
	defb 0f0h,0f0h,0f6h,0f0h,0f0h,0f6h,082h,040h	; 4a4f  .......@
	defb 001h,004h,0f0h,0f0h,0f6h,0f0h,0f0h,060h	; 4a57  .......`
	defb 0f0h,081h,060h,084h,0a0h,000h	; 4a5f

; ======================================================================
; CODIGO 0x4a65..0x4ab5  (80 bytes)
; ======================================================================


PREPARA_LA_CORTINILLA:		; Deja 17 pasos en E00D y el cursor de la cortinilla en la fila 21, y carga los tiles del logotipo
	ld a,011h		;4a65   ; Diecisiete filas por subir
	ld (0e00dh),a		;4a67
	ld hl,03aaah		;4a6a   ; Fila 21, columna 10: por donde empieza
	ld (0e00eh),hl		;4a6d
	ld de,04ab5h		;4a70
	ld hl,06300h		;4a73
	call DESCOMPRIME_TRES_TERCIOS		;4a76
	ld hl,00300h		;4a79   ; Blanco sobre transparente en 0xD0 casillas de color de los tres tercios
	ld bc,000d0h		;4a7c
	ld a,0f0h		;4a7f
	jp RELLENA_TRES_TERCIOS		;4a81
SUBE_EL_LOGOTIPO:		; Una fila mas arriba por llamada: pinta las tres tiras del logotipo y borra el rastro
	ld hl,(0e00eh)		;4a84   ; El cursor sube 32 casillas: una fila
	ld de,0ffe0h		;4a87
	add hl,de			;4a8a
	ld (0e00eh),hl		;4a8b
	ld a,060h		;4a8e   ; Tres tiles arriba, doce en medio y doce abajo
	ld b,003h		;4a90
	call TIRA_DE_TILES		;4a92
	ld bc,00b0ch		;4a95
	call TIRA_DE_TILES		;4a98
	ld b,c			;4a9b
	call TIRA_DE_TILES		;4a9c
	call RELLENA_CON_CERO		;4a9f   ; Y doce ceros debajo, que borran lo que dejo la vuelta anterior
	ld hl,0e00dh		;4aa2
	dec (hl)			;4aa5   ; E00D cuenta las diecisiete filas; al llegar a cero, se acabo
	ret			;4aa6
TIRA_DE_TILES:		; B tiles consecutivos desde A, y luego baja una fila
	push hl			;4aa7
L_4AA8:
	call VPOKE		;4aa8   ; El codigo de tile sube con la columna
	inc hl			;4aab
	inc a			;4aac
	djnz L_4AA8		;4aad
	pop de			;4aaf
	ld hl,00020h		;4ab0   ; Treinta y dos: la fila de debajo, para la llamada siguiente
	add hl,de			;4ab3
	ret			;4ab4

; ----------------------------------------------------------------------
; DATOS tiles_del_logotipo: Flujo comprimido SIN direccion delante: los tiles
;   con los que se dibuja el logotipo HYPER SPORTS 2, que 0x4A70 mete en los
;   TRES tercios desde la VRAM 0x2300
;   0x4ab5..0x4b48  (147 bytes)
DATA_tiles_del_logotipo:
	defb 00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,090h,01fh	; 4ab5  ...........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,005h	; 4ac5  ?............>>.
	defb 000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch	; 4ad5  ..............x.
	defb 0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h	; 4ae5  ....?...........
	defb 0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h	; 4af5  ......x..`..`...
	defb 0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh	; 4b05  .??.>.....?...>>
	defb 03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh	; 4b15  >~..............
	defb 00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,008h,0e7h,008h,08fh	; 4b25  ......?.........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4b35  .............h.(
	defb 010h,0e0h,000h	; 4b45

; ======================================================================
; CODIGO 0x4b48..0x4b80  (56 bytes)
; ======================================================================


MONTA_LA_PRUEBA:		; Borra la RAM del juego, deja tres intentos y llama a lo que monta la prueba que toque
	call CARGA_LOS_TRES_FLUJOS		;4b48
	ld hl,0e081h		;4b4b
	ld de,0e082h		;4b4e
	ld bc,0017eh		;4b51   ; 0x17E bytes desde E081 a cero, de un ldir que se copia a si mismo
	xor a			;4b54
	ld (hl),a			;4b55
	ldir		;4b56
	ld hl,0e090h		;4b58
	ld de,0e091h		;4b5b
	ld bc,00017h		;4b5e   ; Y 0x18 bytes desde E090 a 0xFF
	dec a			;4b61
	ld (hl),a			;4b62
	ldir		;4b63
	ld (0e073h),a		;4b65
	ld a,(0e070h)		;4b68
	and a			;4b6b
	ld a,003h		;4b6c   ; Tres intentos, salvo que E070 este a cero: entonces dos
	jr nz,L_4B71		;4b6e
	dec a			;4b70
L_4B71:
	ld (0e072h),a		;4b71
	xor a			;4b74
	ld (0e071h),a		;4b75
	ld a,(0e080h)		;4b78
	and 003h		;4b7b   ; Los dos bits bajos de E080: la prueba, y su tabla detras
	call DESPACHA		;4b7d

; ----------------------------------------------------------------------
; DATOS tabla_de_4B80: Las 3 palabras del despacho de 0x4B7D, pegadas detras
;   de su call: 0x4C61 0x4CA0 0x4C74. Cierra clavada contra su destino mas
;   bajo hacia delante
;   0x4b80..0x4b86  (6 bytes)
DATA_tabla_de_4B80:
	defw 04c61h	; 4b80  -> PREPARA_MARCADOR_SKEET
	defw 04ca0h	; 4b82  -> PREPARA_MARCADOR_ARCHERY
	defw 04c74h	; 4b84  -> PREPARA_MARCADOR_WEIGHT

; ======================================================================
; CODIGO 0x4b86..0x4bb1  (43 bytes)
; ======================================================================


PREPARA_EL_INTENTO:		; Pone a cero los puntos del intento y la RAM de 0xE100, y llama a lo que arranca la prueba
	xor a			;4b86
	ld (0e08dh),a		;4b87
	ld hl,0e087h		;4b8a   ; Los tres bytes de los puntos de este intento
	ld (hl),a			;4b8d
	inc hl			;4b8e
	ld (hl),a			;4b8f
	inc hl			;4b90
	ld (hl),a			;4b91
	ld (0e08ah),a		;4b92
	ld hl,0e100h		;4b95
	ld de,0e101h		;4b98
	ld (hl),a			;4b9b
	ld bc,00100h		;4b9c   ; 0x100 bytes de E100 a cero
	ldir		;4b9f
	ld hl,0e07dh		;4ba1
	ld (hl),a			;4ba4
	inc hl			;4ba5
	ld a,004h		;4ba6   ; E07E = 4
	ld (hl),a			;4ba8
	ld a,(0e080h)		;4ba9
	and 003h		;4bac   ; Otra vez la prueba, con su tabla propia
	call DESPACHA		;4bae

; ----------------------------------------------------------------------
; DATOS tabla_de_4BB1: Las 3 palabras del despacho de 0x4BAE, pegadas detras
;   de su call: 0x4BB7 0x4C25 0x4BFB. Cierra clavada contra su destino mas
;   bajo hacia delante
;   0x4bb1..0x4bb7  (6 bytes)
DATA_tabla_de_4BB1:
	defw 04bb7h	; 4bb1  -> ARRANCA_SKEET
	defw 04c25h	; 4bb3  -> ARRANCA_ARCHERY
	defw 04bfbh	; 4bb5  -> ARRANCA_WEIGHT

; ======================================================================
; CODIGO 0x4bb7..0x4bf3  (60 bytes)
; ======================================================================


ARRANCA_SKEET:		; La primera prueba: deja la ventana en E142, el ritmo en E1A6 y las dos fichas de sprite
	ld a,00eh		;4bb7
	ld (0e160h),a		;4bb9
	ld a,(0e080h)		;4bbc
	cp 01ch		;4bbf   ; Por encima de 0x1C se clava en 0x18
	jr c,L_4BC5		;4bc1
	ld a,018h		;4bc3
L_4BC5:
	add a,a			;4bc5   ; Por ocho y quedandose los tres bits altos
	add a,a			;4bc6   ; Por cuatro y sin los bits bajos
	add a,a			;4bc7
	and 0e0h		;4bc8
	ld hl,001c0h		;4bca   ; Y sumado a 0x01C0: la velocidad de partida
	call HL_MAS_A		;4bcd
	ld (0e142h),hl		;4bd0
	ld a,015h		;4bd3   ; E1A6 a 0x15
	ld (0e1a6h),a		;4bd5
	ld a,002h		;4bd8   ; Y E172 a dos
	ld (0e172h),a		;4bda
	ld b,040h		;4bdd   ; Los 0x40 bytes de fichas de sprite a 0xE0, que las aparca
	ld hl,0e0c0h		;4bdf
APARCA_LAS_FICHAS:		; Deja 0xE0 en los 0x40 bytes de fichas
	ld (hl),0e0h		;4be2   ; 0xE0 en las Y: las fichas se van de la pantalla
	inc hl			;4be4
	djnz APARCA_LAS_FICHAS		;4be5
	ld hl,04bf3h		;4be7
	ld de,0e0c0h		;4bea
	ld bc,00008h		;4bed   ; Ocho bytes: dos fichas
	ldir		;4bf0
	ret			;4bf2

; ----------------------------------------------------------------------
; DATOS ocho_a_e0c0: Los ocho bytes que 0x4BE7 copia con un ldir a 0xE0C0: dos
;   fichas de sprite
;   0x4bf3..0x4bfb  (8 bytes)
DATA_ocho_a_e0c0:
	defb 090h,090h,004h,006h	; 4bf3
	defb 090h,060h,004h,006h	; 4bf7

; ======================================================================
; CODIGO 0x4bfb..0x4c3d  (66 bytes)
; ======================================================================


ARRANCA_WEIGHT:		; La tercera: pone el ritmo, la barra en E120 y los valores de arranque
	xor a			;4bfb
	ld (0e004h),a		;4bfc
	ld a,030h		;4bff
	ld (0e1a6h),a		;4c01   ; 0x30 de ritmo: mas lento que el skeet
	ld a,(0e075h)		;4c04
	ld (0e110h),a		;4c07
	ld hl,005ffh		;4c0a   ; E120 y E121, con 0x05FF
	ld (0e120h),hl		;4c0d   ; E120 y E121, el reloj de la prueba
	ld a,020h		;4c10
	ld (0e122h),a		;4c12
	ld a,017h		;4c15   ; E107 arranca en 0x17
	ld (0e107h),a		;4c17
	ld a,002h		;4c1a
	ld (0e104h),a		;4c1c   ; E104, el patron de partida
	ld a,0f2h		;4c1f   ; E089, la marca a batir
	ld (0e089h),a		;4c21
	ret			;4c24
ARRANCA_ARCHERY:		; La segunda: las ocho fichas de sprite de 0x4C3D y los valores de la flecha
	ld hl,04c3dh		;4c25   ; Las ocho fichas de sprite de 0x4C3D
	ld de,0e0c0h		;4c28
	ld bc,00020h		;4c2b   ; 0x20 bytes: ocho fichas
	ldir		;4c2e
	ld a,003h		;4c30
	ld (0e145h),a		;4c32   ; E145 = 3
	ld a,007h		;4c35
	ld (0e111h),a		;4c37   ; E111 = 7
	jp ARRANCA_LA_CEREMONIA		;4c3a

; ----------------------------------------------------------------------
; DATOS treinta_y_dos_a_e0c0: Los 0x20 bytes que 0x4C25 copia con un ldir a
;   0xE0C0: ocho fichas de sprite
;   0x4c3d..0x4c5d  (32 bytes)
DATA_treinta_y_dos_a_e0c0:
	defb 0c0h,010h,010h,001h	; 4c3d
	defb 028h,0e8h,004h,006h	; 4c41
	defb 028h,0e8h,000h,004h	; 4c45
	defb 038h,0e8h,020h,006h	; 4c49
	defb 038h,0e8h,01ch,004h	; 4c4d
	defb 048h,0e8h,014h,004h	; 4c51
	defb 048h,0e8h,014h,004h	; 4c55
	defb 073h,01bh,00ch,00fh	; 4c59

; ----------------------------------------------------------------------
; DATOS cuatro_detras_de_las_fichas: Los cuatro bytes que quedan detras de las
;   ocho fichas de sprite de 0x4C3D (F1 F2 F2 F2). El ldir de 0x4C25 no los
;   alcanza -copia 0x20- y ninguna instruccion los apunta
;   0x4c5d..0x4c61  (4 bytes)
DATA_cuatro_detras_de_las_fichas:
	defb 0f1h,0f2h,0f2h,0f2h	; 4c5d

; ======================================================================
; CODIGO 0x4c61..0x4c6e  (13 bytes)
; ======================================================================


PREPARA_MARCADOR_SKEET:		; Coge el liston de la tabla de 0x4C6E y apunta E08B a E059
	ld hl,04c6eh		;4c61
	call LISTON_POR_VUELTA		;4c64
	ld hl,0e059h		;4c67
	ld (0e08bh),hl		;4c6a
	ret			;4c6d

; ----------------------------------------------------------------------
; DATOS dificultad_del_weight: Seis bytes que 0x4CAD indexa con (0xE080)
;   desplazado dos bits y topado en 5: 0x20, 0x30, 0x35, 0x40, 0x42, 0x45.
;   Suben con la vuelta, asi que es el liston que hay que levantar
;   0x4c6e..0x4c74  (6 bytes)
DATA_dificultad_del_weight:
	defb 020h,030h,035h	; 4c6e
	defb 040h,042h,045h	; 4c71

; ======================================================================
; CODIGO 0x4c74..0x4cc2  (78 bytes)
; ======================================================================


PREPARA_MARCADOR_WEIGHT:		; El peso de partida sale de la tabla de 0x6F48, indexada por la vuelta
	ld a,(0e080h)		;4c74
	rra			;4c77   ; E080 desplazado dos bits: la vuelta, no la prueba
	rra			;4c78
	and 03fh		;4c79
	cp 008h		;4c7b   ; Por encima de la octava vuelta se clava en la septima
	jr c,L_4C81		;4c7d
	ld a,007h		;4c7f
L_4C81:
	and 007h		;4c81
	ld (0e075h),a		;4c83
	ld hl,06f48h		;4c86   ; La tabla de pesos, por dos porque son palabras
	add a,a			;4c89
	call HL_MAS_A		;4c8a
	ld e,(hl)			;4c8d
	inc hl			;4c8e
	ld d,(hl)			;4c8f
	ld hl,0e084h		;4c90
	ld (hl),e			;4c93
	inc hl			;4c94
	ld (hl),d			;4c95
	inc hl			;4c96
	ld (hl),0f2h		;4c97   ; 0xF2 en el tercer byte
	ld hl,0e053h		;4c99
	ld (0e08bh),hl		;4c9c
	ret			;4c9f
PREPARA_MARCADOR_ARCHERY:		; Apunta E08B a E056 y coge su liston de la tabla de 0x4CC2
	xor a			;4ca0
	ld (0e205h),a		;4ca1
	ld hl,0e056h		;4ca4
	ld (0e08bh),hl		;4ca7
	ld hl,04cc2h		;4caa
LISTON_POR_VUELTA:		; Saca de la tabla de HL el liston de esta vuelta y lo deja en E085
	ld a,(0e080h)		;4cad
	rra			;4cb0   ; Otra vez la vuelta: E080 sin los dos bits de la prueba
	rra			;4cb1
	and 03fh		;4cb2
	cp 005h		;4cb4   ; De la sexta en adelante, el liston ya no sube
	jr c,L_4CBA		;4cb6
	ld a,005h		;4cb8
L_4CBA:
	call HL_MAS_A		;4cba
	ld a,(hl)			;4cbd
	ld (0e085h),a		;4cbe
	ret			;4cc1

; ----------------------------------------------------------------------
; DATOS dificultad_del_archery: Los seis de la otra prueba, con el mismo
;   indice: 0x25, 0x28, 0x32, 0x35, 0x38, 0x40
;   0x4cc2..0x4cc8  (6 bytes)
DATA_dificultad_del_archery:
	defb 025h,028h,032h	; 4cc2
	defb 035h,038h,040h	; 4cc5

; ======================================================================
; CODIGO 0x4cc8..0x4cd0  (8 bytes)
; ======================================================================


UN_FOTOGRAMA_DE_LA_PRUEBA:		; Despacha al fotograma de la prueba que toque, por los dos bits bajos de E080
	ld a,(0e080h)		;4cc8
	and 003h		;4ccb
	call DESPACHA		;4ccd

; ----------------------------------------------------------------------
; DATOS tabla_de_4CD0: Las 3 palabras del despacho de 0x4CCD, pegadas detras
;   de su call: 0x4EBA 0x528D 0x5147. Cierra clavada contra su destino mas
;   bajo hacia delante
;   0x4cd0..0x4cd6  (6 bytes)
DATA_tabla_de_4CD0:
	defw 04ebah	; 4cd0  -> FOTOGRAMA_DEL_SKEET
	defw 0528dh	; 4cd2  -> FOTOGRAMA_DEL_ARCHERY
	defw 05147h	; 4cd4  -> FOTOGRAMA_DEL_WEIGHT

; ======================================================================
; CODIGO 0x4cd6..0x4cfb  (37 bytes)
; ======================================================================


PINTA_LA_MARCA:		; Pinta el numero de DE; por encima de 0xA0 son dos cifras y una unidad de dos tiles
	ld a,(de)			;4cd6
	ld b,003h		;4cd7
	cp 0a0h		;4cd9   ; Por debajo de 0xA0 van las tres cifras de siempre
	jp c,PINTA_CIFRAS_SIN_CEROS		;4cdb
	dec de			;4cde
	cp 0ffh		;4cdf   ; 0xFF: no hay marca que pintar
	jr z,L_4CF2		;4ce1
	dec b			;4ce3
	call PINTA_CIFRAS_SIN_CEROS		;4ce4
	ld a,01eh		;4ce7   ; Los tiles 0x1E y 0x1F: la unidad que va detras del numero
	call VPOKE		;4ce9
	inc hl			;4cec
	ld a,01fh		;4ced
	jp VPOKE		;4cef
L_4CF2:
	dec de			;4cf2
	dec de			;4cf3
	ret			;4cf4
REPINTA_LOS_INTENTOS:		; La lista de 0x4CFB: YOU y los tres intentos
	ld de,04cfbh		;4cf5
	jp PINTA_LISTA		;4cf8

; ----------------------------------------------------------------------
; DATOS lista_4CFB: YOU y los tres intentos, que es lo que se repinta al
;   cambiar de intento. Descifrada con tools/textos.py (el numero de tile no
;   es el ASCII): «YOU / 1.TRY / 2.TRY / 3.TRY»
;   0x4cfb..0x4d19  (30 bytes)
DATA_lista_4CFB:
	defb 0a3h,038h,039h,02fh,035h,0feh,091h,038h,011h,077h,034h,032h,039h,0feh,0b1h,038h	; 4cfb  .89/5..8.w429..8
	defb 012h,078h,034h,032h,039h,0feh,0d1h,038h,013h,079h,034h,032h,039h,0ffh	; 4d0b  .x429..8.y429.

; ======================================================================
; CODIGO 0x4d19..0x4d94  (123 bytes)
; ======================================================================


PINTA_LAS_MARCAS:		; El liston de la prueba, la marca de la vuelta y la del intento
	ld hl,03833h		;4d19   ; Fila 1, columna 19
	ld a,(0e080h)		;4d1c
	and 003h		;4d1f
	ld b,a			;4d21
	add a,a			;4d22   ; Por tres y en negativo: cada prueba tiene su liston tres bytes mas abajo de E05B
	add a,b			;4d23
	neg		;4d24
	ld de,0e05bh		;4d26
	add a,e			;4d29
	ld e,a			;4d2a
	call PINTA_LA_MARCA		;4d2b
	ld hl,03877h		;4d2e   ; Fila 3, columna 23: la marca de la vuelta
	ld de,0e086h		;4d31   ; La marca de E086
	call PINTA_LA_MARCA		;4d34
PINTA_LA_MARCA_DEL_INTENTO:		; La de E092, en la fila 5, y el rotulo de la vuelta
	ld hl,038a7h		;4d37   ; Fila 5, columna 7
	ld de,0e092h		;4d3a
	call PINTA_LA_MARCA		;4d3d
	call PINTA_EL_AVISO		;4d40
PINTA_LOS_TRES_INTENTOS:		; Las tres marcas de E09E, una por fila
	ld hl,03897h		;4d43   ; Fila 4, columna 23
	ld de,0e09eh		;4d46
	ld b,003h		;4d49   ; Tres intentos
L_4D4B:
	push bc			;4d4b
	push hl			;4d4c
	call PINTA_LA_MARCA		;4d4d
	pop hl			;4d50
	ld a,020h		;4d51   ; Treinta y dos: la fila de abajo
	add a,l			;4d53
	ld l,a			;4d54
	pop bc			;4d55
	djnz L_4D4B		;4d56
	ret			;4d58
ESPERA_O_REPINTA:		; Mientras E08A este puesto, hace parpadear las marcas; si no, espera al sonido y suena el aviso
	ld hl,0e08ah		;4d59
	ld a,(hl)			;4d5c
	and a			;4d5d
	jr z,AVISA_Y_ESPERA		;4d5e   ; Con E08A a cero se pasa a la espera de abajo
	ld a,(0e08dh)		;4d60
	and a			;4d63
	jr z,L_4D76		;4d64
	ld a,(0e003h)		;4d66
	bit 4,a		;4d69   ; Bit 4 del contador: 16 fotogramas con las marcas y 16 sin
	push af			;4d6b
	call nz,PINTA_LAS_MARCAS		;4d6c
	ld de,04d94h		;4d6f
	pop af			;4d72
	call z,DESCOMPRIME_CON_DIRECCION		;4d73
L_4D76:
	ld a,(0e012h)		;4d76   ; Y con el canal callado, se repintan
	and a			;4d79
	push af			;4d7a
	call z,PINTA_LAS_MARCAS		;4d7b
	pop af			;4d7e
	ret			;4d7f
AVISA_Y_ESPERA:		; Cuando el sonido de fondo calla, sube E08A y suena el aviso de fin
	ld a,(0e036h)		;4d80
	and a			;4d83   ; E036: mientras el sonido siga, nada
	ret nz			;4d84
	inc (hl)			;4d85
	ld a,(0e08dh)		;4d86
	and a			;4d89
	jr z,L_4D92		;4d8a
	ld a,09fh		;4d8c   ; El sonido 0x9F, el de terminar
	call SUENA_SI_SE_PUEDE		;4d8e
	xor a			;4d91
L_4D92:
	inc a			;4d92
	ret			;4d93

; ----------------------------------------------------------------------
; DATOS rle_4D94: Flujo comprimido con su direccion de VRAM delante: 7 bytes
;   de VRAM
;   0x4d94..0x4d99  (5 bytes)
DATA_rle_4D94:
	defb 033h,038h,007h,000h,000h	; 4d94

; ======================================================================
; CODIGO 0x4d99..0x4dfe  (101 bytes)
; ======================================================================


GUARDA_LA_MARCA_DEL_INTENTO:		; Copia los tres bytes de los puntos al hueco del intento que toca (tres por intento)
	ld de,0e096h		;4d99
	ld a,(0e072h)		;4d9c
	ld b,a			;4d9f   ; Por tres: cada intento ocupa tres bytes
	add a,a			;4da0   ; Por tres: tres bytes por registro
	add a,b			;4da1
	call DE_MAS_A		;4da2
	ld hl,0e087h		;4da5   ; Los puntos del intento
	ld bc,00003h		;4da8
	ldir		;4dab
	ret			;4dad
PINTA_EL_AVISO:		; El tile 0xA0 o 0xA1 en la fila 5 segun lo que valga E073
	ld hl,0e073h		;4dae   ; E073, la bandera del aviso
	call TILE_DEL_AVISO		;4db1
	ld a,b			;4db4
	ld hl,038aeh		;4db5   ; Fila 5, columna 14
	jp VPOKE		;4db8
TILE_DEL_AVISO:		; 0xA1 con E073 a cero, 0xA0 con uno, y nada con mas
	ld b,000h		;4dbb
	ld a,(hl)			;4dbd   ; Con la prueba 0, el sonido 0xA1
	or a			;4dbe
	jr nz,L_4DC4		;4dbf
	ld b,0a1h		;4dc1
	ret			;4dc3
L_4DC4:
	dec a			;4dc4   ; Y con la 1, el 0xA0
	ret nz			;4dc5
	ld b,0a0h		;4dc6
	ret			;4dc8
COPIA_E071_A_E073:		; Lo que haya en E071 pasa a E073
	ld a,(0e071h)		;4dc9
	ld (0e073h),a		;4dcc
	ret			;4dcf
CAMBIA_DE_PRUEBA:		; Borra la pantalla, sube la prueba dando la vuelta a las tres, y monta la siguiente entera
	call BORRA_LA_PANTALLA		;4dd0
	ld hl,0e080h		;4dd3
	ld a,(hl)			;4dd6
	inc a			;4dd7   ; Tres pruebas: de la 2 se vuelve a la 0
	cp 003h		;4dd8
	jr nz,L_4DDD		;4dda
	xor a			;4ddc
L_4DDD:
	ld (hl),a			;4ddd
	ld hl,0e08eh		;4dde   ; E08E y E08F a cero
	xor a			;4de1
	ld (hl),a			;4de2
	inc hl			;4de3
	ld (hl),a			;4de4
	call CARGA_LA_FUENTE		;4de5   ; La fuente, la prueba, el intento, el marcador y el fondo
	call MONTA_LA_PRUEBA		;4de8
	call PREPARA_EL_INTENTO		;4deb
	call PINTA_EL_MARCADOR		;4dee
	jp PINTA_EL_FONDO_DE_LA_PRUEBA		;4df1
FOTOGRAMA_CON_VUELTA:		; Empuja 0x4CC8 y despacha por la prueba: al volver, corre el fotograma de la prueba
	ld hl,04cc8h		;4df4
	push hl			;4df7
	ld a,(0e080h)		;4df8
	call DESPACHA		;4dfb

; ----------------------------------------------------------------------
; DATOS tabla_de_4DFE: Las 3 palabras del despacho de 0x4DFB, pegadas detras
;   de su call: 0x4E04 0x4E30 0x4EA3. Cierra clavada contra su destino mas
;   bajo hacia delante
;   0x4dfe..0x4e04  (6 bytes)
DATA_tabla_de_4DFE:
	defw 04e04h	; 4dfe  -> SKEET_ENTRE_INTENTOS
	defw 04e30h	; 4e00  -> ARCHERY_ENTRE_INTENTOS
	defw 04ea3h	; 4e02  -> WEIGHT_ENTRE_INTENTOS

; ======================================================================
; CODIGO 0x4e04..0x4e6d  (105 bytes)
; ======================================================================


SKEET_ENTRE_INTENTOS:		; Con E171 por debajo de 0x14, mueve los dos platos y ajusta la ficha segun E1AA
	ld a,001h		;4e04
	ld (0e1abh),a		;4e06   ; E1AB a uno: mientras dure, los disparos solo se apuntan
	ld a,(0e171h)		;4e09   ; E171, por donde va la tanda
	cp 014h		;4e0c   ; Pasado 0x14 no queda plato que mover
	jr nc,L_4E2B		;4e0e
	call DISPARA_ARRIBA		;4e10
	ld hl,0e043h		;4e13
	ld a,(0e1aah)		;4e16
	and a			;4e19
	jr z,L_4E1E		;4e1a
	ld (hl),010h		;4e1c
L_4E1E:
	push hl			;4e1e   ; Y el canon de abajo
	call DISPARA_ABAJO		;4e1f
	pop hl			;4e22
	ld a,(0e1aah)		;4e23   ; E1AA: si le ha dado, el mando se falsea
	and a			;4e26
	jr z,L_4E2B		;4e27
	ld (hl),008h		;4e29
L_4E2B:
	xor a			;4e2b   ; E1AB otra vez a cero
	ld (0e1abh),a		;4e2c
	ret			;4e2f
ARCHERY_ENTRE_INTENTOS:		; Baja E08F y, mientras quede, mueve la diana con la tabla de 0x4E6D
	ld hl,0e08fh		;4e30   ; E08F, lo que le queda a la diana en esa postura
	ld a,(hl)			;4e33
	and a			;4e34
	jr z,ARCHERY_SIGUIENTE_DIANA		;4e35
	dec (hl)			;4e37
	call ARCHERY_ALTURA_DE_LA_DIANA		;4e38   ; El patron que le toca
	ld b,a			;4e3b
	ld a,(hl)			;4e3c
	and a			;4e3d
	ld a,b			;4e3e
	jr nz,L_4E43		;4e3f
	xor 010h		;4e41   ; Sin nada en E08F, el patron cambia con un xor: la diana se da la vuelta
L_4E43:
	ld (0e045h),a		;4e43   ; El patron se deja en E045
	ret			;4e46
ARCHERY_SIGUIENTE_DIANA:		; Coge de la tabla de 0x4E6D lo que dura la diana siguiente y avanza el indice
	ld de,04e6dh		;4e47
	ld a,(0e08eh)		;4e4a   ; E08E, por que diana va
	call DE_MAS_A		;4e4d
	ld a,(de)			;4e50
	ld (0e08fh),a		;4e51   ; E08F: los fotogramas que aguanta
	call ARCHERY_ALTURA_DE_LA_DIANA		;4e54
	ld hl,0e08eh		;4e57
	inc (hl)			;4e5a
	ret			;4e5b
ARCHERY_ALTURA_DE_LA_DIANA:		; De la otra tabla, con el mismo indice, sale el patron que se queda en E043 y E044
	ld de,04e88h		;4e5c   ; La tabla de patrones, con el mismo indice
	ld a,(0e08eh)		;4e5f
	call DE_MAS_A		;4e62
	ld a,(de)			;4e65
	ld (0e043h),a		;4e66   ; El mismo patron en E043 y E044
	ld (0e044h),a		;4e69
	ret			;4e6c

; ----------------------------------------------------------------------
; DATOS tabla_de_4E47: Los bytes que 0x4E47 indexa con (0xE08E) para dejar
;   (0xE08F)
;   0x4e6d..0x4e88  (27 bytes)
DATA_tabla_de_4E47:
	defb 050h,002h,005h,090h,012h,01ah,0f0h,010h,012h	; 4e6d  P........
	defb 0f0h,015h,002h,0f0h,010h,018h,0f0h,017h,004h	; 4e76  .........
	defb 0f0h,012h,005h,0f0h,010h,004h,0f0h,012h,004h	; 4e7f  .........

; ----------------------------------------------------------------------
; DATOS tabla_de_4E5C: La segunda, que indexa 0x4E5C con el mismo formato
;   0x4e88..0x4ea3  (27 bytes)
DATA_tabla_de_4E5C:
	defb 000h,000h,010h,000h,000h,010h,000h,000h,010h	; 4e88  .........
	defb 000h,000h,010h,000h,000h,010h,000h,000h,010h	; 4e91  .........
	defb 000h,000h,010h,000h,000h,010h,000h,000h,010h	; 4e9a  .........

; ======================================================================
; CODIGO 0x4ea3..0x4ec4  (33 bytes)
; ======================================================================


WEIGHT_ENTRE_INTENTOS:		; Baja E08F y, segun su bit alto, refresca cada 4 u 8 fotogramas
	ld hl,0e08fh		;4ea3
	dec (hl)			;4ea6
	ld a,(hl)			;4ea7
	add a,a			;4ea8   ; El bit alto de lo que queda elige el ritmo
	ld c,007h		;4ea9
	jr c,L_4EAF		;4eab
	ld c,003h		;4ead
L_4EAF:
	ld a,(0e003h)		;4eaf
	and c			;4eb2   ; Uno de cada cuatro fotogramas, o de cada ocho
	ret nz			;4eb3
	ld a,018h		;4eb4
	ld (0e043h),a		;4eb6
	ret			;4eb9
FOTOGRAMA_DEL_SKEET:		; Empuja 0x4F87 y despacha por E1A1: los siete pasos de la prueba de tiro al plato
	ld hl,04f87h		;4eba
	ld a,(0e1a1h)		;4ebd
	push hl			;4ec0
	call DESPACHA		;4ec1

; ----------------------------------------------------------------------
; DATOS tabla_de_4EC4: Las 7 palabras del despacho de 0x4EC1, pegadas detras
;   de su call: 0x4ED2 0x4EF3 0x4EFA 0x4FD6 0x4FEA 0x501A 0x50DC. Cierra
;   clavada contra su destino mas bajo hacia delante
;   0x4ec4..0x4ed2  (14 bytes)
DATA_tabla_de_4EC4:
	defw 04ed2h	; 4ec4  -> SKEET_PASO_0
	defw 04ef3h	; 4ec6  -> SKEET_PASO_1
	defw 04efah	; 4ec8  -> SKEET_PASO_2_EN_JUEGO
	defw 04fd6h	; 4eca  -> SKEET_PASO_3_GUARDA
	defw 04feah	; 4ecc  -> SKEET_PASO_4_LISTON
	defw 0501ah	; 4ece  -> SKEET_PASO_5_FIN
	defw 050dch	; 4ed0  -> ACABA_LA_PRUEBA

; ======================================================================
; CODIGO 0x4ed2..0x5054  (386 bytes)
; ======================================================================


SKEET_PASO_0:		; Espera a que calle el sonido, deja el cursor en la fila 22 y suena el aviso de empezar
	ld a,(0e036h)		;4ed2   ; E036: mientras suene algo, no se arranca
	and a			;4ed5
	ret nz			;4ed6
	ld hl,03ab5h		;4ed7   ; Fila 22, columna 21
	ld (0e1a7h),hl		;4eda
	call PINTA_EL_RELOJ		;4edd
	ld a,099h		;4ee0   ; El sonido 0x99: preparados
	call SUENA_SI_SE_PUEDE		;4ee2
ESPERA_128:		; E004 = 128 fotogramas y al paso siguiente
	ld a,080h		;4ee5   ; 0x80 fotogramas, que son mas de dos segundos
	ld (0e004h),a		;4ee7
PASO_SIGUIENTE_DEL_SKEET:		; E1A9 a cero y sube E1A1
	xor a			;4eea
	ld (0e1a9h),a		;4eeb   ; E1A9 a cero: los sprites se refrescan
	ld hl,0e1a1h		;4eee   ; E1A1 es el paso de la prueba
	inc (hl)			;4ef1
	ret			;4ef2
SKEET_PASO_1:		; Espera a que se agote E004
	ld hl,0e004h		;4ef3   ; E004, lo que queda de espera
	dec (hl)			;4ef6
	ret nz			;4ef7
	jr PASO_SIGUIENTE_DEL_SKEET		;4ef8
SKEET_PASO_2_EN_JUEGO:		; El fotograma gordo: los platos, la escopeta, los disparos, los impactos y el marcador
	call GASTA_EL_TIEMPO		;4efa   ; El reloj, los platos y la escopeta
	call LANZA_UN_PLATO		;4efd
	call MUEVE_LOS_PLATOS		;4f00
	call CAEN_LOS_PLATOS		;4f03
	call SACUDE_EL_PRIMER_PLATO		;4f06
	call APUNTA_LA_ESCOPETA		;4f09
	ld hl,0e170h		;4f0c   ; E170 es lo que queda de la tanda
	ld a,(hl)			;4f0f
	and a			;4f10
	jr z,L_4F25		;4f11
	dec (hl)			;4f13
	ld a,002h		;4f14
	ld (0e172h),a		;4f16   ; E172 = 2
	ld a,(0e043h)		;4f19
	and 018h		;4f1c   ; Bits 3-4 de los mandos: con el gatillo, el sonido del disparo
	ld a,08ch		;4f1e
	call nz,SUENA_SI_SE_PUEDE		;4f20
	or 001h		;4f23
L_4F25:
	push af			;4f25
	call CUENTA_ATRAS_DEL_DISPARO		;4f26
	pop af			;4f29
	call z,DISPARA		;4f2a
	call GUARDA_LA_MARCA_DEL_INTENTO		;4f2d   ; La marca del intento y sus tres numeros
	call PINTA_LOS_TRES_INTENTOS		;4f30
	ld a,(0e172h)		;4f33
	and a			;4f36
	jr nz,L_4F3E		;4f37
	ld a,018h		;4f39   ; Con E172 a cero se rearma la tanda: 0x18 platos
	ld (0e170h),a		;4f3b
L_4F3E:
	call MIRA_LOS_IMPACTOS		;4f3e
	call MUEVE_LOS_PERDIGONES		;4f41
	ld hl,0e1a6h		;4f44   ; Mientras E1A5 o E1A6 no esten a cero, no se mira el final
	ld a,(hl)			;4f47
	dec hl			;4f48
	or (hl)			;4f49
	ret nz			;4f4a
	ld hl,0e100h		;4f4b   ; Los tres platos de E100, de 0x10 en 0x10: si alguno sigue vivo, no se acaba
	ld de,00010h		;4f4e
	ld b,003h		;4f51
	xor a			;4f53
L_4F54:
	or (hl)			;4f54
	add hl,de			;4f55
	djnz L_4F54		;4f56
	ret nz			;4f58
	ld a,(0e199h)		;4f59   ; E199 marca el desempate
	and a			;4f5c
	jr nz,L_4F6D		;4f5d
	ld hl,0e19ah		;4f5f
	ld a,(hl)			;4f62
	inc (hl)			;4f63   ; La primera vez lleva a 0x761A y la segunda a 0x762F
	and a			;4f64
	jp z,COPIA_LOS_NUEVE_BYTES		;4f65
	cp 001h		;4f68
	jp z,REARRANCA_LAS_TIRAS		;4f6a
L_4F6D:
	ld a,(0e151h)		;4f6d   ; E151: mientras haya algo en marcha, se espera
	and a			;4f70
	ret nz			;4f71
	ld hl,0e074h		;4f72
	ld a,(0e199h)		;4f75
	and a			;4f78
	jr nz,L_4F84		;4f79
	ld a,(hl)			;4f7b
	inc a			;4f7c
	cp 007h		;4f7d   ; La dificultad sube hasta siete y ahi se queda
	jr c,L_4F83		;4f7f
	ld a,007h		;4f81
L_4F83:
	ld (hl),a			;4f83
L_4F84:
	jp PASO_SIGUIENTE_DEL_SKEET		;4f84
DETRAS_DEL_PASO:		; Lo que corre despues de cada paso de la prueba: los sprites a la VRAM y el corte de la tabla
	call PINTA_LA_ESCOPETA		;4f87
	call COLOCA_LOS_TRES_PLATOS		;4f8a
	call GASTA_LOS_NUMEROS		;4f8d
	ld de,0e0c0h		;4f90   ; Los 0x30 bytes de fichas de E0C0 a la tabla de sprites
	ld hl,03b00h		;4f93
	ld c,030h		;4f96
	push bc			;4f98
	call COPIA_256		;4f99
	pop bc			;4f9c
	add hl,bc			;4f9d
	ld a,0d0h		;4f9e   ; Y 0xD0 en la Y de la siguiente: el VDP deja de dibujar ahi
	jp VPOKE		;4fa0
GASTA_EL_TIEMPO:		; Resta 1,67 al reloj de E1A4 en BCD; al llegar a negativo lo clava en cero
	ld hl,0e1a4h		;4fa3
	ld a,(hl)			;4fa6
	sub 067h		;4fa7   ; 0x67 al byte bajo y 1 al de arriba: 1,67 por fotograma, o sea un segundo cada 60
	daa			;4fa9   ; El daa: el reloj va en BCD
	ld (hl),a			;4faa
	inc hl			;4fab
	ld a,(hl)			;4fac
	sbc a,001h		;4fad   ; Y los otros dos bytes con el acarreo
	daa			;4faf
	ld (hl),a			;4fb0
	inc hl			;4fb1
	ld a,(hl)			;4fb2
	sbc a,000h		;4fb3
	daa			;4fb5
	ld (hl),a			;4fb6
	jp p,PINTA_EL_RELOJ		;4fb7   ; En negativo, el reloj se queda a cero
	xor a			;4fba
	ld (hl),a			;4fbb
	dec hl			;4fbc
	ld (hl),a			;4fbd
PINTA_EL_RELOJ:		; Los minutos, el tile 0x1B de separador y los segundos
	ld b,001h		;4fbe
	ld de,0e1a6h		;4fc0
	ld hl,(0e1a7h)		;4fc3
	call PINTA_CIFRAS_SIN_CEROS		;4fc6
	ld a,01bh		;4fc9   ; El tile 0x1B: los dos puntos del reloj
	call VPOKE		;4fcb
	inc hl			;4fce
	ld b,001h		;4fcf
	ld c,0ffh		;4fd1   ; C a 0xFF: los ceros de los segundos SI se pintan
	jp PINTA_LAS_CIFRAS_DE_DE		;4fd3
SKEET_PASO_3_GUARDA:		; Se queda con la mejor marca de este intento, en el hueco del jugador que toca
	ld de,0e090h		;4fd6
	ld a,(0e002h)		;4fd9   ; El bit 7 de E002 dice si juega el segundo
	add a,a			;4fdc
	jr nc,L_4FE1		;4fdd
	ld e,093h		;4fdf
L_4FE1:
	ld hl,0e087h		;4fe1
	call GUARDA_SI_ES_MAYOR		;4fe4
	jp PASO_SIGUIENTE_DEL_SKEET		;4fe7
SKEET_PASO_4_LISTON:		; Compara la marca con el liston: si llega, deja E071 a uno
	ld hl,0e087h		;4fea
	ld de,0e084h		;4fed
	call COMPARA_TRES_BCD		;4ff0
	ld a,000h		;4ff3
	jr c,L_4FFD		;4ff5   ; Con acarreo no llega al liston
	ld hl,0e071h		;4ff7
	ld a,001h		;4ffa
	ld (hl),a			;4ffc
L_4FFD:
	ld (0e1a3h),a		;4ffd
GUARDA_Y_PINTA:		; Pasa E071 a E073, repinta y mira si es record
	call COPIA_E071_A_E073		;5000
	call PINTA_LA_MARCA_DEL_INTENTO		;5003
	ld hl,0e087h		;5006
	ld de,(0e08bh)		;5009
	call GUARDA_SI_ES_MAYOR		;500d   ; Contra el record del marcador (E08B)
	jr c,L_5017		;5010
	ld a,001h		;5012   ; E08D a uno: hay record nuevo
	ld (0e08dh),a		;5014
L_5017:
	jp PASO_SIGUIENTE_DEL_SKEET		;5017
SKEET_PASO_5_FIN:		; Suena lo que toque -aviso o fanfarria- y espera; luego, el remate de la prueba
	ld a,(0e1a2h)		;501a
	and a			;501d
	jr nz,SKEET_PASO_5_ESPERA		;501e
	call ESPERA_O_REPINTA		;5020
	ret nz			;5023
	ld a,(0e1a3h)		;5024
	and a			;5027   ; E1A3 dice si ha calificado
	push af			;5028
	ld a,001h		;5029
	jr nz,L_502F		;502b
	ld a,0a8h		;502d   ; El sonido 0xA8 si ha calificado, el 0x01 si no
L_502F:
	call SUENA_SI_SE_PUEDE		;502f
	pop af			;5032
	ld a,0c0h		;5033   ; Y la espera: 0xC0 fotogramas o ninguno
	jr z,L_5038		;5035
	xor a			;5037
L_5038:
	ld (0e004h),a		;5038
	ld hl,0e1a2h		;503b
	inc (hl)			;503e
	ret			;503f
SKEET_PASO_5_ESPERA:		; Mientras E004 baja, cada prueba hace lo suyo
	call REMATE_DE_LA_PRUEBA		;5040
	ret nz			;5043
	jp PASO_SIGUIENTE_DEL_SKEET		;5044
REMATE_DE_LA_PRUEBA:		; Baja E004 y, hasta que llegue a cero, despacha al remate de la prueba que toque
	ld hl,0e004h		;5047   ; E004, lo que queda de remate
	dec (hl)			;504a
	ret z			;504b
	ld a,(0e080h)		;504c
	and 003h		;504f
	call DESPACHA		;5051

; ----------------------------------------------------------------------
; DATOS tabla_de_5054: Las 3 palabras del despacho de 0x5051, pegadas detras
;   de su call: 0x505A 0x50B8 0x5065. Cierra clavada contra su destino mas
;   bajo hacia delante
;   0x5054..0x505a  (6 bytes)
DATA_tabla_de_5054:
	defw 0505ah	; 5054  -> REMATE_DEL_SKEET
	defw 050b8h	; 5056  -> REMATE_DEL_ARCHERY
	defw 05065h	; 5058  -> REMATE_DEL_WEIGHT

; ======================================================================
; CODIGO 0x505a..0x511d  (195 bytes)
; ======================================================================


REMATE_DEL_SKEET:		; Deja en E151 el patron que toque y devuelve NZ para que la espera siga
	ld c,001h		;505a
	call PATRON_QUE_PARPADEA		;505c
	ld (0e151h),a		;505f
SIGUE_ESPERANDO:		; Devuelve con el bit 0 puesto: aun no ha terminado
	or 001h		;5062
	ret			;5064
REMATE_DEL_WEIGHT:		; Con la barra arriba del todo (E132=5) pinta las dos filas de tiles y sigue con el levantador
	ld hl,0e132h		;5065
	ld a,(hl)			;5068
	cp 005h		;5069   ; El 5 es la postura de haber levantado
	jr nz,L_5081		;506b
	ld a,091h		;506d
	inc hl			;506f
	ld (hl),a			;5070
	ld hl,03a07h		;5071   ; Fila 16, columna 7: doce tiles
	ld c,00ch		;5074
	call RELLENA_256		;5076
	ld l,027h		;5079   ; Y la fila de al lado, otros doce con el tile siguiente
	inc a			;507b
	ld c,00ch		;507c
	call RELLENA_256		;507e
L_5081:
	ld c,001h		;5081
	ld a,(0e1a3h)		;5083
	and a			;5086   ; E1A3: si ha calificado, un patron; si no, el otro
	jr nz,L_508A		;5087
	inc c			;5089
L_508A:
	ld a,(0e003h)		;508a
	push af			;508d
	ld hl,0e105h		;508e
	ld (0e1a9h),a		;5091
	bit 4,a		;5094   ; Bit 4 del contador: el levantador parpadea
	ld a,01eh		;5096
	jr nz,L_509B		;5098
	add a,c			;509a
L_509B:
	ld (hl),a			;509b
	call COLOCA_LA_BARRA		;509c
	pop af			;509f
	bit 2,a		;50a0   ; Bit 2 del contador: alterna los dos flujos, 0x7230 y 0x7241
	ld de,07230h		;50a2
	jr nz,L_50AA		;50a5
	ld de,07241h		;50a7
L_50AA:
	ld c,010h		;50aa
	ld hl,00c98h		;50ac
	ld a,(0e1a3h)		;50af
	and a			;50b2   ; Y solo si ha calificado
	call nz,COPIA_256		;50b3
	jr SIGUE_ESPERANDO		;50b6
REMATE_DEL_ARCHERY:		; Pinta la lista de 0x6627 y sigue por 0x5EBB o 0x5EBE segun haya calificado
	ld de,06627h		;50b8   ; El rotulo de 0x6627
	call PINTA_LISTA		;50bb
	ld a,(0e1a3h)		;50be   ; E1A3: con el levantamiento valido, la ceremonia sigue
	or a			;50c1
	jp nz,SIGUE_LA_CEREMONIA		;50c2
	jp PARPADEA_LA_FIGURA		;50c5
PATRON_QUE_PARPADEA:		; 3, 4 o 5 segun haya calificado y segun el bit 5 del contador
	ld a,(0e1a3h)		;50c8   ; E1A3 otra vez: el patron cambia
	and a			;50cb
	jr z,L_50CF		;50cc
	inc c			;50ce
L_50CF:
	ld a,(0e003h)		;50cf   ; El contador de fotogramas
	bit 5,a		;50d2   ; Bit 5: dieciseis fotogramas con cada patron
	jr nz,L_50D8		;50d4
	ld c,000h		;50d6
L_50D8:
	ld a,003h		;50d8
	add a,c			;50da
	ret			;50db
ACABA_LA_PRUEBA:		; E081 a uno: el estado 6 lo lee y da el intento por terminado
	ld a,001h		;50dc
	ld (0e081h),a		;50de
	ret			;50e1
COLOCA_LOS_TRES_PLATOS:		; Para cada uno de los tres platos de E100, deja su X, su Y y el patron y color que le toquen
	ld ix,0e100h		;50e2   ; Los tres platos, de 0x10 en 0x10
	ld hl,0e0c8h		;50e6
	ld b,003h		;50e9
L_50EB:
	ld a,(ix+002h)		;50eb   ; +2 es la Y y +4 la X
	ld (hl),a			;50ee
	inc hl			;50ef
	ld a,(ix+004h)		;50f0
	ld (hl),a			;50f3
	inc hl			;50f4
	ex de,hl			;50f5
	ld hl,0e003h		;50f6
	ld a,(ix+000h)		;50f9
	cp 005h		;50fc   ; La postura 5 con el bit 2 del contador a cero cuenta como la 7: asi parpadea al romperse
	jr nz,L_5106		;50fe
	bit 2,(hl)		;5100
	jr nz,L_5106		;5102
	add a,002h		;5104
L_5106:
	ex de,hl			;5106
	add a,a			;5107
	ld de,0511dh		;5108   ; La tabla de parejas patron/color
	call DE_MAS_A		;510b
	ld a,(de)			;510e
	ld (hl),a			;510f
	inc hl			;5110
	inc de			;5111
	ld a,(de)			;5112
	ld (hl),a			;5113
	inc hl			;5114
	ld de,00010h		;5115   ; Y al plato siguiente, 0x10 bytes mas alla
	add ix,de		;5118
	djnz L_50EB		;511a
	ret			;511c

; ----------------------------------------------------------------------
; DATOS dieciseis_de_5108: Los bytes que 0x5108 recorre de dos en dos,
;   indexados con DE_MAS_A
;   0x511d..0x512d  (16 bytes)
DATA_dieciseis_de_5108:
	defb 000h,000h	; 511d
	defb 000h,00fh	; 511f
	defb 000h,004h	; 5121
	defb 000h,006h	; 5123
	defb 02ch,00fh	; 5125
	defb 030h,004h	; 5127
	defb 034h,00fh	; 5129
	defb 038h,004h	; 512b

; ======================================================================
; CODIGO 0x512d..0x5151  (36 bytes)
; ======================================================================


SACUDE_EL_PRIMER_PLATO:		; Con el primer plato en la postura 5 o mas, le da un empujon de +0x40 o -0x40 cada 16 fotogramas
	ld a,(0e100h)		;512d
	cp 005h		;5130   ; Por debajo de la postura 5 no hay nada que sacudir
	ret c			;5132
	ld a,(0e003h)		;5133
	bit 4,a		;5136   ; Bit 4 del contador: hacia un lado o hacia el otro
	ld hl,00040h		;5138   ; 0x40 arriba o 0xC0 abajo
	jr nz,L_5140		;513b
	ld hl,0ffc0h		;513d
L_5140:
	ld (0e105h),hl		;5140   ; E105 y E115, la altura y su copia
	ld (0e115h),hl		;5143
	ret			;5146
FOTOGRAMA_DEL_WEIGHT:		; Empuja 0x521C y despacha por E1A1: los once pasos de la halterofilia
	ld hl,0521ch		;5147
	push hl			;514a
	ld a,(0e1a1h)		;514b   ; Los pasos 6, 7, 8 y 10 son los MISMOS que los del skeet: guardar la marca, mirar el liston, el final y acabar
	call DESPACHA		;514e

; ----------------------------------------------------------------------
; DATOS tabla_de_5151: Las 11 palabras del despacho de 0x514E, pegadas detras
;   de su call: 0x5167 0x518B 0x51AA 0x51BA 0x51C2 0x522E 0x4FD6 0x5000 0x501A
;   0x525B 0x50DC. Cierra clavada contra su destino mas bajo hacia delante
;   0x5151..0x5167  (22 bytes)
DATA_tabla_de_5151:
	defw 05167h	; 5151  -> WEIGHT_PASO_0
	defw 0518bh	; 5153  -> WEIGHT_PASO_1
	defw 051aah	; 5155  -> WEIGHT_PASO_2
	defw 051bah	; 5157  -> WEIGHT_PASO_3
	defw 051c2h	; 5159  -> WEIGHT_PASO_4_EN_JUEGO
	defw 0522eh	; 515b  -> WEIGHT_PASO_5
	defw 04fd6h	; 515d  -> SKEET_PASO_3_GUARDA
	defw 05000h	; 515f  -> GUARDA_Y_PINTA
	defw 0501ah	; 5161  -> SKEET_PASO_5_FIN
	defw 0525bh	; 5163  -> WEIGHT_PASO_9
	defw 050dch	; 5165  -> ACABA_LA_PRUEBA

; ======================================================================
; CODIGO 0x5167..0x5285  (286 bytes)
; ======================================================================


WEIGHT_PASO_0:		; Espera al sonido, agota E004 y, en cuanto se toca el mando, arranca
	ld a,(0e036h)		;5167   ; Mientras suene algo, nada
	and a			;516a   ; Mientras suene algo, no se sigue
	ret nz			;516b
	call DETRAS_DEL_PASO_DEL_WEIGHT		;516c
	ld hl,0e004h		;516f   ; E004, la espera
	dec (hl)			;5172
	jp z,PASO_SIGUIENTE_DEL_SKEET		;5173
	ld hl,0e07dh		;5176   ; E07D y E07E: el contador largo, en 0x0400
	ld (hl),000h		;5179
	inc hl			;517b
	ld (hl),004h		;517c
	ld a,(0e043h)		;517e   ; Los cuatro bits bajos del mando: cualquier direccion arranca
	and 00fh		;5181
	ret z			;5183
	xor a			;5184
	ld (0e004h),a		;5185
	jp ESPERA_128		;5188
WEIGHT_PASO_1:		; Cada cuatro fotogramas baja E004; el mando lo reinicia
	ld a,(0e003h)		;518b
	and 003h		;518e   ; Uno de cada cuatro fotogramas
	jr nz,L_5199		;5190
	ld hl,0e004h		;5192
	dec (hl)			;5195
	jp z,PASO_SIGUIENTE_DEL_SKEET		;5196
L_5199:
	ld a,(0e043h)		;5199
	and 01fh		;519c   ; Los cinco bits bajos del mando: al tocarlo, la espera vuelve a empezar
	jr z,L_51A4		;519e
	xor a			;51a0
	ld (0e004h),a		;51a1
L_51A4:
	call ELIGE_LA_CATEGORIA		;51a4
	jp PINTA_LA_CATEGORIA		;51a7
WEIGHT_PASO_2:		; Espera a que calle el sonido y suena el 0x99, el de preparados
	call PINTA_LA_CATEGORIA		;51aa
	ld a,(0e036h)		;51ad   ; Mientras suene algo, no se sigue
	and a			;51b0
	ret nz			;51b1
	ld a,099h		;51b2   ; El sonido 0x99, el de preparados
	call SUENA_SI_SE_PUEDE		;51b4
	jp PASO_SIGUIENTE_DEL_SKEET		;51b7
WEIGHT_PASO_3:		; Solo espera a que el sonido acabe
	ld a,(0e036h)		;51ba
	and a			;51bd
	ret nz			;51be
	jp PASO_SIGUIENTE_DEL_SKEET		;51bf
WEIGHT_PASO_4_EN_JUEGO:		; El fotograma gordo: el reloj, la barra, la potencia y las luces del jurado
	pop hl			;51c2   ; Se tira la direccion de retorno: este paso no vuelve por donde vino
	ld hl,03a17h		;51c3   ; Fila 16, columna 23: donde va el reloj
	ld (0e1a7h),hl		;51c6
	call GASTA_EL_TIEMPO		;51c9
	ld hl,0e1a5h		;51cc
	ld a,(hl)			;51cf
	ld e,a			;51d0
	inc hl			;51d1
	or (hl)			;51d2
	jr z,GUARDA_Y_ESPERA		;51d3   ; Con el reloj a cero se acaba
	ld d,(hl)			;51d5
	ex de,hl			;51d6
	ld de,00500h		;51d7
	sbc hl,de		;51da   ; Al llegar a 5,00 suena el aviso de que queda poco
	ld a,007h		;51dc   ; El sonido 0x07
	call z,SUENA_SI_SE_PUEDE		;51de
	ld a,(0e101h)		;51e1   ; E101 se copia a E108: la potencia de antes
	ld (0e108h),a		;51e4
	call SUBE_LA_POTENCIA		;51e7
	call PINTA_LA_BARRA_DE_POTENCIA		;51ea
	ld a,(0e101h)		;51ed   ; Con la potencia a cero y la de antes tambien, se acaba
	and a			;51f0
	jr nz,L_51F9		;51f1
	ld hl,0e108h		;51f3
	or (hl)			;51f6
	jr nz,GUARDA_Y_ESPERA		;51f7
L_51F9:
	call MUEVE_LA_BARRA		;51f9   ; La barra, sus fichas y las luces del jurado
	call COLOCA_LA_BARRA		;51fc
	call PARPADEA_LA_BARRA		;51ff
	call SUBE_LAS_FICHAS		;5202
	call CUENTA_LAS_LUCES_DEL_JURADO		;5205
	call PINTA_LAS_LUCES_DEL_JURADO		;5208
	ld a,(0e1a3h)		;520b   ; E1A3: el levantamiento dado por bueno
	and a			;520e
	ret z			;520f
	ld hl,(0e124h)		;5210   ; Y con el levantamiento valido, la marca se copia a los puntos del intento
	ld (0e087h),hl		;5213
GUARDA_Y_ESPERA:		; Guarda la marca del intento y espera 128 fotogramas
	call GUARDA_LA_MARCA_DEL_INTENTO		;5216
	jp ESPERA_128		;5219
DETRAS_DEL_PASO_DEL_WEIGHT:		; Refresca los sprites si E1A9 lo permite y los sube a la VRAM
	ld a,(0e1a9h)		;521c
	and a			;521f
	call z,COLOCA_LA_BARRA		;5220
SUBE_LAS_FICHAS:		; Los 0x3D bytes de fichas de E0C0 a la tabla de sprites
	ld hl,03b00h		;5223
	ld de,0e0c0h		;5226
	ld c,03dh		;5229
	jp COPIA_256		;522b
WEIGHT_PASO_5:		; Con el mando y el levantamiento dado por bueno, sube la postura; luego espera al sonido y cobra
	ld a,(0e1a3h)		;522e
	and a			;5231   ; Sin levantamiento valido no se sube nada
	jr z,L_523F		;5232
	ld a,(0e043h)		;5234
	and 008h		;5237   ; Bit 3 del mando
	ld hl,0e132h		;5239
	jr z,L_523F		;523c
	inc (hl)			;523e
L_523F:
	ld a,(0e012h)		;523f   ; Mientras el canal de E012 suene, se espera
	and a			;5242
	ret nz			;5243
	call CAE_LA_BARRA		;5244
	ret nz			;5247
	ld a,(0e132h)		;5248
	cp 005h		;524b   ; La postura 5 es la buena: entonces se cobran 0x20 puntos
	ld a,020h		;524d
	ld (0e135h),a		;524f
	ld de,0e134h		;5252
	call z,SUMA_A_LOS_PUNTOS		;5255
	jp PASO_SIGUIENTE_DEL_SKEET		;5258
WEIGHT_PASO_9:		; Copia el flujo de 0x7230 a la VRAM y deja la marca sacada de la tabla de 0x5285
	ld hl,00c98h		;525b
	ld de,07230h		;525e
	ld c,010h		;5261
	call COPIA_256		;5263
	ld a,(0e1a3h)		;5266   ; Con el levantamiento valido, C baja a 0x0F: el and de abajo deja otra cifra
	and a			;5269
	jr z,L_526D		;526a
	dec c			;526c
L_526D:
	ld a,(0e110h)		;526d   ; E110, el indice de la marca
	ld de,05285h		;5270   ; La tabla de ocho de 0x5285
	call DE_MAS_A		;5273
	ld hl,0e087h		;5276   ; E087, los puntos del intento
	ld a,(de)			;5279
	and c			;527a   ; El and con C: con el levantamiento valido sale otra cifra
	ld (hl),000h		;527b
	inc hl			;527d
	ld (hl),a			;527e
	inc hl			;527f
	ld (hl),000h		;5280
	jp PASO_SIGUIENTE_DEL_SKEET		;5282

; ----------------------------------------------------------------------
; DATOS ocho_de_5270: Los ocho bytes que 0x5270 indexa y luego pasa por un and
;   con C
;   0x5285..0x528d  (8 bytes)
DATA_ocho_de_5270:
	defb 030h,033h,036h,039h,042h,045h,048h,052h	; 5285  0369BEHR

; ======================================================================
; CODIGO 0x528d..0x5297  (10 bytes)
; ======================================================================


FOTOGRAMA_DEL_ARCHERY:		; B se queda con el submodo (E10A) y se despacha por E1A1: los siete pasos del tiro con arco
	ld a,(0e10ah)		;528d
	ld b,a			;5290
	ld a,(0e1a1h)		;5291   ; Como en el archery, los pasos 3, 4, 5 y 6 son los mismos que los del skeet
	call DESPACHA		;5294

; ----------------------------------------------------------------------
; DATOS tabla_de_5297: Las 7 palabras del despacho de 0x5294, pegadas detras
;   de su call: 0x52A5 0x52C4 0x52D2 0x4FD6 0x4FEA 0x501A 0x50DC. Cierra
;   clavada contra su destino mas bajo hacia delante
;   0x5297..0x52a5  (14 bytes)
DATA_tabla_de_5297:
	defw 052a5h	; 5297  -> ARCHERY_PASO_0
	defw 052c4h	; 5299  -> ARCHERY_PASO_1
	defw 052d2h	; 529b  -> ARCHERY_PASO_2_EN_JUEGO
	defw 04fd6h	; 529d  -> SKEET_PASO_3_GUARDA
	defw 04feah	; 529f  -> SKEET_PASO_4_LISTON
	defw 0501ah	; 52a1  -> SKEET_PASO_5_FIN
	defw 050dch	; 52a3  -> ACABA_LA_PRUEBA

; ======================================================================
; CODIGO 0x52a5..0x547c  (471 bytes)
; ======================================================================


ARCHERY_PASO_0:		; Pinta la lista de 0x6643, espera 0x30 y arranca el submodo 1
	ld a,030h		;52a5   ; 0x30 fotogramas
	ld (0e004h),a		;52a7   ; E004, los fotogramas de espera
	ld de,06643h		;52aa   ; El fondo de la prueba
	call PINTA_LISTA		;52ad
	ld a,(0e036h)		;52b0   ; Mientras suene algo, no se arranca
	and a			;52b3
	ret nz			;52b4
SUBE_EL_PASO_Y_ARRANCA:		; Sube E1A1 y deja el submodo (E10A) en 1
	ld hl,0e1a1h		;52b5   ; E1A1 es el paso de la prueba
	inc (hl)			;52b8
	ld hl,0e10ah		;52b9   ; Y E10A el submodo
	ld (hl),001h		;52bc
	ret			;52be
SUBMODO_SIGUIENTE:		; E10A + 1
	ld hl,0e10ah		;52bf
	inc (hl)			;52c2
	ret			;52c3
ARCHERY_PASO_1:		; Agota E004 y, al llegar a cero, otros 0x50 y al paso siguiente
	ld hl,0e004h		;52c4   ; E004, lo que queda de espera
	dec (hl)			;52c7
	jp nz,REPARTE_LAS_Y		;52c8
	ld a,050h		;52cb
	ld (0e004h),a		;52cd
	jr SUBE_EL_PASO_Y_ARRANCA		;52d0
ARCHERY_PASO_2_EN_JUEGO:		; Reparte por el submodo: 0 el remate, 1 la cuenta atras y 2 en adelante el tiro
	push bc			;52d2
	call PINTA_LA_BARRA_DE_FUERZA		;52d3
	pop bc			;52d6
	djnz L_52E2		;52d7
	ld a,(0e205h)		;52d9   ; E205 decide si se acaba o se sigue
	or a			;52dc
	jr nz,SUBMODO_SIGUIENTE		;52dd
	jp ARCHERY_REMATE		;52df
L_52E2:
	djnz L_52F2		;52e2
	ld hl,0e004h		;52e4   ; E004, la cuenta atras
	ld a,(hl)			;52e7
	or a			;52e8
	jp z,SUBMODO_SIGUIENTE		;52e9
	dec (hl)			;52ec
	call SUENA_AL_LLEGAR		;52ed   ; Y el aviso de que queda poco
	jr COLOCA_LOS_SPRITES_DEL_TIRO		;52f0
L_52F2:
	ld a,(0e147h)		;52f2
	and a			;52f5   ; E147 dice cual de los dos motores mueve la figura
	jr z,L_52FD		;52f6
	call AVANZA_Y_REMATA		;52f8
	jr L_5300		;52fb
L_52FD:
	call ANDA_DE_UN_LADO_A_OTRO		;52fd
L_5300:
	jr nz,ARCHERY_MUEVE		;5300
	ld a,002h		;5302   ; Con el motor parado, el submodo vuelve al 2
	ld (0e10ah),a		;5304
ARCHERY_MUEVE:		; Mira el mando y, con el tiro en marcha, sacude la figura y la flecha
	ld a,(0e118h)		;5307
	or a			;530a
	jr nz,COLOCA_LOS_SPRITES_DEL_TIRO		;530b
	ld a,(0e043h)		;530d
	and 010h		;5310   ; Bit 4 del mando: el boton
	call nz,EMPIEZA_EL_TIRO		;5312
	ld a,(0e115h)		;5315
	or a			;5318
	jr z,COLOCA_LOS_SPRITES_DEL_TIRO		;5319
	call ARRANCA_LA_BARRA		;531b
	call CORRIGE_LA_DERIVA		;531e
	call SUBE_EL_ANGULO		;5321
	ld a,(0e0ddh)		;5324
	cp 0e3h		;5327   ; Pasada la X 0xE3, el remate
	call nc,REMATA_EL_TIRO		;5329
COLOCA_LOS_SPRITES_DEL_TIRO:		; Reparte las Y de los sprites: cada uno 0x10 mas abajo que el anterior
	ld a,(0e147h)		;532c   ; E147 dice cual de los dos repartos toca
	and a			;532f
	jr z,ARCHERY_SIN_VUELO		;5330
	ld a,(0e0c4h)		;5332
	add a,010h		;5335
	ld (0e0c8h),a		;5337
	ld (0e0cch),a		;533a
	ld (0e0d0h),a		;533d
	sub 01ah		;5340   ; Menos 0x1A: el ultimo sprite va mas arriba que los demas
	ld (0e0d4h),a		;5342
	jr GUARDA_Y_SUBE_LAS_FICHAS		;5345
ARCHERY_SIN_VUELO:		; El otro reparto, cuando la flecha no esta en el aire
	call CUENTA_ATRAS_DEL_TIRO		;5347
	call PARPADEA_AL_ACERTAR		;534a
REPARTE_LAS_Y:		; Las Y de seis fichas en tres alturas a partir de la de E0C4: dos a su altura, dos 0x10 mas abajo y dos 0x20
	ld a,(0e0c4h)		;534d
	ld (0e0c8h),a		;5350
	add a,010h		;5353   ; La segunda pareja, 0x10 mas abajo
	ld (0e0cch),a		;5355
	ld (0e0d0h),a		;5358
	add a,010h		;535b   ; Y la tercera, otros 0x10
	ld (0e0d4h),a		;535d
	ld (0e0d8h),a		;5360
	call PINTA_EL_ANGULO		;5363
	call PINTA_EL_VIENTO		;5366
	call PINTA_LOS_PUNTOS_DEL_TIRO		;5369
GUARDA_Y_SUBE_LAS_FICHAS:		; Guarda la marca, la pinta y sube 0x2C bytes de fichas a la VRAM
	call GUARDA_LA_MARCA_DEL_INTENTO		;536c
	call PINTA_LOS_TRES_INTENTOS		;536f
	call REPARTE_LOS_PATRONES		;5372
	ld bc,0002ch		;5375   ; 0x2C bytes: once fichas
	ld hl,03b20h		;5378
	ld de,0e0c0h		;537b
	call COPIA_A_VRAM		;537e
	ld hl,03b4ch		;5381
	ld a,0d0h		;5384   ; Y 0xD0 en la Y de la doceava: el VDP para ahi
	jp VPOKE		;5386
REPARTE_LOS_PATRONES:		; Cuatro sprites con el patron 0x20, otros cuatro con el 0x30 y ocho a cero
	ld b,004h		;5389
	ld hl,03b00h		;538b
	ld a,020h		;538e
	call CADA_CUATRO_BYTES		;5390   ; Los cuatro primeros, con el patron 0x20
	ld b,004h		;5393
	ld a,030h		;5395   ; Y los cuatro siguientes con el 0x30
	call CADA_CUATRO_BYTES		;5397
	ld b,008h		;539a   ; Los ocho de detras, a cero
	ld hl,03b03h		;539c
	xor a			;539f
CADA_CUATRO_BYTES:		; Escribe A cada cuatro casillas: el patron de una ficha de sprite
	call VPOKE		;53a0
	inc hl			;53a3   ; Cuatro bytes por ficha: solo se toca el patron
	inc hl			;53a4
	inc hl			;53a5
	inc hl			;53a6
	djnz CADA_CUATRO_BYTES		;53a7
	ret			;53a9
ARCHERY_REMATE:		; Suena el 0x04, mueve la flecha y, pasada la X 0x1F, da el tiro por bueno
	ld a,(0e036h)		;53aa
	or a			;53ad   ; Solo si no hay nada sonando
	jr nz,L_53B5		;53ae
	ld a,004h		;53b0
	call SUENA_SI_SE_PUEDE		;53b2
L_53B5:
	call SIGUIENTE_VIENTO		;53b5
	ld c,01fh		;53b8
	call BAJA_EL_CONTADOR_LARGO		;53ba
	jp nc,COLOCA_LOS_SPRITES_DEL_TIRO		;53bd
	ld a,001h		;53c0
	ld (0e205h),a		;53c2   ; E205 a uno: el tiro esta hecho
	ld de,06635h		;53c5   ; Y la lista de 0x6635, el rotulo de haberlo conseguido
	call PINTA_LISTA		;53c8
	call CENTRA_EL_VIENTO		;53cb
	ld a,050h		;53ce   ; 0x50 fotogramas de espera
	ld (0e004h),a		;53d0
	call SUBMODO_SIGUIENTE		;53d3
	jp COLOCA_LOS_SPRITES_DEL_TIRO		;53d6
SUENA_AL_LLEGAR:		; Con la flecha justo en 0x4C y E111 en 7, suena el aviso
	ld a,(hl)			;53d9   ; Solo con la flecha justo en el 0x4C
	cp 04ch		;53da
	ret nz			;53dc
	ld a,(0e111h)		;53dd   ; Y E111 en 7
	cp 007h		;53e0
	ret nz			;53e2
	ld a,099h		;53e3   ; El sonido 0x99
	jp SUENA_SI_SE_PUEDE		;53e5
EMPIEZA_EL_TIRO:		; Baja los sprites, pinta la lista de 0x6643 y suena una sola vez
	ld a,0c0h		;53e8   ; 0xC0 en la Y: los sprites bajan de golpe
	ld (0e0c0h),a		;53ea
	ld (0e115h),a		;53ed
	ld de,06643h		;53f0
	call PINTA_LISTA		;53f3
	ld a,(0e11bh)		;53f6
	or a			;53f9
	ret nz			;53fa   ; E11B evita que suene mas de una vez
	inc a			;53fb
	ld (0e11bh),a		;53fc
	ld a,00ah		;53ff
	jp ARRANCA_EL_EFECTO		;5401
REMATA_EL_TIRO:		; Con E11A a cero arranca la animacion del remate, y luego apaga las banderas
	ld a,(0e11ah)		;5404
	or a			;5407   ; E11A: solo la primera vez
	jr nz,L_541C		;5408
	inc a			;540a
	ld (0e11ah),a		;540b
	ld a,(0e147h)		;540e
	and a			;5411   ; Otra vez los dos motores, segun E147
	jr z,L_5419		;5412
	call MIRA_SI_ACIERTA		;5414
	jr L_541C		;5417
L_5419:
	call MIRA_SI_DA_EN_LA_DIANA		;5419
L_541C:
	ld a,(0e117h)		;541c   ; E117: solo si ha acertado se cobra
	or a			;541f
	jr nz,L_5438		;5420
	ld (0e11dh),a		;5422   ; Sin acertar, cero puntos
	ld (0e11eh),a		;5425
	ld a,(0e0ddh)		;5428
	cp 0f7h		;542b   ; Pasada la X 0xF7, la flecha se suelta
	ret c			;542d
	ld a,0c0h		;542e   ; 0xC0 en la Y: la ficha se aparca
	ld (0e0dch),a		;5430
	ld (0e0c0h),a		;5433
	jr L_5449		;5436
L_5438:
	ld a,(0e147h)		;5438   ; E147 dice cual de los dos motores va
	and a			;543b
	jr nz,L_5441		;543c
	call COBRA_EL_TIRO		;543e
L_5441:
	call SUMA_LO_QUE_VALE		;5441   ; Los puntos del anillo, sumados
	ld a,010h		;5444   ; 0x10 fotogramas de cuenta atras
	ld (0e144h),a		;5446
L_5449:
	xor a			;5449   ; E115 y E116 a cero: el tiro se para
	ld (0e116h),a		;544a
	ld (0e115h),a		;544d
	inc a			;5450
	ld (0e118h),a		;5451   ; E118 a uno: se ha terminado de mover
	ret			;5454
BAJA_EL_CONTADOR_LARGO:		; Resta uno al contador de 16 bits de E07D; devuelve acarreo si sigue vivo y el mando esta puesto
	ld hl,0e07dh		;5455
	ld a,(hl)			;5458   ; El byte bajo del contador
	sub 001h		;5459
	ld (hl),a			;545b
	inc hl			;545c
	ld a,(hl)			;545d
	sbc a,000h		;545e
	ld (hl),a			;5460
	ret c			;5461
	ld a,(0e043h)		;5462   ; Y ademas hay que estar pulsando lo que diga C
	and c			;5465
	ret z			;5466
	scf			;5467
	ret			;5468
FOTOGRAMA_DE_LA_TABLA_DE_RECORDS:		; Con el bit 2 de E080, la pantalla de records: cinco pasos por E241
	ld a,(0e080h)		;5469
	bit 2,a		;546c   ; Bit 2 de E080: la vuelta que toca tabla
	jr nz,$+29		;546e
	ld a,(0e241h)		;5470
	push af			;5473
	and a			;5474
	call nz,GIRA_EL_MARCO		;5475
	pop af			;5478
	call DESPACHA		;5479

; ----------------------------------------------------------------------
; DATOS tabla_de_547C: Las 5 palabras del despacho de 0x5479, pegadas detras
;   de su call: 0x5495 0x54E1 0x54E8 0x54ED 0x5486. Cierra clavada contra su
;   destino mas bajo hacia delante
;   0x547c..0x5486  (10 bytes)
DATA_tabla_de_547C:
	defw 05495h	; 547c  -> RECORDS_PASO_0
	defw 054e1h	; 547e  -> RECORDS_PASO_1
	defw 054e8h	; 5480  -> RECORDS_PASO_2
	defw 054edh	; 5482  -> RECORDS_PASO_3
	defw 05486h	; 5484  -> RECORDS_PASO_4

; ======================================================================
; CODIGO 0x5486..0x55f4  (366 bytes)
; ======================================================================


RECORDS_PASO_4:		; Espera al sonido y pasa a la prueba siguiente
	ld a,(0e036h)		;5486
	or a			;5489
	ret nz			;548a
PRUEBA_SIGUIENTE:		; Sube E080 y avisa con E081
	ld hl,0e080h		;548b
	inc (hl)			;548e
	ld a,001h		;548f
	ld (0e081h),a		;5491
	ret			;5494
RECORDS_PASO_0:		; Monta la pantalla entera de records: el fondo, los rotulos y las cifras
	ld a,0abh		;5495   ; El sonido 0xAB, el de la tabla
	call ARRANCA_EL_EFECTO		;5497
	call BORRA_LA_PANTALLA		;549a
	ld hl,05700h		;549d
	ld de,056e8h		;54a0
	call ARRANCA_LA_ANIMACION		;54a3
	call SUBE_LAS_SEIS_FICHAS		;54a6
	call CARGA_LOS_TRES_FLUJOS		;54a9
	ld de,055fah		;54ac   ; La lista de 0x55FA, con el WORLD RECORD
	call PINTA_LISTA		;54af
	ld hl,03883h		;54b2   ; Fila 4, columna 3
	call TRES_FILAS_DE_DIECISEIS		;54b5   ; Las tres filas de rotulos y el marco
	call PINTA_EL_MARCO		;54b8
	call PINTA_LAS_TRES_MARCAS		;54bb
	xor a			;54be
	ld (0e23eh),a		;54bf   ; E23E a cero
PASO_SIGUIENTE_DE_RECORDS:		; Sube E241
	ld hl,0e241h		;54c2   ; E241 es el paso de la tabla de records
	inc (hl)			;54c5
	ret			;54c6
ARRANCA_LA_ANIMACION:		; Guarda las dos poses (0xE24B y 0xE24D), borra los 0x20 bytes de trabajo de 0xE222 y arranca
	ld (0e24bh),hl		;54c7
	ld (0e24dh),de		;54ca
	ld hl,0e222h		;54ce   ; 0x1F bytes a cero con un ldir que se copia a si mismo
	ld de,0e223h		;54d1
	xor a			;54d4
	ld (hl),a			;54d5
	ld bc,0001fh		;54d6
	ldir		;54d9
	inc a			;54db
	ld (0e23ah),a		;54dc   ; E23A a uno: el motor arranca
	jr L_5514		;54df
RECORDS_PASO_1:		; Espera a que E23E llegue a cero
	ld hl,0e23eh		;54e1
	dec (hl)			;54e4
	ret nz			;54e5
	jr PASO_SIGUIENTE_DE_RECORDS		;54e6
RECORDS_PASO_2:		; La figura que se mueve; cuando E23A vuelve a cero, al paso siguiente
	call MUEVE_LA_FIGURA		;54e8
	jr L_54F0		;54eb
RECORDS_PASO_3:		; Lo mismo con el otro motor, el de 0x555A
	call PASA_LAS_MARCAS		;54ed
L_54F0:
	ld hl,0e23ah		;54f0
	ld a,(hl)			;54f3   ; E23A dice si el motor ha terminado
	or a			;54f4
	ret nz			;54f5
	inc (hl)			;54f6
	jr PASO_SIGUIENTE_DE_RECORDS		;54f7
MUEVE_LA_FIGURA:		; Cada dos fotogramas avanza E23F y, segun por donde vaya, copia una pose o interpola hacia ella
	call SUBE_LAS_SEIS_FICHAS		;54f9
	ld a,(0e003h)		;54fc
	rra			;54ff   ; Uno de cada dos fotogramas
	jr c,DEVUELVE_NZ		;5500
	ld hl,0e23fh		;5502
	inc (hl)			;5505
	ld a,(hl)			;5506
	sub 020h		;5507   ; A los 0x20 pasos se cambia de pose
	jr z,L_552B		;5509
	ld a,(hl)			;550b
	cp 004h		;550c   ; Los cuatro primeros pasos y los que pasan de 0x1C: la pose entera, copiada
	jr c,L_5514		;550e
	cp 01ch		;5510
	jr c,L_551A		;5512
L_5514:
	ld hl,(0e24dh)		;5514
	jp L_5521		;5517
L_551A:
	cp 004h		;551a
	jr nz,INTERPOLA_LA_POSE		;551c
	ld hl,(0e24bh)		;551e
L_5521:
	ld de,0e222h		;5521   ; Los 0x18 bytes de la pose, a la zona de trabajo
	ld bc,00018h		;5524
	ldir		;5527
	jr DEVUELVE_NZ		;5529
L_552B:
	ld (hl),a			;552b
	inc hl			;552c
	inc (hl)			;552d
	ld a,(hl)			;552e
	dec hl			;552f
	cp 005h		;5530   ; Cinco poses y se acaba
	jr z,ACABA_LA_ANIMACION		;5532
INTERPOLA_LA_POSE:		; Suma o resta a cada uno de los seis sprites el paso que dice la tabla de 0x5718
	ld a,(hl)			;5534
	ld d,a			;5535
	ld hl,05718h		;5536   ; La tabla de pasos, indexada por donde va la animacion
	call HL_MAS_A		;5539
	ld c,(hl)			;553c
	ld hl,0e222h		;553d
	ld b,006h		;5540
L_5542:
	ld a,(hl)			;5542
	add a,c			;5543
	bit 4,d		;5544   ; El bit 4 dice si se suma o se resta
	jr nz,L_554A		;5546
	sub c			;5548
	sub c			;5549
L_554A:
	ld (hl),a			;554a
	inc hl			;554b   ; Cuatro bytes: al siguiente sprite
	inc hl			;554c   ; Tres bytes por marca
	inc hl			;554d
	inc hl			;554e
	djnz L_5542		;554f
DEVUELVE_NZ:		; Sale con 0xFF: la animacion sigue
	or 0ffh		;5551
	ret			;5553
ACABA_LA_ANIMACION:		; Baja E23A, que es lo que mira el paso para seguir
	ld hl,0e23ah		;5554   ; E23A, la cuenta de la animacion
	dec (hl)			;5557
	jr DEVUELVE_NZ		;5558
PASA_LAS_MARCAS:		; Uno de cada ocho fotogramas: va sacando las marcas de la tabla, fila a fila
	ld a,(0e003h)		;555a
	and 007h		;555d   ; Uno de cada ocho
	ret nz			;555f
	ld hl,0e23dh		;5560
	inc (hl)			;5563
	ld b,(hl)			;5564
	ld a,(hl)			;5565
	sub 011h		;5566   ; A los 0x11 pasos, marca siguiente
	jr nz,L_556D		;5568
	ld (hl),a			;556a
	dec hl			;556b
	inc (hl)			;556c
L_556D:
	ld a,(0e23ch)		;556d
	cp 003h		;5570   ; Tres marcas y se acaba
	jr z,ACABA_LA_ANIMACION		;5572
	add a,a			;5574
	ld hl,055f4h		;5575
	call HL_MAS_A		;5578
	ld e,(hl)			;557b
	inc hl			;557c
	ld d,(hl)			;557d
	ex de,hl			;557e
	ld a,b			;557f
	rra			;5580   ; Un paso si y otro no: en uno se borra la fila y en el otro se pinta
	jr nc,REPINTA_LA_FILA		;5581
	ld bc,00017h		;5583
	jp RELLENA_CON_CERO		;5586
REPINTA_LA_FILA:		; Fila 4, columna 3: las tres filas de dieciseis
	ld hl,03883h		;5589
	call TRES_FILAS_DE_DIECISEIS		;558c
PINTA_LAS_TRES_MARCAS:		; Las tres marcas, cada una en su casilla y con su liston
	ld hl,(055f8h)		;558f   ; La marca de mas abajo
	ld c,002h		;5592
	call PINTA_LA_MARCA_DEL_RECORD		;5594
	ld hl,(055f6h)		;5597   ; La de en medio
	ld c,001h		;559a
	call PINTA_LA_MARCA_DEL_RECORD		;559c
	ld hl,(055f4h)		;559f   ; Y la de arriba
	ld c,000h		;55a2
PINTA_LA_MARCA_DEL_RECORD:		; Una de las tres marcas de la tabla de records: su cifra y, tres bytes mas alla, el liston de esa prueba
	ld a,011h		;55a4   ; 0x11 casillas mas a la derecha
	add a,l			;55a6
	ld l,a			;55a7
	ld de,0e05bh		;55a8
	ld a,c			;55ab
	add a,a			;55ac   ; Por tres: cada prueba tiene su liston tres bytes mas abajo de E05B
	add a,c			;55ad
	ld b,a			;55ae
	ld a,e			;55af
	sub b			;55b0
	ld e,a			;55b1
	jr nc,L_55B5		;55b2
	dec d			;55b4
L_55B5:
	jp PINTA_LA_MARCA		;55b5
GIRA_EL_MARCO:		; Uno de cada ocho fotogramas, corre el patron del marco: parece que da vueltas
	ld a,(0e003h)		;55b8
	and 007h		;55bb   ; Uno de cada ocho
	ret nz			;55bd
	ld hl,0e23bh		;55be
	inc (hl)			;55c1
	ld a,(hl)			;55c2
	and 003h		;55c3
	ld c,a			;55c5
	jr L_55CA		;55c6
PINTA_EL_MARCO:		; El marco entero, con el patron de partida en C
	ld c,000h		;55c8
L_55CA:
	ld hl,03803h		;55ca   ; Fila 0, columna 3
	ld de,00001h		;55cd
	ld b,01ah		;55d0   ; 0x1A tiles a lo ancho
	call TIRA_DEL_MARCO		;55d2
	ld e,020h		;55d5   ; 0x20 de salto: la columna de al lado
	call DIEZ_DE_ALTO		;55d7
	ld de,0ffffh		;55da   ; Una casilla menos: la fila de abajo, del reves
	ld b,01ah		;55dd
	call TIRA_DEL_MARCO		;55df
	ld de,0ffe0h		;55e2   ; Y 0x20 menos: subiendo
DIEZ_DE_ALTO:		; Los diez de un lado
	ld b,00ah		;55e5   ; Diez de alto
TIRA_DEL_MARCO:		; B tiles del marco, cada uno con el patron siguiente de los cuatro
	ld a,c			;55e7
	inc c			;55e8
	and 003h		;55e9   ; Cuatro patrones que se van turnando
	add a,03ch		;55eb   ; 0x3C es el primero de los cuatro tiles del marco
	call VPOKE		;55ed
	add hl,de			;55f0
	djnz TIRA_DEL_MARCO		;55f1
	ret			;55f3

; ----------------------------------------------------------------------
; DATOS casillas_de_las_marcas: Tres palabras con la casilla de la VRAM de
;   cada una de las tres marcas de la tabla de records: 0x3885, 0x38C5 y
;   0x3905, o sea las filas 4, 6 y 8. Las lee 0x558F, y 0x5575 las indexa por
;   dos con (0xE23C)
;   0x55f4..0x55fa  (6 bytes)
DATA_casillas_de_las_marcas:
	defw 03885h	; 55f4
	defw 038c5h	; 55f6
	defw 03905h	; 55f8

; ----------------------------------------------------------------------
; DATOS lista_del_marco: Lista de tiles con el marco de la tabla de records y
;   el rotulo. Descifrada con tools/textos.py: «0112 / 3..4 / 7885..6889 /
;   5...AB...6 / 5...CD...6 / 5........6 / WORLD RECORD»
;   0x55fa..0x564b  (81 bytes)
DATA_lista_del_marco:
	defb 02eh,03ah,040h,041h,041h,042h,0feh,04eh,03ah,043h,04bh,04ch,044h,0feh,06bh,03ah	; 55fa  .:@AAB.N:CKLD.k:
	defb 047h,048h,048h,045h,04dh,04eh,046h,048h,048h,049h,0feh,08bh,03ah,045h,04ah,04ah	; 560a  GHHEMNFHHI..:EJJ
	defb 04ah,051h,052h,04ah,04ah,04ah,046h,0feh,0abh,03ah,045h,04fh,04ah,04ah,053h,054h	; 561a  JQRJJJF..:EOJJST
	defb 04ah,04ah,050h,046h,0feh,0cbh,03ah,045h,04ah,04ah,04ah,04ah,04ah,04ah,04ah,04ah	; 562a  JJPF..:EJJJJJJJJ
	defb 046h,0feh,04ah,038h,037h,02fh,032h,02ch,024h,000h,032h,025h,023h,02fh,032h,024h	; 563a  F.J87/2,$.2%#/2$
	defb 0ffh	; 564a

; ----------------------------------------------------------------------
; DATOS rle_564B: Flujo comprimido con su direccion de VRAM delante: 164 bytes
;   de VRAM
;   0x564b..0x56bb  (112 bytes)
DATA_rle_564B:
	defb 004h,0ffh,083h,01fh,03fh,07fh,00dh,0ffh,085h,0f8h,0fch,0feh,0ffh,000h,007h,07fh	; 564b  ....?...........
	defb 081h,000h,007h,0feh,008h,07fh,008h,0feh,004h,0ffh,084h,00fh,01fh,07fh,07fh,00ch	; 565b  ................
	defb 0ffh,084h,0f0h,0f8h,0feh,0feh,008h,0ffh,005h,000h,083h,001h,003h,001h,005h,000h	; 566b  ................
	defb 003h,080h,003h,001h,081h,007h,004h,000h,003h,080h,081h,0e0h,005h,000h,08fh,03eh	; 567b  ...............>
	defb 063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh,0a0h,000h	; 568b  c..<p..>c...c>..
	defb 00fh,00fh,07fh,0cfh,08fh,04fh,03fh,000h,0f0h,0f0h,0feh,0f3h,0f1h,0f2h,0fch,02fh	; 569b  .....O?......../
	defb 047h,003h,001h,001h,001h,003h,01fh,0f4h,0e2h,0c0h,080h,080h,080h,0c0h,0f8h,000h	; 56ab  G...............

; ----------------------------------------------------------------------
; DATOS rle_56BB: Flujo comprimido con su direccion de VRAM delante: 164 bytes
;   de VRAM
;   0x56bb..0x56e8  (45 bytes)
DATA_rle_56BB:
	defb 004h,000h,004h,0e0h,004h,000h,004h,0e0h,004h,000h,004h,0e0h,020h,0efh,004h,000h	; 56bb  ............ ...
	defb 003h,0e0h,081h,0feh,004h,000h,003h,0e0h,081h,0f0h,004h,000h,003h,0e0h,081h,0feh	; 56cb  ................
	defb 008h,0e0h,081h,04fh,007h,04eh,081h,04fh,027h,04eh,020h,06eh,000h	; 56db  ...O.N.O'N n.

; ----------------------------------------------------------------------
; DATOS registros_de_cuatro_A: Seis registros de cuatro bytes que 0x54A0 pasa
;   como segundo puntero a 0x54C7, que los guarda en 0xE24D
;   0x56e8..0x5700  (24 bytes)
DATA_registros_de_cuatro_A:
	defb 06fh,078h,030h,00bh	; 56e8
	defb 075h,07bh,038h,004h	; 56ec
	defb 07dh,07ch,03ch,006h	; 56f0
	defb 081h,07ch,040h,00bh	; 56f4
	defb 06dh,07bh,02ch,006h	; 56f8
	defb 077h,084h,034h,00bh	; 56fc

; ----------------------------------------------------------------------
; DATOS registros_de_cuatro_B: Otros seis, que 0x549D pasa como primero y
;   0x54C7 guarda en 0xE24B
;   0x5700..0x5718  (24 bytes)
DATA_registros_de_cuatro_B:
	defb 067h,077h,044h,00bh	; 5700
	defb 071h,07ah,048h,004h	; 5704
	defb 078h,075h,04ch,006h	; 5708
	defb 07bh,078h,050h,00bh	; 570c
	defb 06ah,07bh,02ch,006h	; 5710
	defb 0e0h,000h,008h,000h	; 5714

; ----------------------------------------------------------------------
; DATOS tabla_de_5536: Los bytes que 0x5536 indexa, y que compara contra los
;   seis de 0xE222
;   0x5718..0x5738  (32 bytes)
DATA_tabla_de_5536:
	defb 000h,000h,000h,000h,000h,003h,003h,002h	; 5718  ........
	defb 002h,002h,001h,001h,001h,001h,001h,000h	; 5720  ........
	defb 000h,001h,001h,001h,001h,001h,002h,002h	; 5728  ........
	defb 002h,003h,003h,003h,000h,000h,000h,000h	; 5730  ........

; ======================================================================
; CODIGO 0x5738..0x583e  (262 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL LANZADOR DE PLATOS. Cada 0x18 fotogramas busca una de las tres
; ranuras de 0xE100 que este libre y suelta un plato. Ni la direccion
; ni la altura salen de un azar de verdad: se leen BIT A BIT de dos
; tablas, la de 0x583E y la de 0x5866, cada una recorrida con su
; propio contador. El mismo cartucho lanza siempre igual.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
LANZA_UN_PLATO:		; Cada 0x18 fotogramas suelta un plato por la ranura que este libre
	ld hl,0e1a6h		;5738   ; Mientras E1A5 o E1A6 no esten a cero, no se lanza nada
	ld a,(hl)			;573b
	dec hl			;573c
	or (hl)			;573d
	ret z			;573e
	ld hl,0e140h		;573f
	ld a,(hl)			;5742
	dec (hl)			;5743   ; E140: la cuenta atras entre plato y plato
	and a			;5744
	ret nz			;5745
	ld (hl),a			;5746
	ld de,0e100h		;5747
	ld b,003h		;574a
BUSCA_RANURA_LIBRE:		; Las tres ranuras de 0xE100, de 0x10 en 0x10
	ld a,(de)			;574c
	and a			;574d   ; La primera con el estado a cero
	jr z,SUELTA_EL_PLATO		;574e
	ld a,010h		;5750
	add a,e			;5752
	ld e,a			;5753
	djnz BUSCA_RANURA_LIBRE		;5754
	ret			;5756
SUELTA_EL_PLATO:		; Rellena la ranura: 0x18 fotogramas hasta el siguiente y la postura de partida
	ld (hl),018h		;5757   ; Otros 0x18 fotogramas hasta el proximo
	inc hl			;5759
	push hl			;575a
	ld hl,0e171h		;575b   ; E171 cuenta los platos de la tanda
	ld a,(hl)			;575e
	inc (hl)			;575f
	ld c,001h		;5760
	cp 00eh		;5762   ; En el plato 0x0E se lanzan de dos en dos...
	jr nz,L_5767		;5764
	inc c			;5766
L_5767:
	cp 01dh		;5767   ; ...y en el 0x1D, de tres en tres
	jr nz,L_576D		;5769
	ld c,003h		;576b
L_576D:
	ld a,c			;576d
	ld (de),a			;576e
	inc de			;576f
	pop hl			;5770
	ld a,(hl)			;5771
	inc (hl)			;5772
	ld b,a			;5773
	rra			;5774   ; Tres rra: el contador entre ocho da el byte de la tabla
	rra			;5775
	rra			;5776
	and 01fh		;5777
	ex af,af'			;5779
	ld hl,0e074h		;577a   ; E074, la dificultad, elige de que fila de la tabla se lee
	ld a,(hl)			;577d
	add a,a			;577e
	add a,a			;577f
	add a,(hl)			;5780
	ld hl,0583eh		;5781   ; Cinco bytes por dificultad
	call HL_MAS_A		;5784
	ex af,af'			;5787
	call HL_MAS_A		;5788
	ld a,b			;578b
	and 007h		;578c   ; Los tres bits bajos: el bit dentro del byte
	ld b,a			;578e
	inc b			;578f
	ld a,(hl)			;5790
SACA_EL_BIT:		; Rota el byte hasta dejar en el acarreo el bit que toca
	rla			;5791
	djnz SACA_EL_BIT		;5792
	ex de,hl			;5794
	ld (hl),000h		;5795
	inc hl			;5797
	ld (hl),090h		;5798   ; Y = 0x90: los platos salen de abajo
	inc hl			;579a
	ld de,01000h		;579b   ; Segun el bit, el plato sale hacia un lado o hacia el otro
	jr nc,L_57A3		;579e
	ld de,0f000h		;57a0
L_57A3:
	ld (hl),e			;57a3
	inc hl			;57a4
	ld (hl),d			;57a5
	inc hl			;57a6
	inc hl			;57a7
	inc hl			;57a8
	ld de,(0e142h)		;57a9   ; E142: la velocidad que se le pone
	call c,CAMBIA_EL_SIGNO		;57ad
	ld (hl),e			;57b0
	inc hl			;57b1
	ld (hl),d			;57b2
	dec hl			;57b3
	dec hl			;57b4
	push hl			;57b5
	ld a,(0e141h)		;57b6   ; E141 cuenta las alturas, y su tabla es la de 0x5866
	dec a			;57b9
	ld b,a			;57ba
	rra			;57bb
	rra			;57bc
	and 03fh		;57bd   ; Dos bits por altura: cuatro alturas distintas
	ld hl,05866h		;57bf   ; La tabla de alturas, leida de dos en dos bits
	call HL_MAS_A		;57c2
	ld a,b			;57c5
	and 003h		;57c6   ; Los dos bits bajos del contador: cual de los cuatro pares
	ld b,a			;57c8
	inc b			;57c9
	ld a,(hl)			;57ca
SACA_LOS_DOS_BITS:		; Rota de dos en dos hasta el par que toca
	rlca			;57cb   ; Dos rotaciones por par
	rlca			;57cc
	djnz SACA_LOS_DOS_BITS		;57cd
	ld l,b			;57cf
	ld h,b			;57d0
	rrca			;57d1
	rrca			;57d2
	and 003h		;57d3   ; Y con los dos bits, la altura
	ld (0e200h),a		;57d5   ; E200 se queda con la altura, de 0 a 3
	add a,a			;57d8
	add a,002h		;57d9   ; Y de ella salen las vueltas del bucle de abajo
	ld b,a			;57db
	ld de,(0e142h)		;57dc
	sra d		;57e0   ; La velocidad partida por cuatro, con sra: con signo
	rr e		;57e2
	sra d		;57e4
	rr e		;57e6
ACUMULA_LA_ALTURA:		; Suma la velocidad tantas veces como diga la altura
	add hl,de			;57e8
	djnz ACUMULA_LA_ALTURA		;57e9
	pop de			;57eb
	ex de,hl			;57ec
	call CAMBIA_EL_SIGNO		;57ed
	sra d		;57f0   ; Otra division por dos, ya para guardarla
	rr e		;57f2
	ld (hl),d			;57f4   ; La velocidad, guardada del reves
	dec hl			;57f5
	ld (hl),e			;57f6
	ld e,l			;57f7
	ld d,h			;57f8
	ex de,hl			;57f9
	dec de			;57fa
	call CASILLA_DE_LA_RANURA		;57fb   ; La casilla de la ranura que toca
	ld a,(0e200h)		;57fe
	cp 002h		;5801   ; Por debajo de la altura 2, un patron; por encima, otro
	ld a,020h		;5803   ; El patron 0x20 o el 0x50 segun el lado
	jr c,COLOCA_EL_SPRITE_DEL_PLATO		;5805
	ld a,050h		;5807
COLOCA_EL_SPRITE_DEL_PLATO:		; Deja el patron, el color y la marca de vivo en la ficha del plato
	ld (hl),a			;5809   ; El patron
	inc hl			;580a
	inc hl			;580b
	ld (hl),098h		;580c   ; El color 0x98
	inc hl			;580e
	ld a,(de)			;580f   ; Y la marca de vivo
	ld (hl),a			;5810
	inc hl			;5811
	ld (hl),000h		;5812
	inc hl			;5814
	ld (hl),001h		;5815
	ld a,005h		;5817   ; El sonido 0x05: el lanzamiento
	call ARRANCA_EL_EFECTO		;5819
	ld hl,0e19bh		;581c   ; E19B: si esta puesto, se apunta un plato mas
	ld a,(hl)			;581f
	and a			;5820
	ret z			;5821
	dec hl			;5822
	inc (hl)			;5823
	ret			;5824
CASILLA_DE_LA_RANURA:		; De la direccion de la ranura saca la casilla de su ficha de sprite
	ld a,l			;5825   ; El nibble alto de L dice la ranura
	rra			;5826
	rra			;5827
	rra			;5828
	rra			;5829
	and 003h		;582a
	ld c,a			;582c
	add a,a			;582d   ; Por seis: seis bytes por ranura en la tabla de fichas
	add a,a			;582e
	add a,c			;582f
	add a,c			;5830
	ld l,080h		;5831   ; La tabla de fichas arranca en el 0x80 de la pagina
	add a,l			;5833
	ld l,a			;5834
	ret			;5835
CAMBIA_EL_SIGNO:		; Complemento a dos de DE: la velocidad hacia el otro lado
	ld a,d			;5836
	cpl			;5837
	ld d,a			;5838
	ld a,e			;5839
	cpl			;583a
	ld e,a			;583b
	inc de			;583c   ; El cpl de los dos bytes mas uno: complemento a dos
	ret			;583d

; ----------------------------------------------------------------------
; DATOS direcciones_de_los_platos: Cinco bytes por dificultad -ocho
;   dificultades- que el lanzador lee BIT A BIT: cada bit dice hacia que lado
;   sale el plato. Es lo que hace de azar, y por eso el cartucho lanza siempre
;   igual
;   0x583e..0x5866  (40 bytes)
DATA_direcciones_de_los_platos:
	defb 0ffh,0fdh,0ffh,0fbh,0ffh,00fh,033h,035h	; 583e  ......35
	defb 01ch,070h,0cch,0c9h,033h,024h,0cdh,0cch	; 5846  .p..3$..
	defb 0cah,0a5h,05ah,0ach,055h,055h,055h,0aah	; 584e  ..Z.UUU.
	defb 0cah,06ah,0d4h,0cdh,05bh,056h,0a9h,0e2h	; 5856  .j..[V..
	defb 0abh,055h,0eah,0adh,0d5h,0cah,02bh,057h	; 585e  .U....+W

; ----------------------------------------------------------------------
; DATOS alturas_de_los_platos: Nueve bytes que se leen de DOS EN DOS BITS:
;   cuatro alturas posibles por pareja, con su propio contador (E141)
;   0x5866..0x586f  (9 bytes)
DATA_alturas_de_los_platos:
	defb 033h,0dch,08dh,0c8h,0dch,0dch,08dh,0c8h,0cch	; 5866  3........

; ======================================================================
; CODIGO 0x586f..0x5aa6  (567 bytes)
; ======================================================================


CAEN_LOS_PLATOS:		; A cada plato vivo le suma la gravedad, que es mayor cuanto mas alto va, y lo mata al salirse por abajo
	ld hl,0e100h		;586f
	ld b,003h		;5872
L_5874:
	push hl			;5874
	ld a,(hl)			;5875
	dec a			;5876
	cp 003h		;5877   ; Solo las posturas 1, 2 y 3: las demas ya no caen
	jr nc,L_58B0		;5879
	inc hl			;587b
	inc hl			;587c
	ld a,(hl)			;587d
	inc hl			;587e
	inc hl			;587f
	inc hl			;5880
	cp 060h		;5881   ; Por encima de la Y 0x60, la gravedad es 1...
	ld e,001h		;5883
	jr nc,L_589E		;5885
	ld e,006h		;5887
	cp 050h		;5889   ; ...entre 0x50 y 0x60, 6...
	jr nc,L_589E		;588b
	ld e,010h		;588d
	cp 038h		;588f   ; ...y por debajo de 0x38, 0x10: cuanto mas arriba, mas despacio
	jr nc,L_589E		;5891   ; El plato ya se fue del todo
	inc hl			;5893
	ld a,(hl)			;5894
	dec hl			;5895
	and a			;5896
	jr z,L_589E		;5897
	xor a			;5899   ; La ranura se cierra
	ld (hl),a			;589a
	inc hl			;589b
	ld (hl),a			;589c
	dec hl			;589d
L_589E:
	ld a,e			;589e
	add a,(hl)			;589f   ; La gravedad, sumada a la Y de 16 bits
	ld (hl),a			;58a0
	inc hl			;58a1
	jr nc,L_58A5		;58a2
	inc (hl)			;58a4
L_58A5:
	ld a,(hl)			;58a5
	dec a			;58a6
	cp 010h		;58a7   ; Pasado el 0x10 por abajo, el plato se apaga
	jr nc,L_58B0		;58a9
	ld (hl),000h		;58ab   ; La ranura se cierra y el plato se da por ido
	dec hl			;58ad
	ld (hl),0ffh		;58ae
L_58B0:
	pop hl			;58b0
	ld de,00010h		;58b1   ; 0x10 bytes: la ranura siguiente
	add hl,de			;58b4
	djnz L_5874		;58b5
	ret			;58b7
MUEVE_LOS_PLATOS:		; A cada plato vivo le suma su velocidad a la X y a la Y, las dos de 16 bits
	ld hl,0e100h		;58b8   ; Las tres ranuras de plato de 0xE100
	ld de,0e105h		;58bb   ; Y sus tres velocidades de 0xE105
	ld b,003h		;58be
L_58C0:
	push hl			;58c0
	push de			;58c1
	ld a,(hl)			;58c2   ; La ranura vacia se salta
	and a			;58c3
	jr z,L_58D6		;58c4
	inc hl			;58c6
	ld c,002h		;58c7   ; Dos parejas: la X y la Y
SUMA_LAS_PALABRAS:		; De dos en dos bytes, C veces: lo que hay en DE se le suma a lo que hay en HL
	ld a,(de)			;58c9
	add a,(hl)			;58ca
	ld (hl),a			;58cb
	inc hl			;58cc
	inc de			;58cd
	ld a,(de)			;58ce
	adc a,(hl)			;58cf   ; Y el acarreo al byte alto
	ld (hl),a			;58d0
	inc hl			;58d1
	inc de			;58d2
	dec c			;58d3   ; C parejas
	jr nz,SUMA_LAS_PALABRAS		;58d4
L_58D6:
	pop de			;58d6
	pop hl			;58d7
	ld a,010h		;58d8   ; Y al siguiente, 0x10 bytes mas alla
	add a,l			;58da
	ld l,a			;58db
	ld a,010h		;58dc
	add a,e			;58de
	ld e,a			;58df
	djnz L_58C0		;58e0
	ret			;58e2
MIRA_LOS_IMPACTOS:		; Para cada plato mira si el disparo le ha dado, y si si, lo revienta
	ld hl,0e100h		;58e3
	ld b,003h		;58e6   ; Las tres ranuras de plato
L_58E8:
	push bc			;58e8
	ld (0e200h),hl		;58e9   ; La ranura en curso se aparca en E200
	call LE_HE_DADO		;58ec
	call c,REVIENTA_EL_PLATO		;58ef   ; Con acarreo, el plato estaba tocado
	pop bc			;58f2
	ld hl,(0e200h)		;58f3
	ld a,010h		;58f6
	add a,l			;58f8
	ld l,a			;58f9
	djnz L_58E8		;58fa
	ret			;58fc
ACELERA_UN_POCO:		; Le quita 0x40 a la velocidad, sin bajar de 0x180: los platos siguientes salen mas rapidos
	ld hl,(0e142h)		;58fd
	ld de,0ffc0h		;5900   ; 0x40 menos: los platos van mas rapidos
	add hl,de			;5903
	ld b,h			;5904
	ld c,l			;5905
	and a			;5906
	ld de,00180h		;5907   ; 0x180 es el suelo de la velocidad
	sbc hl,de		;590a
	jr nc,L_5910		;590c
	ld c,e			;590e
	ld b,d			;590f
L_5910:
	ld (0e142h),bc		;5910
	ret			;5914
REVIENTA_EL_PLATO:		; Lo apunta, acelera el siguiente, y borra la ranura y su ficha de sprite
	ld a,(0e179h)		;5915
	and a			;5918   ; Con E179 a cero, se marca el desempate en E199
	jr nz,L_5920		;5919
	ld a,001h		;591b
	ld (0e199h),a		;591d
L_5920:
	call ACELERA_UN_POCO		;5920   ; El plato siguiente sale mas rapido
	ld a,00eh		;5923   ; E160 = 0x0E
	ld (0e160h),a		;5925
	ld hl,0e174h		;5928   ; E172, E173 y E174 a cero
	xor a			;592b
	ld (hl),a			;592c
	dec hl			;592d
	ld (hl),a			;592e
	dec hl			;592f
	dec hl			;5930
	ld (hl),a			;5931
BORRA_LA_RANURA:		; Los ocho bytes de la ranura a cero y su ficha de sprite aparcada
	ld hl,(0e200h)		;5932
	ld c,008h		;5935
BUCLE_DE_BORRADO:		; Deja la ranura a cero y saca su ficha de la pantalla
	ld (hl),000h		;5937
	inc hl			;5939
	dec c			;593a   ; C bytes a cero
	jr nz,BUCLE_DE_BORRADO		;593b
	call CASILLA_DE_LA_RANURA		;593d
	ld (hl),000h		;5940
	ld c,005h		;5942
L_5944:
	inc hl			;5944
	ld (hl),0e0h		;5945   ; 0xE0 en los cinco bytes: la ficha sale de la pantalla
	dec c			;5947
	jr nz,L_5944		;5948
	ret			;594a
LE_HE_DADO:		; Devuelve con acarreo si el disparo cae dentro del plato: mira la Y y luego la distancia en X
	ld a,(hl)			;594b   ; La primera casilla de la ranura dice la postura
	ld b,a			;594c
	and a			;594d
	ret z			;594e   ; Con la ranura vacia no hay nada que mirar
	inc hl			;594f
	inc hl			;5950
	inc hl			;5951
	inc hl			;5952
	ld a,(hl)			;5953
	add a,008h		;5954   ; Ocho de margen arriba y ocho abajo
	cp 010h		;5956
	ret c			;5958
	ld a,b			;5959
	cp 004h		;595a   ; Solo las posturas 0 a 3 se pueden reventar
	ret nc			;595c
	dec hl			;595d
	dec hl			;595e
	ld e,(hl)			;595f
	call CASILLA_DE_LA_RANURA		;5960
	inc hl			;5963
	inc hl			;5964
	ld a,(hl)			;5965
	dec a			;5966
	sub e			;5967   ; Y la distancia en X: si sale con acarreo, el disparo cae dentro
	ret			;5968
MUEVE_LOS_PERDIGONES:		; A los tres perdigones les resta su paso a la Y y les copia el patron del plato al que van
	ld de,0e104h		;5969
	ld hl,0e180h		;596c
	ld b,003h		;596f   ; Los tres perdigones
L_5971:
	ld c,(hl)			;5971
	inc hl			;5972
	ld a,(hl)			;5973
	sub c			;5974   ; La Y de 16 bits, menos el paso
	ld (hl),a			;5975
	inc hl			;5976
	jr nc,L_597A		;5977
	dec (hl)			;5979
L_597A:
	inc hl			;597a
	ld a,(de)			;597b   ; El patron sale de la ranura del plato
	ld (hl),a			;597c
	inc hl			;597d
	inc hl			;597e
	inc hl			;597f
	ld a,010h		;5980   ; 0x10 bytes: el perdigon siguiente
	add a,e			;5982
	ld e,a			;5983
	djnz L_5971		;5984
	ld de,0e0d4h		;5986
	ld hl,0e180h		;5989
	ld a,003h		;598c   ; Tres perdigones
COPIA_LAS_FICHAS:		; Los cuatro bytes de cada perdigon, a la tabla de fichas de 0xE0D4
	inc hl			;598e   ; Dos bytes de cabecera que no se copian
	inc hl			;598f
	ld bc,00004h		;5990
	ldir		;5993   ; Y sus cuatro bytes de ficha
	dec a			;5995
	jr nz,COPIA_LAS_FICHAS		;5996
	ret			;5998
APUNTA_LA_ESCOPETA:		; Deja el color y el patron de los dos canones, y los apunta al plato mas cercano a cada altura
	ld a,(0e170h)		;5999   ; Con la tanda acabada (E170 a cero), otro color
	and a			;599c
	ld a,006h		;599d
	jr z,L_59A3		;599f
	ld a,001h		;59a1
L_59A3:
	ld (0e0c3h),a		;59a3
	ld (0e0c7h),a		;59a6
	ld a,(0e174h)		;59a9   ; E174 elige el patron: cuatro por postura
	add a,a			;59ac
	add a,a			;59ad
	add a,004h		;59ae
	ld (0e0c2h),a		;59b0
	ld (0e0c6h),a		;59b3
	ld d,090h		;59b6   ; El canon de abajo busca alrededor de la Y 0x90...
	call PLATO_MAS_CERCANO		;59b8
	ld (0e0c0h),a		;59bb
	ld d,060h		;59be   ; ...y el de arriba, de la 0x60
	call PLATO_MAS_CERCANO		;59c0
	ld (0e0c4h),a		;59c3
	ret			;59c6
PLATO_MAS_CERCANO:		; De los tres platos, el que menos se aleje de la Y de D; si no hay ninguno, 0x90
	ld e,0ffh		;59c7   ; E arranca en 0xFF: la distancia mas grande posible
	ld b,003h		;59c9
	ld hl,0e100h		;59cb
L_59CE:
	ld a,(hl)			;59ce   ; Con la ranura vacia, se pasa de largo
	and a			;59cf
	inc hl			;59d0
	inc hl			;59d1
	inc hl			;59d2
	inc hl			;59d3
	jr z,L_59E3		;59d4
	ld a,d			;59d6
	sub (hl)			;59d7   ; La distancia, en valor absoluto
	jr nc,L_59DC		;59d8
	neg		;59da
L_59DC:
	cp e			;59dc   ; Y se queda con la menor
	jr nc,L_59E3		;59dd
	ld e,a			;59df
	ld (0e200h),hl		;59e0
L_59E3:
	ld a,00ch		;59e3   ; 0x0C bytes: la ranura siguiente
	add a,l			;59e5
	ld l,a			;59e6
	djnz L_59CE		;59e7
	ld hl,(0e200h)		;59e9
	dec hl			;59ec
	dec hl			;59ed
	ld a,(hl)			;59ee   ; Sin plato en esa ranura, la escopeta no apunta ahi
	and a			;59ef
	jr z,L_59F5		;59f0
	cp 090h		;59f2
	ret c			;59f4
L_59F5:
	ld a,090h		;59f5   ; Sin ningun plato, la escopeta se queda apuntando a 0x90
	ret			;59f7
DISPARA:		; Con el mando, dispara el canon que toque: el bit 3 el de arriba y los bits 2 y 4 el de abajo
	ld hl,0e043h		;59f8
	bit 3,(hl)		;59fb   ; Bit 3 del mando: el canon de arriba
	push hl			;59fd
	call nz,DISPARA_ABAJO		;59fe
	pop hl			;5a01
	ld a,(hl)			;5a02
	and 014h		;5a03   ; Bits 2 y 4: el de abajo
	ret z			;5a05
DISPARA_ARRIBA:		; El canon de arriba, el de 0xE0C4
	ld de,0e0c4h		;5a06
	inc a			;5a09
	jr UN_DISPARO		;5a0a
DISPARA_ABAJO:		; El de abajo, el de 0xE0C0
	ld de,0e0c0h		;5a0c
	xor a			;5a0f
UN_DISPARO:		; Apunta la escopeta, gasta un cartucho y mira si le da a alguno de los tres platos
	ld (0e178h),a		;5a10
	xor a			;5a13
	ld (0e1aah),a		;5a14   ; E1AA a cero: todavia no ha dado
	ld (0e203h),de		;5a17
	ld hl,0e172h		;5a1b
	ld a,(hl)			;5a1e
	and a			;5a1f   ; Sin cartuchos (E172 a cero) solo suena el clic
	ld a,08ch		;5a20
	jp z,SUENA_SI_SE_PUEDE		;5a22
	ld a,(0e1abh)		;5a25   ; Y con E1AB puesto tampoco se gasta: es el disparo de la demo
	and a			;5a28
	jr nz,L_5A2C		;5a29
	dec (hl)			;5a2b
L_5A2C:
	ld hl,0e100h		;5a2c
	ld a,(0e160h)		;5a2f   ; E160 es el margen de acierto: cuanto mas alto, mas facil
	ld c,a			;5a32
	ld b,003h		;5a33
L_5A35:
	push bc			;5a35
	push de			;5a36
	ld (0e200h),hl		;5a37   ; La ranura en curso se aparca en E200
	ld a,(hl)			;5a3a   ; Con la ranura vacia no hay plato al que dar
	and a			;5a3b
	jr z,L_5A52		;5a3c
	inc hl			;5a3e
	inc hl			;5a3f
	ld a,(de)			;5a40
	sub (hl)			;5a41
	sub 006h		;5a42   ; Seis de margen en la X...
	add a,c			;5a44
	jr nc,L_5A52		;5a45
	inc hl			;5a47
	inc hl			;5a48
	inc de			;5a49
	ld a,(de)			;5a4a
	sub (hl)			;5a4b
	sub 006h		;5a4c   ; ...y otros seis en la Y
	add a,c			;5a4e
	call c,HA_DADO		;5a4f
L_5A52:
	pop de			;5a52
	ld hl,(0e200h)		;5a53
	ld bc,00010h		;5a56   ; 0x10 bytes: la ranura siguiente
	add hl,bc			;5a59
	pop bc			;5a5a
	djnz L_5A35		;5a5b
	ld a,04eh		;5a5d   ; El sonido 0x4E: el disparo
	jp SUENA_SI_SE_PUEDE		;5a5f
HA_DADO:		; Apunta el impacto; con E1AB puesto solo cuenta, y si no, revienta el plato y saca el numero
	ld hl,0e1abh		;5a62
	ld a,(hl)			;5a65
	and a			;5a66   ; E1AB puesto: es el disparo de la demo, solo se apunta
	jr z,REVIENTA_Y_PUNTUA		;5a67
	inc a			;5a69
	dec hl			;5a6a
	ld (hl),a			;5a6b
	ret			;5a6c
REVIENTA_Y_PUNTUA:		; Cobra los puntos, suena, y busca hueco para el numerito que sale flotando
	call COBRA_EL_PLATO		;5a6d
	ld a,050h		;5a70   ; El sonido 0x50: el plato roto
	call SUENA_SI_SE_PUEDE		;5a72
	ld de,0e0e0h		;5a75
	ld hl,0e175h		;5a78
	ld b,002h		;5a7b   ; Dos huecos para los numeros que flotan
BUSCA_UN_HUECO:		; Recorre las ranuras hasta dar con una a cero y monta ahi la ficha que apunte E203
	ld a,(hl)			;5a7d
	and a			;5a7e
	jr z,L_5A88		;5a7f
	inc hl			;5a81
	inc de			;5a82   ; Cuatro bytes de ficha por ranura
	inc de			;5a83
	inc de			;5a84
	inc de			;5a85
	djnz BUSCA_UN_HUECO		;5a86
L_5A88:
	ld (hl),010h		;5a88   ; 0x10 fotogramas de vida
	ld hl,(0e203h)		;5a8a   ; El molde de la ficha
	ld a,(hl)			;5a8d
	add a,010h		;5a8e   ; 0x10 mas abajo que el molde
	ld (de),a			;5a90
	inc hl			;5a91
	inc de			;5a92
	ld a,(hl)			;5a93
	ld (de),a			;5a94
	inc de			;5a95
	ld a,(0e202h)		;5a96   ; El patron del numero sale de la tabla que empieza en el ret de 0x5AA5
	ld hl,l5aa5h		;5a99   ; OJO: la tabla se indexa DESDE el ret, asi que su entrada 0 es el propio opcode 0xC9
	call HL_MAS_A		;5a9c
	ld a,(hl)			;5a9f
	ld (de),a			;5aa0
	inc de			;5aa1
	ld a,001h		;5aa2
	ld (de),a			;5aa4
L_5AA5:
	ret			;5aa5

; ----------------------------------------------------------------------
; DATOS patrones_del_numero: Los patrones del numerito que sale al romper un
;   plato, uno por postura: 0x14, 0x18, 0x1C, 0x3C, 0x1C, 0x1C, 0x1C. La
;   indexa 0x5A96 desde el RET de 0x5AA5, asi que la entrada 0 es el propio
;   opcode 0xC9 y nunca se usa
;   0x5aa6..0x5aad  (7 bytes)
DATA_patrones_del_numero:
	defb 014h,018h,01ch,03ch,01ch,01ch,01ch	; 5aa6

; ======================================================================
; CODIGO 0x5aad..0x5b0b  (94 bytes)
; ======================================================================


COBRA_EL_PLATO:		; Suma al marcador lo que valga la postura en la que se rompio, y sube la dificultad
	ld hl,(0e200h)		;5aad   ; La ranura que se aparco en E200
	ld a,(hl)			;5ab0   ; Su postura, a E202
	ld (0e202h),a		;5ab1
	cp 004h		;5ab4   ; La postura 4 con E178 puesto marca E179
	jr nz,L_5AC5		;5ab6
	ex af,af'			;5ab8
	ld a,(0e178h)		;5ab9
	and a			;5abc
	ld a,001h		;5abd
	jr z,L_5AC4		;5abf
	ld (0e179h),a		;5ac1
L_5AC4:
	ex af,af'			;5ac4
L_5AC5:
	push af			;5ac5
	ld hl,l5b0ah		;5ac6   ; Otra tabla que arranca en un ret: lo que paga cada postura, en BCD
	call HL_MAS_A		;5ac9   ; Indexada por la postura
	ld a,(hl)			;5acc
	ld hl,0e088h		;5acd
	add a,(hl)			;5ad0
	daa			;5ad1   ; El daa: los puntos van en BCD
	ld (hl),a			;5ad2
	inc hl			;5ad3
	jr nc,L_5AD7		;5ad4
	inc (hl)			;5ad6
L_5AD7:
	pop af			;5ad7
	cp 005h		;5ad8   ; Por debajo de la postura 5, la ranura se borra
	call c,BORRA_LA_RANURA		;5ada
	ld hl,0e172h		;5add
	ld (hl),002h		;5ae0   ; Dos cartuchos otra vez
	inc hl			;5ae2
	inc (hl)			;5ae3
	bit 0,(hl)		;5ae4   ; Uno de cada dos impactos sube el nivel
	ret nz			;5ae6
	inc hl			;5ae7
	inc (hl)			;5ae8
	ld a,(hl)			;5ae9
	cp 004h		;5aea   ; El nivel tapa en 3
	jr c,L_5AF0		;5aec
	ld a,003h		;5aee
L_5AF0:
	ld (hl),a			;5af0
	add a,a			;5af1
	add a,00eh		;5af2   ; Y de el sale el margen de acierto: 0x0E, 0x10, 0x12 o 0x14
	ld (0e160h),a		;5af4
	ld hl,0e142h		;5af7
	ld a,020h		;5afa   ; La velocidad sube 0x20
	add a,(hl)			;5afc
	ld (hl),a			;5afd
	ret nc			;5afe
	inc hl			;5aff
	inc (hl)			;5b00
	ld a,(hl)			;5b01
	cp 004h		;5b02   ; Con tope en 4
	ret c			;5b04
	ld (hl),004h		;5b05
	dec hl			;5b07
	ld (hl),000h		;5b08
L_5B0A:
	ret			;5b0a

; ----------------------------------------------------------------------
; DATOS puntos_por_postura: Lo que paga cada postura al romper el plato, en
;   BCD: 01, 05, 10, 30, 10, 00, 00. Con el mismo apano: 0x5AC6 la indexa
;   desde el RET de 0x5B0A
;   0x5b0b..0x5b12  (7 bytes)
DATA_puntos_por_postura:
	defb 001h,005h,010h,030h,010h,000h,000h	; 5b0b

; ======================================================================
; CODIGO 0x5b12..0x5bb0  (158 bytes)
; ======================================================================


GASTA_LOS_NUMEROS:		; Los tres numeros que flotan pierden un fotograma de vida y, al acabarse, se aparcan
	ld hl,0e175h		;5b12
	ld de,0e0e0h		;5b15
	ld b,003h		;5b18
L_5B1A:
	dec (hl)			;5b1a
	jp p,L_5B22		;5b1b   ; Con la cuenta en negativo, el numero se apaga
	inc (hl)			;5b1e
	ld a,0e0h		;5b1f
	ld (de),a			;5b21
L_5B22:
	inc de			;5b22   ; Cuatro bytes por ficha
	inc de			;5b23
	inc de			;5b24
	inc de			;5b25
	inc hl			;5b26
	djnz L_5B1A		;5b27   ; Las que queden
	ret			;5b29
ARRANCA_LA_BARRA:		; La primera vez guarda la postura en E148, y luego sube la Y tres puntos por fotograma
	ld hl,0e116h		;5b2a
	ld a,(hl)			;5b2d
	or a			;5b2e   ; E116: solo la primera vez
	jr nz,L_5B3B		;5b2f
	inc a			;5b31
	ld (hl),a			;5b32
	ld a,(0e202h)		;5b33
	and 00fh		;5b36   ; El nibble bajo de E202: la fuerza del viento
	ld (0e148h),a		;5b38
L_5B3B:
	ld hl,0e0ddh		;5b3b
	inc (hl)			;5b3e   ; Tres puntos por fotograma
	inc (hl)			;5b3f
	inc (hl)			;5b40
	ret			;5b41
SUBE_EL_ANGULO:		; Con el boton, el angulo del rotulo ANGLE sube 0,28 grados en BCD y da la vuelta a los 4,00
	ld a,(0e112h)		;5b42
	or a			;5b45
	ret nz			;5b46
	ld a,(0e044h)		;5b47
	and 010h		;5b4a   ; Bit 4 del mando: el boton
	ret z			;5b4c
	ld hl,0e114h		;5b4d
	ld a,(hl)			;5b50
	dec hl			;5b51
	cp 010h		;5b52   ; Pasado el 0x10 el contador se reinicia
	jr c,L_5B5A		;5b54
	ld (hl),000h		;5b56
	jr L_5B6F		;5b58
L_5B5A:
	ld a,(hl)			;5b5a
	add a,028h		;5b5b   ; 0x28 en BCD: el angulo sube de 0,28 en 0,28 grados
	daa			;5b5d
	ld (hl),a			;5b5e   ; El resultado, otra vez a su sitio
	jr nc,L_5B6F		;5b5f
	inc hl			;5b61   ; Con acarreo, sube la cifra de las centenas
	ld a,(hl)			;5b62
	add a,001h		;5b63
	daa			;5b65
	ld (hl),a			;5b66
	dec hl			;5b67
	ld a,(hl)			;5b68
	cp 004h		;5b69   ; A los 4,00 grados, vuelta a empezar
	jr nz,L_5B6E		;5b6b
	xor a			;5b6d
L_5B6E:
	ld (hl),a			;5b6e
L_5B6F:
	ld a,(0e045h)		;5b6f
	and 010h		;5b72   ; Y hasta soltar el boton no se admite otro
	ret nz			;5b74
	inc a			;5b75
	ld (0e112h),a		;5b76
	ret			;5b79
CENTRA_EL_VIENTO:		; Del valor de E202 saca el viento, en valor absoluto y centrado en 0x80
	ld a,(0e202h)		;5b7a
	ld c,a			;5b7d
	and 00fh		;5b7e
	bit 7,c		;5b80   ; El bit 7 dice para que lado sopla
	jr z,L_5B86		;5b82
	neg		;5b84
L_5B86:
	add a,080h		;5b86   ; 0x80 es el centro: sin viento
	ld (0e204h),a		;5b88
	ret			;5b8b
CORRIGE_LA_DERIVA:		; Segun la altura, la deriva se va corrigiendo: cada tramo de la tabla de 0x5BB0 quita un punto
	ld hl,05bb0h		;5b8c
	ld de,0e148h		;5b8f   ; E148, el tramo por el que va
	ld a,(de)			;5b92
	call HL_MAS_A		;5b93
	ld a,(hl)			;5b96   ; La altura de ese tramo
	ld hl,0e0ddh		;5b97
	cp (hl)			;5b9a   ; Mientras no se pase de la altura del tramo, no toca
	ret nc			;5b9b
	ld a,(de)			;5b9c
	or a			;5b9d
	jr z,L_5BA1		;5b9e
	dec a			;5ba0
L_5BA1:
	ld (de),a			;5ba1
	ld hl,0e0dch		;5ba2   ; Y la deriva, que se corrige un punto
	ld a,(0e202h)		;5ba5
	or a			;5ba8
	jp p,L_5BAE		;5ba9   ; El signo de E202 dice hacia donde se corrige
	dec (hl)			;5bac
	ret			;5bad
L_5BAE:
	inc (hl)			;5bae
	ret			;5baf

; ----------------------------------------------------------------------
; DATOS ocho_de_5B8C: Ocho bytes que 0x5B8C indexa con (0xE148)
;   0x5bb0..0x5bb8  (8 bytes)
DATA_ocho_de_5B8C:
	defb 0f0h,0c8h,0b0h,098h,080h,068h,050h,038h	; 5bb0  .....hP8

; ======================================================================
; CODIGO 0x5bb8..0x5bcb  (19 bytes)
; ======================================================================


SIGUIENTE_VIENTO:		; Avanza el contador de E203 en redondo y saca de la tabla el viento nuevo
	ld hl,05bcbh		;5bb8
	ld de,0e203h		;5bbb
	ld a,(de)			;5bbe
	inc a			;5bbf
	and 00fh		;5bc0   ; Dieciseis valores en redondo
	ld (de),a			;5bc2
	call HL_MAS_A		;5bc3
	ld a,(hl)			;5bc6
	ld (0e202h),a		;5bc7
	ret			;5bca

; ----------------------------------------------------------------------
; DATOS dieciseis_vientos: Dieciseis valores de viento que 0x5BB8 recorre con
;   el contador de 0xE203, que da la vuelta con un and 0x0F: el bit 7 es el
;   lado y el nibble bajo la fuerza
;   0x5bcb..0x5bdb  (16 bytes)
DATA_dieciseis_vientos:
	defb 087h,083h,006h,001h,082h,085h,003h,007h,080h,084h,005h,002h,086h,081h,000h,004h	; 5bcb  ................

; ======================================================================
; CODIGO 0x5bdb..0x5d03  (296 bytes)
; ======================================================================


ANDA_DE_UN_LADO_A_OTRO:		; Un fotograma si y otro no: anda hacia un lado o hacia el otro, y al llegar al final remata
	ld a,(0e003h)		;5bdb
	and 001h		;5bde   ; Uno de cada dos fotogramas
	ret nz			;5be0
	ld hl,0e0dch		;5be1
	ld de,0e117h		;5be4
	ld a,(0e143h)		;5be7   ; E143 dice hacia donde anda
	or a			;5bea
	jr z,ANDA_A_LA_IZQUIERDA		;5beb
	ld a,(de)			;5bed
	or a			;5bee
	jr z,L_5BF2		;5bef
	dec (hl)			;5bf1
L_5BF2:
	ld hl,0e0c4h		;5bf2
	dec (hl)			;5bf5
	ld a,(hl)			;5bf6
	cp 029h		;5bf7   ; Pasado el 0x29 por la izquierda se para
	jp nc,SIGUE		;5bf9
	jr REMATA_EL_PASO		;5bfc
ANDA_A_LA_DERECHA:		; La X sube, y con la marca de E117 tambien la del cuerpo
	ld a,(de)			;5bfe
	or a			;5bff
	jr z,L_5C03		;5c00
	inc (hl)			;5c02
L_5C03:
	ld hl,0e0c4h		;5c03
	inc (hl)			;5c06
	ld a,(hl)			;5c07
	cp 0afh		;5c08   ; Y el tope por la derecha es 0xAF
	ret			;5c0a
ANDA_A_LA_IZQUIERDA:		; El otro sentido
	call ANDA_A_LA_DERECHA		;5c0b
	jp c,SIGUE		;5c0e
REMATA_EL_PASO:		; Coloca las seis fichas, elige el motor que toca y deja ocho fotogramas de espera
	call PINTA_EL_ROTULO_DEL_TIRO		;5c11
	ld a,(0e111h)		;5c14
	or a			;5c17   ; E111 a cero: es la primera vez
	jr nz,L_5C3B		;5c18
	ld a,0c0h		;5c1a
	ld (0e0c4h),a		;5c1c
	ld (0e0dch),a		;5c1f
	ld a,(0e145h)		;5c22
	and a			;5c25   ; E145 elige entre los dos remates
	jr z,L_5C30		;5c26
	ld a,008h		;5c28
	ld (0e111h),a		;5c2a
	jp SUBE_EL_PASO_Y_ARRANCA		;5c2d
L_5C30:
	ld a,003h		;5c30
	ld (0e111h),a		;5c32
	ld (0e147h),a		;5c35
	call COLOCA_LAS_SEIS_FICHAS		;5c38
L_5C3B:
	ld de,06635h		;5c3b   ; La lista de 0x6635
	call PINTA_LISTA		;5c3e
	ld a,01bh		;5c41
	ld (0e0ddh),a		;5c43
	ld a,073h		;5c46
	ld (0e0dch),a		;5c48
	xor a			;5c4b
	ld hl,0e112h		;5c4c
	ld b,00bh		;5c4f   ; Once bytes de E112 a cero
L_5C51:
	ld (hl),a			;5c51
	inc hl			;5c52
	djnz L_5C51		;5c53
	ld hl,0e111h		;5c55
	dec (hl)			;5c58
	ld hl,0e143h		;5c59
	ld a,(hl)			;5c5c
	cpl			;5c5d   ; E143 se invierte: la vuelta siguiente anda al reves
	ld (hl),a			;5c5e
	ld a,008h		;5c5f
	ld (0e004h),a		;5c61   ; Ocho fotogramas
	ld a,08ch		;5c64   ; El sonido 0x8C
	call ARRANCA_EL_EFECTO		;5c66
	xor a			;5c69
	ret			;5c6a
SIGUE:		; Sale con el bit 0 puesto
	or 001h		;5c6b
	ret			;5c6d
MIRA_SI_DA_EN_LA_DIANA:		; Si cae dentro de los 0x27 puntos de la diana, acierta: suena y coloca los dos sprites
	ld a,(0e0c4h)		;5c6e
	dec a			;5c71
	ld b,a			;5c72
	add a,027h		;5c73   ; 0x27 de ancho tiene la diana
	ld c,a			;5c75
	ld a,(0e204h)		;5c76
	cp b			;5c79
	ret c			;5c7a   ; Por fuera, no la toca
	cp c			;5c7b
	ret nc			;5c7c
	ld a,001h		;5c7d
	ld (0e117h),a		;5c7f   ; E117 y E119 a uno: ha acertado
	ld (0e119h),a		;5c82
	ld a,008h		;5c85   ; El sonido 0x08
	call ARRANCA_EL_EFECTO		;5c87
	ld b,0a4h		;5c8a
	ld a,(0e0c4h)		;5c8c
	ld c,a			;5c8f
	ld a,(0e204h)		;5c90
	sub c			;5c93   ; La X del sprite, relativa a donde esta la diana
	add a,b			;5c94
	ld (0e0c1h),a		;5c95
	call ALTURA_DE_LA_FLECHA		;5c98
	ld (0e0c0h),a		;5c9b
	ret			;5c9e
ALTURA_DE_LA_FLECHA:		; Su Y sale de 0x67 menos dos tramos: cuatro puntos por cada paso de E114 y otros pocos por E113
	ld c,000h		;5c9f
	ld a,(0e114h)		;5ca1
	cp 010h		;5ca4   ; El 0x10 cuenta como diez
	jr nz,CUATRO_POR_PASO		;5ca6
	ld a,00ah		;5ca8
CUATRO_POR_PASO:		; Cuatro puntos por cada paso que lleve
	or a			;5caa   ; Sin pasos que quedar, se sale
	jr z,L_5CB4		;5cab
	dec a			;5cad
	inc c			;5cae   ; Cuatro puntos por paso
	inc c			;5caf
	inc c			;5cb0
	inc c			;5cb1
	jr CUATRO_POR_PASO		;5cb2
L_5CB4:
	ld b,003h		;5cb4   ; Tres tramos como mucho
	ld a,(0e113h)		;5cb6
	cp 077h		;5cb9   ; Tres tramos por la altura de E113: 0x77, 0x50 y 0x25
	jr nc,L_5CC8		;5cbb
	dec b			;5cbd
	cp 050h		;5cbe
	jr nc,L_5CC8		;5cc0
	dec b			;5cc2
	cp 025h		;5cc3
	jr nc,L_5CC8		;5cc5
	dec b			;5cc7
L_5CC8:
	ld a,067h		;5cc8   ; 0x67 es la Y del suelo
	sub b			;5cca
	sub c			;5ccb
	sub 004h		;5ccc   ; Y cuatro puntos mas de la ficha
	ret			;5cce

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL ACIERTO DEL ARCO, SIN RAIZ CUADRADA. La distancia al centro de la
; diana se calcula con Pitagoras, pero el cartucho no saca la raiz:
; eleva al cuadrado las dos diferencias -0x5D0C, con ocho sumas-, las
; suma, y compara ese cuadrado contra la tabla de 0x5D03, que son los
; radios de los anillos YA ELEVADOS AL CUADRADO. El anillo que sale
; indexa los puntos de 0x5D37.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
QUE_ANILLO_HA_TOCADO:		; Suma los cuadrados de las dos distancias al centro y busca en que anillo cae
	ld a,(0e0c1h)		;5ccf
	add a,004h		;5cd2
	ld b,a			;5cd4
	ld a,0bch		;5cd5   ; El centro de la diana en X, 0xBC
	call CUADRADO_DE_LA_DIFERENCIA		;5cd7
	push hl			;5cda
	ld a,(0e0c0h)		;5cdb
	add a,004h		;5cde
	ld b,a			;5ce0
	ld a,053h		;5ce1   ; Y en Y, 0x53
	call CUADRADO_DE_LA_DIFERENCIA		;5ce3
	pop de			;5ce6
	add hl,de			;5ce7   ; Los dos cuadrados, sumados: la distancia al centro, al cuadrado
	ld b,009h		;5ce8
	ld de,05d03h		;5cea   ; La tabla de radios al cuadrado, nueve anillos
BUSCA_EL_ANILLO:		; Compara con cada radio hasta pasarse
	xor a			;5ced   ; El byte alto del radio: cero en los ocho primeros
	djnz L_5CF1		;5cee
	inc a			;5cf0   ; Y uno en el noveno, el 0x121, que no cabe en un byte
L_5CF1:
	inc b			;5cf1
	cp h			;5cf2   ; Compara el cuadrado de la distancia contra el radio, primero el byte alto
	jr c,L_5CFB		;5cf3
	jr nz,L_5CFE		;5cf5
	ld a,(de)			;5cf7
	cp l			;5cf8   ; Y luego el bajo
	jr nc,L_5CFE		;5cf9
L_5CFB:
	inc de			;5cfb
	djnz BUSCA_EL_ANILLO		;5cfc
L_5CFE:
	ld a,b			;5cfe
	ld (0e11ch),a		;5cff   ; E11C: el anillo, del 0 -el aro de fuera- al 9 -el centro-
	ret			;5d02

; ----------------------------------------------------------------------
; DATOS radios_al_cuadrado: Los nueve anillos de la diana, con su radio YA
;   ELEVADO AL CUADRADO: 1, 6, 16, 25, 64, 96, 144, 196 y 289. El ultimo no
;   cabe en un byte, y por eso 0x5CED le pone el 1 de arriba a mano
;   0x5d03..0x5d0c  (9 bytes)
DATA_radios_al_cuadrado:
	defb 001h,006h,010h,019h,040h,060h,090h,0c4h,021h	; 5d03  ....@`..!

; ======================================================================
; CODIGO 0x5d0c..0x5d37  (43 bytes)
; ======================================================================


CUADRADO_DE_LA_DIFERENCIA:		; A menos B en valor absoluto, elevado al cuadrado con ocho sumas y desplazamientos
	sub b			;5d0c
	jp p,L_5D11		;5d0d   ; Valor absoluto: da igual de que lado del centro caiga
	neg		;5d10   ; El valor absoluto de la diferencia
	ld h,a			;5d12
	ld e,a			;5d13   ; El mismo numero en DE y en H: se multiplica por si mismo
	ld l,000h		;5d14
	ld d,l			;5d16
	ld b,008h		;5d17   ; Ocho bits
MULTIPLICA_OCHO_BITS:		; Ocho vueltas de desplazar y sumar: el clasico
	add hl,hl			;5d19   ; Desplaza...
	jr nc,L_5D1D		;5d1a
	add hl,de			;5d1c   ; ...y suma cuando sale acarreo
L_5D1D:
	djnz MULTIPLICA_OCHO_BITS		;5d1d
	ret			;5d1f
COBRA_EL_TIRO:		; Busca el anillo y deja en E11D los dos bytes en BCD que paga, sacados de la tabla de 0x5D37
	call QUE_ANILLO_HA_TOCADO		;5d20
	ld de,0e11dh		;5d23   ; E11D, donde se deja lo que paga
	ld hl,05d37h		;5d26   ; La tabla de diez palabras
	ld a,(0e11ch)		;5d29   ; E11C, el anillo que ha tocado
	add a,a			;5d2c   ; Por dos: son palabras
	call HL_MAS_A		;5d2d
	ld a,(hl)			;5d30
	ld (de),a			;5d31
	inc hl			;5d32
	inc de			;5d33
	ld a,(hl)			;5d34
	ld (de),a			;5d35
	ret			;5d36

; ----------------------------------------------------------------------
; DATOS puntos_por_anillo: Lo que paga cada anillo, en BCD: 10, 100, 170, 210,
;   250, 290, 320, 350, 400 y 600. Del centro hacia fuera, al reves: el 0x0010
;   es el aro de fuera
;   0x5d37..0x5d4b  (20 bytes)
DATA_puntos_por_anillo:
	defw 00010h	; 5d37
	defw 00100h	; 5d39
	defw 00170h	; 5d3b
	defw 00210h	; 5d3d
	defw 00250h	; 5d3f
	defw 00290h	; 5d41
	defw 00320h	; 5d43
	defw 00350h	; 5d45
	defw 00400h	; 5d47
	defw 00600h	; 5d49

; ======================================================================
; CODIGO 0x5d4b..0x5e59  (270 bytes)
; ======================================================================


SUMA_LO_QUE_VALE:		; Suma a los puntos del intento los dos bytes en BCD del anillo
	ld hl,0e087h		;5d4b
	ld de,0e11dh		;5d4e
	ld b,002h		;5d51   ; Dos bytes en BCD
	and a			;5d53   ; Y sin acarreo de entrada
L_5D54:
	ld a,(de)			;5d54
	adc a,(hl)			;5d55
	daa			;5d56
	ld (hl),a			;5d57   ; Y de vuelta a su sitio
	inc hl			;5d58
	inc de			;5d59
	djnz L_5D54		;5d5a
	ld a,000h		;5d5c   ; El tercer byte solo recoge el acarreo
	adc a,(hl)			;5d5e
	ld (hl),a			;5d5f
	ret			;5d60
PINTA_EL_ANGULO:		; Las tres cifras del angulo, en el rotulo ANGLE de la fila 10: los dos decimales de E113 y la unidad de E114
	ld de,0e113h		;5d61
	ld hl,03950h		;5d64   ; Fila 10, columna 16
	ld b,001h		;5d67
	ld c,0ffh		;5d69
	call PINTA_LAS_CIFRAS_DE_DE		;5d6b
	ld de,0e114h		;5d6e
	ld hl,0394dh		;5d71   ; Y la de al lado, tres casillas antes
	ld b,001h		;5d74
	jp PINTA_CIFRAS_SIN_CEROS		;5d76
PINTA_EL_VIENTO:		; La cifra del viento y, al lado, la flecha que dice hacia que lado sopla: el rotulo WIND
	ld hl,03acfh		;5d79
	ld de,0e202h		;5d7c
	ld a,(de)			;5d7f
	and 00fh		;5d80
	add a,010h		;5d82   ; 0x10 es el tile del cero
	call VPOKE		;5d84
	dec hl			;5d87
	ld a,(de)			;5d88
	add a,a			;5d89   ; El bit 7 elige entre los tiles 0x57 y 0x58: la flecha a un lado o al otro
	ld a,058h		;5d8a
	jr nc,L_5D8F		;5d8c
	dec a			;5d8e
L_5D8F:
	jp VPOKE		;5d8f
PINTA_LOS_PUNTOS_DEL_TIRO:		; Los puntos del ultimo tiro, que parpadean mientras E119 este puesto
	ld hl,03ad5h		;5d92
	ld a,(0e119h)		;5d95
	or a			;5d98
	jr z,L_5DA8		;5d99
	ld a,(0e003h)		;5d9b
	bit 4,a		;5d9e   ; Bit 4 del contador: se apagan la mitad del tiempo
	jr z,L_5DA8		;5da0
	ld bc,00004h		;5da2   ; Cuatro casillas a cero: la marca se borra
	jp RELLENA_CON_CERO		;5da5
L_5DA8:
	ld de,0e11eh		;5da8   ; Y si no, las dos cifras de E11E
	ld b,002h		;5dab
	jp PINTA_CIFRAS_SIN_CEROS		;5dad
PARPADEA_AL_ACERTAR:		; Cambia el color cada ocho fotogramas mientras E119 este puesto
	ld b,000h		;5db0
	ld hl,0e0c3h		;5db2   ; E0C3, el color de la primera ficha
	ld a,(0e119h)		;5db5   ; E119: solo mientras este puesto
	or a			;5db8
	jr z,L_5DC2		;5db9
	ld a,(0e003h)		;5dbb
	bit 3,a		;5dbe   ; Bit 3: ocho fotogramas con cada color
	jr nz,L_5DC3		;5dc0
L_5DC2:
	inc b			;5dc2
L_5DC3:
	ld (hl),b			;5dc3
	ret			;5dc4
PINTA_LA_BARRA_DE_FUERZA:		; La barra de la fila 12: los tramos llenos, medio tramo si sobra, y el resto vacio
	ld hl,03985h		;5dc5   ; Fila 12, columna 5
	ld a,(0e111h)		;5dc8
	or a			;5dcb
	rra			;5dcc   ; E111 entre dos: cada tramo son dos unidades
	push af			;5dcd
	ld b,a			;5dce
	sub 004h		;5dcf
	neg		;5dd1
	ld c,a			;5dd3
	ld a,04ch		;5dd4   ; El tile 0x4C es el tramo lleno
	call PINTA_HACIA_ARRIBA		;5dd6
	pop af			;5dd9
	jr nc,L_5DE3		;5dda
	ld a,079h		;5ddc   ; Y el 0x79 el medio tramo, cuando la cuenta era impar
	call VPOKE		;5dde
	add hl,de			;5de1
	dec c			;5de2
L_5DE3:
	ld b,c			;5de3
	xor a			;5de4
	jp PINTA_HACIA_ARRIBA		;5de5
AVANZA_Y_REMATA:		; Un fotograma si y otro no: alterna los dos patrones, corre la X a la derecha y, al llegar al tope, coloca las seis fichas
	ld a,(0e003h)		;5de8
	and 001h		;5deb   ; Uno de cada dos
	ret nz			;5ded
	call ALTERNA_DOS_PATRONES		;5dee   ; Los dos patrones alternos
	ld hl,0e0dch		;5df1
	ld de,0e117h		;5df4
	call ANDA_A_LA_DERECHA		;5df7   ; Y un punto a la derecha
	jp c,SIGUE		;5dfa
	call COLOCA_LAS_SEIS_FICHAS		;5dfd   ; Al llegar, las seis fichas otra vez
	ld a,(0e111h)		;5e00
	and a			;5e03
	jp nz,L_5C3B		;5e04
	ld a,0c0h		;5e07
	ld (0e0dch),a		;5e09
	jp SUBE_EL_PASO_Y_ARRANCA		;5e0c
MIRA_SI_ACIERTA:		; Si E204 cae en los ocho puntos por encima de (0xE0C4), pone el patron 0x7C, marca E117 y suena
	ld a,(0e0c4h)		;5e0f
	add a,008h		;5e12   ; Ocho de margen a cada lado
	ld b,a			;5e14
	add a,008h		;5e15   ; Ocho mas: el otro extremo
	ld c,a			;5e17
	ld a,(0e204h)		;5e18   ; E204, el viento centrado
	cp b			;5e1b
	ret c			;5e1c   ; Fuera de los ocho puntos, no vale
	cp c			;5e1d
	ret nc			;5e1e
	xor a			;5e1f
	ld hl,0e11dh		;5e20   ; E11D y E11E a cero
	ld (hl),a			;5e23
	inc hl			;5e24
	ld a,07ch		;5e25   ; El patron 0x7C y el color 0x30
	ld c,030h		;5e27
	ld (0e0d6h),a		;5e29
	ld (hl),c			;5e2c
	ld (0e117h),a		;5e2d
	ld a,096h		;5e30   ; El sonido 0x96
	jp ARRANCA_EL_EFECTO		;5e32
ALTERNA_DOS_PATRONES:		; Los patrones de 0xE0CA y 0xE0D2 cambian cada ocho fotogramas entre 0x68/0x70 y 0x74/0x78
	ld b,068h		;5e35
	ld c,070h		;5e37
	ld a,(0e003h)		;5e39
	bit 3,a		;5e3c   ; Bit 3: ocho y ocho
	jr z,L_5E44		;5e3e
	ld b,074h		;5e40
	ld c,078h		;5e42
L_5E44:
	ld a,b			;5e44   ; Los patrones van a las fichas de E0CA y E0D2
	ld (0e0cah),a		;5e45
	ld a,c			;5e48
	ld (0e0d2h),a		;5e49
	ret			;5e4c
COLOCA_LAS_SEIS_FICHAS:		; Las seis fichas de sprite de 0x5E59, tal cual
	ld hl,05e59h		;5e4d   ; El molde de las seis fichas
	ld de,0e0c4h		;5e50
	ld bc,00018h		;5e53   ; 0x18 bytes: seis fichas
	ldir		;5e56
	ret			;5e58

; ----------------------------------------------------------------------
; DATOS veinticuatro_a_e0c4: Los 0x18 bytes que 0x5E4D copia con un ldir a
;   0xE0C4: seis fichas de sprite
;   0x5e59..0x5e71  (24 bytes)
DATA_veinticuatro_a_e0c4:
	defb 020h,0e8h,064h,006h	; 5e59
	defb 030h,0e4h,068h,004h	; 5e5d
	defb 030h,0e4h,06ch,00fh	; 5e61
	defb 030h,0e4h,070h,00ah	; 5e65
	defb 005h,0e4h,018h,00fh	; 5e69
	defb 0c0h,000h,018h,000h	; 5e6d

; ======================================================================
; CODIGO 0x5e71..0x5e8b  (26 bytes)
; ======================================================================


ARRANCA_LA_CEREMONIA:		; Las dos poses de la figura (0x5E8B y 0x5EA3) y la segunda copiada ya a la zona de trabajo
	ld hl,05e8bh		;5e71
	ld de,05ea3h		;5e74
	call ARRANCA_LA_ANIMACION		;5e77
	ld hl,05ea3h		;5e7a
	ld de,0e222h		;5e7d
	ld bc,00018h		;5e80
	ldir		;5e83
	ld a,07fh		;5e85
	ld (0e236h),a		;5e87   ; E236 = 0x7F
	ret			;5e8a

; ----------------------------------------------------------------------
; DATOS tabla_5E8B: Veinticuatro bytes que 0x5E71 pasa como primero de los dos
;   punteros de 0x54C7
;   0x5e8b..0x5ea3  (24 bytes)
DATA_tabla_5E8B:
	defb 07bh,014h,044h,00bh	; 5e8b
	defb 085h,017h,048h,004h	; 5e8f
	defb 08ch,012h,04ch,006h	; 5e93
	defb 08fh,015h,050h,00bh	; 5e97
	defb 07eh,018h,02ch,006h	; 5e9b
	defb 07ch,011h,008h,000h	; 5e9f

; ----------------------------------------------------------------------
; DATOS tabla_a_e222: Los veinticuatro bytes que 0x5E7A copia con un ldir a
;   0xE222, y que 0x5E74 pasa como segundo puntero
;   0x5ea3..0x5ebb  (24 bytes)
DATA_tabla_a_e222:
	defb 080h,015h,030h,00bh	; 5ea3
	defb 086h,018h,038h,004h	; 5ea7
	defb 08eh,019h,03ch,006h	; 5eab
	defb 092h,019h,040h,00bh	; 5eaf
	defb 07eh,018h,02ch,006h	; 5eb3
	defb 088h,021h,034h,00bh	; 5eb7

; ======================================================================
; CODIGO 0x5ebb..0x5f4e  (147 bytes)
; ======================================================================


SIGUE_LA_CEREMONIA:		; Otro paso de la figura
	jp MUEVE_LA_FIGURA		;5ebb
PARPADEA_LA_FIGURA:		; Cambia el patron cada 32 fotogramas y sube las fichas
	ld hl,0e238h		;5ebe
	ld a,(0e003h)		;5ec1
	and 020h		;5ec4   ; Bit 5: 32 y 32
	ld a,054h		;5ec6
	jr z,L_5ECC		;5ec8
	ld a,058h		;5eca
L_5ECC:
	ld (hl),a			;5ecc
SUBE_LAS_SEIS_FICHAS:		; Los 0x18 bytes de E222 a la tabla de sprites, y el corte detras
	ld hl,03b00h		;5ecd
	ld de,0e222h		;5ed0
	ld c,018h		;5ed3
	call COPIA_256		;5ed5
	ld hl,03b18h		;5ed8
	ld a,0d0h		;5edb   ; 0xD0 en la Y de la septima: el VDP para ahi
	call VPOKE		;5edd
	or 0ffh		;5ee0
	ret			;5ee2
CUENTA_ATRAS_DEL_DISPARO:		; Baja el contador de recarga y, con el mando, deja apuntado que canon dispara
	ld hl,0e150h		;5ee3   ; E150, el contador de recarga
	ld a,(hl)			;5ee6
	and a			;5ee7
	jr z,L_5EEB		;5ee8
	dec a			;5eea
L_5EEB:
	ld (hl),a			;5eeb   ; Y al llegar a cero, el de al lado tambien
	inc hl			;5eec
	jr nz,L_5EF0		;5eed
	ld (hl),a			;5eef
L_5EF0:
	ld a,(0e170h)		;5ef0   ; Con la tanda acabada no se dispara
	and a			;5ef3
	ret nz			;5ef4
	ld a,(0e043h)		;5ef5
	and 01ch		;5ef8   ; Los bits 2, 3 y 4 del mando
	ret z			;5efa
	bit 3,a		;5efb
	jr z,L_5F01		;5efd   ; Bit 3: el canon de arriba
	ld (hl),001h		;5eff
L_5F01:
	and 014h		;5f01   ; Bits 2 y 4: el de abajo
	jr z,L_5F07		;5f03
	ld (hl),002h		;5f05
L_5F07:
	dec hl			;5f07
	ld (hl),008h		;5f08   ; Ocho fotogramas de recarga
	ret			;5f0a
PINTA_LA_ESCOPETA:		; Sube el dibujo que toque -cuatro tiles por fila, cinco filas- y coloca su sprite
	ld a,(0e151h)		;5f0b
	cp 003h		;5f0e   ; Cuatro dibujos, del 0 al 3
	push af			;5f10
	jr c,L_5F15		;5f11
	ld a,003h		;5f13
L_5F15:
	add a,a			;5f15
	ld hl,05f4eh		;5f16
	call HL_MAS_A		;5f19
	ld e,(hl)			;5f1c
	inc hl			;5f1d
	ld d,(hl)			;5f1e
	ld hl,03a6eh		;5f1f   ; Fila 19, columna 14
	ld b,005h		;5f22   ; Cinco filas
L_5F24:
	push bc			;5f24
	ld c,004h		;5f25   ; Cuatro tiles por fila
	call COPIA_256		;5f27
	ld a,020h		;5f2a   ; Y la fila de abajo, 32 casillas mas alla
	call HL_MAS_A		;5f2c
	pop bc			;5f2f
	djnz L_5F24		;5f30   ; Cinco filas
	call PINTA_LISTA		;5f32
	pop af			;5f35
	sub 003h		;5f36
	ld c,001h		;5f38
	jr nc,L_5F3D		;5f3a
	dec c			;5f3c
L_5F3D:
	add a,a			;5f3d   ; Por cuatro y mas 0x20: la X del humo
	add a,a			;5f3e
	add a,020h		;5f3f
	ld hl,0e0ech		;5f41
	ld (hl),0a3h		;5f44   ; El sprite del humo: patron 0xA3, color 0x7D
	inc hl			;5f46
	ld (hl),07dh		;5f47
	inc hl			;5f49
	ld (hl),a			;5f4a
	inc hl			;5f4b
	ld (hl),c			;5f4c
	ret			;5f4d

; ----------------------------------------------------------------------
; DATOS tabla_de_las_escopetas: Cuatro punteros a los cuatro dibujos de la
;   escopeta, que 0x5F16 indexa por dos con (0xE151) topando en 3: 0x5F90,
;   0x5F56, 0x5F73 y 0x5FAD
;   0x5f4e..0x5f56  (8 bytes)
DATA_tabla_de_las_escopetas:
	defw 05f90h	; 5f4e  -> DATA_escopeta_0
	defw 05f56h	; 5f50  -> DATA_escopeta_1
	defw 05f73h	; 5f52  -> DATA_escopeta_2
	defw 05fadh	; 5f54  -> DATA_escopeta_3

; ----------------------------------------------------------------------
; DATOS escopeta_1: El dibujo de una postura: cinco filas de cuatro tiles, que
;   0x5F24 sube de cuatro en cuatro a la VRAM 0x3A6E
;   0x5f56..0x5f73  (29 bytes)
DATA_escopeta_1:
	defb 067h,067h,0a5h,09ah	; 5f56
	defb 08fh,091h,0bdh,0beh	; 5f5a
	defb 090h,092h,08bh,04fh	; 5f5e
	defb 0bah,0bfh,0c0h,0bch	; 5f62
	defb 080h,081h,07eh,086h	; 5f66
	defb 04dh,03ah,052h,052h	; 5f6a
	defb 052h,052h,04ah,04bh	; 5f6e
	defb 0ffh	; 5f72

; ----------------------------------------------------------------------
; DATOS escopeta_2: Otra postura, con el mismo reparto
;   0x5f73..0x5f90  (29 bytes)
DATA_escopeta_2:
	defb 09bh,0a6h,067h,067h	; 5f73
	defb 09ch,096h,097h,074h	; 5f77
	defb 08ah,099h,098h,075h	; 5f7b
	defb 085h,08dh,08ch,0b1h	; 5f7f
	defb 069h,082h,083h,084h	; 5f83
	defb 04dh,03ah,04ah,04bh	; 5f87
	defb 052h,052h,052h,052h	; 5f8b
	defb 0ffh	; 5f8f

; ----------------------------------------------------------------------
; DATOS escopeta_0: La de reposo, que es la entrada 0 de la tabla
;   0x5f90..0x5fad  (29 bytes)
DATA_escopeta_0:
	defb 067h,067h,076h,067h	; 5f90
	defb 072h,0a1h,094h,073h	; 5f94
	defb 077h,0a2h,095h,052h	; 5f98
	defb 0b0h,08eh,089h,087h	; 5f9c
	defb 069h,07fh,0bbh,088h	; 5fa0
	defb 04dh,03ah,052h,052h	; 5fa4
	defb 052h,052h,052h,052h	; 5fa8
	defb 0ffh	; 5fac

; ----------------------------------------------------------------------
; DATOS escopeta_3: La ultima, la del disparo
;   0x5fad..0x5fc5  (24 bytes)
DATA_escopeta_3:
	defb 067h,067h,076h,067h	; 5fad
	defb 04ch,0c1h,0c2h,0c3h	; 5fb1
	defb 04dh,0c4h,0c5h,04eh	; 5fb5
	defb 0b0h,0c6h,0c7h,087h	; 5fb9
	defb 069h,07fh,0bbh,088h	; 5fbd
	defb 04dh,03ah,052h,0ffh	; 5fc1

; ======================================================================
; CODIGO 0x5fc5..0x6021  (92 bytes)
; ======================================================================


COLOCA_LA_BARRA:		; Con E105 en 0x12 o mas, saca las fichas de la tabla de 0x7CDA; si no, las calcula corriendo la Y
	ld a,(0e105h)		;5fc5
	cp 012h		;5fc8   ; Por debajo de 0x12 no hay tabla: se calculan
	jr c,CALCULA_LAS_FICHAS		;5fca
	add a,a			;5fcc
	ld hl,07cb6h		;5fcd   ; La tabla de fichas, indexada por dos
	call HL_MAS_A		;5fd0
	ld e,(hl)			;5fd3   ; El puntero de la pose
	inc hl			;5fd4
	ld d,(hl)			;5fd5
	ex de,hl			;5fd6
	ld c,(hl)			;5fd7   ; El primer byte es la cuenta
	inc hl			;5fd8
	ld b,000h		;5fd9
	ld de,0e0c0h		;5fdb   ; Y las fichas van a 0xE0C0
	ld a,(0e105h)		;5fde
	cp 01dh		;5fe1   ; En el 0x1D las fichas van a 0xE0C8 en vez de a 0xE0C0
	jr nz,L_5FE7		;5fe3
	ld e,0c8h		;5fe5
L_5FE7:
	ldir		;5fe7
CIERRA_LAS_FICHAS:		; 0xD0 en la Y de la siguiente, y con E133 puesto anade las cinco de 0x6021
	ld a,0d0h		;5fe9
	ld (de),a			;5feb
	ld a,(0e133h)		;5fec
	and a			;5fef
	ret z			;5ff0
	ld hl,06021h		;5ff1
	ld bc,00005h		;5ff4   ; Cinco bytes mas de ficha
	ldir		;5ff7
	ret			;5ff9
CALCULA_LAS_FICHAS:		; Diez fichas, cada una con la Y corrida por lo que falte para 0x12
	ld hl,06026h		;5ffa
	neg		;5ffd   ; En negativo: lo que le falta a la barra para llegar
	ld c,a			;5fff
	ld b,00ah		;6000   ; Diez fichas
	ld de,0e0c0h		;6002
L_6005:
	ld a,(hl)			;6005   ; La Y, corrida por lo que falte
	add a,c			;6006
	ld (de),a			;6007
	inc hl			;6008
	inc de			;6009
	ld a,(hl)			;600a   ; Y los otros tres bytes de la ficha, tal cual
	ld (de),a			;600b   ; El patron y el color, tal cual
	inc hl			;600c
	inc de			;600d
	ld a,(hl)			;600e
	ld (de),a			;600f
	inc hl			;6010
	inc de			;6011
	ld a,(hl)			;6012
	ld (de),a			;6013
	inc hl			;6014
	inc de			;6015
	ld a,b			;6016
	cp 005h		;6017   ; De la quinta en adelante, la correccion se apaga
	jr nc,L_601D		;6019
	ld c,000h		;601b
L_601D:
	djnz L_6005		;601d
	jr CIERRA_LAS_FICHAS		;601f

; ----------------------------------------------------------------------
; DATOS rle_6021: Flujo comprimido con su direccion de VRAM delante: 682 bytes
;   de VRAM
;   0x6021..0x6244  (547 bytes)
DATA_rle_6021:
	defb 065h,07ah,0c0h,00fh,0d0h,083h,05bh,000h,001h,06fh,065h,00ch,00bh,06fh,065h,008h	; 6021  ez....[..oe..oe.
	defb 001h,077h,066h,010h,005h,06dh,061h,014h,00bh,07dh,061h,018h,00bh,083h,06bh,004h	; 6031  .wf..ma..}a...k.
	defb 001h,08eh,060h,03ch,005h,08eh,068h,03ch,005h,07eh,060h,038h,00bh,083h,000h,000h	; 6041  ..`<..h<.~`8....
	defb 022h,003h,000h,081h,048h,007h,000h,082h,048h,000h,010h,018h,006h,000h,082h,003h	; 6051  "...H...H.......
	defb 007h,006h,000h,002h,0ffh,006h,000h,082h,0c0h,0e0h,008h,007h,008h,0e0h,082h,007h	; 6061  ................
	defb 003h,004h,000h,084h,048h,000h,0ffh,0ffh,004h,000h,084h,048h,000h,0e0h,0c0h,004h	; 6071  ....H......H....
	defb 000h,089h,048h,000h,060h,03eh,060h,000h,060h,03eh,060h,003h,000h,081h,022h,003h	; 6081  ..H.`>`.`>`...".
	defb 000h,085h,001h,003h,000h,000h,022h,007h,000h,086h,022h,000h,000h,000h,080h,000h	; 6091  ......"...".....
	defb 008h,003h,008h,0c0h,087h,003h,003h,001h,000h,000h,000h,048h,007h,000h,089h,048h	; 60a1  ...........H...H
	defb 000h,0c0h,0c0h,080h,000h,000h,000h,048h,008h,000h,085h,020h,000h,070h,050h,070h	; 60b1  .......H... .pPp
	defb 005h,000h,084h,018h,03ch,07eh,0ffh,006h,03ch,090h,0ffh,07eh,03ch,018h,000h,000h	; 60c1  ....<~..<..~<...
	defb 000h,022h,000h,000h,001h,003h,007h,000h,000h,022h,007h,000h,086h,022h,000h,000h	; 60d1  ."......."..."..
	defb 080h,0c0h,0e0h,008h,007h,008h,0e0h,087h,007h,007h,003h,001h,000h,000h,048h,007h	; 60e1  ..............H.
	defb 000h,095h,048h,000h,0e0h,0e0h,0c0h,080h,000h,000h,048h,000h,000h,000h,022h,000h	; 60f1  ..H.......H...".
	defb 000h,001h,003h,003h,000h,000h,022h,007h,000h,086h,022h,000h,000h,080h,0c0h,0c0h	; 6101  ......"...".....
	defb 008h,003h,008h,0c0h,003h,003h,085h,001h,000h,000h,048h,000h,003h,0c0h,084h,080h	; 6111  ..........H.....
	defb 000h,000h,048h,007h,000h,094h,048h,000h,000h,000h,0ffh,0ffh,00fh,01eh,03ch,0f0h	; 6121  ..H...H.......<.
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,067h,005h,06ch,09ch,067h,000h,0cfh	; 6131  .cs{.ogc.g.l.g..
	defb 06ch,00ch,00fh,00ch,06ch,0cfh,000h,0eeh,00eh,00eh,0ceh,004h,000h,0eeh,000h,000h	; 6141  l...l...........
	defb 022h,000h,003h,007h,00fh,00fh,018h,038h,07ch,003h,0feh,08dh,07ch,038h,000h,000h	; 6151  "......8|...|8..
	defb 022h,000h,0c0h,0f0h,0fch,0fch,000h,000h,022h,003h,000h,084h,048h,080h,00fh,007h	; 6161  "......."...H...
	defb 004h,003h,092h,048h,000h,0e0h,0e0h,0c3h,003h,000h,000h,018h,018h,0fch,0ffh,0c7h	; 6171  ...H............
	defb 080h,080h,000h,048h,000h,003h,080h,003h,000h,088h,048h,000h,000h,000h,024h,000h	; 6181  ...H......H...$.
	defb 001h,001h,004h,003h,08eh,001h,003h,003h,001h,003h,000h,01ch,01ch,018h,003h,003h	; 6191  ................
	defb 000h,000h,018h,004h,000h,084h,060h,03eh,060h,000h,007h,000h,08bh,001h,000h,000h	; 61a1  ......`>`.......
	defb 000h,007h,01fh,07fh,0ffh,0ffh,000h,000h,005h,0ffh,089h,081h,000h,000h,000h,0e0h	; 61b1  ................
	defb 0f8h,0feh,0ffh,0ffh,007h,000h,086h,080h,001h,003h,007h,00fh,00fh,003h,01fh,088h	; 61c1  ................
	defb 0fch,0f0h,0e0h,0c0h,081h,083h,007h,00fh,003h,000h,081h,03ch,004h,0ffh,08dh,03fh	; 61d1  ...........<...?
	defb 00fh,007h,003h,081h,0c1h,0e0h,0f0h,080h,0c0h,0e0h,0f0h,0f0h,003h,0f8h,008h,03eh	; 61e1  ...............>
	defb 008h,01fh,082h,0c3h,081h,004h,000h,082h,081h,0c3h,008h,0f8h,008h,07ch,003h,01fh	; 61f1  .............|..
	defb 08dh,00fh,00fh,007h,007h,003h,00fh,007h,083h,081h,0c0h,0e0h,0f0h,0fch,004h,0ffh	; 6201  ................
	defb 081h,03ch,003h,000h,088h,0f0h,0e0h,0c1h,081h,003h,007h,00fh,03fh,003h,0f8h,086h	; 6211  .<..........?...
	defb 0f0h,0f0h,0e0h,0e0h,0c0h,001h,007h,000h,089h,0ffh,0ffh,07fh,01fh,007h,000h,000h	; 6221  ................
	defb 000h,081h,005h,0ffh,08bh,000h,000h,0ffh,0ffh,0feh,0f8h,0e0h,000h,000h,000h,080h	; 6231  ................
	defb 007h,000h,000h	; 6241

; ----------------------------------------------------------------------
; DATOS rle_6244: Flujo comprimido con su direccion de VRAM delante: 656 bytes
;   de VRAM
;   0x6244..0x6318  (212 bytes)
DATA_rle_6244:
	defb 008h,02ch,004h,000h,004h,02ch,004h,0f0h,004h,0fch,008h,0fch,004h,000h,004h,08ch	; 6244  .,...,..........
	defb 004h,000h,004h,08ch,004h,000h,014h,08ch,006h,08ch,002h,02ch,006h,08ch,002h,02ch	; 6254  ...........,...,
	defb 006h,08ch,002h,02ch,008h,0f0h,006h,02ch,002h,04ch,006h,02ch,002h,044h,006h,02ch	; 6264  ...,...,.L.,.D.,
	defb 018h,04ch,085h,02ch,02ch,000h,044h,044h,005h,02ch,006h,04ch,002h,02ch,020h,0f0h	; 6274  .L.,,.DD.,.L., .
	defb 005h,02ch,003h,0ach,005h,02ch,003h,0aah,005h,02ch,019h,0ach,002h,02ch,081h,000h	; 6284  .,...,...,...,..
	defb 003h,0aah,004h,02ch,006h,0ach,007h,02ch,003h,07ch,005h,02ch,083h,077h,077h,0ffh	; 6294  ...,...,.|.,.ww.
	defb 005h,02ch,019h,07ch,002h,02ch,006h,07ch,002h,02ch,002h,0ffh,002h,077h,004h,02ch	; 62a4  .,.|.,.|.,...w.,
	defb 002h,0ffh,006h,07ch,020h,06fh,004h,02ch,004h,05ch,081h,0fch,003h,01ch,003h,015h	; 62b4  ...| o.,.\......
	defb 081h,014h,004h,02ch,084h,05ch,05ch,05fh,04fh,007h,02ch,081h,00ch,003h,05ch,08fh	; 62c4  ...,.\\_O.,...\.
	defb 0fch,0fch,00ch,02ch,02ch,0f4h,0f4h,0f0h,0f0h,000h,000h,0fch,0fch,00fh,00fh,004h	; 62d4  ...,,...........
	defb 00ch,081h,02ch,007h,00ch,006h,02ch,007h,05ch,003h,0fch,002h,00ch,003h,0f4h,004h	; 62e4  ..,...,.\.......
	defb 0f0h,081h,0fch,008h,0f0h,030h,04eh,004h,04fh,00ch,06fh,004h,04fh,004h,06fh,010h	; 62f4  .....0N.O.o.O.o.
	defb 04eh,008h,06fh,008h,06bh,008h,06fh,010h,04eh,004h,06fh,004h,04fh,00ch,06fh,004h	; 6304  N.o.k.o.N.o.O.o.
	defb 04fh,030h,04eh,000h	; 6314

; ----------------------------------------------------------------------
; DATOS flujo_6318: Flujo comprimido con su direccion de VRAM delante: 1027
;   bytes de VRAM
;   0x6318..0x64c5  (429 bytes)
DATA_flujo_6318:
	defb 002h,001h,005h,003h,004h,007h,005h,00fh,017h,000h,004h,004h,005h,00ch,03bh,000h	; 6318  ..............;.
	defb 085h,0c0h,060h,03fh,060h,0c0h,00ch,000h,08bh,020h,0f0h,020h,000h,000h,042h,024h	; 6328  ..`?`.... . ..B$
	defb 018h,018h,024h,042h,019h,000h,081h,007h,005h,003h,002h,001h,038h,000h,008h,01fh	; 6338  ..$B........8...
	defb 005h,00fh,003h,007h,010h,000h,00dh,00ch,003h,004h,030h,000h,020h,0ffh,081h,07eh	; 6348  ..........0. ..~
	defb 005h,0ffh,082h,042h,020h,009h,000h,081h,080h,00eh,000h,096h,001h,007h,007h,00fh	; 6358  ...B ...........
	defb 007h,003h,000h,020h,070h,0f0h,0e0h,0e0h,0f8h,078h,038h,000h,0e0h,040h,0f0h,0e0h	; 6368  ... p....x8..@..
	defb 0a0h,0c0h,00ah,000h,087h,080h,0c0h,0c0h,0e0h,0e0h,0e0h,0c0h,019h,000h,004h,0ffh	; 6378  ................
	defb 004h,07fh,008h,000h,082h,080h,0c0h,006h,080h,008h,000h,003h,0ffh,081h,07eh,005h	; 6388  ..............~.
	defb 004h,004h,008h,083h,0feh,0ffh,0ffh,00fh,000h,081h,080h,004h,07eh,085h,0feh,0feh	; 6398  ............~...
	defb 0fch,0fch,0fch,017h,000h,003h,070h,003h,0e0h,086h,0e3h,0f3h,0f7h,07bh,039h,030h	; 63a8  ......p......{90
	defb 004h,000h,08ch,00eh,00eh,00eh,007h,007h,0f7h,0a7h,0ffh,0f7h,0dfh,0e6h,004h,004h	; 63b8  ................
	defb 000h,088h,020h,07fh,0ffh,07fh,03fh,03fh,03fh,01fh,008h,000h,083h,0c0h,0c0h,0e0h	; 63c8  .. ...???.......
	defb 005h,0c0h,008h,000h,089h,001h,001h,039h,034h,064h,060h,0e0h,0e0h,060h,007h,000h	; 63d8  .......94d`..`..
	defb 004h,0feh,085h,010h,010h,020h,020h,040h,007h,000h,087h,048h,0ffh,0ffh,0ffh,0ffh	; 63e8  .....  @...H....
	defb 07dh,03bh,009h,000h,087h,0f0h,0f0h,0f0h,0e0h,0e0h,0c0h,080h,009h,000h,08bh,060h	; 63f8  };.............`
	defb 0e0h,0f0h,078h,038h,038h,078h,078h,030h,060h,040h,017h,000h,089h,0e0h,060h,070h	; 6408  ..x88xx0`@....`p
	defb 038h,038h,078h,038h,070h,060h,055h,000h,006h,000h,08ah,01ch,008h,07eh,0dfh,0bfh	; 6418  88x8p`U......~..
	defb 0bfh,0ffh,0ffh,07eh,03ch,010h,000h,08ch,007h,00fh,01ch,01ah,01ah,01ch,038h,078h	; 6428  ...~<.........8x
	defb 0f0h,0d0h,090h,010h,004h,000h,08ch,0e0h,0f0h,038h,058h,058h,039h,01fh,01eh,008h	; 6438  .........8XX9...
	defb 008h,008h,008h,006h,000h,086h,003h,005h,005h,000h,000h,004h,006h,00fh,08ah,007h	; 6448  ................
	defb 000h,000h,000h,0c0h,0a0h,0a0h,000h,000h,020h,006h,0f0h,081h,0e0h,006h,000h,083h	; 6458  ........ .......
	defb 003h,007h,003h,004h,000h,083h,070h,0f0h,070h,006h,000h,083h,0c0h,0e0h,0c0h,005h	; 6468  ......p.p.......
	defb 000h,08bh,008h,01ch,03eh,007h,00fh,01ch,01ah,01ah,09ch,0f8h,078h,004h,010h,004h	; 6478  ....>.......x...
	defb 000h,08ch,0e0h,0f0h,038h,058h,058h,038h,01ch,01eh,00fh,00bh,009h,008h,009h,000h	; 6488  ....8XX8........
	defb 083h,003h,007h,003h,005h,000h,083h,010h,038h,07ch,005h,000h,083h,0c0h,0e0h,0c0h	; 6498  ........8|......
	defb 004h,000h,083h,00eh,00fh,00eh,006h,000h,087h,0f2h,015h,015h,0f5h,015h,015h,0f2h	; 64a8  ................
	defb 009h,000h,087h,022h,055h,055h,055h,055h,055h,022h,009h,000h,000h	; 64b8  ..."UUUUU"...

; ----------------------------------------------------------------------
; DATOS flujo_64C5: Flujo comprimido con su direccion de VRAM delante: 509
;   bytes de VRAM
;   0x64c5..0x65d1  (268 bytes)
DATA_flujo_64C5:
	defb 003h,041h,084h,042h,044h,045h,046h,00eh,041h,093h,07ah,07bh,07ch,07dh,07eh,041h	; 64c5  .A.BDEF.A.z{|}~A
	defb 041h,041h,000h,041h,041h,040h,040h,040h,043h,047h,04ch,048h,04dh,00bh,04eh,08bh	; 64d5  AA.AA@@@CGLHM.N.
	defb 04fh,040h,07fh,080h,081h,082h,083h,040h,040h,040h,000h,005h,040h,0a5h,043h,047h	; 64e5  O@.....@@@..@.CG
	defb 04ch,048h,050h,021h,02eh,027h,02ch,025h,000h,000h,055h,000h,000h,056h,051h,040h	; 64f5  LHP!.',%..U..VQ@
	defb 084h,085h,086h,087h,088h,040h,040h,040h,000h,040h,040h,040h,040h,040h,043h,047h	; 6505  .....@@@.@@@@@CG
	defb 04ch,048h,052h,00bh,053h,08bh,054h,040h,089h,08ah,08bh,08ch,08dh,040h,040h,040h	; 6515  LHR.S.T@.....@@@
	defb 000h,005h,040h,084h,043h,047h,04ch,048h,00eh,040h,089h,08eh,08fh,090h,091h,092h	; 6525  ..@.CGLH.@......
	defb 040h,040h,040h,000h,005h,040h,084h,043h,049h,04ah,04bh,016h,040h,081h,000h,005h	; 6535  @@@..@.CIJK.@...
	defb 040h,081h,043h,019h,040h,081h,000h,005h,040h,081h,043h,019h,040h,081h,000h,005h	; 6545  @.C.@...@.C.@...
	defb 040h,081h,043h,019h,040h,081h,000h,005h,040h,081h,043h,019h,040h,081h,000h,005h	; 6555  @.C.@...@.C.@...
	defb 040h,081h,043h,019h,040h,081h,000h,005h,040h,081h,043h,019h,040h,081h,000h,005h	; 6565  @.C.@...@.C.@...
	defb 040h,081h,043h,010h,040h,081h,059h,005h,05ah,084h,05bh,040h,040h,000h,005h,040h	; 6575  @.C.@.Y.Z.[@@..@
	defb 081h,043h,004h,040h,081h,04dh,007h,04eh,08eh,04fh,040h,040h,040h,05ch,033h,023h	; 6585  .C.@.M.N.O@@@\3#
	defb 02fh,032h,025h,05dh,040h,040h,000h,005h,040h,081h,043h,004h,040h,08dh,050h,037h	; 6595  /2%]@@..@.C.@.P7
	defb 029h,02eh,024h,000h,000h,000h,051h,040h,040h,040h,05ch,005h,000h,084h,05dh,040h	; 65a5  ).$...Q@@@\...]@
	defb 040h,000h,005h,040h,081h,043h,004h,040h,081h,052h,007h,053h,085h,054h,040h,040h	; 65b5  @..@.C.@.R.S.T@@
	defb 040h,05eh,005h,05fh,086h,060h,040h,040h,000h,040h,040h,000h	; 65c5  @^._.`@@.@@.

; ======================================================================
; CODIGO 0x65d1..0x65f7  (38 bytes)
; ======================================================================


CUENTA_ATRAS_DEL_TIRO:		; Baja E144 y, justo al llegar a uno, si el anillo era el 9, baja la dificultad y suena
	ld hl,0e144h		;65d1
	ld a,(hl)			;65d4
	or a			;65d5
	ret z			;65d6
	dec (hl)			;65d7
	cp 001h		;65d8
	ret nz			;65da
	ld a,(0e11ch)		;65db
	cp 009h		;65de   ; El anillo 9 es el aro de fuera: el peor
	ret nz			;65e0
	ld a,(0e111h)		;65e1
	cp 003h		;65e4   ; Con E111 por debajo de tres, se baja E145
	jr nc,L_65EC		;65e6
	ld hl,0e145h		;65e8
	dec (hl)			;65eb
L_65EC:
	ld a,096h		;65ec   ; El sonido 0x96
	call SUENA_SI_SE_PUEDE		;65ee
	ld de,065f7h		;65f1   ; Y la lista de 0x65F7
	jp PINTA_LISTA		;65f4

; ----------------------------------------------------------------------
; DATOS lista_65F7: Lista de 18 tiles con su direccion de VRAM delante, para
;   PINTA_LISTA (0x4050)
;   0x65f7..0x6612  (27 bytes)
DATA_lista_65F7:
	defb 035h,03ah,061h,062h,062h,062h,062h,063h,0feh,055h,03ah,064h,06ah,06bh,06ch,06dh	; 65f7  5:abbbbc.U:djklm
	defb 065h,0feh,075h,03ah,066h,068h,069h,068h,068h,067h,0ffh	; 6607  e.u:fhihhg.

; ======================================================================
; CODIGO 0x6612..0x6618  (6 bytes)
; ======================================================================


PINTA_EL_ROTULO_DEL_TIRO:		; El flujo de 0x6618, que borra el rotulo de las tres filas
	ld de,06618h		;6612
	jp DESCOMPRIME_CON_DIRECCION		;6615

; ----------------------------------------------------------------------
; DATOS rle_6618: Flujo comprimido con su direccion de VRAM delante: 18 bytes
;   de VRAM
;   0x6618..0x6627  (15 bytes)
DATA_rle_6618:
	defb 035h,03ah,006h,040h,080h,055h,03ah,006h,040h,080h,075h,03ah,006h,040h,000h	; 6618  5:.@.U:.@.u:.@.

; ----------------------------------------------------------------------
; DATOS lista_6627: Dos veces 0300. Descifrada con tools/textos.py (el numero
;   de tile no es el ASCII): «0300 / 0300»
;   0x6627..0x6635  (14 bytes)
DATA_lista_6627:
	defb 0e2h,039h,040h,043h,040h,040h,0feh,002h,03ah,040h,043h,040h,040h,0ffh	; 6627  .9@C@@..:@C@@.

; ----------------------------------------------------------------------
; DATOS lista_6635: Lista de 8 tiles con su direccion de VRAM delante, para
;   PINTA_LISTA (0x4050)
;   0x6635..0x6643  (14 bytes)
DATA_lista_6635:
	defb 0e2h,039h,076h,06fh,070h,071h,0feh,002h,03ah,077h,078h,074h,075h,0ffh	; 6635  .9vopq..:wxtu.

; ----------------------------------------------------------------------
; DATOS lista_6643: Lista de 8 tiles con su direccion de VRAM delante, para
;   PINTA_LISTA (0x4050)
;   0x6643..0x6651  (14 bytes)
DATA_lista_6643:
	defb 0e2h,039h,06eh,06fh,070h,071h,0feh,002h,03ah,072h,073h,074h,075h,0ffh	; 6643  .9nopq..:rstu.

; ----------------------------------------------------------------------
; DATOS rle_6651: Flujo comprimido con su direccion de VRAM delante: 909 bytes
;   de VRAM
;   0x6651..0x694c  (763 bytes)
DATA_rle_6651:
	defb 084h,03ch,0feh,0fch,0f8h,005h,0f0h,089h,0f8h,0fch,0feh,0ffh,0ffh,0feh,0fch,0c0h	; 6651  .<..............
	defb 080h,006h,000h,005h,0ffh,087h,0fch,0e0h,080h,0ffh,09fh,08fh,007h,004h,000h,088h	; 6661  ................
	defb 03fh,00fh,007h,003h,001h,001h,000h,000h,004h,0ffh,084h,0efh,067h,043h,001h,005h	; 6671  ?...........gC..
	defb 0ffh,083h,07fh,03fh,00eh,003h,000h,085h,001h,003h,007h,00fh,00fh,003h,000h,094h	; 6681  ...?............
	defb 080h,0c0h,0e0h,0f0h,0f0h,003h,000h,004h,008h,008h,002h,008h,004h,020h,050h,000h	; 6691  ............. P.
	defb 080h,010h,010h,0a0h,003h,000h,002h,001h,006h,003h,086h,007h,007h,005h,006h,003h	; 66a1  ................
	defb 001h,005h,0c0h,085h,080h,000h,000h,0c0h,0c0h,005h,0e0h,009h,0f0h,008h,00fh,008h	; 66b1  ................
	defb 0ffh,090h,00fh,00fh,01fh,03fh,0ffh,0ffh,0ffh,03fh,0c0h,0e0h,0ffh,0f8h,0f0h,0fch	; 66c1  .....?...?......
	defb 0f8h,0feh,007h,0ffh,085h,0f0h,00fh,01fh,01fh,00fh,004h,000h,007h,0ffh,085h,00fh	; 66d1  ................
	defb 0f0h,0f8h,0f8h,0f0h,004h,000h,005h,0ffh,083h,0f0h,000h,000h,003h,0ffh,081h,0f0h	; 66e1  ................
	defb 004h,000h,082h,0ffh,0f0h,006h,000h,082h,0ffh,00fh,006h,000h,003h,0ffh,081h,00fh	; 66f1  ................
	defb 004h,000h,005h,0ffh,093h,00fh,000h,000h,003h,007h,0ffh,01fh,00fh,03fh,01fh,07fh	; 6701  .............?..
	defb 03ch,07eh,0ffh,07eh,0f7h,0efh,07eh,03ch,04fh,0ffh,081h,01fh,004h,0ffh,004h,03ch	; 6711  <~.~..~<O......<
	defb 008h,0e0h,004h,03ch,00ah,0ffh,086h,0f0h,00fh,0ffh,0fch,0c0h,0e0h,004h,000h,005h	; 6721  ...<............
	defb 0ffh,083h,0f8h,0e0h,000h,005h,0ffh,088h,01fh,003h,0e0h,000h,000h,001h,003h,003h	; 6731  ................
	defb 003h,007h,005h,000h,003h,080h,085h,000h,000h,080h,0c0h,0c0h,007h,0e0h,003h,0c0h	; 6741  ................
	defb 083h,080h,030h,030h,005h,078h,081h,0fch,004h,007h,003h,003h,083h,001h,0f0h,00fh	; 6751  ..00.x..........
	defb 00eh,0f8h,005h,000h,08bh,001h,003h,007h,00fh,00fh,01fh,03fh,03fh,07fh,07fh,0ffh	; 6761  ...........??...
	defb 005h,000h,08eh,080h,0c0h,0e0h,0f0h,0f0h,0f8h,0fch,0fch,0feh,0feh,0ffh,007h,001h	; 6771  ................
	defb 001h,006h,000h,088h,080h,0c0h,0c0h,0e0h,0e9h,0e9h,0e0h,0fch,003h,0feh,004h,0ffh	; 6781  ................
	defb 005h,000h,082h,050h,050h,006h,000h,003h,080h,005h,000h,084h,036h,036h,000h,01fh	; 6791  ...PP.......66..
	defb 005h,03fh,08bh,01fh,01fh,00fh,007h,007h,003h,003h,001h,000h,000h,0c0h,007h,000h	; 67a1  .?..............
	defb 085h,07fh,03fh,01fh,00fh,007h,005h,003h,083h,007h,03fh,03fh,003h,01fh,082h,007h	; 67b1  ..?.......??....
	defb 00fh,004h,01fh,083h,00fh,007h,007h,007h,00fh,08ah,0f0h,0f0h,0e1h,0e1h,0c0h,0c0h	; 67c1  ................
	defb 080h,080h,0ffh,03eh,006h,000h,08ah,0e0h,0f0h,0f8h,0f8h,0f8h,0f0h,0c0h,000h,0ffh	; 67d1  ...>............
	defb 07ch,006h,000h,087h,0f0h,0e0h,0d8h,08ch,006h,003h,001h,004h,000h,086h,050h,080h	; 67e1  |.............P.
	defb 080h,0c0h,0e0h,003h,005h,000h,0adh,080h,0c0h,0c8h,07ch,06eh,077h,03bh,01fh,00eh	; 67f1  ..........|nw;..
	defb 000h,000h,000h,018h,000h,000h,018h,000h,000h,001h,000h,0c0h,060h,030h,018h,00ch	; 6801  ............`0..
	defb 00ch,00eh,01fh,01dh,01dh,01dh,01fh,00eh,01fh,080h,000h,003h,006h,00ch,018h,030h	; 6811  ...............0
	defb 030h,001h,0feh,0c0h,008h,000h,081h,009h,004h,000h,099h,070h,0f8h,0b8h,0b8h,0b8h	; 6821  0..........p....
	defb 0f8h,070h,0f8h,00eh,00eh,01eh,01ch,03ch,038h,078h,070h,030h,038h,03ch,01ch,01eh	; 6831  .p.....<8xp08<..
	defb 00fh,00fh,007h,007h,006h,003h,081h,007h,004h,0ffh,082h,0f0h,00fh,004h,0ffh,082h	; 6841  ................
	defb 0f0h,00fh,006h,0ffh,082h,00fh,0f0h,008h,0ffh,087h,00fh,0f0h,0ffh,0ffh,07fh,080h	; 6851  ................
	defb 0fch,005h,0ffh,003h,000h,081h,090h,004h,000h,093h,0feh,0efh,0feh,0fbh,05fh,0d6h	; 6861  .............._.
	defb 07fh,00fh,07fh,0f7h,07fh,0dfh,0fah,06bh,0feh,0f0h,000h,000h,0ffh,004h,000h,08eh	; 6871  .......k........
	defb 070h,000h,000h,0ffh,000h,000h,000h,080h,0bfh,0ffh,0ffh,003h,00fh,03fh,008h,0ffh	; 6881  p............?..
	defb 088h,0efh,083h,00fh,0ffh,0ffh,080h,0f0h,0fch,008h,0ffh,083h,080h,0fch,0f8h,005h	; 6891  ................
	defb 0ffh,081h,078h,007h,0ffh,082h,00eh,07fh,007h,0ffh,082h,0e0h,0f0h,005h,0ffh,085h	; 68a1  ..x.............
	defb 01ch,03fh,0ffh,0ffh,007h,009h,000h,004h,001h,085h,000h,000h,000h,080h,0c0h,004h	; 68b1  .?..............
	defb 0e0h,08ah,0f8h,0e0h,080h,0c0h,0f8h,0f8h,0fch,0feh,00fh,0f0h,006h,01fh,084h,00fh	; 68c1  ................
	defb 01fh,03fh,07fh,00ah,0ffh,08ah,00fh,0f0h,0f0h,0f0h,0f8h,0fch,0ffh,0ffh,0ffh,0fch	; 68d1  .?..............
	defb 004h,0ffh,004h,0f0h,084h,0f0h,0f8h,0fch,0feh,008h,0ffh,004h,00fh,083h,00fh,003h	; 68e1  ................
	defb 001h,006h,003h,081h,001h,006h,000h,004h,007h,006h,00fh,088h,01eh,01eh,03ch,030h	; 68f1  ..............<0
	defb 060h,060h,0f0h,0f0h,005h,0e0h,085h,0c0h,0f8h,0e0h,001h,001h,004h,000h,081h,003h	; 6901  ``..............
	defb 005h,000h,0adh,0c0h,0e0h,0f0h,080h,000h,000h,003h,00fh,01fh,03fh,003h,000h,000h	; 6911  ............?...
	defb 03ch,0feh,093h,001h,001h,000h,000h,0f0h,0e0h,080h,000h,000h,080h,0c0h,000h,080h	; 6921  <...............
	defb 0c0h,0e0h,0e0h,060h,0e0h,0feh,0feh,06ch,0e0h,0feh,07eh,000h,000h,0c0h,0f0h,080h	; 6931  ...`...l..~.....
	defb 005h,000h,082h,0f8h,0f0h,004h,0e0h,082h,0f0h,0f8h,000h	; 6941  ...........

; ----------------------------------------------------------------------
; DATOS rle_694C: Flujo comprimido con su direccion de VRAM delante: 1435
;   bytes de VRAM
;   0x694c..0x6c0a  (702 bytes)
DATA_rle_694C:
	defb 081h,027h,03fh,02ch,03dh,0f3h,003h,0a3h,01fh,03fh,081h,03ch,064h,0c3h,002h,0c6h	; 694c  .'?,=....?.<d...
	defb 002h,0c3h,004h,070h,002h,0f0h,002h,070h,008h,020h,086h,000h,0e0h,0f0h,0f0h,030h	; 695c  ...p...p. .....0
	defb 030h,00bh,0c0h,086h,030h,0c0h,030h,0c0h,030h,030h,005h,0c0h,006h,030h,081h,0c0h	; 696c  0...0.0.00...0..
	defb 008h,030h,003h,0f0h,082h,0e0h,000h,008h,0e0h,08ch,070h,070h,0f0h,070h,070h,0f0h	; 697c  .0........pp.pp.
	defb 074h,074h,000h,0e0h,0f0h,0f0h,010h,0feh,00bh,030h,083h,0e0h,042h,042h,015h,052h	; 698c  tt.......0..BB.R
	defb 081h,0c2h,01dh,043h,005h,003h,081h,00ch,004h,003h,006h,043h,003h,003h,082h,030h	; 699c  ...C.......C...0
	defb 0e0h,00eh,0efh,020h,0e3h,081h,0a6h,037h,0e6h,005h,0a3h,00bh,0aeh,005h,03ah,006h	; 69ac  ... ...7......:.
	defb 0eah,005h,0e6h,008h,0a6h,008h,0a3h,008h,0b0h,008h,006h,008h,0a6h,008h,016h,004h	; 69bc  ................
	defb 034h,008h,0f4h,003h,034h,081h,030h,004h,034h,00ah,0f4h,00ah,0f0h,081h,034h,00ch	; 69cc  4...4.0.4.....4.
	defb 0f4h,084h,0f0h,0f0h,0b0h,004h,007h,0f4h,081h,034h,00dh,0f4h,002h,000h,005h,0f4h	; 69dc  .........4......
	defb 086h,0f0h,0f0h,0b0h,003h,003h,00ch,007h,003h,081h,00ch,008h,003h,004h,0f3h,081h	; 69ec  ................
	defb 0a3h,005h,030h,003h,0e0h,003h,030h,005h,0e0h,003h,030h,005h,0e0h,005h,030h,003h	; 69fc  ..0...0...0...0.
	defb 0e0h,081h,043h,007h,04fh,006h,0f4h,002h,000h,090h,0c3h,0c6h,0c3h,0c6h,0c6h,0c3h	; 6a0c  ..C.O...........
	defb 036h,03ch,0c3h,0c6h,0c3h,0c6h,0c6h,0c3h,036h,03ch,007h,0c3h,081h,043h,006h,0c3h	; 6a1c  6<......6<...C..
	defb 085h,013h,043h,070h,070h,02fh,005h,027h,08bh,070h,070h,0f0h,070h,070h,0f4h,024h	; 6a2c  ..Cpp/.'.pp.pp.$
	defb 024h,070h,070h,0cfh,005h,0c7h,0a8h,070h,070h,0f0h,070h,070h,0cfh,0c4h,0c4h,070h	; 6a3c  $pp....pp.pp...p
	defb 070h,0f0h,070h,070h,04fh,04fh,04fh,070h,070h,0f0h,070h,070h,05fh,05fh,05fh,070h	; 6a4c  p.ppOOOpp.pp___p
	defb 070h,0f0h,070h,070h,0f0h,057h,057h,070h,070h,0f0h,070h,070h,04fh,047h,047h,008h	; 6a5c  p.pp.WWpp.ppOGG.
	defb 04ch,005h,063h,003h,06eh,005h,063h,003h,06eh,003h,045h,002h,0c5h,003h,0c2h,082h	; 6a6c  L.c.n.c.n.E.....
	defb 030h,0e0h,006h,0efh,004h,0ceh,00bh,030h,081h,0e0h,007h,03fh,087h,03ch,000h,0e0h	; 6a7c  0......0...?.<..
	defb 0f0h,0f0h,03eh,03eh,006h,0ceh,004h,030h,08ah,000h,0e0h,0f0h,0f0h,03eh,03eh,0ceh	; 6a8c  ..>>...0.....>>.
	defb 0ceh,003h,003h,003h,063h,003h,06eh,008h,0a6h,005h,03ah,003h,0eah,006h,034h,002h	; 6a9c  ....c.n...:...4.
	defb 0b4h,004h,003h,003h,0f3h,083h,043h,006h,006h,006h,0a6h,004h,00ah,004h,06ah,081h	; 6aac  ......C.......j.
	defb 034h,003h,0f4h,004h,0b4h,003h,034h,002h,0b4h,003h,0bfh,007h,043h,082h,0f3h,04bh	; 6abc  4.....4.....C..K
	defb 00ah,0fbh,005h,01bh,082h,0fbh,03bh,006h,036h,002h,0bah,006h,06ah,0bah,0bah,06ah	; 6acc  ......;.6...j..j
	defb 06ah,06ah,06ah,06ah,06ah,000h,006h,000h,083h,078h,0fch,078h,01ah,000h,002h,0ffh	; 6adc  jjjjj....x.x....
	defb 006h,0c0h,002h,0ffh,006h,000h,00ah,0c0h,005h,000h,002h,0ffh,008h,0c0h,002h,0ffh	; 6aec  ................
	defb 004h,000h,002h,0f0h,008h,030h,002h,0f0h,003h,000h,002h,0ffh,00ah,0c0h,002h,0ffh	; 6afc  .....0..........
	defb 002h,000h,002h,0fch,00ah,00ch,085h,0fch,0fch,000h,0ffh,0ffh,00ch,0c0h,004h,0ffh	; 6b0c  ................
	defb 00ch,003h,002h,0ffh,005h,000h,082h,048h,0d5h,004h,055h,081h,048h,009h,000h,081h	; 6b1c  .......H..U.H...
	defb 080h,005h,040h,081h,080h,009h,000h,087h,0f2h,085h,085h,0e5h,015h,015h,0e2h,009h	; 6b2c  ..@.............
	defb 000h,081h,020h,005h,050h,081h,020h,009h,000h,081h,048h,005h,04ah,081h,044h,009h	; 6b3c  .. .P. ...H.J.D.
	defb 000h,081h,044h,005h,0aah,081h,044h,004h,000h,085h,03dh,000h,000h,005h,005h,006h	; 6b4c  ..D...D...=.....
	defb 000h,081h,007h,004h,000h,081h,0c0h,00ah,000h,081h,080h,004h,000h,086h,03dh,040h	; 6b5c  ..............=@
	defb 085h,005h,01fh,005h,005h,000h,002h,003h,003h,000h,085h,0c0h,020h,000h,000h,0c0h	; 6b6c  ............ ...
	defb 00bh,000h,085h,03dh,000h,000h,019h,025h,003h,000h,084h,080h,080h,040h,03fh,004h	; 6b7c  ...=...%.....@?.
	defb 000h,081h,0c0h,009h,000h,082h,020h,0c0h,006h,000h,08ch,01eh,03fh,07fh,06bh,07fh	; 6b8c  ...... .....?.k.
	defb 077h,037h,01fh,07fh,0c9h,0cdh,064h,006h,000h,004h,080h,086h,000h,00ch,070h,018h	; 6b9c  w7....d.......p.
	defb 0c0h,060h,004h,000h,09bh,001h,001h,000h,001h,003h,003h,00fh,01fh,01fh,017h,004h	; 6bac  .`..............
	defb 009h,000h,000h,000h,000h,0c0h,060h,060h,0e0h,0e0h,0c0h,0c0h,0f0h,0f0h,0b0h,090h	; 6bbc  ......``........
	defb 006h,000h,084h,03eh,0ffh,01eh,07ch,00ch,000h,002h,080h,00dh,000h,09bh,001h,001h	; 6bcc  ...>..|.........
	defb 000h,001h,003h,023h,03fh,01fh,00fh,007h,004h,009h,000h,000h,000h,000h,0c0h,060h	; 6bdc  ...#?..........`
	defb 060h,0e0h,0e4h,0cch,0fch,0f8h,0f0h,080h,080h,008h,000h,087h,0f2h,015h,015h,0f5h	; 6bec  `...............
	defb 015h,015h,0f2h,009h,000h,081h,022h,005h,055h,081h,022h,004h,000h,000h	; 6bfc  ......".U."...

; ======================================================================
; CODIGO 0x6c0a..0x6c3a  (48 bytes)
; ======================================================================


CARGA_LOS_TRES_FLUJOS:		; Los tres flujos de graficos de la prueba, sacados de la tabla de 0x6C3A
	ld a,(0e080h)		;6c0a
	and 003h		;6c0d   ; Los dos bits bajos de E080: la prueba
	add a,a			;6c0f   ; Por seis: tres punteros por prueba
	ld b,a			;6c10   ; Por seis: tres punteros por prueba
	add a,a			;6c11
	add a,b			;6c12
	ld hl,06c3ah		;6c13
	call HL_MAS_A		;6c16
	ld e,(hl)			;6c19   ; El primer puntero
	inc hl			;6c1a
	ld d,(hl)			;6c1b
	inc hl			;6c1c
	push hl			;6c1d
	ld hl,02a00h		;6c1e   ; El primero, a la VRAM 0x2A00
	call DESCOMPRIME_DOS_TERCIOS		;6c21
	pop hl			;6c24
	ld e,(hl)			;6c25
	inc hl			;6c26
	ld d,(hl)			;6c27
	inc hl			;6c28
	push hl			;6c29
	ld hl,00a00h		;6c2a   ; El segundo, a la 0x0A00
	call DESCOMPRIME_DOS_TERCIOS		;6c2d
	pop hl			;6c30
	ld e,(hl)			;6c31
	inc hl			;6c32
	ld d,(hl)			;6c33
	ld hl,01800h		;6c34
	jp DESCOMPRIME_EN_HL		;6c37

; ----------------------------------------------------------------------
; DATOS tabla_de_las_pruebas: Cuatro registros de tres punteros, uno por
;   prueba: los tres flujos de graficos que 0x6C13 descomprime en la VRAM
;   0x2A00, 0x0A00 y la tercera. El indice son los dos bits bajos de (0xE080)
;   por seis
;   0x6c3a..0x6c52  (24 bytes)
DATA_tabla_de_las_pruebas:
	defw 06651h,0694ch,06ae2h	; 6c3a  -> DATA_rle_6651 DATA_rle_694C 0x6ae2
	defw 0604eh,06244h,06318h	; 6c40  -> 0x604e DATA_rle_6244 DATA_flujo_6318
	defw 07003h,07148h,07251h	; 6c46  -> DATA_rle_7003 DATA_rle_7148 DATA_flujo_7251
	defw 0564bh,056bbh,06318h	; 6c4c  -> DATA_rle_564B DATA_rle_56BB DATA_flujo_6318

; ----------------------------------------------------------------------
; DATOS flujo_6C52: Flujo comprimido con su direccion de VRAM delante: 480
;   bytes de VRAM
;   0x6c52..0x6d2b  (217 bytes)
DATA_flujo_6C52:
	defb 020h,061h,0e0h,0a8h,0a7h,040h,0a9h,0aah,0abh,06ah,0ach,0adh,0aeh,0a8h,0a7h,040h	; 6c52   a...@...j.....@
	defb 0a9h,0aah,0abh,06ah,0ach,0adh,0aeh,0a8h,0a7h,040h,0a9h,0aah,0abh,06ah,0ach,0adh	; 6c62  ...j.....@...j..
	defb 0aeh,0a8h,0a7h,062h,062h,041h,064h,064h,0afh,0b2h,071h,070h,06fh,062h,062h,041h	; 6c72  ...bbAdd..qpobbA
	defb 064h,064h,0afh,0b2h,071h,070h,06fh,062h,062h,041h,064h,064h,0afh,0b2h,071h,070h	; 6c82  dd..qpobbAdd..qp
	defb 06fh,062h,062h,043h,044h,042h,064h,064h,064h,064h,045h,046h,047h,043h,044h,042h	; 6c92  obbCDBddddEFGCDB
	defb 064h,064h,064h,064h,045h,046h,047h,043h,044h,042h,064h,064h,064h,064h,045h,046h	; 6ca2  ddddEFGCDBddddEF
	defb 047h,043h,044h,020h,065h,008h,067h,081h,060h,00eh,067h,081h,060h,00ch,067h,082h	; 6cb2  GCD e.g.`.g.`.g.
	defb 05fh,054h,014h,067h,082h,05fh,054h,004h,067h,004h,052h,082h,0a4h,0a3h,014h,052h	; 6cc2  _T.g._T.g.R....R
	defb 082h,0a4h,0a3h,004h,052h,020h,067h,020h,052h,083h,09dh,09eh,078h,01ah,052h,086h	; 6cd2  ....R g R...x.R.
	defb 0b3h,09fh,0a0h,069h,069h,079h,01ah,067h,086h,06ch,069h,069h,059h,05ah,05bh,011h	; 6ce2  ...iiy.g.liiYZ[.
	defb 052h,081h,048h,005h,068h,086h,049h,052h,052h,05ch,05dh,05eh,014h,052h,087h,050h	; 6cf2  R.H.h.IRR\]^.R.P
	defb 000h,000h,093h,000h,000h,051h,012h,052h,081h,07ah,004h,052h,089h,07ch,052h,0b6h	; 6d02  .....Q.R.z.R.|R.
	defb 063h,0b7h,06bh,0b9h,063h,053h,012h,052h,081h,07bh,004h,052h,089h,07dh,052h,056h	; 6d12  c.k.cS.R.{.R.}RV
	defb 066h,0b8h,06dh,0b4h,066h,058h,005h,052h,000h	; 6d22  f.m.fX.R.

; ----------------------------------------------------------------------
; DATOS flujo_6D2B: Flujo comprimido con su direccion de VRAM delante: 508
;   bytes de VRAM
;   0x6d2b..0x6e24  (249 bytes)
DATA_flujo_6D2B:
	defb 004h,042h,082h,041h,069h,006h,042h,082h,041h,069h,006h,042h,082h,041h,069h,006h	; 6d2b  .B.Ai.B.Ai.B.Ai.
	defb 042h,084h,041h,069h,042h,042h,004h,043h,082h,041h,06ah,006h,043h,082h,041h,06ah	; 6d3b  B.AiBB.C.Aj.C.Aj
	defb 006h,043h,082h,041h,06ah,006h,043h,084h,041h,06ah,043h,043h,004h,040h,082h,041h	; 6d4b  .C.Aj.C.AjCC.@.A
	defb 090h,006h,040h,082h,041h,090h,006h,040h,082h,041h,090h,006h,040h,084h,041h,090h	; 6d5b  ..@.A..@.A..@.A.
	defb 040h,040h,020h,093h,020h,094h,020h,04ch,084h,04ch,04dh,04eh,04fh,014h,04ch,08ch	; 6d6b  @@ . . L.LMNO.L.
	defb 050h,051h,052h,053h,054h,04ch,04ch,04ch,044h,07dh,000h,085h,012h,044h,081h,07ch	; 6d7b  PQRSTLLLD}...D.|
	defb 005h,04ah,088h,089h,044h,044h,044h,047h,067h,000h,068h,012h,047h,090h,065h,013h	; 6d8b  .J..DDDGg.h.G.e.
	defb 010h,01bh,010h,010h,066h,047h,047h,047h,046h,05bh,000h,062h,046h,073h,00eh,08ch	; 6d9b  ....fGGGF[.bFs..
	defb 089h,074h,046h,088h,049h,07fh,049h,07fh,049h,08ah,004h,046h,084h,05ch,05eh,05fh	; 6dab  .tF.I.I.I..F.\^_
	defb 073h,010h,08ch,083h,074h,046h,060h,005h,048h,089h,05dh,046h,046h,047h,06dh,06ch	; 6dbb  s...tF`.H.]FFGml
	defb 06eh,078h,076h,00eh,079h,0aah,087h,078h,047h,065h,000h,000h,000h,01eh,01fh,063h	; 6dcb  nxv.y..xGe.....c
	defb 047h,047h,046h,046h,046h,06fh,078h,077h,000h,023h,028h,02fh,02fh,033h,025h,000h	; 6ddb  GGFFFoxw.#(//3%.
	defb 023h,02ch,021h,033h,033h,000h,07eh,078h,046h,064h,04bh,080h,082h,084h,04bh,08eh	; 6deb  #,!33.~xFdK...K.
	defb 005h,046h,083h,06fh,078h,075h,00eh,086h,08ch,08bh,078h,046h,071h,07bh,07ah,081h	; 6dfb  .F.oxu....xFq{z.
	defb 083h,07bh,06bh,046h,046h,004h,046h,012h,045h,00ah,046h,088h,000h,000h,000h,030h	; 6e0b  .{kFF.F.E.F....0
	defb 02fh,037h,025h,032h,00fh,05ah,009h,000h,000h	; 6e1b  /7%2.Z...

; ======================================================================
; CODIGO 0x6e24..0x6e77  (83 bytes)
; ======================================================================


PINTA_LA_BARRA_DE_POTENCIA:		; La barra POWER de la fila 23: los tramos llenos con el tile 0x72 y el resto con el 0x5A
	ld a,(0e101h)		;6e24
	rra			;6e27
	rra			;6e28
	ld d,a			;6e29   ; Cuatro rra: el nibble alto de la potencia
	rra			;6e2a
	rra			;6e2b
	and 00fh		;6e2c
	ld b,a			;6e2e
	ld hl,03ae8h		;6e2f   ; Fila 23, columna 8
	sub 00fh		;6e32   ; Lo que falta hasta 0x0F: lo que queda vacio
	neg		;6e34   ; Lo que falta hasta 0x0F: los tramos vacios
	ld c,a			;6e36
	ld de,00001h		;6e37   ; Una casilla cada vez: la barra va en horizontal
	ld a,072h		;6e3a   ; El tile 0x72, el tramo lleno
	call PINTA_B_CASILLAS		;6e3c
	ld b,c			;6e3f
	ld a,05ah		;6e40   ; Y el 0x5A, el vacio
	jp PINTA_B_CASILLAS		;6e42
SUBE_LA_POTENCIA:		; La tabla de 0x6E77 le resta y el mando le suma; el resultado se guarda en E100
	ld de,(0e100h)		;6e45
	ld a,d			;6e49   ; El byte alto de E100 es la potencia
	rra			;6e4a
	rra			;6e4b
	rra			;6e4c
	rra			;6e4d
	and 00fh		;6e4e
	ld hl,06e77h		;6e50   ; La tabla de trece, indexada por el nibble alto de E101
	call HL_MAS_A		;6e53
	ld l,(hl)			;6e56
	ld h,000h		;6e57
	add hl,hl			;6e59   ; Por cuatro
	add hl,hl			;6e5a
	ex de,hl			;6e5b
	sbc hl,de		;6e5c
	jr nc,L_6E62		;6e5e   ; Si se pasa por abajo, se queda en cero
	ld h,000h		;6e60
L_6E62:
	ld a,(0e043h)		;6e62
	ld de,00000h		;6e65
	and 008h		;6e68   ; Bit 3 del mando: el jugador empuja
	jr z,L_6E6E		;6e6a
	ld d,010h		;6e6c
L_6E6E:
	add hl,de			;6e6e
	jr nc,L_6E73		;6e6f
	ld h,0ffh		;6e71   ; Y por arriba, tope en 0xFF
L_6E73:
	ld (0e100h),hl		;6e73
	ret			;6e76

; ----------------------------------------------------------------------
; DATOS lo_que_baja_la_potencia: Trece valores que 0x6E50 indexa con el nibble
;   alto de E101: lo que la potencia pierde por fotograma, de 0x04 a 0xD8
;   0x6e77..0x6e87  (16 bytes)
DATA_lo_que_baja_la_potencia:
	defb 004h,028h,040h,050h,064h,074h,088h,098h,0a0h,0a8h,0b4h,0c0h,0d8h,0e8h,0f0h,0ffh	; 6e77  .(@Pdt..........

; ======================================================================
; CODIGO 0x6e87..0x6ed4  (77 bytes)
; ======================================================================


MUEVE_LA_BARRA:		; Coloca la barra en su altura, la mueve un punto arriba o abajo y suena al llegar
	ld a,(0e110h)		;6e87   ; E110, la categoria elegida: 0x10 de altura por categoria
	add a,a			;6e8a
	add a,a			;6e8b
	add a,a			;6e8c
	add a,a			;6e8d
	ld c,a			;6e8e
	ld a,(0e105h)		;6e8f
	ld hl,06ed4h		;6e92   ; La tabla de alturas de la barra
	call HL_MAS_A		;6e95
	ld a,(hl)			;6e98
	add a,c			;6e99
	ld hl,0e103h		;6e9a
	ld (hl),a			;6e9d
	dec hl			;6e9e
	add a,020h		;6e9f   ; Y el sprite de al lado, 0x20 mas abajo
	ld (hl),a			;6ea1
	dec hl			;6ea2
	ld a,(hl)			;6ea3
	inc hl			;6ea4
	cp (hl)			;6ea5
	inc hl			;6ea6
	ld e,001h		;6ea7   ; E vale +1 o -1: hacia donde se mueve
	jr nc,L_6EAF		;6ea9
	ld e,0ffh		;6eab
	cp (hl)			;6ead
	ret nc			;6eae
L_6EAF:
	inc hl			;6eaf
	dec (hl)			;6eb0
	ret nz			;6eb1
	inc hl			;6eb2
	ld a,(hl)			;6eb3
	cp 017h		;6eb4   ; Por debajo de 0x17 el paso es 2, y por encima 0x20
	ld a,002h		;6eb6
	jr c,L_6EBC		;6eb8
	ld a,020h		;6eba
L_6EBC:
	dec hl			;6ebc   ; El paso nuevo
	ld (hl),a			;6ebd
	inc hl			;6ebe
	ld a,(hl)			;6ebf
	add a,e			;6ec0
	ret m			;6ec1   ; Por debajo de cero no baja
	inc hl			;6ec2
	cp (hl)			;6ec3   ; Ni se pasa del tope de arriba
	ret c			;6ec4
	inc hl			;6ec5
	cp (hl)			;6ec6
	ret nc			;6ec7
	dec hl			;6ec8
	dec hl			;6ec9
	ld (hl),a			;6eca
	xor a			;6ecb
	ld (0e035h),a		;6ecc   ; E035 a cero
	ld a,086h		;6ecf   ; El sonido 0x86: la barra en su sitio
	jp SUENA_SI_SE_PUEDE		;6ed1

; ----------------------------------------------------------------------
; DATOS alturas_de_la_barra: Las 36 alturas por las que pasa la barra,
;   indexadas con (0xE105): de 0x18 a 0x50 de dos en dos, y luego a saltos
;   hasta 0xD0
;   0x6ed4..0x6ef8  (36 bytes)
DATA_alturas_de_la_barra:
	defb 018h,01ah,01ch,01eh,020h,022h	; 6ed4
	defb 024h,026h,028h,02ah,02ch,02eh	; 6eda
	defb 030h,032h,034h,036h,038h,03ah	; 6ee0
	defb 03ch,03eh,040h,042h,044h,046h	; 6ee6
	defb 048h,04ah,04ch,04eh,050h,068h	; 6eec
	defb 078h,090h,0a0h,0b0h,0c0h,0d0h	; 6ef2

; ======================================================================
; CODIGO 0x6ef8..0x6f48  (80 bytes)
; ======================================================================


PARPADEA_LA_BARRA:		; En el paso 0x16 la barra parpadea, y con el boton se levanta
	ld a,(0e105h)		;6ef8
	cp 016h		;6efb   ; Solo en el 0x16
	ret nz			;6efd
	call z,COLOR_QUE_PARPADEA		;6efe
	ld a,(0e043h)		;6f01
	and 010h		;6f04   ; Bit 4: el boton levanta
	ret z			;6f06
	ld hl,0e105h		;6f07
	inc (hl)			;6f0a
	inc hl			;6f0b
	ld (hl),017h		;6f0c   ; El levantamiento arranca en el 0x17, y el 0x1D es la barra quieta
	inc hl			;6f0e
	ld (hl),01dh		;6f0f   ; El paso 0x1D: la barra quieta
	jr L_6F1C		;6f11
COLOR_QUE_PARPADEA:		; El bit 2 del contador elige entre el color 1 y el 0x0F
	ld a,(0e003h)		;6f13
	bit 2,a		;6f16   ; Bit 2: cuatro fotogramas con cada color
	ld a,00fh		;6f18
	jr nz,L_6F1E		;6f1a
L_6F1C:
	ld a,001h		;6f1c
L_6F1E:
	ld (0e0c3h),a		;6f1e   ; El color va a las dos fichas, E0C3 y E0D3
	ld (0e0d3h),a		;6f21
	ret			;6f24
PINTA_LOS_KILOS:		; Los kilos de la categoria, sacados de la tabla de 0x6F48, en el cartel KG de la fila 19
	ld a,(0e110h)		;6f25
	add a,a			;6f28
	ld de,06f49h		;6f29   ; La tabla, indexada por dos con la categoria
	call DE_MAS_A		;6f2c
	ld a,(de)			;6f2f
	ld (0e125h),a		;6f30
	dec de			;6f33
	add a,010h		;6f34
	ld hl,03a78h		;6f36   ; Fila 19, columna 24
	call VPOKE		;6f39
	inc hl			;6f3c
	ld c,0ffh		;6f3d   ; C a 0xFF: los ceros tambien se pintan
	ld b,001h		;6f3f
	ld a,(de)			;6f41
	ld (0e124h),a		;6f42
	jp PINTA_LAS_CIFRAS_DE_DE		;6f45

; ----------------------------------------------------------------------
; DATOS kilos_de_cada_categoria: Ocho pesos en BCD, uno por categoria: 150,
;   165, 180, 195, 210, 225, 240 y 260 kilos. La cifra de las centenas la
;   pinta 0x6F36 en el cartel KG
;   0x6f48..0x6f58  (16 bytes)
DATA_kilos_de_cada_categoria:
	defb 050h,001h,065h,001h	; 6f48
	defb 080h,001h,095h,001h	; 6f4c
	defb 010h,002h,025h,002h	; 6f50
	defb 040h,002h,060h,002h	; 6f54

; ======================================================================
; CODIGO 0x6f58..0x7003  (171 bytes)
; ======================================================================


PINTA_LAS_LUCES_DEL_JURADO:		; Las tres luces de la columna 2, bajo el rotulo JUDGE: encendidas con el tile 0x8F las que diga E123, y apagadas las demas
	ld a,(0e123h)		;6f58
	ld b,a			;6f5b
	sub 003h		;6f5c   ; Lo que le falta a E123 para tres: las luces apagadas
	neg		;6f5e
	ld c,a			;6f60
	ld a,08fh		;6f61
	ld hl,03a22h		;6f63   ; Fila 17, columna 2: la de mas abajo
	call PINTA_HACIA_ARRIBA		;6f66
	ld b,c			;6f69
	xor a			;6f6a   ; Y el tile 0 para las de arriba
PINTA_HACIA_ARRIBA:		; B casillas con el tile de A, subiendo de fila en fila
	ld de,0ffe0h		;6f6b   ; Una fila menos son 32 casillas menos
PINTA_B_CASILLAS:		; B casillas con el tile de A; con B a cero no pinta nada
	dec b			;6f6e   ; Con B a cero no se pinta nada
	inc b			;6f6f
	ret z			;6f70
L_6F71:
	call VPOKE		;6f71
	add hl,de			;6f74
	djnz L_6F71		;6f75
	ret			;6f77
CUENTA_LAS_LUCES_DEL_JURADO:		; Con la barra en el paso 0x1C, cada 0x20 fotogramas se enciende una luz; a la tercera, el levantamiento es valido
	ld a,(0e105h)		;6f78
	cp 01ch		;6f7b   ; Solo en el paso 0x1C
	ld hl,0e122h		;6f7d
	jr nz,SIN_LUCES		;6f80
	dec (hl)			;6f82   ; 0x20 fotogramas entre luz y luz
	ret nz			;6f83
	ld (hl),020h		;6f84
	inc hl			;6f86
	inc (hl)			;6f87
	ld a,(hl)			;6f88
	push af			;6f89
	ld a,092h		;6f8a   ; El sonido 0x92
	call SUENA_SI_SE_PUEDE		;6f8c
	pop af			;6f8f
	cp 003h		;6f90
	ret nz			;6f92
	ld a,001h		;6f93   ; E071 y E1A3 a uno: levantamiento valido
	ld (0e071h),a		;6f95
	ld (0e1a3h),a		;6f98
	ret			;6f9b
SIN_LUCES:		; Fuera del paso 0x1C, la cuenta vuelve a 0x20 y las luces se apagan
	ld (hl),020h		;6f9c
	inc hl			;6f9e
	ld (hl),000h		;6f9f
	ret			;6fa1
CAE_LA_BARRA:		; Tres fases en E138: arranca el sonido, deja caer los dos discos y espera a que el canal calle. Devuelve Z cuando ha terminado
	ld hl,0e105h		;6fa2
	ld a,(hl)			;6fa5
	cp 017h		;6fa6   ; Por debajo del 0x17 la barra ni llego a subir: se acaba en el sitio
	jr nc,L_6FB3		;6fa8
	call SUENA_Y_ESPERA		;6faa
	xor a			;6fad
	ret			;6fae
SUENA_Y_ESPERA:		; El sonido 0xAE y sale con 0xFF: aun no ha terminado
	ld a,0aeh		;6faf
	jr L_6FC8		;6fb1
L_6FB3:
	ld (hl),01dh		;6fb3   ; El paso 0x1D es la barra quieta
	ld hl,0e138h		;6fb5
	ld a,(hl)			;6fb8
	dec a			;6fb9
	jr nz,ESPERA_A_QUE_CALLE		;6fba   ; Fase 1: la caida
	dec hl			;6fbc
	ld a,(hl)			;6fbd
	inc (hl)			;6fbe   ; E137 baja dos puntos por fotograma
	inc (hl)			;6fbf
	cp 03ch		;6fc0   ; Hasta 0x3C, que son treinta fotogramas
	jr c,CAEN_LOS_DOS_DISCOS		;6fc2
	inc hl			;6fc4
	inc (hl)			;6fc5
	ld a,094h		;6fc6   ; Al llegar, el sonido 0x94 y la fase 2
L_6FC8:
	call ARRANCA_EL_EFECTO		;6fc8
	or 0ffh		;6fcb
	ret			;6fcd
CAEN_LOS_DOS_DISCOS:		; Las dos primeras fichas de sprite, patrones 0 y 4 -los dos discos de la barra-, bajando desde la Y 0x4A y corriendose hasta ocho puntos a la derecha
	ld d,a			;6fce
	and a			;6fcf
	rra			;6fd0   ; La mitad de lo caido, con tope en ocho: lo que se corre a la derecha
	cp 008h		;6fd1
	jr c,L_6FD7		;6fd3
	ld a,008h		;6fd5
L_6FD7:
	add a,058h		;6fd7   ; 0x58 es la X de partida
	ld e,a			;6fd9
	ld a,04ah		;6fda   ; Y 0x4A la Y
	add a,d			;6fdc
	ld d,a			;6fdd
	ld c,000h		;6fde
	ld b,002h		;6fe0   ; Dos fichas
	ld hl,0e0c0h		;6fe2
L_6FE5:
	ld (hl),d			;6fe5
	inc hl			;6fe6
	ld (hl),e			;6fe7
	inc hl			;6fe8
	ld (hl),c			;6fe9
	ld c,004h		;6fea   ; La segunda lleva el patron 4
	inc hl			;6fec
	ld (hl),001h		;6fed   ; El color 1, negro
	inc hl			;6fef
	ld a,010h		;6ff0   ; Una ficha al lado de la otra
	add a,e			;6ff2
	ld e,a			;6ff3
	djnz L_6FE5		;6ff4
	or a			;6ff6   ; Sale con NZ: la caida sigue
	ret			;6ff7
ESPERA_A_QUE_CALLE:		; Fase 2: hasta que el canal de E036 calle no se da por terminado
	dec a			;6ff8   ; La fase 2 si el contador estaba en 2
	jr nz,ARRANCA_LA_CAIDA		;6ff9
	ld a,(0e036h)		;6ffb   ; El canal de E036: mientras suene, no se acaba
	and a			;6ffe
	ret			;6fff
ARRANCA_LA_CAIDA:		; Fase 0: pasa a la 1 y suena
	inc (hl)			;7000   ; A la fase siguiente
	jr SUENA_Y_ESPERA		;7001

; ----------------------------------------------------------------------
; DATOS rle_7003: Flujo comprimido con su direccion de VRAM delante: 576 bytes
;   de VRAM
;   0x7003..0x7148  (325 bytes)
DATA_rle_7003:
	defb 068h,0ffh,097h,0f4h,024h,0a4h,0a4h,043h,000h,001h,003h,0b8h,0a5h,0a5h,0a5h,038h	; 7003  h...$..C.......8
	defb 000h,0ffh,0ffh,0cfh,008h,06fh,028h,0efh,000h,080h,001h,0c0h,001h,000h,007h,003h	; 7013  .....o(.........
	defb 09ch,01ch,038h,070h,0e1h,0cdh,0cdh,0fdh,079h,000h,000h,000h,0eeh,06bh,06bh,06bh	; 7023  ..8p....y....kkk
	defb 0ebh,000h,000h,000h,073h,01ah,07ah,05ah,07ah,000h,003h,000h,0f3h,004h,05bh,028h	; 7033  ....s.zZz.....[(
	defb 000h,008h,001h,009h,0fch,081h,0feh,009h,0ffh,087h,07fh,03fh,01fh,00fh,00fh,000h	; 7043  ...........?....
	defb 000h,006h,0e7h,082h,03fh,07fh,009h,0ffh,083h,0feh,0fch,0f8h,00ah,0f0h,008h,03fh	; 7053  ....?..........?
	defb 008h,00fh,084h,0f0h,0f0h,0f8h,0fch,003h,0ffh,081h,0fch,008h,0f0h,008h,01fh,008h	; 7063  ................
	defb 003h,008h,0c0h,006h,0ffh,00ah,0f0h,084h,00fh,007h,007h,00fh,004h,0ffh,085h,0e7h	; 7073  ................
	defb 0c3h,0c3h,000h,0ffh,003h,000h,085h,0fch,0f8h,0f8h,0ffh,000h,003h,0ffh,085h,0c1h	; 7083  ................
	defb 0e1h,0e1h,001h,0ffh,003h,001h,010h,0feh,084h,0f0h,0e0h,0e0h,0f0h,004h,0ffh,008h	; 7093  ................
	defb 0feh,090h,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,0ffh,07fh,03fh,01fh,00fh,007h	; 70a3  ............?...
	defb 003h,001h,003h,0fch,00ah,0feh,00bh,0fch,00dh,0fdh,087h,000h,000h,0ffh,0f8h,0f8h	; 70b3  ................
	defb 0fch,0feh,012h,0ffh,082h,0fch,0f8h,010h,0fch,003h,0ffh,003h,03ch,082h,018h,0ffh	; 70c3  ............<...
	defb 004h,0ffh,004h,0f8h,004h,0c3h,008h,0ffh,004h,03ch,084h,0e0h,0e0h,0c0h,080h,008h	; 70d3  .........<......
	defb 0ffh,004h,0e0h,008h,03fh,003h,0ffh,00ah,002h,08ah,0ffh,0ffh,003h,0f8h,0f8h,0fch	; 70e3  ....?...........
	defb 0ffh,0fch,0f8h,0f8h,007h,0ffh,08dh,03fh,01fh,01fh,01fh,03fh,0ffh,03fh,01fh,01fh	; 70f3  .......?...?.?..
	defb 0ffh,0fch,0ffh,0ffh,005h,002h,088h,004h,000h,040h,000h,004h,000h,040h,000h,008h	; 7103  .........@...@..
	defb 07eh,090h,0f0h,0f0h,0e0h,0c0h,000h,000h,000h,0c0h,000h,018h,03ch,07eh,07eh,07eh	; 7113  ~...........<~~~
	defb 03ch,018h,008h,0f0h,090h,03ch,07eh,0dbh,0e7h,0e7h,0dbh,07eh,03ch,099h,0dbh,07eh	; 7123  <....<~....~<..~
	defb 03ch,099h,0dbh,07eh,03ch,002h,0ffh,003h,09ch,083h,0a4h,05bh,0ffh,003h,039h,082h	; 7133  <..~<......[..9.
	defb 0dah,025h,003h,0ffh,000h	; 7143

; ----------------------------------------------------------------------
; DATOS rle_7148: Flujo comprimido con su direccion de VRAM delante: 676 bytes
;   de VRAM
;   0x7148..0x7241  (249 bytes)
DATA_rle_7148:
	defb 004h,050h,010h,0e0h,002h,000h,00ah,050h,089h,090h,060h,090h,060h,090h,090h,060h	; 7148  .P.....P..`.`..`
	defb 090h,060h,013h,090h,081h,060h,006h,090h,003h,0f0h,09ah,0e0h,000h,000h,0f0h,0f0h	; 7158  .`...`..........
	defb 090h,060h,060h,060h,090h,090h,060h,090h,060h,090h,090h,0f0h,0f0h,000h,0e0h,0f0h	; 7168  .```..`.`.......
	defb 0f0h,090h,090h,060h,060h,008h,040h,070h,0f4h,044h,09fh,081h,06fh,00ah,09fh,081h	; 7178  ...``.@p.D..o...
	defb 096h,004h,09fh,081h,06fh,007h,09fh,081h,06fh,003h,09fh,004h,0f9h,081h,0f6h,007h	; 7188  ....o...o.......
	defb 0f9h,081h,0f6h,003h,0f9h,004h,0e0h,00ch,005h,008h,096h,003h,06fh,005h,069h,008h	; 7198  ............o.i.
	defb 096h,008h,069h,018h,096h,008h,06fh,010h,092h,027h,0afh,081h,000h,004h,06eh,004h	; 71a8  ..i...o..'....n.
	defb 090h,004h,060h,005h,090h,08fh,060h,090h,060h,090h,09fh,06fh,09fh,09fh,06fh,09fh	; 71b8  ..`...`.`..o..o.
	defb 06fh,09fh,09fh,06fh,09fh,008h,00fh,090h,000h,0f0h,0f0h,0f9h,0f6h,0f6h,0f6h,090h	; 71c8  o..o............
	defb 000h,0e0h,0f0h,0f0h,09eh,09eh,06eh,06eh,004h,0efh,004h,090h,084h,000h,0e0h,0f0h	; 71d8  ......nn........
	defb 0f0h,004h,0feh,004h,0e6h,004h,090h,091h,000h,0e0h,0f0h,0f0h,0e9h,0e9h,0e6h,0e6h	; 71e8  ................
	defb 09fh,06fh,09fh,06fh,09fh,09fh,06fh,09fh,000h,00eh,0fah,081h,0f0h,004h,09fh,004h	; 71f8  .o.o..o.........
	defb 096h,087h,090h,060h,090h,060h,090h,09fh,06fh,005h,09fh,004h,096h,081h,00fh,007h	; 7208  ...`.`..o.......
	defb 0fah,008h,0d2h,008h,070h,007h,0f9h,081h,069h,008h,0f0h,004h,005h,004h,0eeh,002h	; 7218  ....p...i.......
	defb 0d9h,004h,0d6h,002h,0d9h,008h,07ch,090h,000h,066h,020h,02bh,02bh,0d4h,0d4h,0e0h	; 7228  ......|..f ++...
	defb 020h,026h,026h,07dh,07dh,0e0h,0a0h,040h,000h	; 7238   &&}}..@.

; ----------------------------------------------------------------------
; DATOS dieciseis_a_la_vram: Los dieciseis bytes que 0x50B3 copia a la VRAM
;   cuando (0xE1A3) no es cero; con (0xE1A3) a cero se copian los de 0x7230
;   0x7241..0x7251  (16 bytes)
DATA_dieciseis_a_la_vram:
	defb 000h,066h,0b0h,0bbh,0bbh,0b4h,0b4h,0b0h	; 7241  .f......
	defb 0b0h,0b6h,0b6h,0bdh,0bdh,0b0h,0b0h,040h	; 7249  .......@

; ----------------------------------------------------------------------
; DATOS flujo_7251: Flujo comprimido: 1568 bytes de VRAM
;   0x7251..0x756d  (796 bytes)
DATA_flujo_7251:
	defb 094h,00fh,01fh,03fh,07fh,0ffh,0fdh,0feh,0fah,0fah,0feh,0fdh,0ffh,07fh,03fh,01fh	; 7251  ...?..........?.
	defb 00fh,0b8h,0dch,0eeh,0f7h,008h,0fbh,098h,0f7h,0eeh,0dch,0b8h,00fh,01fh,03fh,07fh	; 7261  ..............?.
	defb 0ffh,0ffh,003h,0fdh,0fdh,003h,0ffh,0ffh,07fh,03fh,01fh,00fh,0b8h,0dch,0eeh,0f7h	; 7271  .........?......
	defb 008h,0fbh,088h,0f7h,0eeh,0dch,0b8h,01fh,03fh,07fh,07fh,008h,0ffh,087h,07fh,03fh	; 7281  ........?......?
	defb 00fh,007h,0f8h,0fch,0feh,00ah,0ffh,083h,0feh,0fch,0f8h,004h,000h,08ch,001h,007h	; 7291  ................
	defb 00fh,0dfh,0dfh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,004h,000h,08ch,0fch,0d6h,0d7h	; 72a1  ......?.........
	defb 0d7h,0ffh,0bfh,083h,083h,0ffh,0c6h,0fch,0f8h,004h,000h,08ch,081h,0c1h,060h,020h	; 72b1  ..............` 
	defb 020h,020h,031h,07bh,03fh,01fh,00eh,004h,005h,000h,008h,080h,011h,000h,082h,01fh	; 72c1    1{?...........
	defb 03fh,00eh,000h,085h,0fch,0feh,03fh,07fh,07fh,003h,0ffh,00ah,000h,006h,0ffh,007h	; 72d1  ?.....?.........
	defb 00fh,083h,007h,007h,00fh,006h,000h,086h,0f0h,070h,070h,0f0h,0e0h,0e0h,004h,0f0h	; 72e1  .........pp.....
	defb 018h,000h,088h,078h,078h,07ch,07ch,07ch,07eh,03eh,03eh,008h,000h,082h,00eh,002h	; 72f1  ...xx|||~>>.....
	defb 00eh,000h,002h,001h,00eh,000h,088h,004h,086h,082h,083h,0c3h,0c3h,0e3h,0f7h,005h	; 7301  ................
	defb 03fh,003h,07fh,002h,07eh,081h,07fh,002h,03fh,003h,01fh,006h,000h,083h,004h,00eh	; 7311  ?...~...?.......
	defb 0feh,007h,0ffh,085h,001h,003h,007h,03fh,03fh,004h,07fh,087h,03fh,03fh,01fh,00fh	; 7321  .......??...??..
	defb 003h,000h,000h,003h,0feh,005h,0fch,085h,0fch,0f8h,0f0h,0e0h,0c0h,003h,000h,004h	; 7331  ................
	defb 01fh,01eh,000h,082h,01ch,03eh,004h,07fh,00bh,000h,085h,002h,006h,00eh,01eh,03eh	; 7341  .....>.........>
	defb 008h,000h,004h,07fh,003h,03fh,083h,03eh,07eh,0feh,004h,0fch,082h,0f8h,078h,007h	; 7351  .....?.>~.....x.
	defb 07eh,083h,03ch,07ch,0fch,003h,0f8h,003h,0f0h,084h,0fch,0feh,0ffh,0ffh,00fh,000h	; 7361  ~.<|............
	defb 081h,080h,00ch,000h,087h,060h,0e0h,0f8h,0f8h,0fch,07eh,03fh,019h,000h,08ah,03eh	; 7371  .....`....~?...>
	defb 07fh,0ffh,0ffh,0ffh,07fh,03fh,001h,000h,000h,004h,001h,003h,000h,08dh,080h,0e0h	; 7381  .....?..........
	defb 0f0h,0f8h,0fch,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h,00ch,000h,083h,001h,01fh	; 7391  ................
	defb 07fh,003h,0ffh,008h,000h,09dh,030h,07ch,0ffh,0feh,0f8h,0f0h,080h,000h,00fh,01fh	; 73a1  ......0|........
	defb 03fh,03fh,03fh,01fh,00fh,01fh,03fh,07fh,0ffh,0feh,0f8h,0f0h,0e0h,080h,080h,0e0h	; 73b1  ???...?.........
	defb 0f8h,0fch,0feh,005h,0ffh,08dh,07eh,07eh,07ch,07ch,078h,078h,010h,030h,070h,0f0h	; 73c1  ......~~||xx.0p.
	defb 0f0h,0f0h,060h,019h,000h,081h,007h,004h,00fh,090h,007h,003h,001h,000h,001h,003h	; 73d1  ..`.............
	defb 00fh,03fh,07fh,0ffh,0ffh,080h,0c1h,0f3h,0ffh,0ffh,003h,0feh,006h,0ffh,085h,0feh	; 73e1  .?..............
	defb 07eh,0fch,0f0h,060h,00dh,000h,083h,07ch,07ch,078h,00dh,000h,082h,003h,007h,005h	; 73f1  ~..`...||x......
	defb 00fh,09fh,007h,007h,003h,003h,001h,001h,007h,00fh,01fh,080h,0c0h,0e1h,0e3h,0f7h	; 7401  ................
	defb 0ffh,0ffh,0feh,0feh,0fch,0fch,0f8h,0f8h,0f8h,0f0h,0f0h,03fh,03fh,07fh,07fh,037h	; 7411  ...........??..7
	defb 003h,00ah,000h,003h,0e0h,003h,0c0h,00ah,000h,083h,00eh,01fh,01fh,006h,03fh,003h	; 7421  ..............?.
	defb 01fh,08ah,00fh,00fh,01fh,01fh,000h,000h,004h,08ch,09ch,0bch,007h,0fch,084h,0f8h	; 7431  ................
	defb 0f8h,0f0h,01fh,004h,03fh,081h,01fh,00ah,000h,084h,0e0h,0c0h,0c0h,080h,015h,000h	; 7441  ....?...........
	defb 087h,01fh,03fh,03fh,07fh,07fh,0ffh,0ffh,009h,000h,082h,0fch,0feh,025h,0ffh,08ah	; 7451  ..??.........%..
	defb 08ch,00ch,018h,018h,01ch,01eh,01eh,00eh,00eh,01eh,036h,000h,088h,060h,0e0h,0f0h	; 7461  ..........6..`..
	defb 0f0h,078h,038h,038h,078h,038h,000h,085h,03ch,01ch,01ch,03ch,0f8h,03bh,000h,087h	; 7471  .x88x8..<..<.;..
	defb 03ch,01ch,01ch,03ch,0f8h,0f0h,0e0h,039h,000h,089h,01eh,00eh,00eh,01eh,07eh,07eh	; 7481  <..<...9......~~
	defb 07ch,0fch,038h,01bh,000h,08ch,001h,007h,00fh,0dfh,0dfh,0ffh,0ffh,07fh,03fh,01fh	; 7491  |.8...........?.
	defb 00fh,007h,004h,000h,08ch,0fch,07ch,0bbh,0d7h,0ffh,0bfh,083h,083h,0ffh,0eeh,0ech	; 74a1  ......|.........
	defb 0f8h,004h,000h,08ch,001h,007h,00fh,0deh,0dfh,0ffh,0ffh,07dh,03eh,01fh,00fh,007h	; 74b1  ...........}>...
	defb 004h,000h,08ch,0fch,0f6h,037h,0d7h,0ffh,0bfh,083h,083h,0fdh,002h,0fch,0f8h,006h	; 74c1  .....7..........
	defb 000h,082h,030h,07ch,003h,07fh,002h,03fh,003h,01fh,007h,000h,081h,007h,005h,0ffh	; 74d1  ..0|...?........
	defb 083h,03fh,01fh,008h,01dh,000h,08eh,0c0h,0e0h,0f6h,0c0h,0f0h,0f8h,0fch,0feh,0efh	; 74e1  .?..............
	defb 0f7h,079h,039h,03bh,078h,00bh,000h,004h,080h,006h,000h,090h,007h,01fh,03fh,07fh	; 74f1  .y9;x.........?.
	defb 07fh,0ffh,0fch,0fch,07eh,03fh,01fh,00fh,01fh,01eh,000h,000h,005h,0ffh,003h,07fh	; 7501  ....~?..........
	defb 008h,000h,008h,0ffh,008h,000h,084h,0f0h,0e0h,0c0h,080h,01ah,000h,089h,003h,007h	; 7511  ................
	defb 000h,01ch,03eh,03eh,03eh,01ch,01ch,005h,03ch,081h,07ch,003h,0f8h,008h,000h,081h	; 7521  ..>>>...<.|.....
	defb 0feh,007h,0ffh,082h,000h,0e0h,004h,0f0h,09ah,0f8h,07ch,07ch,0beh,0feh,0feh,0feh	; 7531  ..........||....
	defb 0feh,0fch,000h,000h,000h,038h,01ch,01ch,01ch,01eh,01eh,01fh,00fh,00fh,00fh,00fh	; 7541  .....8..........
	defb 01fh,07fh,0ffh,00ah,000h,006h,080h,005h,000h,087h,0f2h,015h,015h,0f5h,085h,085h	; 7551  ................
	defb 0f2h,009h,000h,081h,022h,005h,055h,081h,022h,004h,000h,000h	; 7561  ....".U."...

; ======================================================================
; CODIGO 0x756d..0x7587  (26 bytes)
; ======================================================================


PINTA_LA_CATEGORIA:		; El nombre de la categoria, catorce tiles de la tabla de 0x7587, en el cartel CHOOSE CLASS de la fila 20; y detras, sus kilos
	ld a,(0e110h)		;756d   ; E110, la categoria elegida
	ld b,a			;7570
	add a,a			;7571   ; Por catorce: doblado tres veces, menos una y otra vez doblado
	add a,a			;7572
	add a,a			;7573
	sub b			;7574
	add a,a			;7575
	ld de,07587h		;7576
	call DE_MAS_A		;7579
	ld hl,03a86h		;757c   ; Fila 20, columna 6
	ld c,00eh		;757f   ; Catorce tiles
	call COPIA_256		;7581
	jp PINTA_LOS_KILOS		;7584

; ----------------------------------------------------------------------
; DATOS nombres_de_las_categorias: Los ocho nombres de categoria, de catorce
;   tiles cada uno: FLY, BANTAM, FEATHER, LIGHT y MIDDLE WEIGHT, MIDDLE HEAVY,
;   HEAVY WEIGHT y SUPER HEAVY
;   0x7587..0x75f7  (112 bytes)
DATA_nombres_de_las_categorias:
	defb 026h,02ch,039h,000h,000h,000h,000h,000h,037h,025h,029h,027h,028h,034h	; 7587  &,9.....7%)'(4
	defb 022h,021h,02eh,034h,021h,02dh,000h,000h,037h,025h,029h,027h,028h,034h	; 7595  "!.4!-..7%)'(4
	defb 026h,025h,021h,034h,028h,025h,032h,000h,037h,025h,029h,027h,028h,034h	; 75a3  &%!4(%2.7%)'(4
	defb 02ch,029h,027h,028h,034h,000h,000h,000h,037h,025h,029h,027h,028h,034h	; 75b1  ,)'(4...7%)'(4
	defb 02dh,029h,024h,024h,02ch,025h,000h,000h,037h,025h,029h,027h,028h,034h	; 75bf  -)$$,%..7%)'(4
	defb 02dh,029h,024h,024h,02ch,025h,000h,000h,028h,025h,021h,036h,039h,000h	; 75cd  -)$$,%..(%!69.
	defb 028h,025h,021h,036h,039h,000h,000h,000h,037h,025h,029h,027h,028h,034h	; 75db  (%!69...7%)'(4
	defb 033h,035h,030h,025h,032h,000h,000h,000h,028h,025h,021h,036h,039h,000h	; 75e9  350%2...(%!69.

; ======================================================================
; CODIGO 0x75f7..0x7626  (47 bytes)
; ======================================================================


ELIGE_LA_CATEGORIA:		; Con el boton se acepta la categoria; con cualquier direccion se pasa a la siguiente, y al dar la vuelta se arranca en la de E075
	ld a,(0e043h)		;75f7
	bit 4,a		;75fa   ; Bit 4 del mando: aceptada
	jp nz,ESPERA_128		;75fc
	and 00fh		;75ff   ; Los cuatro bits bajos: cualquier direccion
	ret z			;7601
	ld a,009h		;7602   ; El sonido 0x09
	call SUENA_SI_SE_PUEDE		;7604
	ld a,(0e075h)		;7607
	ld b,a			;760a
	ld hl,0e110h		;760b
	ld a,(hl)			;760e
	inc a			;760f
	and 007h		;7610   ; Ocho categorias en redondo
	jr nz,L_7615		;7612
	ld a,b			;7614
L_7615:
	ld (hl),a			;7615
	ld (0e110h),a		;7616   ; La escribe dos veces: HL ya apuntaba a E110
	ret			;7619
COPIA_LOS_NUEVE_BYTES:		; Los nueve bytes de 0x7626 a 0xE100
	ld de,0e100h		;761a
	ld hl,07626h		;761d
	ld bc,00009h		;7620
	ldir		;7623
	ret			;7625

; ----------------------------------------------------------------------
; DATOS nueve_de_761D: Los nueve bytes que 0x761D copia con un ldir
;   0x7626..0x762f  (9 bytes)
DATA_nueve_de_761D:
	defb 004h,000h,060h,000h,0e8h,000h,000h,000h,0fch	; 7626  ..`......

; ======================================================================
; CODIGO 0x762f..0x764c  (29 bytes)
; ======================================================================


REARRANCA_LAS_TIRAS:		; Con E179 puesto, deja las dos tiras de nueve bytes y el paso en 5
	ld a,(0e179h)		;762f   ; Sin E179, no se toca nada
	and a			;7632
	ret z			;7633
	ld de,0e118h		;7634
	ld a,002h		;7637   ; Dos vueltas
COPIA_LOS_NUEVE_DEL_REVES:		; Los nueve bytes de 0x764C a 0xE110 y otra vez a 0xE100, copiados hacia atras con un lddr
	ld hl,07654h		;7639
	ld bc,00009h		;763c
	lddr		;763f   ; Del reves: el lddr acaba en el primer byte
	ld e,008h		;7641   ; Y la segunda vuelta, a 0xE100
	dec a			;7643
	jr nz,COPIA_LOS_NUEVE_DEL_REVES		;7644
	ld a,005h		;7646
	ld (0e100h),a		;7648
	ret			;764b

; ----------------------------------------------------------------------
; DATOS nueve_de_7639: Los nueve bytes que 0x7639 copia del reves a 0xE110 y a
;   0xE100: los mismos que los de 0x7626 salvo el primero y el ultimo
;   0x764c..0x7655  (9 bytes)
DATA_nueve_de_7639:
	defb 006h,000h,060h,000h,0e8h,000h,000h,000h,0ffh	; 764c  ..`......

; ======================================================================
; CODIGO 0x7655..0x7832  (477 bytes)
; ======================================================================


L_7655:
	inc hl			;7655
	ld a,(ix+009h)		;7656   ; La altura de antes, mas uno
	inc a			;7659
	cp (hl)			;765a
	jp z,CALLA_EL_CANAL		;765b   ; Si coinciden, la orden de repetir se salta
	jp m,L_7662		;765e   ; Por debajo, se deja como estaba
	dec a			;7661
L_7662:
	ex af,af'			;7662
	ld a,(ix+002h)		;7663   ; La altura nueva
	push bc			;7666
	call REPARTE_EL_EFECTO		;7667
	pop bc			;766a
	ex af,af'			;766b
	ld (ix+009h),a		;766c   ; Y se guarda en el canal
	ret			;766f

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL REPRODUCTOR. Tres canales de doce bytes desde 0xE010: el contador
; de la nota, lo que dura, el estado (que es el numero del efecto que
; suena, con el bit 7 para las ordenes largas y el bit 6 para el
; ruido), el puntero al flujo, la octava, el volumen de fondo, el
; volumen que suena, la cuenta del apagado, la altura y el desafine.
; Cada fotograma 0x7696 da un paso a los tres y deja en 0xE036 el o de
; los tres estados: esa es la bandera de "algo esta sonando" que mira
; medio cartucho.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ABRE_O_CIERRA_EL_CANAL:		; Toca el bit del canal en el registro 7 del PSG: con D a cero lo abre y con D a uno lo cierra
	ld a,(0e034h)		;7670   ; E034 lleva copia del registro 7
	ld e,a			;7673
	ld a,c			;7674   ; El canal viene en C como 1, 3 o 5
	cp 001h		;7675
	jr z,L_767A		;7677
	dec a			;7679
L_767A:
	rlca			;767a   ; Tres desplazamientos: el bit del canal
	rlca			;767b
	rlca			;767c
	dec d			;767d
	jr z,L_7684		;767e
	cpl			;7680
	and e			;7681
	jr L_7685		;7682
L_7684:
	or e			;7684
L_7685:
	set 1,a		;7685   ; El bit 1 se pone siempre, y si estaba el 4 se quita
	bit 4,a		;7687
	jr z,ESCRIBE_LA_MEZCLA		;7689
	res 1,a		;768b
ESCRIBE_LA_MEZCLA:		; Guarda el registro 7 en E034 y lo manda al PSG
	ld (0e034h),a		;768d
	ld e,a			;7690
	ld a,007h		;7691   ; El registro 7 del PSG es el de la mezcla
	jp 00093h		;7693   ; BIOS WRTPSG - Writes data to PSG-register
CORRE_EL_SONIDO:		; Un paso de los tres canales y, detras, E036 con el o de los tres estados
	call LOS_TRES_CANALES		;7696
	ld de,0000ch		;7699   ; Doce bytes de un canal al siguiente
	ld hl,0e012h		;769c
	ld a,(hl)			;769f
	add hl,de			;76a0
	or (hl)			;76a1
	add hl,de			;76a2
	or (hl)			;76a3
	ld (0e036h),a		;76a4   ; E036: la bandera de que algo suena
	ret			;76a7
LOS_TRES_CANALES:		; IX en 0xE010, C con el canal y tres vueltas de doce bytes
	ld a,(0e034h)		;76a8
	call ESCRIBE_LA_MEZCLA		;76ab
	ld c,001h		;76ae   ; C es el canal: 1, 3 y 5
	ld ix,0e010h		;76b0
	exx			;76b4
	ld b,003h		;76b5   ; Tres canales
	ld de,0000ch		;76b7
VUELTA_DE_UN_CANAL:		; Con el estado a cero, ese canal esta callado
	exx			;76ba
	ld a,(ix+002h)		;76bb
	or a			;76be
	call nz,PASO_DEL_CANAL		;76bf
	inc c			;76c2   ; C sube de dos en dos: el canal siguiente
	inc c			;76c3
	exx			;76c4
	add ix,de		;76c5
	djnz VUELTA_DE_UN_CANAL		;76c7
	ret			;76c9
PASO_DEL_CANAL:		; Abre el canal si no es de ruido y, con el bit 7 del estado, mantiene la nota en vez de leer otra
	bit 6,a		;76ca   ; El bit 6 dice que ese canal es el del ruido
	ld d,001h		;76cc
	call z,ABRE_O_CIERRA_EL_CANAL		;76ce
	ld a,(ix+002h)		;76d1
	or a			;76d4
	jp m,MANTIENE_LA_NOTA		;76d5   ; Con el bit 7 la nota se mantiene
	dec (ix+000h)		;76d8   ; Y mientras el contador no llegue a cero, tampoco se lee nada
	ret nz			;76db
SIGUIENTE_ORDEN:		; Lee la orden que toca del flujo: 0xFE la repeticion, 0xFF y mas el final, y por debajo la nota
	ld l,(ix+003h)		;76dc
	ld h,(ix+004h)		;76df
	ld a,(hl)			;76e2
	cp 0feh		;76e3   ; 0xFE: la orden de repetir
	jp z,L_7655		;76e5
	jr nc,CALLA_EL_CANAL		;76e8   ; De 0xFF en adelante, se acaba
	bit 7,(ix+002h)		;76ea   ; Con el bit 7 del estado, las ordenes son las de 0x778D
	jp nz,ORDENES_LARGAS		;76ee
	and 0f0h		;76f1
	cp 020h		;76f3   ; 0x2N: N es lo que dura la nota
	jr nz,L_76FE		;76f5
	ld a,(hl)			;76f7
	and 00fh		;76f8
	ld (ix+001h),a		;76fa
	inc hl			;76fd
L_76FE:
	ld a,(hl)			;76fe
	and 0f0h		;76ff
	cp 010h		;7701   ; 0x1N: el registro 6 del PSG, el periodo del ruido
	jr nz,NOTA_O_RUIDO		;7703
	ld a,(hl)			;7705
	and 01fh		;7706
	ld e,a			;7708
	ld a,006h		;7709
	call 00093h		;770b   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;770e
	call ABRE_O_CIERRA_EL_CANAL		;7710   ; Y el ruido abre su canal
	inc hl			;7713
	ld a,(hl)			;7714
NOTA_O_RUIDO:		; El canal de ruido se salta la altura; los demas la parten en nibble alto y bajo
	bit 6,(ix+002h)		;7715
	jr z,PARTE_LA_NOTA		;7719   ; Sin el bit 6, la nota de siempre
	ld a,c			;771b
	cp 003h		;771c   ; Solo el tercer canal
	ld a,(hl)			;771e
	jr nz,PARTE_LA_NOTA		;771f
	call APUNTA_EL_FLUJO		;7721
	jr GUARDA_LA_DURACION		;7724
PARTE_LA_NOTA:		; El nibble alto es el volumen y el bajo la nota; el byte de detras, la octava
	and 0f0h		;7726
	ld b,a			;7728
	xor (hl)			;7729   ; Un xor deja el nibble bajo: la nota
	ld d,a			;772a
	inc hl			;772b
	ld e,(hl)			;772c
	call APUNTA_EL_FLUJO		;772d   ; Se apunta el flujo detras
	ex de,hl			;7730
	call ESCRIBE_EL_PERIODO		;7731
	ld a,b			;7734
	rrca			;7735
	rrca			;7736
	rrca			;7737
	rrca			;7738
GUARDA_LA_DURACION:		; Deja lo que dura la nota en el contador, y tres mas en la cuenta del apagado
	ld h,a			;7739   ; Lo que dura la nota
	ld a,(ix+001h)		;773a
	ld (ix+000h),a		;773d
	add a,003h		;7740   ; Tres mas: la cuenta del apagado
	ld (ix+008h),a		;7742
	jr ESCRIBE_EL_VOLUMEN		;7745
CALLA_EL_CANAL:		; Cierra el canal, borra el estado y baja el volumen a cero
	xor a			;7747
	ld (ix+009h),a		;7748   ; La altura y el desafine a cero
	ld (ix+00bh),a		;774b
	ld d,001h		;774e   ; D a uno: el canal se cierra
	call ABRE_O_CIERRA_EL_CANAL		;7750
	xor a			;7753
	ld (ix+002h),a		;7754   ; Y el estado a cero: el canal queda libre
	ld h,a			;7757
	jr ESCRIBE_EL_VOLUMEN		;7758
MANTIENE_LA_NOTA:		; Baja el contador y, con el, la cuenta del apagado: el volumen va cayendo de uno en uno
	dec (ix+000h)		;775a
	jp z,SIGUIENTE_ORDEN		;775d   ; Al llegar a cero, a por la orden siguiente
	dec (ix+008h)		;7760
	ld a,(ix+008h)		;7763
	cp (ix+000h)		;7766   ; Mientras las dos cuentas no coincidan, no se apaga
	jr nz,L_7770		;7769
	cp 003h		;776b
	jr c,L_7773		;776d
	ret			;776f
L_7770:
	dec (ix+008h)		;7770
L_7773:
	ld a,(ix+007h)		;7773   ; El volumen baja de uno en uno hasta cero
	dec a			;7776
	ret m			;7777
	ld (ix+007h),a		;7778
	ld h,a			;777b
ESCRIBE_EL_VOLUMEN:		; Los registros 8, 9 y 10 del PSG, uno por canal
	ld a,(ix+002h)		;777c
	cp 094h		;777f   ; El efecto 0x94 suena dos puntos mas fuerte
	jr nz,L_7785		;7781
	inc h			;7783
	inc h			;7784
L_7785:
	ld a,c			;7785
	rrca			;7786
	add a,088h		;7787   ; C partido por dos y mas 8: los registros 8, 9 y 10
	ld e,h			;7789
	jp 00093h		;778a   ; BIOS WRTPSG - Writes data to PSG-register
ORDENES_LARGAS:		; Las ordenes del bit 7: 0xDN el desafine, 0xFN el volumen de fondo, 0xEN la octava o el vibrato
	ld a,(hl)			;778d
	and 0f0h		;778e
	cp 0d0h		;7790   ; 0xDN: lo que se le suma a la altura
	ld a,(hl)			;7792
	jr nz,L_779C		;7793
	and 00fh		;7795
	ld (ix+00ah),a		;7797
	inc hl			;779a
	ld a,(hl)			;779b
L_779C:
	cp 0f0h		;779c   ; 0xFN: el volumen de fondo
	jr c,L_77A7		;779e
	and 00fh		;77a0
	ld (ix+006h),a		;77a2
	inc hl			;77a5
	ld a,(hl)			;77a6
L_77A7:
	cp 0e0h		;77a7   ; 0xEN: la octava, y con el bit 3 el desafine
	jr c,ALTURA_DE_LA_NOTA		;77a9
	and 00fh		;77ab   ; El nibble bajo de la orden
	bit 3,a		;77ad   ; Con el bit 3, lo que llega es el desafine
	jr z,L_77B7		;77af
	ld (ix+00bh),a		;77b1
	inc hl			;77b4
	jr ORDENES_LARGAS		;77b5
L_77B7:
	ld (ix+005h),a		;77b7   ; Y si no, la octava
	inc hl			;77ba
	ld a,(hl)			;77bb
ALTURA_DE_LA_NOTA:		; La nota por el desafine, sumandolo tantas veces como diga el nibble bajo
	and 00fh		;77bc
	ld b,a			;77be
	ld a,(ix+00ah)		;77bf   ; El desafine del canal
	jr z,ELIGE_EL_VOLUMEN		;77c2
L_77C4:
	add a,(ix+00ah)		;77c4   ; Sumado tantas veces como diga el nibble
	djnz L_77C4		;77c7
ELIGE_EL_VOLUMEN:		; Guarda la nota, avanza el flujo y saca el volumen: con 0xC0 el de fondo o el del contador
	ld (ix+001h),a		;77c9
	ld a,(hl)			;77cc
	call APUNTA_EL_FLUJO		;77cd
	cp 0c0h		;77d0   ; 0xC0: la nota sin volumen propio
	jr nz,L_77F0		;77d2
	ld a,(ix+002h)		;77d4
	cp 086h		;77d7   ; El efecto 0x86 sube su propio contador de 0xE035
	jr nz,L_77EC		;77d9
	ld a,(0e035h)		;77db   ; E035, el contador del efecto 0x86
	or a			;77de
	jr z,L_77E5		;77df
	cp 00fh		;77e1   ; Topado en 0x0F
	jr z,L_77E9		;77e3
L_77E5:
	inc a			;77e5
	ld (0e035h),a		;77e6
L_77E9:
	ld (ix+001h),a		;77e9   ; Y ese es el numero de la nota
L_77EC:
	xor a			;77ec   ; Sin volumen propio: se coge el de fondo
	ld b,a			;77ed
	jr PERIODO_DE_LA_NOTA		;77ee
L_77F0:
	and 0f0h		;77f0   ; El nibble alto es el volumen, y el 0x0C deja el de fondo
	rrca			;77f2
	rrca			;77f3
	rrca			;77f4
	rrca			;77f5
	ld b,a			;77f6
	sub 00ch		;77f7
	jr z,PERIODO_DE_LA_NOTA		;77f9
	ld a,(ix+006h)		;77fb

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS DOCE NOTAS. La tabla de 0x7832 son los periodos del PSG de UNA
; octava entera: 0x6A, 0x64, 0x5F, 0x59, 0x54, 0x50, 0x4B, 0x47, 0x43,
; 0x3F, 0x3C y 0x38. Con el reloj del PSG -111.861 Hz partido por el
; periodo- el 0x6A da 1.055 Hz y el 0x38 da 1.998, que son el do y el
; si de la misma octava; y las once razones de en medio caen en el
; semitono. Las demas octavas no se guardan: se sacan doblando el
; periodo en 0x7815, que es exactamente bajar una octava.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PERIODO_DE_LA_NOTA:		; Del indice sale el periodo de 0x7832, se baja tantas octavas como diga la octava y se escribe en el PSG
	ld (ix+007h),a		;77fe
	call GUARDA_LA_DURACION		;7801
	ld a,b			;7804
	ld hl,07832h		;7805   ; La tabla de las doce notas
	call HL_MAS_A		;7808
	ld l,(hl)			;780b
	ld h,000h		;780c
	ld a,(ix+005h)		;780e   ; La octava del canal
	or a			;7811
	jr z,ESCRIBE_EL_PERIODO		;7812
	ld b,a			;7814
BAJA_UNA_OCTAVA:		; Doblar el periodo es bajar una octava
	add hl,hl			;7815
	djnz BAJA_UNA_OCTAVA		;7816
	ld a,(ix+00bh)		;7818   ; Y el desafine suma uno al periodo
	or a			;781b
	jr z,ESCRIBE_EL_PERIODO		;781c
	inc hl			;781e
ESCRIBE_EL_PERIODO:		; Los dos registros del canal: primero el alto y luego el bajo
	ld a,c			;781f
	ld e,h			;7820
	call 00093h		;7821   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7824
	dec a			;7825
	ld e,l			;7826
	jp 00093h		;7827   ; BIOS WRTPSG - Writes data to PSG-register
APUNTA_EL_FLUJO:		; Guarda en el canal por donde va leyendo
	inc hl			;782a
	ld (ix+003h),l		;782b
	ld (ix+004h),h		;782e
	ret			;7831

; ----------------------------------------------------------------------
; DATOS las_doce_notas: Los periodos del PSG de las doce notas de una octava,
;   de do a si; las otras octavas salen doblando en 0x7815
;   0x7832..0x783e  (12 bytes)
DATA_las_doce_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 7832  jd_YTPKGC?<8

; ======================================================================
; CODIGO 0x783e..0x78ac  (110 bytes)
; ======================================================================


SUENA_SI_SE_PUEDE:		; Solo con el bit 6 de E002 puesto; si no, no suena nada
	ld hl,0e002h		;783e
	bit 6,(hl)		;7841
	ret z			;7843
ARRANCA_EL_EFECTO:		; Reparte el efecto de A por los canales que le toquen, con las interrupciones cerradas
	di			;7844   ; Con las interrupciones cerradas
	push hl			;7845
	push de			;7846
	push bc			;7847
	push af			;7848
	cp 001h		;7849   ; El efecto 1 arranca ademas el 0x43 y el 0x42
	jr nz,L_7857		;784b
	call REPARTE_EL_EFECTO		;784d
	ld a,043h		;7850   ; El efecto 1 arrastra el 0x43 y el 0x42
	call REPARTE_EL_EFECTO		;7852
	ld a,042h		;7855
L_7857:
	call REPARTE_EL_EFECTO		;7857
	pop af			;785a   ; Se recupera todo y se vuelve a abrir
	pop bc			;785b
	pop de			;785c
	pop hl			;785d
	ei			;785e
	ret			;785f
REPARTE_EL_EFECTO:		; Segun el numero, el efecto ocupa uno, dos o tres canales, y no pisa a otro de mas peso
	ld c,a			;7860
	ld b,002h		;7861   ; Dos canales por defecto
	ld hl,0e012h		;7863
	and 03fh		;7866
	cp 00ah		;7868   ; Por debajo del 0x0A va a un solo canal
	jr c,L_7873		;786a
	cp 016h		;786c   ; Del 0x16 en adelante, a los tres
	jr c,SOLO_SI_PESA_MAS		;786e
	inc b			;7870
	jr SOLO_SI_PESA_MAS		;7871
L_7873:
	dec b			;7873   ; Un canal: el 0, el 1 o el 2 segun el numero
	cp 002h		;7874
	jr c,MONTA_EL_EFECTO		;7876
	ld hl,0e01eh		;7878
	jr z,MONTA_EL_EFECTO		;787b
	ld hl,0e02ah		;787d
	cp 003h		;7880
	jr z,MONTA_EL_EFECTO		;7882
SOLO_SI_PESA_MAS:		; Los seis bits bajos son el peso: si el que suena pesa mas, el nuevo no entra
	ld a,(hl)			;7884
	and 03fh		;7885   ; Los seis bits bajos del que ya suena
	ld e,a			;7887
	ld a,c			;7888
	and 03fh		;7889
	cp e			;788b   ; Si ese pesa mas, el nuevo no entra
	ret c			;788c
MONTA_EL_EFECTO:		; Deja en cada canal el contador a uno, el numero del efecto y el puntero de la tabla de 0x78AC
	add a,a			;788d
	ld de,078aah		;788e   ; La tabla arranca en 0x78AA: el efecto 1 es la primera palabra de 0x78AC
	call DE_MAS_A		;7891
	dec hl			;7894   ; Dos atras: el primer byte del canal
	dec hl			;7895
MONTA_UN_CANAL:		; Los cinco bytes de arranque de un canal
	ld (hl),001h		;7896   ; El contador y la duracion a uno: la primera nota entra ya
	inc hl			;7898
	ld (hl),001h		;7899
	inc hl			;789b
	ld (hl),c			;789c   ; El numero del efecto se queda de estado
	inc hl			;789d
	ld a,(de)			;789e   ; Y detras, el puntero del flujo
	ld (hl),a			;789f
	inc hl			;78a0
	inc de			;78a1
	ld a,(de)			;78a2
	ld (hl),a			;78a3
	ld a,008h		;78a4   ; Ocho mas: el primer byte del canal siguiente
	add a,l			;78a6
	ld l,a			;78a7
	inc de			;78a8
	djnz MONTA_UN_CANAL		;78a9
	ret			;78ab

; ----------------------------------------------------------------------
; DATOS tabla_de_efectos: Los 48 punteros a los efectos y melodias cortas del
;   reproductor, cada uno a su tira de eventos. La tabla cierra clavada contra
;   su destino mas bajo, 0x790C
;   0x78ac..0x790c  (96 bytes)
DATA_tabla_de_efectos:
	defw 0790ch	; 78ac  -> DATA_tira_00
	defw 0793bh	; 78ae  -> DATA_tira_02
	defw 0792fh	; 78b0  -> DATA_tira_01
	defw 07940h	; 78b2  -> DATA_tira_03
	defw 0794ah	; 78b4  -> DATA_tira_04
	defw 07985h	; 78b6  -> DATA_tira_07
	defw 0795ch	; 78b8  -> DATA_tira_06
	defw 0798ch	; 78ba  -> DATA_tira_08
	defw 07a60h	; 78bc  -> DATA_tira_0D
	defw 079a0h	; 78be  -> DATA_tira_09
	defw 079eah	; 78c0  -> DATA_tira_0A
	defw 07ac4h	; 78c2  -> DATA_tira_12
	defw 07acbh	; 78c4  -> DATA_tira_13
	defw 07a74h	; 78c6  -> DATA_tira_0E
	defw 07a9ah	; 78c8  -> DATA_tira_0F
	defw 07a34h	; 78ca  -> DATA_tira_0B
	defw 07a46h	; 78cc  -> DATA_tira_0C
	defw 07aeah	; 78ce  -> DATA_tira_17
	defw 07afbh	; 78d0  -> DATA_tira_18
	defw 07aach	; 78d2  -> DATA_tira_10
	defw 07ab8h	; 78d4  -> DATA_tira_11
	defw 07ad2h	; 78d6  -> DATA_tira_14
	defw 07adah	; 78d8  -> DATA_tira_15
	defw 07ae2h	; 78da  -> DATA_tira_16
	defw 07b0ch	; 78dc  -> DATA_tira_19
	defw 07b11h	; 78de  -> DATA_tira_1A
	defw 07b16h	; 78e0  -> DATA_tira_1B
	defw 07b1bh	; 78e2  -> DATA_tira_1C
	defw 07b35h	; 78e4  -> DATA_tira_1D
	defw 07b4ch	; 78e6  -> DATA_tira_1E
	defw 07b6ah	; 78e8  -> DATA_tira_1F
	defw 07b6bh	; 78ea  -> DATA_tira_20
	defw 07b83h	; 78ec  -> DATA_tira_21
	defw 07b9bh	; 78ee  -> DATA_tira_22
	defw 07b9ch	; 78f0  -> DATA_tira_23
	defw 07bb6h	; 78f2  -> DATA_tira_24
	defw 07bd7h	; 78f4  -> DATA_tira_25
	defw 07bd8h	; 78f6  -> DATA_tira_26
	defw 07bedh	; 78f8  -> DATA_tira_27
	defw 07bffh	; 78fa  -> DATA_tira_28
	defw 07c12h	; 78fc  -> DATA_tira_29
	defw 07c1ch	; 78fe  -> DATA_tira_2A
	defw 07c2ah	; 7900  -> DATA_tira_2B
	defw 07c2bh	; 7902  -> DATA_tira_2C
	defw 07c8eh	; 7904  -> DATA_tira_2D
	defw 0795bh	; 7906  -> DATA_tira_05
	defw 0795bh	; 7908  -> DATA_tira_05
	defw 0795bh	; 790a  -> DATA_tira_05

; ----------------------------------------------------------------------
; DATOS tira_00: Tira de eventos de 35 bytes: la entrada 0 de la tabla de
;   0x78AC
;   0x790c..0x792f  (35 bytes)
DATA_tira_00:
	defb 024h,000h,000h,026h,090h,021h,090h,020h,090h,021h,090h,020h,02fh,000h,000h,000h	; 790c  $..&.!. .!. /...
	defb 000h,026h,080h,021h,080h,020h,080h,021h,080h,020h,02fh,000h,000h,000h,000h,000h	; 791c  .&.!. .!. /.....
	defb 000h,0feh,002h	; 792c

; ----------------------------------------------------------------------
; DATOS tira_01: Tira de eventos de 12 bytes: la entrada 2 de la tabla de
;   0x78AC
;   0x792f..0x793b  (12 bytes)
DATA_tira_01:
	defb 023h,014h,091h,070h,000h,000h,091h,098h,000h,000h,0feh,013h	; 792f  #..p........

; ----------------------------------------------------------------------
; DATOS tira_02: Tira de eventos de 5 bytes: la entrada 1 de la tabla de
;   0x78AC
;   0x793b..0x7940  (5 bytes)
DATA_tira_02:
	defb 02fh,014h,00bh,0feh,00fh	; 793b

; ----------------------------------------------------------------------
; DATOS tira_03: Tira de eventos de 10 bytes: la entrada 3 de la tabla de
;   0x78AC
;   0x7940..0x794a  (10 bytes)
DATA_tira_03:
	defb 021h,080h,090h,0c1h,000h,023h,000h,000h,0feh,0ffh	; 7940  !....#....

; ----------------------------------------------------------------------
; DATOS tira_04: Tira de eventos de 17 bytes: la entrada 4 de la tabla de
;   0x78AC
;   0x794a..0x795b  (17 bytes)
DATA_tira_04:
	defb 022h,0c0h,090h,0c0h,0a8h,0a0h,098h,0b0h,090h,0a0h,080h,0a0h,078h,080h,070h,080h	; 794a  "...........x.p.
	defb 06dh	; 795a

; ----------------------------------------------------------------------
; DATOS tira_05: Tira de eventos de 1 bytes: la entrada 45, 46, 47 de la tabla
;   de 0x78AC
;   0x795b..0x795c  (1 bytes)
DATA_tira_05:
	defb 0ffh	; 795b

; ----------------------------------------------------------------------
; DATOS tira_06: Tira de eventos de 41 bytes: la entrada 6 de la tabla de
;   0x78AC
;   0x795c..0x7985  (41 bytes)
DATA_tira_06:
	defb 023h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,023h,0d0h,08fh,0d0h,0a0h,0d0h,08fh	; 795c  #........#......
	defb 0d0h,0a0h,023h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,023h,0d0h,08fh,0d0h,0a0h	; 796c  ..#........#....
	defb 0d0h,08fh,0d0h,0a0h,02fh,000h,000h,0feh,005h	; 797c  ..../....

; ----------------------------------------------------------------------
; DATOS tira_07: Tira de eventos de 7 bytes: la entrada 5 de la tabla de
;   0x78AC
;   0x7985..0x798c  (7 bytes)
DATA_tira_07:
	defb 0d1h,0fdh,0e2h,090h,0c0h,0feh,0ffh	; 7985

; ----------------------------------------------------------------------
; DATOS tira_08: Tira de eventos de 20 bytes: la entrada 7 de la tabla de
;   0x78AC
;   0x798c..0x79a0  (20 bytes)
DATA_tira_08:
	defb 021h,0e1h,028h,0e1h,058h,0c1h,088h,0c1h,0a8h,0a1h,0cdh,0b1h,0fdh,082h,01dh,082h	; 798c  !.(.X...........
	defb 038h,072h,048h,0ffh	; 799c

; ----------------------------------------------------------------------
; DATOS tira_09: Tira de eventos de 74 bytes: la entrada 9 de la tabla de
;   0x78AC
;   0x79a0..0x79ea  (74 bytes)
DATA_tira_09:
	defb 021h,0b1h,020h,0b1h,000h,0b1h,010h,0b0h,0f0h,0b1h,000h,0b0h,0e0h,0a0h,0f0h,0a0h	; 79a0  !. .............
	defb 0d0h,0a0h,0e0h,0a0h,0c0h,0a0h,0d0h,0a0h,0b0h,090h,0c0h,090h,0a0h,090h,0b0h,090h	; 79b0  ................
	defb 090h,090h,0a0h,090h,080h,080h,090h,080h,070h,080h,080h,080h,060h,080h,070h,080h	; 79c0  ........p...`.p.
	defb 050h,070h,080h,070h,060h,070h,070h,070h,050h,070h,060h,070h,040h,060h,050h,050h	; 79d0  Pp.p`pppPp`p@`PP
	defb 030h,060h,040h,060h,020h,060h,030h,060h,010h,0ffh	; 79e0  0`@` `0`..

; ----------------------------------------------------------------------
; DATOS tira_0A: Tira de eventos de 74 bytes: la entrada 10 de la tabla de
;   0x78AC
;   0x79ea..0x7a34  (74 bytes)
DATA_tira_0A:
	defb 021h,0b0h,0c0h,0b0h,0a0h,0b0h,0b0h,0b0h,090h,0b0h,0a0h,0b0h,080h,0a0h,090h,0a0h	; 79ea  !...............
	defb 070h,0a0h,080h,0a0h,060h,0a0h,070h,0a0h,050h,090h,080h,090h,060h,090h,070h,090h	; 79fa  p...`.p.P...`.p.
	defb 050h,090h,060h,090h,040h,080h,050h,080h,030h,080h,040h,080h,020h,080h,030h,080h	; 7a0a  P.`.@.P.0.@. .0.
	defb 010h,070h,080h,070h,060h,070h,070h,070h,050h,060h,060h,060h,040h,060h,050h,060h	; 7a1a  .p.p`pppP```@`P`
	defb 030h,060h,040h,060h,020h,060h,030h,060h,010h,0ffh	; 7a2a  0`@` `0`..

; ----------------------------------------------------------------------
; DATOS tira_0B: Tira de eventos de 18 bytes: la entrada 15 de la tabla de
;   0x78AC
;   0x7a34..0x7a46  (18 bytes)
DATA_tira_0B:
	defb 022h,0f1h,040h,0d2h,020h,000h,000h,0b1h,0e0h,092h,0c0h,071h,0a0h,062h,0e0h,041h	; 7a34  ".@. ......q.b.A
	defb 0c0h,0ffh	; 7a44

; ----------------------------------------------------------------------
; DATOS tira_0C: Tira de eventos de 26 bytes: la entrada 16 de la tabla de
;   0x78AC
;   0x7a46..0x7a60  (26 bytes)
DATA_tira_0C:
	defb 021h,010h,000h,023h,00fh,011h,00eh,012h,00dh,013h,00ch,014h,00bh,015h,00ah,016h	; 7a46  !..#............
	defb 009h,017h,008h,018h,007h,019h,006h,01ah,005h,0ffh	; 7a56  ..........

; ----------------------------------------------------------------------
; DATOS tira_0D: Tira de eventos de 20 bytes: la entrada 8 de la tabla de
;   0x78AC
;   0x7a60..0x7a74  (20 bytes)
DATA_tira_0D:
	defb 021h,0d0h,0a0h,0b0h,0a0h,0a0h,0a0h,024h,000h,000h,021h,0a0h,0a0h,080h,0a0h,060h	; 7a60  !......$..!....`
	defb 0a0h,040h,0a0h,0ffh	; 7a70

; ----------------------------------------------------------------------
; DATOS tira_0E: Tira de eventos de 38 bytes: la entrada 13 de la tabla de
;   0x78AC
;   0x7a74..0x7a9a  (38 bytes)
DATA_tira_0E:
	defb 021h,0f1h,050h,0f2h,040h,0f1h,000h,0e2h,010h,0e1h,0a0h,0d2h,040h,0d1h,050h,0c1h	; 7a74  !.P.@.......@.P.
	defb 0d0h,0b1h,080h,0b1h,0c0h,0a2h,020h,0a1h,010h,091h,0d0h,091h,020h,081h,0a0h,061h	; 7a84  ...... ..... ..a
	defb 0c0h,051h,0a0h,051h,0f0h,0ffh	; 7a94

; ----------------------------------------------------------------------
; DATOS tira_0F: Tira de eventos de 18 bytes: la entrada 14 de la tabla de
;   0x78AC
;   0x7a9a..0x7aac  (18 bytes)
DATA_tira_0F:
	defb 023h,01fh,00ch,00bh,00ah,009h,008h,01dh,008h,01ch,007h,01bh,007h,01ah,006h,019h	; 7a9a  #...............
	defb 006h,0ffh	; 7aaa

; ----------------------------------------------------------------------
; DATOS tira_10: Tira de eventos de 12 bytes: la entrada 19 de la tabla de
;   0x78AC
;   0x7aac..0x7ab8  (12 bytes)
DATA_tira_10:
	defb 0d2h,0fdh,0e4h,0b0h,0fbh,0b0h,0fah,0b0h,0d6h,0fch,0b1h,0ffh	; 7aac  ............

; ----------------------------------------------------------------------
; DATOS tira_11: Tira de eventos de 12 bytes: la entrada 20 de la tabla de
;   0x78AC
;   0x7ab8..0x7ac4  (12 bytes)
DATA_tira_11:
	defb 0d2h,0fch,0e1h,0b0h,0fbh,0b0h,0f9h,0b0h,0d8h,0f9h,0b0h,0ffh	; 7ab8  ............

; ----------------------------------------------------------------------
; DATOS tira_12: Tira de eventos de 7 bytes: la entrada 11 de la tabla de
;   0x78AC
;   0x7ac4..0x7acb  (7 bytes)
DATA_tira_12:
	defb 0d1h,0fah,0e2h,001h,0c2h,041h,0ffh	; 7ac4

; ----------------------------------------------------------------------
; DATOS tira_13: Tira de eventos de 7 bytes: la entrada 12 de la tabla de
;   0x78AC
;   0x7acb..0x7ad2  (7 bytes)
DATA_tira_13:
	defb 0d1h,0fch,0e1h,001h,0c2h,041h,0ffh	; 7acb

; ----------------------------------------------------------------------
; DATOS tira_14: Tira de eventos de 8 bytes: la entrada 21 de la tabla de
;   0x78AC
;   0x7ad2..0x7ada  (8 bytes)
DATA_tira_14:
	defb 0d6h,0fch,0e2h,000h,040h,070h,0feh,002h	; 7ad2  ....@p..

; ----------------------------------------------------------------------
; DATOS tira_15: Tira de eventos de 8 bytes: la entrada 22 de la tabla de
;   0x78AC
;   0x7ada..0x7ae2  (8 bytes)
DATA_tira_15:
	defb 0d6h,0fch,0e1h,040h,070h,0e0h,000h,0ffh	; 7ada  ...@p...

; ----------------------------------------------------------------------
; DATOS tira_16: Tira de eventos de 8 bytes: la entrada 23 de la tabla de
;   0x78AC
;   0x7ae2..0x7aea  (8 bytes)
DATA_tira_16:
	defb 0d6h,0fch,0e2h,070h,0e1h,000h,040h,0ffh	; 7ae2  ...p..@.

; ----------------------------------------------------------------------
; DATOS tira_17: Tira de eventos de 17 bytes: la entrada 17 de la tabla de
;   0x78AC
;   0x7aea..0x7afb  (17 bytes)
DATA_tira_17:
	defb 0d5h,0fdh,0e1h,000h,0fch,000h,0fah,000h,0f8h,000h,0d2h,0c0h,0f7h,000h,0f6h,000h	; 7aea  ................
	defb 0ffh	; 7afa

; ----------------------------------------------------------------------
; DATOS tira_18: Tira de eventos de 17 bytes: la entrada 18 de la tabla de
;   0x78AC
;   0x7afb..0x7b0c  (17 bytes)
DATA_tira_18:
	defb 0d5h,0fdh,0e1h,070h,0fch,070h,0fah,070h,0f8h,070h,0d2h,0c0h,0f7h,070h,0f6h,000h	; 7afb  ...p.p.p.p...p..
	defb 0ffh	; 7b0b

; ----------------------------------------------------------------------
; DATOS tira_19: Tira de eventos de 5 bytes: la entrada 24 de la tabla de
;   0x78AC
;   0x7b0c..0x7b11  (5 bytes)
DATA_tira_19:
	defb 0d8h,0fch,0e1h,095h,0ffh	; 7b0c

; ----------------------------------------------------------------------
; DATOS tira_1A: Tira de eventos de 5 bytes: la entrada 25 de la tabla de
;   0x78AC
;   0x7b11..0x7b16  (5 bytes)
DATA_tira_1A:
	defb 0d8h,0fch,0e0h,055h,0ffh	; 7b11

; ----------------------------------------------------------------------
; DATOS tira_1B: Tira de eventos de 5 bytes: la entrada 26 de la tabla de
;   0x78AC
;   0x7b16..0x7b1b  (5 bytes)
DATA_tira_1B:
	defb 0d8h,0fch,0e0h,095h,0ffh	; 7b16

; ----------------------------------------------------------------------
; DATOS tira_1C: Tira de eventos de 26 bytes: la entrada 27 de la tabla de
;   0x78AC
;   0x7b1b..0x7b35  (26 bytes)
DATA_tira_1C:
	defb 0d6h,0fch,0e2h,0b5h,0b0h,0b0h,0b1h,091h,0d8h,090h,090h,0e1h,020h,0d6h,0e2h,0b5h	; 7b1b  ............ ...
	defb 0b0h,0e1h,010h,023h,041h,010h,040h,06bh,0c4h,0ffh	; 7b2b  ...#A.@k..

; ----------------------------------------------------------------------
; DATOS tira_1D: Tira de eventos de 23 bytes: la entrada 28 de la tabla de
;   0x78AC
;   0x7b35..0x7b4c  (23 bytes)
DATA_tira_1D:
	defb 0d6h,0fch,0e2h,085h,080h,080h,081h,061h,0d8h,060h,060h,0b0h,0d6h,085h,080h,090h	; 7b35  .......a.``.....
	defb 0b3h,091h,090h,090h,0e1h,03bh,0ffh	; 7b45

; ----------------------------------------------------------------------
; DATOS tira_1E: Tira de eventos de 30 bytes: la entrada 29 de la tabla de
;   0x78AC
;   0x7b4c..0x7b6a  (30 bytes)
DATA_tira_1E:
	defb 0d6h,0fch,0e3h,041h,040h,040h,045h,041h,0d8h,040h,040h,040h,0d6h,041h,040h,040h	; 7b4c  ...A@@EA.@@@.A@@
	defb 045h,0fbh,0b0h,0e2h,010h,020h,010h,0e3h,090h,0e2h,010h,0e3h,0bbh,0ffh	; 7b5c  E.... ........

; ----------------------------------------------------------------------
; DATOS tira_1F: Tira de eventos de 1 bytes: la entrada 30 de la tabla de
;   0x78AC
;   0x7b6a..0x7b6b  (1 bytes)
DATA_tira_1F:
	defb 0e8h	; 7b6a

; ----------------------------------------------------------------------
; DATOS tira_20: Tira de eventos de 24 bytes: la entrada 31 de la tabla de
;   0x78AC
;   0x7b6b..0x7b83  (24 bytes)
DATA_tira_20:
	defb 0d7h,0fch,0e2h,020h,020h,020h,072h,0e1h,000h,0e2h,0b0h,090h,0b1h,070h,0a0h,0a0h	; 7b6b  ...   r......p..
	defb 0a0h,0e1h,032h,070h,050h,030h,028h,0ffh	; 7b7b  ..2pP0(.

; ----------------------------------------------------------------------
; DATOS tira_21: Tira de eventos de 24 bytes: la entrada 32 de la tabla de
;   0x78AC
;   0x7b83..0x7b9b  (24 bytes)
DATA_tira_21:
	defb 0d7h,0fch,0e3h,070h,070h,070h,072h,0e2h,000h,000h,000h,0e3h,071h,070h,0e2h,030h	; 7b83  ...pppr.....qp.0
	defb 030h,030h,032h,030h,030h,050h,078h,0ffh	; 7b93  00200Px.

; ----------------------------------------------------------------------
; DATOS tira_22: Tira de eventos de 1 bytes: la entrada 33 de la tabla de
;   0x78AC
;   0x7b9b..0x7b9c  (1 bytes)
DATA_tira_22:
	defb 0e8h	; 7b9b

; ----------------------------------------------------------------------
; DATOS tira_23: Tira de eventos de 26 bytes: la entrada 34 de la tabla de
;   0x78AC
;   0x7b9c..0x7bb6  (26 bytes)
DATA_tira_23:
	defb 0d6h,0fch,0e2h,040h,070h,040h,070h,050h,091h,050h,070h,0b0h,070h,0b0h,090h,0e1h	; 7b9c  ...@p@pP.Pp.p...
	defb 001h,0e2h,090h,0e1h,010h,020h,071h,007h,0c8h,0ffh	; 7bac  ..... q...

; ----------------------------------------------------------------------
; DATOS tira_24: Tira de eventos de 33 bytes: la entrada 35 de la tabla de
;   0x78AC
;   0x7bb6..0x7bd7  (33 bytes)
DATA_tira_24:
	defb 0d6h,0fch,0e3h,000h,070h,0b0h,070h,020h,090h,0e2h,000h,0e3h,090h,000h,000h,0e2h	; 7bb6  ....p.p ........
	defb 020h,0e3h,0b0h,050h,0e2h,000h,040h,000h,0e3h,070h,0e2h,020h,050h,020h,007h,0c8h	; 7bc6   ..P..@..p. P ..
	defb 0ffh	; 7bd6

; ----------------------------------------------------------------------
; DATOS tira_25: Tira de eventos de 1 bytes: la entrada 36 de la tabla de
;   0x78AC
;   0x7bd7..0x7bd8  (1 bytes)
DATA_tira_25:
	defb 0e8h	; 7bd7

; ----------------------------------------------------------------------
; DATOS tira_26: Tira de eventos de 21 bytes: la entrada 37 de la tabla de
;   0x78AC
;   0x7bd8..0x7bed  (21 bytes)
DATA_tira_26:
	defb 0d6h,0fch,0e1h,005h,0e2h,070h,0e1h,000h,0e2h,0a1h,071h,0d8h,090h,070h,050h,0d6h	; 7bd8  .....p....q..pP.
	defb 072h,0e1h,020h,027h,0ffh	; 7be8

; ----------------------------------------------------------------------
; DATOS tira_27: Tira de eventos de 18 bytes: la entrada 38 de la tabla de
;   0x78AC
;   0x7bed..0x7bff  (18 bytes)
DATA_tira_27:
	defb 0d6h,0fch,0e2h,045h,040h,040h,0e3h,031h,031h,0d8h,050h,070h,090h,0d6h,072h,0b0h	; 7bed  ...E@@.11.Pp..r.
	defb 0b7h,0ffh	; 7bfd

; ----------------------------------------------------------------------
; DATOS tira_28: Tira de eventos de 19 bytes: la entrada 39 de la tabla de
;   0x78AC
;   0x7bff..0x7c12  (19 bytes)
DATA_tira_28:
	defb 0d8h,0fch,0e2h,0a0h,070h,030h,0e1h,010h,0e2h,0a0h,060h,0e1h,000h,0e2h,090h,050h	; 7bff  ....p0....`....P
	defb 0d6h,0abh,0ffh	; 7c0f

; ----------------------------------------------------------------------
; DATOS tira_29: Tira de eventos de 10 bytes: la entrada 40 de la tabla de
;   0x78AC
;   0x7c12..0x7c1c  (10 bytes)
DATA_tira_29:
	defb 0d6h,0fbh,0e3h,0a3h,0e2h,013h,003h,0d6h,07bh,0ffh	; 7c12  ........{.

; ----------------------------------------------------------------------
; DATOS tira_2A: Tira de eventos de 14 bytes: la entrada 41 de la tabla de
;   0x78AC
;   0x7c1c..0x7c2a  (14 bytes)
DATA_tira_2A:
	defb 0d6h,0fch,0e3h,033h,063h,053h,0d6h,0fdh,032h,0e4h,0a0h,0e3h,037h,0ffh	; 7c1c  ...3cS..2...7.

; ----------------------------------------------------------------------
; DATOS tira_2B: Tira de eventos de 1 bytes: la entrada 42 de la tabla de
;   0x78AC
;   0x7c2a..0x7c2b  (1 bytes)
DATA_tira_2B:
	defb 0e8h	; 7c2a

; ----------------------------------------------------------------------
; DATOS tira_2C: Tira de eventos de 99 bytes: la entrada 43 de la tabla de
;   0x78AC
;   0x7c2b..0x7c8e  (99 bytes)
DATA_tira_2C:
	defb 0d8h,0fch,0c7h,0e2h,090h,090h,090h,0d6h,0e1h,022h,0e2h,090h,0e1h,032h,030h,073h	; 7c2b  ........."...20s
	defb 062h,060h,0d8h,090h,060h,020h,0d6h,092h,060h,09bh,0c3h,0d8h,0e3h,090h,0e2h,020h	; 7c3b  b`..` ..`...... 
	defb 070h,0d6h,062h,098h,0d8h,0e3h,090h,0e2h,020h,070h,0d6h,062h,097h,060h,0d8h,090h	; 7c4b  p.b..... p.b.`..
	defb 070h,060h,0d6h,02bh,0d8h,0e1h,090h,070h,060h,0d6h,027h,047h,0d8h,060h,060h,060h	; 7c5b  p`.+...p`.'G.```
	defb 0c0h,040h,060h,071h,061h,020h,0e2h,0b0h,0e2h,060h,060h,060h,0c0h,040h,060h,0d6h	; 7c6b  .@`qa ...```.@`.
	defb 072h,060h,092h,070h,0d8h,060h,060h,060h,090h,060h,020h,071h,0a1h,0e1h,021h,0d6h	; 7c7b  r`.p.```.` q..!.
	defb 06bh,0c7h,0ffh	; 7c8b

; ----------------------------------------------------------------------
; DATOS tira_2D: Tira de eventos de 76 bytes: la entrada 44 de la tabla de
;   0x78AC
;   0x7c8e..0x7cda  (76 bytes)
DATA_tira_2D:
	defb 0d8h,0fch,0c7h,0e3h,093h,080h,090h,0a3h,090h,0a0h,0b3h,0e2h,000h,0e3h,0b0h,0abh	; 7c8e  ................
	defb 0c5h,0fdh,022h,022h,020h,020h,020h,022h,002h,002h,000h,000h,000h,002h,093h,070h	; 7c9e  ..""   ".......p
	defb 060h,0e4h,0b0h,0b0h,0b0h,0b2h,0e3h,022h,070h,060h,070h,0e2h,023h,000h,0e3h,0a0h	; 7cae  `......"p`p.#...
	defb 0fbh,092h,092h,0e2h,002h,002h,0e3h,0b2h,0b2h,0a2h,0a2h,0fdh,022h,020h,020h,020h	; 7cbe  ............"   
	defb 001h,001h,001h,0d6h,0e2h,091h,0e1h,000h,0e2h,0b0h,097h,0ffh	; 7cce  ............

; ----------------------------------------------------------------------
; DATOS tabla_de_poses: Quince punteros a las poses de la barra, una por paso.
;   0x5FCD indexa por dos la tabla que arranca en 0x7CB6 con (0xE105), y solo
;   entra con el 0x12 o mayor: por eso la palabra de 0x7CDA es la entrada 0x12
;   y la tabla empieza de verdad aqui
;   0x7cda..0x7cf8  (30 bytes)
DATA_tabla_de_poses:
	defw 07cf8h	; 7cda  -> DATA_pose_00
	defw 07d21h	; 7cdc  -> DATA_pose_01
	defw 07d4eh	; 7cde  -> DATA_pose_02
	defw 07d7fh	; 7ce0  -> DATA_pose_03
	defw 07da8h	; 7ce2  -> DATA_pose_04
	defw 07dd5h	; 7ce4  -> DATA_pose_05
	defw 07e0eh	; 7ce6  -> DATA_pose_06
	defw 07e47h	; 7ce8  -> DATA_pose_07
	defw 07e80h	; 7cea  -> DATA_pose_08
	defw 07eb9h	; 7cec  -> DATA_pose_09
	defw 07ef2h	; 7cee  -> DATA_pose_10
	defw 07f2bh	; 7cf0  -> DATA_pose_11
	defw 07f58h	; 7cf2  -> DATA_pose_12
	defw 07f85h	; 7cf4  -> DATA_pose_13
	defw 07fb6h	; 7cf6  -> DATA_pose_14

; ----------------------------------------------------------------------
; DATOS pose_00: Pose de la barra en el paso 0x12: un byte de cuenta -0x28, o
;   sea 10 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7cf8..0x7d21  (41 bytes)
DATA_pose_00:
	defb 028h,071h,05bh,000h,001h,05dh,063h,00ch,00bh,05dh,063h,008h,001h,066h,065h,010h	; 7cf8  (q[..]c..]c..fe.
	defb 005h,061h,060h,06ch,00bh,071h,06ah,074h,00bh,071h,06bh,004h,001h,07eh,060h,038h	; 7d08  .a`l.qjt.qk..~`8
	defb 00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7d18  ..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_01: Pose de la barra en el paso 0x13: un byte de cuenta -0x2C, o
;   sea 11 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7d21..0x7d4e  (45 bytes)
DATA_pose_01:
	defb 02ch,070h,05bh,000h,001h,05ch,062h,00ch,00bh,05ch,062h,008h,001h,066h,064h,010h	; 7d21  ,p[..\b..\b..fd.
	defb 005h,061h,05fh,06ch,00bh,071h,06ch,07ch,00bh,06fh,06bh,004h,001h,078h,060h,034h	; 7d31  .a_l.ql|.ok..x`4
	defb 00bh,07eh,060h,038h,00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7d41  .~`8..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_02: Pose de la barra en el paso 0x14: un byte de cuenta -0x30, o
;   sea 12 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7d4e..0x7d7f  (49 bytes)
DATA_pose_02:
	defb 030h,06ch,05eh,000h,001h,05ah,060h,00ch,00bh,05ah,060h,008h,001h,066h,064h,010h	; 7d4e  0l^..Z`..Z`..fd.
	defb 005h,061h,05fh,06ch,00bh,072h,06eh,084h,00bh,06ch,06eh,004h,001h,078h,060h,034h	; 7d5e  .a_l.rn..ln..x`4
	defb 00bh,072h,060h,02ch,005h,07eh,060h,038h,00bh,08eh,060h,03ch,005h,08eh,068h,03ch	; 7d6e  .r`,.~`8..`<..h<
	defb 005h	; 7d7e

; ----------------------------------------------------------------------
; DATOS pose_03: Pose de la barra en el paso 0x15: un byte de cuenta -0x28, o
;   sea 10 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7d7f..0x7da8  (41 bytes)
DATA_pose_03:
	defb 028h,068h,05fh,000h,001h,05ah,060h,00ch,00bh,05ah,060h,008h,001h,06eh,06fh,08ch	; 7d7f  (h_..Z`..Z`..no.
	defb 00bh,068h,06fh,004h,001h,078h,060h,034h,00bh,072h,060h,02ch,005h,07eh,060h,038h	; 7d8f  .ho..x`4.r`,.~`8
	defb 00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7d9f  ..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_04: Pose de la barra en el paso 0x16: un byte de cuenta -0x2C, o
;   sea 11 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7da8..0x7dd5  (45 bytes)
DATA_pose_04:
	defb 02ch,064h,05eh,000h,001h,05ah,060h,09ch,00bh,05ah,060h,008h,001h,06ah,06dh,094h	; 7da8  ,d^..Z`..Z`..jm.
	defb 00bh,064h,06eh,004h,001h,078h,060h,034h,00bh,072h,060h,030h,00bh,072h,060h,02ch	; 7db8  .dn..x`4.r`0.r`,
	defb 005h,07eh,060h,038h,00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7dc8  .~`8..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_05: Pose de la barra en el paso 0x17: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7dd5..0x7e0e  (57 bytes)
DATA_pose_05:
	defb 038h,051h,04ch,000h,001h,051h,05fh,01ch,00bh,051h,05ch,004h,001h,059h,054h,020h	; 7dd5  8QL..Q_..Q\..YT 
	defb 00bh,069h,054h,024h,005h,069h,054h,028h,00bh,061h,054h,00ch,00bh,061h,054h,008h	; 7de5  .iT$.iT(.aT..aT.
	defb 001h,080h,05ah,044h,00bh,079h,054h,02ch,005h,079h,054h,030h,00bh,07dh,04ch,048h	; 7df5  ..ZD.yT,.yT0.}LH
	defb 00bh,08bh,049h,040h,005h,08eh,060h,03ch,005h	; 7e05  ..I@..`<.

; ----------------------------------------------------------------------
; DATOS pose_06: Pose de la barra en el paso 0x18: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7e0e..0x7e47  (57 bytes)
DATA_pose_06:
	defb 038h,04eh,04fh,000h,001h,04eh,062h,01ch,00bh,04eh,05fh,004h,001h,056h,057h,020h	; 7e0e  8NO..Nb..N_..VW 
	defb 00bh,066h,057h,024h,005h,066h,057h,028h,00bh,05eh,057h,098h,00bh,05eh,057h,008h	; 7e1e  .fW$.fW(.^W..^W.
	defb 001h,07eh,058h,04ch,00bh,076h,057h,02ch,005h,076h,057h,030h,00bh,088h,054h,050h	; 7e2e  .~XL.vW,.vW0..TP
	defb 00bh,08bh,051h,040h,005h,08eh,060h,03ch,005h	; 7e3e  ..Q@..`<.

; ----------------------------------------------------------------------
; DATOS pose_07: Pose de la barra en el paso 0x19: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7e47..0x7e80  (57 bytes)
DATA_pose_07:
	defb 038h,04ch,052h,000h,001h,04ch,065h,01ch,00bh,04ch,062h,004h,001h,054h,05ah,020h	; 7e47  8LR..Le..Lb..TZ 
	defb 00bh,064h,05ah,024h,005h,064h,05ah,028h,00bh,05ch,05ah,098h,00bh,05ch,05ah,008h	; 7e57  .dZ$.dZ(.\Z..\Z.
	defb 001h,07bh,058h,054h,00bh,074h,05ah,02ch,005h,074h,05ah,030h,00bh,08bh,058h,058h	; 7e67  .{XT.tZ,.tZ0..XX
	defb 00bh,08bh,055h,040h,005h,08eh,060h,03ch,005h	; 7e77  ..U@..`<.

; ----------------------------------------------------------------------
; DATOS pose_08: Pose de la barra en el paso 0x1A: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7e80..0x7eb9  (57 bytes)
DATA_pose_08:
	defb 038h,04ah,055h,000h,001h,04ah,068h,01ch,00bh,04ah,065h,004h,001h,052h,05dh,020h	; 7e80  8JU..Jh..Je..R] 
	defb 00bh,062h,05dh,024h,005h,062h,05dh,028h,00bh,05ah,05dh,098h,00bh,05ah,05dh,008h	; 7e90  .b]$.b](.Z]..Z].
	defb 001h,078h,05bh,05ch,00bh,072h,05dh,02ch,005h,072h,05dh,030h,00bh,088h,05bh,060h	; 7ea0  .x[\.r],.r]0..[`
	defb 00bh,08ah,05ah,040h,005h,08eh,060h,03ch,005h	; 7eb0  ..Z@..`<.

; ----------------------------------------------------------------------
; DATOS pose_09: Pose de la barra en el paso 0x1B: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7eb9..0x7ef2  (57 bytes)
DATA_pose_09:
	defb 038h,04ah,056h,000h,001h,04ah,069h,01ch,00bh,04ah,066h,004h,001h,052h,05eh,020h	; 7eb9  8JV..Ji..Jf..R^ 
	defb 00bh,062h,05eh,024h,005h,062h,05eh,028h,00bh,05ah,05eh,098h,00bh,05ah,05eh,008h	; 7ec9  .b^$.b^(.Z^..Z^.
	defb 001h,078h,05eh,064h,00bh,072h,05eh,02ch,005h,072h,05eh,030h,00bh,088h,05eh,068h	; 7ed9  .x^d.r^,.r^0..^h
	defb 00bh,08eh,060h,03ch,005h,08eh,061h,03ch,005h	; 7ee9  ..`<..a<.

; ----------------------------------------------------------------------
; DATOS pose_10: Pose de la barra en el paso 0x1C: un byte de cuenta -0x38, o
;   sea 14 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7ef2..0x7f2b  (57 bytes)
DATA_pose_10:
	defb 038h,04ah,058h,000h,001h,04ah,06bh,01ch,00bh,04ah,068h,004h,001h,052h,060h,020h	; 7ef2  8JX..Jk..Jh..R` 
	defb 00bh,062h,060h,024h,005h,062h,060h,028h,00bh,05ah,060h,098h,00bh,05ah,060h,008h	; 7f02  .b`$.b`(.Z`..Z`.
	defb 001h,078h,060h,034h,00bh,072h,060h,02ch,005h,072h,060h,030h,00bh,07eh,060h,038h	; 7f12  .x`4.r`,.r`0.~`8
	defb 00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7f22  ..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_11: Pose de la barra en el paso 0x1D: un byte de cuenta -0x2C, o
;   sea 11 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7f2b..0x7f58  (45 bytes)
DATA_pose_11:
	defb 02ch,05ah,060h,00ch,00bh,05ah,060h,008h,001h,062h,060h,0a0h,00bh,06ah,070h,0a8h	; 7f2b  ,Z`..Z`..b`..jp.
	defb 00bh,062h,060h,0a4h,005h,078h,060h,034h,00bh,072h,060h,02ch,005h,072h,060h,030h	; 7f3b  .b`..x`4.r`,.r`0
	defb 00bh,07eh,060h,038h,00bh,08eh,060h,03ch,005h,08eh,068h,03ch,005h	; 7f4b  .~`8..`<..h<.

; ----------------------------------------------------------------------
; DATOS pose_12: Pose de la barra en el paso 0x1E: un byte de cuenta -0x2C, o
;   sea 11 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7f58..0x7f85  (45 bytes)
DATA_pose_12:
	defb 02ch,084h,060h,000h,001h,084h,070h,004h,001h,05ah,060h,00ch,00bh,05ah,060h,008h	; 7f58  ,.`...p..Z`..Z`.
	defb 001h,062h,060h,024h,005h,062h,068h,0b8h,00bh,06ah,05ah,0ach,00bh,078h,060h,034h	; 7f68  .b`$.bh..jZ..x`4
	defb 00bh,072h,060h,02ch,005h,072h,060h,030h,00bh,07eh,060h,038h,00bh	; 7f78  .r`,.r`0.~`8.

; ----------------------------------------------------------------------
; DATOS pose_13: Pose de la barra en el paso 0x1F: un byte de cuenta -0x30, o
;   sea 12 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7f85..0x7fb6  (49 bytes)
DATA_pose_13:
	defb 030h,084h,060h,000h,001h,084h,070h,004h,001h,05ah,060h,09ch,00bh,05ah,060h,008h	; 7f85  0.`...p..Z`..Z`.
	defb 001h,05ah,068h,0b4h,00bh,062h,060h,024h,005h,06ah,05ah,0ach,00bh,06ah,068h,0b0h	; 7f95  .Zh..b`$.jZ..jh.
	defb 00bh,078h,060h,034h,00bh,072h,060h,02ch,005h,072h,060h,030h,00bh,07eh,060h,038h	; 7fa5  .x`4.r`,.r`0.~`8
	defb 00bh	; 7fb5

; ----------------------------------------------------------------------
; DATOS pose_14: Pose de la barra en el paso 0x20: un byte de cuenta -0x30, o
;   sea 12 fichas de sprite- y las fichas que 0x5FE7 copia a 0xE0C0
;   0x7fb6..0x7fe7  (49 bytes)
DATA_pose_14:
	defb 030h,084h,060h,000h,001h,084h,070h,004h,001h,05ah,060h,098h,00bh,05ah,060h,008h	; 7fb6  0.`...p..Z`..Z`.
	defb 001h,05ah,06dh,0bch,00bh,062h,060h,024h,005h,06ah,05ah,0ach,00bh,06ah,068h,0b0h	; 7fc6  .Zm..b`$.jZ..jh.
	defb 00bh,078h,060h,034h,00bh,072h,060h,02ch,005h,072h,060h,030h,00bh,07eh,060h,038h	; 7fd6  .x`4.r`,.r`0.~`8
	defb 00bh	; 7fe6

; ----------------------------------------------------------------------
; DATOS relleno_final: Los 25 bytes de 0xFF con los que acaba el cartucho
;   0x7fe7..0x8000  (25 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff7  .........
