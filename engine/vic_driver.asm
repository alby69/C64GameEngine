; =============================================================================
; C64 GAME ENGINE - vic_driver.asm
; =============================================================================
; Driver video generico per il VIC-II (MOS 6569 / 6567).
;
; Il driver non sa nulla del gioco: espone solo primitive di basso livello
; (inizializzazione, colori, pulizia schermo, sincronizzazione raster).
;
; API:
;   vic_init             configura il VIC-II e pulisce lo schermo
;   vic_set_border       A = colore del bordo
;   vic_set_bg           A = colore dello sfondo
;   vic_clear_screen     pulisce Screen RAM ($0400) e Color RAM ($D800)
;   vic_wait_raster      sincronizza con la linea di raster
;   vic_set_raster_line  A = nuova linea di sincronizzazione
;   vic_get_raster       A = linea di raster corrente
; =============================================================================

!src "c64hw.inc"

; -----------------------------------------------------------------------------
; vic_init
; Configura il VIC-II per uno schermo testuale standard ($0400 / $1000),
; disabilita gli interrupt, spegne gli sprite e pulisce lo schermo.
; -----------------------------------------------------------------------------
vic_init:
    ; Posizione della RAM: Screen RAM a $0400, caratteri a $1000
    lda #$15
    sta VIC_MEM_SETUP

    ; Disabilita gli interrupt raster/sprite
    lda #$00
    sta VIC_IRQ_MASK
    sta VIC_IRQ_STATUS

    ; Spegne tutti gli sprite e azzera i 9° bit delle coordinate
    sta VIC_SPR_ENA
    sta VIC_SPR_X_MSB

    ; Modalita' hires 24x21, nessuna espansione X/Y
    sta VIC_SPR_MCOLOR
    sta VIC_SPR_EXP_X
    sta VIC_SPR_EXP_Y

    ; Priorita': sprite davanti allo sfondo
    lda #$00
    sta VIC_SPR_PRIO

    ; Colori di default: look arcade, fondo nero
    lda #COLOR_BLACK
    sta VIC_BORDER_COL
    sta VIC_BG_COL0
    sta VIC_BG_COL1
    sta VIC_BG_COL2
    sta VIC_BG_COL3

    jsr vic_clear_screen
    rts

; -----------------------------------------------------------------------------
; vic_set_border - A = colore del bordo (0-15)
; -----------------------------------------------------------------------------
vic_set_border:
    sta VIC_BORDER_COL
    rts

; -----------------------------------------------------------------------------
; vic_set_bg - A = colore dello sfondo (0-15)
; -----------------------------------------------------------------------------
vic_set_bg:
    sta VIC_BG_COL0
    rts

; -----------------------------------------------------------------------------
; vic_clear_screen
; Riempe la Screen RAM di spazi e la Color RAM di bianco.
; -----------------------------------------------------------------------------
vic_clear_screen:
    ldx #$00
    lda #$20                ; codice schermo dello spazio
    ldy #COLOR_WHITE        ; colore predefinito del testo
.clear_loop:
    tya
    sta COLOR_RAM, x
    sta COLOR_RAM + $100, x
    sta COLOR_RAM + $200, x
    sta COLOR_RAM + $300, x
    lda #$20
    sta SCREEN_RAM, x
    sta SCREEN_RAM + $100, x
    sta SCREEN_RAM + $200, x
    sta SCREEN_RAM + $300, x
    inx
    bne .clear_loop
    rts

; -----------------------------------------------------------------------------
; vic_set_raster_line - A = linea di raster (0-255)
; Imposta la linea usata da vic_wait_raster per la sincronizzazione.
; -----------------------------------------------------------------------------
vic_set_raster_line:
    sta VIC_LINE
    rts

; -----------------------------------------------------------------------------
; vic_get_raster - A = linea di raster corrente
; -----------------------------------------------------------------------------
vic_get_raster:
    lda VIC_RASTER
    rts

; -----------------------------------------------------------------------------
; vic_wait_raster
; Attende che il pennello raggiunga la linea di raster configurata e che la
; superi: in quel momento e' sicuro modificare la memoria video senza
; sfarfallio (tearing).
; -----------------------------------------------------------------------------
vic_wait_raster:
.wait_line:
    lda VIC_RASTER
    cmp VIC_LINE
    bne .wait_line
.wait_pass:
    lda VIC_RASTER
    cmp VIC_LINE
    beq .wait_pass
    rts
