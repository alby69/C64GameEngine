; =============================================================================
; SPACE INVADERS (C64 GAME ENGINE) - si_player.asm
; =============================================================================
; Logica specifica del cannone del giocatore e del suo proiettile.
;
; Nota di refactoring: nel codice originale questo file conteneva anche la
; lettura del joystick e il debounce del tasto fuoco. Qui la lettura dei
; comandi e' delegata all'engine (input.asm) e questo modulo contiene solo
; le regole del gioco (velocita', limiti, cooldown, posizionamento).
; =============================================================================

; -----------------------------------------------------------------------------
; si_player_init
; Alloca gli sprite del giocatore e del proiettile e li posiziona.
; -----------------------------------------------------------------------------
si_player_init:
    ; Posizione iniziale del cannone
    lda #SI_PLAYER_START_X
    sta SI_PLAYER_X

    ; Alloca lo slot sprite del cannone
    jsr sprite_alloc
    sta SI_SLOT_PLAYER

    ; Immagine e colore
    lda SI_SLOT_PLAYER
    ldx #SI_BLOCK_PLAYER
    jsr sprite_set_frame
    lda SI_SLOT_PLAYER
    ldx #SI_COLOR_PLAYER
    jsr sprite_set_color

    ; Posizione
    lda SI_SLOT_PLAYER
    ldx SI_PLAYER_X
    ldy #SI_PLAYER_Y
    jsr sprite_move

    ; Visibile
    lda SI_SLOT_PLAYER
    jsr sprite_enable

    ; Alloca lo slot sprite del proiettile (nascosto per ora)
    jsr sprite_alloc
    sta SI_SLOT_BULLET
    lda SI_SLOT_BULLET
    ldx #SI_BLOCK_BULLET
    jsr sprite_set_frame
    lda SI_SLOT_BULLET
    ldx #SI_COLOR_BULLET
    jsr sprite_set_color
    lda SI_SLOT_BULLET
    jsr sprite_disable

    ; Nessun proiettile attivo
    lda #$00
    sta SI_BULLET_ON
    sta SI_COOLDOWN
    rts

; -----------------------------------------------------------------------------
; si_player_update
; Un frame di gioco: legge i comandi, muove il cannone, gestisce il fuoco.
; -----------------------------------------------------------------------------
si_player_update:
    lda #$00
    sta SI_DIR

    ; --- Joystick (porta 1 o 2, lo stato e' gia' stato letto) ---
    lda #JOY_LEFT
    jsr input_is_pressed
    beq .si_pl_chk_right
    lda #$01
    sta SI_DIR
.si_pl_chk_right:
    lda #JOY_RIGHT
    jsr input_is_pressed
    beq .si_pl_chk_keys
    lda #$02
    sta SI_DIR

.si_pl_chk_keys:
    ; --- Tastiera: A e D muovono, SPAZIO spara ---
    ; La tastiera viene interrogata una volta per frame in si_update:
    ; qui si controlla solo il tasto letto.
    lda INPUT_KEY
    cmp #'A'
    beq .si_pl_key_left
    cmp #'D'
    beq .si_pl_key_right
    jmp .si_pl_apply

.si_pl_key_left:
    lda #$01
    sta SI_DIR
    jmp .si_pl_apply

.si_pl_key_right:
    lda #$02
    sta SI_DIR

.si_pl_apply:
    lda SI_DIR
    cmp #$01
    beq .si_pl_left
    cmp #$02
    beq .si_pl_right
    jmp .si_pl_move_sprite

.si_pl_left:
    lda SI_PLAYER_X
    sec
    sbc #SI_PLAYER_SPEED
    cmp #SI_PLAYER_MIN_X
    bcc .si_pl_move_sprite
    sta SI_PLAYER_X
    jmp .si_pl_move_sprite

.si_pl_right:
    lda SI_PLAYER_X
    clc
    adc #SI_PLAYER_SPEED
    cmp #SI_PLAYER_MAX_X
    bcs .si_pl_move_sprite
    sta SI_PLAYER_X

.si_pl_move_sprite:
    ; Aggiorna la posizione dello sprite
    lda SI_SLOT_PLAYER
    ldx SI_PLAYER_X
    ldy #SI_PLAYER_Y
    jsr sprite_move

    ; --- Fuoco ---
    jsr si_player_check_fire
    rts

; -----------------------------------------------------------------------------
; si_player_check_fire
; Spara se il tasto fuoco e' premuto, se il cooldown e' scaduto e se non c'e'
; gia' un proiettile a schermo.
; -----------------------------------------------------------------------------
si_player_check_fire:
    lda SI_COOLDOWN
    bne .si_pl_no_fire

    ; Joystick oppure barra spaziatrice
    jsr si_fire_pressed
    beq .si_pl_no_fire

    ; Un solo colpo alla volta (regola di Space Invaders)
    lda SI_BULLET_ON
    bne .si_pl_no_fire

    jsr si_player_fire
    lda #SI_FIRE_DELAY
    sta SI_COOLDOWN
.si_pl_no_fire:
    rts

; -----------------------------------------------------------------------------
; si_player_fire
; Crea il proiettile al centro del cannone e suona il raggio laser.
; -----------------------------------------------------------------------------
si_player_fire:
    ; Posizione del proiettile
    lda SI_PLAYER_X
    clc
    adc #SI_BULLET_DX
    sta SI_BULLET_X
    lda #SI_PLAYER_Y
    sec
    sbc #SI_BULLET_DY
    sta SI_BULLET_Y

    lda #$01
    sta SI_BULLET_ON

    ; Sprite del proiettile
    lda SI_SLOT_BULLET
    ldx SI_BULLET_X
    ldy SI_BULLET_Y
    jsr sprite_move
    lda SI_SLOT_BULLET
    jsr sprite_enable

    ; Effetto sonoro (fornito dall'engine)
    lda #SID_SFX_LASER
    jsr sid_play_sfx
    rts

; -----------------------------------------------------------------------------
; si_bullet_update
; Muove il proiettile verso l'alto; se esce dallo schermo lo disattiva.
; -----------------------------------------------------------------------------
si_bullet_update:
    lda SI_BULLET_ON
    beq .si_bu_none

    lda SI_BULLET_Y
    sec
    sbc #SI_BULLET_SPEED
    bcc .si_bu_kill
    cmp #SI_BULLET_TOP_Y
    bcc .si_bu_kill

    sta SI_BULLET_Y
    lda SI_SLOT_BULLET
    ldx SI_BULLET_X
    ldy SI_BULLET_Y
    jsr sprite_move
    rts

.si_bu_kill:
    lda #$00
    sta SI_BULLET_ON
    lda SI_SLOT_BULLET
    jsr sprite_disable

.si_bu_none:
    rts

; -----------------------------------------------------------------------------
; si_player_hit
; Il giocatore e' stato colpito dalla bomba: perde una vita.
; -----------------------------------------------------------------------------
si_player_hit:
    ; La bomba sparisce
    lda #$00
    sta SI_BOMB_ON
    lda SI_SLOT_BOMB
    jsr sprite_disable

    ; Esplosione
    lda #SID_SFX_EXPLOSION
    jsr sid_play_sfx

    ; Una vita in meno
    dec SI_LIVES
    jsr si_hud_draw_lives
    lda SI_LIVES
    bne .si_ph_keep

    ; Game over
    lda #SI_STATE_GAMEOVER
    sta SI_STATE
    rts

.si_ph_keep:
    ; Il cannone torna al centro
    lda #SI_PLAYER_START_X
    sta SI_PLAYER_X
    rts
