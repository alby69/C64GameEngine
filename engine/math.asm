; =============================================================================
; C64 GAME ENGINE - math.asm
; =============================================================================
; Helper matematici a 8/16 bit, indipendenti dal gioco.
;
; API:
;   math_mul8    A = multiplicando, X = moltiplicatore -> MATH_RESULT (16 bit)
;   math_div8    A = dividendo, X = divisore -> A = quoziente, resto in
;                MATH_REM_L
;   math_rand    A = byte pseudo-casuale (xorshift a 8 bit)
;   math_abs     A = valore -> A = valore assoluto
;   math_clamp   A = valore, X = minimo, Y = massimo -> A = valore limitato
; =============================================================================

!src "c64hw.inc"

; -----------------------------------------------------------------------------
; math_mul8 - A = multiplicando, X = moltiplicatore
; Risultato a 16 bit in MATH_RESULT (basso in MATH_RESULT, alto in +1).
; -----------------------------------------------------------------------------
math_mul8:
    sta ZP_ARG             ; multiplicando
    stx ZP_ARG2            ; moltiplicatore
    lda #$00
    sta MATH_RESULT
    sta MATH_RESULT+1
    ldy #$08
.math_mul_loop:
    lsr ZP_ARG2            ; C = bit corrente del moltiplicatore
    bcc .math_mul_noadd
    clc
    lda MATH_RESULT
    adc ZP_ARG
    sta MATH_RESULT
    lda MATH_RESULT+1
    adc #$00
    sta MATH_RESULT+1
.math_mul_noadd:
    asl ZP_ARG             ; multiplicando <<= 1
    dey
    bne .math_mul_loop
    rts

; -----------------------------------------------------------------------------
; math_div8 - A = dividendo (0-255), X = divisore (1-255)
; Restituisce in A il quoziente; il resto resta in MATH_REM_L.
; -----------------------------------------------------------------------------
math_div8:
    sta ZP_ARG             ; dividendo
    stx ZP_ARG2            ; divisore
    lda #$00
    sta MATH_REM_L
    sta MATH_REM_H
    sta MATH_RESULT
    ldy #$08
.math_div_loop:
    asl MATH_RESULT        ; il quoziente cresce a sinistra
    asl MATH_REM_L
    rol MATH_REM_H
    asl ZP_ARG             ; il dividendo cresce a sinistra
    bcc .math_div_noinc
    inc MATH_REM_L         ; il bit uscente entra nel resto
    bne .math_div_noinc
    inc MATH_REM_H
.math_div_noinc:
    lda MATH_REM_H
    bne .math_div_subtract ; resto >= 512 -> sicuro >= divisore
    lda MATH_REM_L
    cmp ZP_ARG2
    bcc .math_div_next
.math_div_subtract:
    sec
    lda MATH_REM_L
    sbc ZP_ARG2
    sta MATH_REM_L
    lda MATH_REM_H
    sbc #$00
    sta MATH_REM_H
    lda MATH_RESULT        ; il bit di quoziente e' 1
    ora #$01
    sta MATH_RESULT
.math_div_next:
    dey
    bne .math_div_loop
    lda MATH_RESULT
    rts

; -----------------------------------------------------------------------------
; math_rand - A = byte pseudo-casuale
; Xorshift a 8 bit: periodo 255, rapido e senza moltiplicazioni.
; -----------------------------------------------------------------------------
math_rand:
    lda MATH_RAND
    bne .math_rand_ok
    lda #$A5              ; il seme non deve essere zero
    sta MATH_RAND
.math_rand_ok:
    sta ZP_TMP

    ; x ^= x << 3
    lda ZP_TMP
    asl
    asl
    asl
    sta ZP_TMP2
    lda ZP_TMP
    eor ZP_TMP2
    sta ZP_TMP

    ; x ^= x >> 5
    lda ZP_TMP
    sta ZP_TMP2
    lsr
    lsr
    lsr
    lsr
    lsr
    sta ZP_TMP2
    lda ZP_TMP
    eor ZP_TMP2

    sta MATH_RAND
    lda MATH_RAND
    rts

; -----------------------------------------------------------------------------
; math_abs - A = valore -> A = valore assoluto
; -----------------------------------------------------------------------------
math_abs:
    cmp #$80
    bcs .math_abs_neg
    rts
.math_abs_neg:
    eor #$FF
    clc
    adc #$01
    rts

; -----------------------------------------------------------------------------
; math_clamp - A = valore, X = minimo, Y = massimo -> A = valore limitato
; -----------------------------------------------------------------------------
math_clamp:
    stx ZP_TMP_X
    sty ZP_TMP_Y
    cmp ZP_TMP_X
    bcs .math_clamp_max
    lda ZP_TMP_X
    rts
.math_clamp_max:
    cmp ZP_TMP_Y
    bcc .math_clamp_done
    lda ZP_TMP_Y
.math_clamp_done:
    rts
