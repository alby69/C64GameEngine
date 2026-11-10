; =============================================================================
; C64 GAME ENGINE - c64hw.inc
; =============================================================================
; Costanti hardware PURE del Commodore 64.
;
; REGOLA: questo file non contiene variabili di gioco, solo indirizzi di
; registri, indirizzi di memoria e costanti. E' la base condivisa da tutti i
; moduli dell'engine ed e' sicuro da includere in qualunque progetto.
;
; Nessuna logica, nessun codice: solo dati (KISS).
; =============================================================================

; -----------------------------------------------------------------------------
; 1. REGISTRI VIC-II (MOS 6569 PAL / 6567 NTSC) - $D000 - $D02E
; -----------------------------------------------------------------------------
; Coordinate degli 8 sprite hardware (X, Y) e il registro del 9° bit.
VIC_SPR0_X      = $D000     ; X sprite 0
VIC_SPR0_Y      = $D001     ; Y sprite 0
VIC_SPR1_X      = $D002     ; X sprite 1
VIC_SPR1_Y      = $D003     ; Y sprite 1
VIC_SPR2_X      = $D004     ; X sprite 2
VIC_SPR2_Y      = $D005     ; Y sprite 2
VIC_SPR3_X      = $D006     ; X sprite 3
VIC_SPR3_Y      = $D007     ; Y sprite 3
VIC_SPR4_X      = $D008     ; X sprite 4
VIC_SPR4_Y      = $D009     ; Y sprite 4
VIC_SPR5_X      = $D00A     ; X sprite 5
VIC_SPR5_Y      = $D00B     ; Y sprite 5
VIC_SPR6_X      = $D00C     ; X sprite 6
VIC_SPR6_Y      = $D00D     ; Y sprite 6
VIC_SPR7_X      = $D00E     ; X sprite 7
VIC_SPR7_Y      = $D00F     ; Y sprite 7
VIC_SPR_X_MSB   = $D010     ; 9° bit delle coordinate X (bit N = sprite N)

VIC_CTRL_1      = $D011     ; Controllo 1 (bit 7: 9° bit raster, bit 4: display on)
VIC_RASTER      = $D012     ; Linea di raster corrente (0-255)
VIC_SPR_ENA     = $D015     ; Abilitazione sprite (un bit per sprite)
VIC_CTRL_2      = $D016     ; Controllo 2 (scrolling, 40/38 colonne)
VIC_SPR_EXP_Y   = $D017     ; Espansione Y (sprite 21 -> 42 pixel)
VIC_MEM_SETUP   = $D018     ; Posizione RAM schermo / caratteri
VIC_IRQ_STATUS  = $D019     ; Flag interrupt raster/sprite (si azzera leggendo)
VIC_IRQ_MASK    = $D01A     ; Maschera abilitazione interrupt VIC-II
VIC_SPR_PRIO    = $D01B     ; Priorita' sprite/sfondo
VIC_SPR_MCOLOR  = $D01C     ; 1 = sprite multicolore 12x21, 0 = hires 24x21
VIC_SPR_EXP_X   = $D01D     ; Espansione X (sprite 24 -> 48 pixel)
VIC_SPR_COLL_S  = $D01E     ; Collisione sprite-sprite (la lettura lo azzera)
VIC_SPR_COLL_B  = $D01F     ; Collisione sprite-sfondo

VIC_BORDER_COL  = $D020     ; Colore del bordo
VIC_BG_COL0     = $D021     ; Sfondo 0
VIC_BG_COL1     = $D022     ; Sfondo 1
VIC_BG_COL2     = $D023     ; Sfondo 2
VIC_BG_COL3     = $D024     ; Sfondo 3
VIC_SPR_MCOL0   = $D025     ; Colore comune multicolore sprite 1
VIC_SPR_MCOL1   = $D026     ; Colore comune multicolore sprite 2
VIC_SPR0_COL    = $D027     ; Colore individuale sprite 0
VIC_SPR1_COL    = $D028     ; Colore individuale sprite 1
VIC_SPR2_COL    = $D029     ; Colore individuale sprite 2
VIC_SPR3_COL    = $D02A     ; Colore individuale sprite 3
VIC_SPR4_COL    = $D02B     ; Colore individuale sprite 4
VIC_SPR5_COL    = $D02C     ; Colore individuale sprite 5
VIC_SPR6_COL    = $D02D     ; Colore individuale sprite 6
VIC_SPR7_COL    = $D02E     ; Colore individuale sprite 7

; -----------------------------------------------------------------------------
; 2. REGISTRI SID (MOS 6581 / 8580) - $D400 - $D41C
; -----------------------------------------------------------------------------
; Voce 1: tipicamente laser del giocatore o sirena dell'UFO
SID_V1_FREQ_LO  = $D400
SID_V1_FREQ_HI  = $D401
SID_V1_PW_LO    = $D402
SID_V1_PW_HI    = $D403
SID_V1_CTRL     = $D404
SID_V1_AD       = $D405
SID_V1_SR       = $D406

; Voce 2: tipicamente la marcia degli invasori
SID_V2_FREQ_LO  = $D407
SID_V2_FREQ_HI  = $D408
SID_V2_PW_LO    = $D409
SID_V2_PW_HI    = $D40A
SID_V2_CTRL     = $D40B
SID_V2_AD       = $D40C
SID_V2_SR       = $D40D

; Voce 3: tipicamente esplosioni (rumore bianco)
SID_V3_FREQ_LO  = $D40E
SID_V3_FREQ_HI  = $D40F
SID_V3_PW_LO    = $D410
SID_V3_PW_HI    = $D411
SID_V3_CTRL     = $D412
SID_V3_AD       = $D413
SID_V3_SR       = $D414

SID_FLT_LO      = $D415     ; Taglio filtro basso
SID_FLT_HI      = $D416     ; Taglio filtro alto
SID_FLT_CTRL    = $D417     ; Risonanza e routing dei filtri
SID_VOL_CTRL    = $D418     ; Volume master (4 bit bassi) e routing dei filtri

; Bitmask delle forme d'onda (registri CTRL $D404, $D40B, $D412)
SID_WAVE_GATE   = $01       ; Gate on (attacca l'inviluppo)
SID_WAVE_SYNC   = $02       ; Sincronizzazione oscillatori
SID_WAVE_RING   = $04       ; Ring modulation
SID_WAVE_TEST   = $08       ; Test (azzera l'oscillatore)
SID_WAVE_TRI    = $10       ; Triangolare
SID_WAVE_SAW    = $20       ; Dente di sega
SID_WAVE_PULSE  = $40       ; Onda quadra
SID_WAVE_NOISE  = $80       ; Rumore bianco

; -----------------------------------------------------------------------------
; 3. CIA 1 (MOS 6526) - $DC00 - $DC0F (joystick e matrice tastiera)
; -----------------------------------------------------------------------------
CIA1_PORT_A     = $DC00     ; Righe della matrice tastiera / joystick porta 2
CIA1_PORT_B     = $DC01     ; Colonne della matrice tastiera / joystick porta 1
CIA1_TIMER_A_LO = $DC04
CIA1_TIMER_A_HI = $DC05
CIA1_TIMER_B_LO = $DC06
CIA1_TIMER_B_HI = $DC07
CIA1_TOD_LO     = $DC08
CIA1_TOD_HI     = $DC09
CIA1_SDR        = $DC0C
CIA1_ICR        = $DC0D     ; Interrupt control (bit 7 = abilita, bit 4 = IRQ)
CIA1_CRA        = $DC0E     ; Control register A
CIA1_CRB        = $DC0F     ; Control register B

; Maschere joystick: i pin del microinterruttore vanno a massa (logica
; invertita: 0 = premuto).
JOY_UP          = $01
JOY_DOWN        = $02
JOY_LEFT        = $04
JOY_RIGHT       = $08
JOY_FIRE        = $10

; -----------------------------------------------------------------------------
; 4. MAPPA DELLA MEMORIA
; -----------------------------------------------------------------------------
SCREEN_RAM      = $0400     ; 40x25 caratteri (1000 byte: $0400 - $07E7)
COLOR_RAM       = $D800     ; Colori del testo (1000 byte: $D800 - $DBE7)
SPRITE_PTR_BASE = $07F8     ; Puntatori ai blocchi dati degli 8 sprite
SPRITE_MEM_BASE = $2000     ; Indirizzo standard dei dati sprite
SPRITE_BLOCK_SIZE = 64     ; Byte per blocco sprite (8x8 celle, hires 24x21)
BASIC_STUB      = $0801     ; Stub BASIC "10 SYS 2064"
PRG_LOAD_ADDR   = $0810     ; Primo byte di codice dopo lo stub BASIC

; Puntatori ai singoli sprite (offset relativi a SPRITE_PTR_BASE)
SPRITE_PTR_0    = $07F8
SPRITE_PTR_1    = $07F9
SPRITE_PTR_2    = $07FA
SPRITE_PTR_3    = $07FB
SPRITE_PTR_4    = $07FC
SPRITE_PTR_5    = $07FD
SPRITE_PTR_6    = $07FE
SPRITE_PTR_7    = $07FF

; -----------------------------------------------------------------------------
; 5. I 16 COLORI STANDARD DEL COMMODORE 64
; -----------------------------------------------------------------------------
COLOR_BLACK      = 0
COLOR_WHITE      = 1
COLOR_RED        = 2
COLOR_CYAN       = 3
COLOR_PURPLE     = 4
COLOR_GREEN      = 5
COLOR_BLUE       = 6
COLOR_YELLOW     = 7
COLOR_ORANGE     = 8
COLOR_BROWN      = 9
COLOR_LIGHTRED   = 10
COLOR_DARKGREY   = 11
COLOR_GREY       = 12
COLOR_LIGHTGREEN = 13
COLOR_LIGHTBLUE  = 14
COLOR_LIGHTGREY  = 15

; -----------------------------------------------------------------------------
; 6. ZERO PAGE RISERVATA ALL'ENGINE ($02 - $1F)
; -----------------------------------------------------------------------------
; L'engine non conosce il gioco: userà solo questa area. I giochi possono
; usare liberamente $20 - $7F.
; -----------------------------------------------------------------------------
ZP_TMP        = $02       ; Temporaneo generale
ZP_TMP2       = $03       ; Temporaneo generale 2
ZP_TMP3       = $04       ; Temporaneo generale 3
ZP_TMP4       = $05       ; Temporaneo generale 4
ZP_MASK       = $06       ; Maschera di bit corrente
ZP_COUNT      = $07       ; Contatore generico
ZP_DELAY      = $08       ; Timer per il debounce
ZP_TMP_X      = $09       ; Temporaneo X
ZP_TMP_Y      = $0A       ; Temporaneo Y
ZP_TMP_LO     = $0B       ; Temporaneo byte basso
ZP_TMP_HI     = $0C       ; Temporaneo byte alto
ZP_OFFSET     = $0D       ; Offset a 8 bit
ZP_OFFSET_HI  = $0E       ; Offset a 8 bit (alto)
ZP_PTR        = $0F       ; Puntatore indiretto 16 bit (usa $0F e $10)
ZP_SRC        = $11       ; Puntatore sorgente 16 bit (usa $11 e $12)
ZP_DST        = $13       ; Puntatore destinazione 16 bit (usa $13 e $14)
ZP_KEY        = $15       ; Codice tasto letto dalla tastiera
ZP_MUL        = $16       ; Moltiplicando
ZP_MUL2       = $17       ; Moltiplicando 2
ZP_ROW        = $18       ; Riga corrente del cursore
ZP_COL        = $19       ; Colonna corrente del cursore
ZP_RESULT_LO  = $1A       ; Risultato 16 bit (basso)
ZP_RESULT_HI  = $1B       ; Risultato 16 bit (alto)
ZP_RAND       = $1C       ; Seme del generatore pseudo-casuale
ZP_ADSR       = $1D       ; Temporaneo per gli inviluppi ADSR
ZP_ARG        = $1E       ; Argomento generico
ZP_ARG2       = $1F       ; Argomento generico 2

; -----------------------------------------------------------------------------
; 7. VARIABILI ASSOLUTE DELL'ENGINE ($0300 - $033F)
; -----------------------------------------------------------------------------
; Area sicura: non usata dal BASIC ne' dal KERNAL.
; -----------------------------------------------------------------------------
TEXT_CURSOR   = $0300     ; Cursore di testo nella Screen RAM (2 byte)
TEXT_CPTR     = $0302     ; Cursore nella Color RAM (2 byte)
TEXT_COLOR    = $0304     ; Colore corrente del testo
SPR_ALLOC     = $0305     ; Bitmap delle allocazioni sprite
SPR_XTABLE    = $0306     ; Tabella delle coordinate X (8 byte)
SPR_MSB       = $030E     ; Tabella del 9° bit X (8 byte)
SPR_FRAME     = $0316     ; Tabella dei blocchi grafici (8 byte)
INPUT_JOY     = $031E     ; Ultimo stato del joystick (porta 2)
INPUT_PREV    = $031F     ; Stato precedente (edge detection)
INPUT_KEY     = $0320     ; Ultimo tasto letto dalla tastiera
INPUT_KBDROW  = $0321     ; Riga della matrice tastiera in scansione
SID_STATE     = $0322     ; Stato interno del driver SID
MATH_RESULT   = $0323     ; Risultato 16 bit (2 byte)
MATH_RAND     = $0325     ; Seme del generatore pseudo-casuale
SID_WAVE      = $0326     ; Forma d'onda impostata per voce (3 byte)
SID_AD        = $0329     ; Inviluppo AD per voce (3 byte)
SID_SR        = $032C     ; Inviluppo SR per voce (3 byte)
SID_FREQ_LO   = $032F     ; Frequenza corrente per voce (3 byte, basso)
SID_FREQ_HI   = $0332     ; Frequenza corrente per voce (3 byte, alto)
SID_TIMER     = $0335     ; Timer degli effetti sonori
SID_KIND      = $0336     ; Effetto sonoro attualmente in esecuzione
MATH_DIV      = $0337     ; Divisore temporaneo
MATH_REM_L    = $0338     ; Resto della divisione (basso)
MATH_REM_H    = $0339     ; Resto della divisione (alto)
VIC_LINE      = $033A     ; Linea di raster usata per la sincronizzazione

