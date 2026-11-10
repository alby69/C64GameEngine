; =============================================================================
; SPACE INVADERS (C64 GAME ENGINE) - si_main.asm
; =============================================================================
; Punto di ingresso e ciclo principale del gioco.
;
; Il gioco non tocca MAI i registri hardware del C64: usa solo l'API
; dell'engine (vic_driver, sid_driver, sprite_mgr, input, text, math).
; Tutto il codice specifico del gioco vive nei moduli si_*.
;
; STRUTTURA DELLA MEMORIA
;   $0801 - $080C  Stub BASIC "10 SYS 2064"
;   $0810 - $0812  Trampolino verso il gioco
;   $0813 - ....   Codice dell'engine (la libreria)
;   $1800 - ....   Codice del gioco
;   $2000 - $22BF  Dati grafici degli sprite del gioco
;
; COMPILAZIONE (dalla radice del progetto)
;   acme -f cbm -o games/space-invaders/space_invaders.prg \
;        -I engine -I games/space-invaders games/space-invaders/si_main.asm
;
; NOTA SULL'ORDINE DEGLI INCLUDE
; ACME usa l'indirizzamento zero page solo se il simbolo e' gia' definito
; quando viene usato: per questo le costanti si includono PRIMA del codice
; che le usa. Ogni file viene incluso una sola volta.
; =============================================================================

* = $0801

; -----------------------------------------------------------------------------
; Stub BASIC: "10 SYS 2064" ($0810 = 2064 decimale)
;   $0801: $0B $08  puntatore alla riga successiva a $080B
;   $0803: $0A $00  numero di riga 10
;   $0805: $9E       token BASIC SYS
;   $0806: "2064"   indirizzo in ASCII
;   $080A: $00       fine riga
;   $080B: $00 $00   fine programma
; -----------------------------------------------------------------------------
basic_header:
    !byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

* = $0810

; -----------------------------------------------------------------------------
; Trampolino: il BASIC chiama $0810, che salta al vero punto di ingresso.
; Serve per poter linkare l'engine PRIMA del codice del gioco.
; -----------------------------------------------------------------------------
    jmp si_entry

* = $0813

; =============================================================================
; LA LIBRERIA (engine)
; Codice indipendente dal gioco: puo' essere usata da qualunque progetto.
; =============================================================================
!src "engine.asm"

* = $1800

; =============================================================================
; COSTANTI DEL GIOCO
; Nessuna di queste costanti appartiene all'engine.
; =============================================================================
!src "si_config.inc"

* = $1810

; -----------------------------------------------------------------------------
; si_entry
; Punto di ingresso chiamato dallo stub BASIC.
; -----------------------------------------------------------------------------
si_entry:
    sei                     ; Configurazione sicura
    cld                     ; Flag decimale disattivato
    jsr si_init
    cli                     ; Riabilita gli interrupt

; -----------------------------------------------------------------------------
; si_main_loop
; Un frame = una sincronizzazione raster.
; -----------------------------------------------------------------------------
si_main_loop:
    jsr vic_wait_raster
    jsr si_update
    jmp si_main_loop

; -----------------------------------------------------------------------------
; si_init
; Inizializza l'engine e mostra la schermata del titolo.
; -----------------------------------------------------------------------------
si_init:
    jsr sid_init            ; Motore audio
    jsr vic_init            ; Motore video
    jsr sprite_init         ; Gestore degli sprite
    jsr input_init          ; Joystick e tastiera
    jsr text_init           ; Cursore di testo

    lda #SI_STATE_TITLE
    sta SI_STATE

    jsr si_hud_init
    jsr si_hud_show_title
    rts

; -----------------------------------------------------------------------------
; si_new_game
; Prepara una partita nuova: azzera il punteggio, le vite, lo schermo e
; rilancia lo sciame.
; -----------------------------------------------------------------------------
si_new_game:
    lda #$00
    sta SI_SCORE_LO
    sta SI_SCORE_HI
    sta SI_HI_LO
    sta SI_HI_HI
    lda #SI_LIVES_START
    sta SI_LIVES
    sta SI_COOLDOWN

    jsr vic_init            ; Schermo pulito
    jsr sprite_init         ; Tutti gli sprite liberati
    jsr text_init
    jsr si_hud_init
    jsr si_player_init
    jsr si_invaders_init
    rts

; -----------------------------------------------------------------------------
; si_update
; Macchina a stati finiti: un frame di gioco.
; -----------------------------------------------------------------------------
si_update:
    ; Aggiorna una volta per frame lo stato dei comandi.
    ; Il joystick viene letto su entrambe le porte e la tastiera viene
    ; interrogata qui, cosi' i comandi valgono anche nelle schermate di
    ; titolo e game over (dove si decide di iniziare la partita).
    jsr input_read_joy_any
    jsr input_read_kbd

    lda SI_STATE
    cmp #SI_STATE_TITLE
    beq .si_upd_title
    cmp #SI_STATE_PLAYING
    beq .si_upd_playing
    cmp #SI_STATE_GAMEOVER
    beq .si_upd_gameover
    cmp #SI_STATE_NEXTWAVE
    beq .si_upd_nextwave
    rts

.si_upd_title:
    ; Si aspetta la pressione del fuoco per iniziare
    jsr si_fire_pressed
    beq .si_upd_title_end
    jsr si_new_game
    lda #SI_STATE_PLAYING
    sta SI_STATE
.si_upd_title_end:
    rts

.si_upd_playing:
    inc SI_FRAME

    ; Cooldown del fuoco
    lda SI_COOLDOWN
    beq .si_upd_no_cooldown
    dec SI_COOLDOWN
.si_upd_no_cooldown:

    jsr si_player_update     ; Cannone e proiettile
    jsr si_bullet_update     ; Movimento del proiettile
    jsr si_invaders_update   ; Sciame e bombe
    jsr si_check_collisions  ; Collisioni
    jsr sid_tick             ; Audio (sweep e durata degli effetti)
    rts

.si_upd_gameover:
    jsr si_hud_show_game_over
    ; Si riparte con un nuovo colpo
    jsr si_fire_pressed
    beq .si_upd_gameover_end
    jsr si_new_game
    lda #SI_STATE_PLAYING
    sta SI_STATE
.si_upd_gameover_end:
    rts

.si_upd_nextwave:
    ; Ondata completata: lo sciame riparte un po' piu' in basso e veloce
    jsr si_invaders_init
    lda #SI_STATE_PLAYING
    sta SI_STATE
    rts

; -----------------------------------------------------------------------------
; si_fire_pressed
; A = 1 se il tasto di fuoco e' premuto (joystick su una delle porte
; oppure barra spaziatrice), A = 0 altrimenti.
; -----------------------------------------------------------------------------
si_fire_pressed:
    lda #JOY_FIRE
    jsr input_is_pressed
    bne .si_fire_yes
    lda INPUT_KEY
    cmp #$20                ; SPAZIO
    bne .si_fire_no
.si_fire_yes:
    lda #$01
    rts
.si_fire_no:
    lda #$00
    rts

; -----------------------------------------------------------------------------
; si_check_collisions
; 1. proiettile del giocatore contro lo sciame
; 2. bomba aliena contro il cannone
; 3. lo sciame raggiunge la base
; -----------------------------------------------------------------------------
si_check_collisions:
    ; --- 1. proiettile contro sciame ---
    lda SI_BULLET_ON
    beq .si_col_bomb

    ; La Y del proiettile deve essere dentro l'altezza dello sciame
    lda SI_BULLET_Y
    sec
    sbc SI_SWARM_Y
    bcc .si_col_bomb
    cmp #SI_SWARM_HEIGHT
    bcs .si_col_bomb

    ; La X del proiettile deve essere dentro la larghezza dello sciame
    lda SI_BULLET_X
    sec
    sbc SI_SWARM_X
    bcc .si_col_bomb
    cmp #SI_SWARM_WIDTH
    bcs .si_col_bomb

    ; Colpito! Il proiettile viene distrutto
    lda #$00
    sta SI_BULLET_ON
    lda SI_SLOT_BULLET
    jsr sprite_disable

    jsr si_invaders_on_hit    ; Punteggio e accelerazione dello sciame
    lda #SI_SCORE_HIT
    jsr si_hud_add_score

.si_col_bomb:
    ; --- 2. bomba aliena contro cannone ---
    lda SI_BOMB_ON
    beq .si_col_bottom

    lda SI_BOMB_Y
    cmp #SI_BOMB_HIT_TOP
    bcc .si_col_bottom
    cmp #SI_BOMB_HIT_BOT
    bcs .si_col_bottom

    ; La X della bomba deve cadere sulla hitbox del cannone
    lda SI_BOMB_X
    sec
    sbc SI_PLAYER_X
    clc
    adc #SI_BOMB_HALF
    cmp #SI_BOMB_FULL
    bcs .si_col_bottom

    jsr si_player_hit

.si_col_bottom:
    ; --- 3. lo sciame e' arrivato alla base ---
    lda SI_SWARM_Y
    cmp #SI_SWARM_BOTTOM_Y
    bcc .si_col_done
    lda #SI_STATE_GAMEOVER
    sta SI_STATE
.si_col_done:
    rts

; =============================================================================
; MODULI DEL GIOCO (logica specifica di Space Invaders)
; =============================================================================
!src "si_hud.asm"
!src "si_player.asm"
!src "si_invaders.asm"

; =============================================================================
; DATI GRAFICI DEL GIOCO (devono stare per ultimi: impongono * = $2000)
; =============================================================================
!src "si_sprites.asm"
