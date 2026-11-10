; =============================================================================
; C64 GAME ENGINE - text.asm
; =============================================================================
; Rendering del testo PETSCII nella Screen RAM ($0400) e nella Color RAM
; ($D800). Il gioco non conosce gli indirizzi della memoria video: scrive
; testo con il cursore logico.
;
; CONVENZIONE DELLE CHIAMATE
;   text_gotoxy    A = riga (0-24), X = colonna (0-39)
;   text_print     A = puntatore ALTO, X = puntatore BASSO della stringa
;                  (stringa in codici schermo terminata da 0)
;   text_print_at  come text_print, ma posiziona il cursore prima: la riga e
;                  la colonna vanno messe in ZP_ROW e ZP_COL
;
; API:
;   text_init           inizializza il cursore e il colore di default
;   text_gotoxy         A = riga, X = colonna: sposta il cursore
;   text_print          A = ptr alto, X = ptr basso: stampa la stringa
;   text_print_at       stampa la stringa alla posizione ZP_ROW/ZP_COL
;   text_putc           A = codice schermo: stampa un carattere
;   text_print_bcd      A = byte basso, X = byte alto: stampa 4 cifre BCD
;   text_print_dec      A = valore 0-255: stampa 3 cifre decimali
;   text_clear_area     A = riga, X = colonna, Y = lunghezza: cancella
;   text_set_color      A = colore (0-15) per i caratteri successivi
; =============================================================================

!src "c64hw.inc"

; -----------------------------------------------------------------------------
; text_init
; -----------------------------------------------------------------------------
text_init:
    lda #COLOR_WHITE
    sta TEXT_COLOR
    lda #$00
    sta ZP_ROW
    sta ZP_COL
    lda #$00
    ldx #$00
    jsr text_gotoxy
    rts

; -----------------------------------------------------------------------------
; text_set_color - A = colore (0-15)
; -----------------------------------------------------------------------------
text_set_color:
    sta TEXT_COLOR
    rts

; -----------------------------------------------------------------------------
; text_gotoxy - A = riga (0-24), X = colonna (0-39)
; Calcola l'indirizzo nella Screen RAM e nella Color RAM.
; -----------------------------------------------------------------------------
text_gotoxy:
    sta ZP_ROW
    stx ZP_COL

    ; offset = riga * 40 + colonna
    ; Il prodotto riga * 40 non entra in 8 bit (fino a 24 * 40 = 960):
    ; si calcola prima riga * 5 (max 120, ci sta) e poi si raddoppia tre
    ; volte a 16 bit.
    lda ZP_ROW
    asl                         ; riga * 2
    asl                         ; riga * 4
    clc
    adc ZP_ROW                  ; riga * 5
    sta ZP_OFFSET

    lda #$00
    sta ZP_OFFSET_HI

    ldx #$03
.text_gotoxy_shift:
    asl ZP_OFFSET
    rol ZP_OFFSET_HI            ; riga * 40
    dex
    bne .text_gotoxy_shift

    clc                         ; + colonna
    lda ZP_OFFSET
    adc ZP_COL
    sta ZP_OFFSET
    bcc .text_gotoxy_no_carry
    inc ZP_OFFSET_HI
.text_gotoxy_no_carry:

    ; Cursore nella Screen RAM
    clc
    lda ZP_OFFSET
    adc #<SCREEN_RAM
    sta TEXT_CURSOR
    lda ZP_OFFSET_HI
    adc #>SCREEN_RAM
    sta TEXT_CURSOR+1

    ; Cursore nella Color RAM
    clc
    lda ZP_OFFSET
    adc #<COLOR_RAM
    sta TEXT_CPTR
    lda ZP_OFFSET_HI
    adc #>COLOR_RAM
    sta TEXT_CPTR+1
    rts

; -----------------------------------------------------------------------------
; text_advance
; Sposta in avanti di una posizione i due cursori (schermo e colori).
; -----------------------------------------------------------------------------
text_advance:
    inc TEXT_CURSOR
    bne .text_adv_screen
    inc TEXT_CURSOR+1
.text_adv_screen:
    inc TEXT_CPTR
    bne .text_adv_color
    inc TEXT_CPTR+1
.text_adv_color:
    rts

; -----------------------------------------------------------------------------
; text_putc - A = codice schermo del carattere
; Scrive il carattere e il colore corrente, poi avanza il cursore.
; -----------------------------------------------------------------------------
text_putc:
    sta ZP_TMP

    ; Carattere nella Screen RAM
    lda TEXT_CURSOR
    sta ZP_DST
    lda TEXT_CURSOR+1
    sta ZP_DST+1
    ldy #$00
    lda ZP_TMP
    sta (ZP_DST),y

    ; Colore nella Color RAM
    lda TEXT_CPTR
    sta ZP_PTR
    lda TEXT_CPTR+1
    sta ZP_PTR+1
    ldy #$00
    lda TEXT_COLOR
    sta (ZP_PTR),y

    jsr text_advance
    rts

; -----------------------------------------------------------------------------
; text_print - A = puntatore ALTO, X = puntatore BASSO
; Stampa la stringa terminata da 0 a partire dalla posizione del cursore.
; -----------------------------------------------------------------------------
text_print:
    sta ZP_SRC+1
    stx ZP_SRC
.text_print_loop:
    ldy #$00
    lda (ZP_SRC),y
    beq .text_print_done
    jsr text_putc
    inc ZP_SRC
    bne .text_print_loop
    inc ZP_SRC+1
    jmp .text_print_loop
.text_print_done:
    rts

; -----------------------------------------------------------------------------
; text_print_at - A = puntatore ALTO, X = puntatore BASSO
; La posizione di partenza e' in ZP_ROW (riga) e ZP_COL (colonna).
; -----------------------------------------------------------------------------
text_print_at:
    sta ZP_TMP2
    stx ZP_TMP3
    lda ZP_ROW
    ldx ZP_COL
    jsr text_gotoxy
    lda ZP_TMP2
    ldx ZP_TMP3
    jsr text_print
    rts

; -----------------------------------------------------------------------------
; text_print_bcd - A = byte basso, X = byte alto
; Stampa un numero di 4 cifre in formato BCD (00 00 -> "0000").
; -----------------------------------------------------------------------------
text_print_bcd:
    sta ZP_TMP_LO
    stx ZP_TMP_HI

    lda ZP_TMP_HI
    lsr
    lsr
    lsr
    lsr
    ora #$30                ; migliaia
    jsr text_putc

    lda ZP_TMP_HI
    and #$0F
    ora #$30                ; centinaia
    jsr text_putc

    lda ZP_TMP_LO
    lsr
    lsr
    lsr
    lsr
    ora #$30                ; decine
    jsr text_putc

    lda ZP_TMP_LO
    and #$0F
    ora #$30                ; unità
    jsr text_putc
    rts

; -----------------------------------------------------------------------------
; text_print_digit - A = valore 0-15
; Stampa una sola cifra decimale.
; -----------------------------------------------------------------------------
text_print_digit:
    and #$0F
    ora #$30
    jsr text_putc
    rts

; -----------------------------------------------------------------------------
; text_print_dec - A = valore 0-255
; Stampa il valore in base 10 con tre cifre (zeri iniziali inclusi).
; -----------------------------------------------------------------------------
text_print_dec:
    sta ZP_TMP_LO

    ; Centinaia (0-2)
    lda ZP_TMP_LO
    cmp #100
    bcc .text_dec_no_hundred
    sec
    sbc #100
    sta ZP_TMP_LO
    lda #$01
    jmp .text_dec_hundred
.text_dec_no_hundred:
    lda #$00
.text_dec_hundred:
    ora #$30
    jsr text_putc

    ; Decine
    lda ZP_TMP_LO
    cmp #10
    bcc .text_dec_no_ten
    sec
    sbc #10
    sta ZP_TMP_LO
    lda #$01
    jmp .text_dec_ten
.text_dec_no_ten:
    lda #$00
.text_dec_ten:
    ora #$30
    jsr text_putc

    ; Unità
    lda ZP_TMP_LO
    ora #$30
    jsr text_putc
    rts

; -----------------------------------------------------------------------------
; text_clear_area - A = riga, X = colonna, Y = numero di caratteri
; Cancella un'area rettangolare di una riga (riempie di spazi).
; -----------------------------------------------------------------------------
text_clear_area:
    sta ZP_ROW
    stx ZP_COL
    sty ZP_COUNT

    lda ZP_ROW
    ldx ZP_COL
    jsr text_gotoxy

.text_clear_loop:
    ldy ZP_COUNT
    beq .text_clear_done
    dec ZP_COUNT
    lda #$20                ; spazio
    jsr text_putc
    jmp .text_clear_loop
.text_clear_done:
    rts
