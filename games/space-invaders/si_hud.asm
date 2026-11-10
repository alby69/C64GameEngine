; =============================================================================
; SPACE INVADERS (C64 GAME ENGINE) - si_hud.asm
; =============================================================================
; HUD specifico del gioco: etichette, punteggio, vite, schermata del titolo e
; Game Over.
;
; Tutto il rendering e' delegato al modulo text dell'engine: qui ci sono solo
; le stringhe e la logica di punteggio del gioco.
; =============================================================================

; -----------------------------------------------------------------------------
; si_hud_init
; Stampa le etichette fisse dell'interfaccia.
; -----------------------------------------------------------------------------
si_hud_init:
    ; "SCORE" alla riga 0, colonna 2
    lda #$00
    ldx #$02
    jsr text_gotoxy
    lda #>si_str_score
    ldx #<si_str_score
    jsr text_print

    ; "HI-SCORE" alla riga 0, colonna 16
    lda #$00
    ldx #$10
    jsr text_gotoxy
    lda #>si_str_hiscore
    ldx #<si_str_hiscore
    jsr text_print

    ; "LIVES:" alla riga 24, colonna 2
    lda #SI_HUD_ROW_LIVES
    ldx #$02
    jsr text_gotoxy
    lda #>si_str_lives
    ldx #<si_str_lives
    jsr text_print

    jsr si_hud_draw_score
    jsr si_hud_draw_lives
    rts

; -----------------------------------------------------------------------------
; si_hud_draw_score
; Stampa il punteggio (4 cifre BCD) sotto la scritta SCORE.
; -----------------------------------------------------------------------------
si_hud_draw_score:
    lda #SI_HUD_ROW_SCORE
    ldx #SI_HUD_COL_SCORE
    jsr text_gotoxy
    lda SI_SCORE_LO
    ldx SI_SCORE_HI
    jsr text_print_bcd
    rts

; -----------------------------------------------------------------------------
; si_hud_draw_lives
; Stampa il numero di vite accanto alla scritta LIVES.
; -----------------------------------------------------------------------------
si_hud_draw_lives:
    lda #SI_HUD_ROW_LIVES
    ldx #SI_HUD_COL_LIVES
    jsr text_gotoxy
    lda SI_LIVES
    jsr text_print_digit
    rts

; -----------------------------------------------------------------------------
; si_hud_add_score - A = valore BCD da aggiungere
; -----------------------------------------------------------------------------
si_hud_add_score:
    sed                     ; Aritmetica decimale BCD
    clc
    adc SI_SCORE_LO
    sta SI_SCORE_LO
    lda SI_SCORE_HI
    adc #$00
    sta SI_SCORE_HI
    cld                     ; Si esce SEMPRE in modo decimale

    jsr si_hud_draw_score
    rts

; -----------------------------------------------------------------------------
; si_hud_show_title
; Schermata di attesa.
; -----------------------------------------------------------------------------
si_hud_show_title:
    lda #SI_HUD_ROW_TITLE
    ldx #$00
    jsr text_gotoxy
    lda #>si_str_title
    ldx #<si_str_title
    jsr text_print

    lda #SI_HUD_ROW_PRESS
    ldx #$00
    jsr text_gotoxy
    lda #>si_str_press
    ldx #<si_str_press
    jsr text_print
    rts

; -----------------------------------------------------------------------------
; si_hud_show_game_over
; -----------------------------------------------------------------------------
si_hud_show_game_over:
    lda #SI_HUD_ROW_OVER
    ldx #$11
    jsr text_gotoxy
    lda #>si_str_game_over
    ldx #<si_str_game_over
    jsr text_print
    rts

; -----------------------------------------------------------------------------
; STRINGHE IN CODICI SCHERMO
; !scr converte i caratteri in codici schermo: le lettere vanno scritte in
; minuscolo (ACME le converte nei codici $01-$1A, cioe' lettere maiuscole
; sullo schermo), le cifre e la spaziatura si lasciano cosi' come sono.
; -----------------------------------------------------------------------------
si_str_score:
    !scr "score", 0
si_str_hiscore:
    !scr "hi-score", 0
si_str_lives:
    !scr "lives: ", 0
si_str_title:
    !scr "commodore 64 space invaders", 0
si_str_press:
    !scr "press fire or space to start", 0
si_str_game_over:
    !scr "game over", 0
