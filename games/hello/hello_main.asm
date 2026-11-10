; =============================================================================
; HELLO - gioco di esempio minimo del C64 Game Engine
; =============================================================================
; Il gioco piu' piccolo possibile: non usa sprite, solo l'engine video e testo.
; Serve da modello per partire con un gioco nuovo.
;
;   Compilazione:  scripts\build-game.bat -game hello
;                  ./scripts/build-game.sh --game hello
;                  make game GAME=hello
; =============================================================================

* = $0801

; Stub BASIC: "10 SYS 2064" ($0810 = 2064 decimale)
basic_header:
    !byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

* = $0810

; Trampolino: il BASIC chiama $0810, che salta al vero ingresso
    jmp hello_entry

* = $0813

; La libreria (una sola volta, prima di qualunque codice che la usa)
!src "engine.asm"

* = $1800

; Configurazione specifica del gioco
!src "hello_config.inc"

* = $1810

; -----------------------------------------------------------------------------
; hello_entry - punto di ingresso
; -----------------------------------------------------------------------------
hello_entry:
    sei
    cld

    ; --- inizializzazione dell'engine ---
    jsr sid_init            ; motore audio
    jsr vic_init            ; motore video
    jsr text_init           ; cursore di testo

    ; --- contenuto del gioco ---
    lda #HELLO_ROW
    ldx #HELLO_COL
    jsr text_gotoxy
    lda #>hello_msg
    ldx #<hello_msg
    jsr text_print

    lda #HELLO_ROW + 2
    ldx #HELLO_COL
    jsr text_gotoxy
    lda #>hello_hint
    ldx #<hello_hint
    jsr text_print

    ; --- avvio del gioco ---
    lda #HELLO_STATE_RUN
    sta HELLO_STATE

    cli

; -----------------------------------------------------------------------------
; hello_loop - ciclo principale: un frame = una sincronizzazione raster
; -----------------------------------------------------------------------------
hello_loop:
    jsr vic_wait_raster
    jmp hello_loop

; -----------------------------------------------------------------------------
; Stringhe in codici schermo (minuscolo = maiuscole a schermo)
; -----------------------------------------------------------------------------
hello_msg:
    !scr "ciao dal c64 game engine", 0
hello_hint:
    !scr "questo gioco usa solo l'engine", 0
