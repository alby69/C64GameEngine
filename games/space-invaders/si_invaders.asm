; =============================================================================
; SPACE INVADERS (C64 GAME ENGINE) - si_invaders.asm
; =============================================================================
; Logica specifica dello sciame di invasori e delle bombe aliene.
;
; Nota di refactoring: la marcia a 4 note e' un suono "del gioco", quindi
; resta qui (con la sua tabella di frequenze); l'engine fornisce solo le
; primitive vocali (sid_set_wave, sid_set_adsr, sid_play_note).
; =============================================================================

; Frequenze delle 4 note discendenti della marcia (SID, formato 16 bit)
si_march_freq_lo:
    !byte $70, $F0, $80, $20
si_march_freq_hi:
    !byte $04, $03, $03, $03

; Inviluppo della marcia: percussivo e secco
si_march_ad = $06
si_march_sr = $02

; -----------------------------------------------------------------------------
; si_invaders_init
; Prepara una nuova ondata: posizione dello sciame, velocita' e sprite.
; -----------------------------------------------------------------------------
si_invaders_init:
    lda #SI_SWARM_START_X
    sta SI_SWARM_X
    lda #SI_SWARM_START_Y
    sta SI_SWARM_Y

    lda #$01                ; Direzione iniziale: verso destra
    sta SI_SWARM_DIR

    lda #SI_SWARM_COUNT
    sta SI_ALIVE

    lda #30                ; Timer iniziale del passo
    sta SI_SWARM_SPEED
    sta SI_SWARM_TIMER

    lda #$00
    sta SI_ANIM
    sta SI_BOMB_ON

    ; Alloca gli slot sprite delle tre righe
    jsr sprite_alloc
    sta SI_SLOT_SWARM1
    jsr sprite_alloc
    sta SI_SLOT_SWARM2
    jsr sprite_alloc
    sta SI_SLOT_SWARM3

    ; Colori delle tre righe
    lda SI_SLOT_SWARM1
    ldx #SI_COLOR_INV1
    jsr sprite_set_color
    lda SI_SLOT_SWARM2
    ldx #SI_COLOR_INV2
    jsr sprite_set_color
    lda SI_SLOT_SWARM3
    ldx #SI_COLOR_INV3
    jsr sprite_set_color

    ; Frame iniziale dell'animazione
    jsr si_invaders_toggle_anim

    ; Alloca lo slot sprite della bomba (nascosta)
    jsr sprite_alloc
    sta SI_SLOT_BOMB
    lda SI_SLOT_BOMB
    ldx #SI_BLOCK_BOMB
    jsr sprite_set_frame
    lda SI_SLOT_BOMB
    ldx #SI_COLOR_BOMB
    jsr sprite_set_color
    lda SI_SLOT_BOMB
    jsr sprite_disable

    ; Posiziona lo sciame
    jsr si_invaders_refresh
    rts

; -----------------------------------------------------------------------------
; si_invaders_update
; Un frame: il timer del passo scade, lo sciame avanza, suona la marcia e si
; alterna l'animazione. Poi si aggiornano le bombe.
; -----------------------------------------------------------------------------
si_invaders_update:
    dec SI_SWARM_TIMER
    bne .si_inv_bombs

    ; Il passo e' scaduto: ricarica il timer con la velocita' attuale
    lda SI_SWARM_SPEED
    sta SI_SWARM_TIMER

    ; Suono della marcia
    jsr si_invaders_march

    ; Alterna il frame di animazione
    lda SI_ANIM
    eor #$01
    sta SI_ANIM
    jsr si_invaders_toggle_anim

    ; Movimento orizzontale
    lda SI_SWARM_DIR
    bne .si_inv_right

    ; Verso sinistra
    lda SI_SWARM_X
    sec
    sbc #SI_SWARM_STEP
    cmp #SI_SWARM_MIN_X
    bcc .si_inv_drop_right
    sta SI_SWARM_X
    jmp .si_inv_refresh

.si_inv_drop_right:
    ; Bordo sinistro: scende e inverte
    lda SI_SWARM_Y
    clc
    adc #SI_SWARM_DROP
    sta SI_SWARM_Y
    lda #$01
    sta SI_SWARM_DIR
    jmp .si_inv_refresh

.si_inv_right:
    ; Verso destra
    lda SI_SWARM_X
    clc
    adc #SI_SWARM_STEP
    cmp #SI_SWARM_MAX_X
    bcs .si_inv_drop_left
    sta SI_SWARM_X
    jmp .si_inv_refresh

.si_inv_drop_left:
    ; Bordo destro: scende e inverte
    lda SI_SWARM_Y
    clc
    adc #SI_SWARM_DROP
    sta SI_SWARM_Y
    lda #$00
    sta SI_SWARM_DIR

.si_inv_refresh:
    jsr si_invaders_refresh

.si_inv_bombs:
    jsr si_bomb_update
    rts

; -----------------------------------------------------------------------------
; si_invaders_refresh
; Calcola le coordinate dei tre sprite che rappresentano lo sciame.
; -----------------------------------------------------------------------------
si_invaders_refresh:
    ; Riga 1
    lda SI_SLOT_SWARM1
    ldx SI_SWARM_X
    ldy SI_SWARM_Y
    jsr sprite_move

    ; Riga 2: piu' in basso e a destra
    lda SI_SWARM_X
    clc
    adc #SI_SWARM_ROW2_DX
    sta SI_TMP_X
    lda SI_SWARM_Y
    clc
    adc #SI_SWARM_ROW2_DY
    sta SI_TMP_Y
    lda SI_SLOT_SWARM2
    ldx SI_TMP_X
    ldy SI_TMP_Y
    jsr sprite_move

    ; Riga 3
    lda SI_SWARM_X
    clc
    adc #SI_SWARM_ROW3_DX
    sta SI_TMP_X
    lda SI_SWARM_Y
    clc
    adc #SI_SWARM_ROW3_DY
    sta SI_TMP_Y
    lda SI_SLOT_SWARM3
    ldx SI_TMP_X
    ldy SI_TMP_Y
    jsr sprite_move
    rts

; -----------------------------------------------------------------------------
; si_invaders_toggle_anim
; Assegna alle tre righe il frame A o B in base a SI_ANIM.
; -----------------------------------------------------------------------------
si_invaders_toggle_anim:
    lda SI_ANIM
    bne .si_inv_frame_b

    ; Frame A
    lda SI_SLOT_SWARM1
    ldx #SI_BLOCK_INV1_A
    jsr sprite_set_frame
    lda SI_SLOT_SWARM2
    ldx #SI_BLOCK_INV2_A
    jsr sprite_set_frame
    lda SI_SLOT_SWARM3
    ldx #SI_BLOCK_INV3_A
    jsr sprite_set_frame
    rts

.si_inv_frame_b:
    ; Frame B
    lda SI_SLOT_SWARM1
    ldx #SI_BLOCK_INV1_B
    jsr sprite_set_frame
    lda SI_SLOT_SWARM2
    ldx #SI_BLOCK_INV2_B
    jsr sprite_set_frame
    lda SI_SLOT_SWARM3
    ldx #SI_BLOCK_INV3_B
    jsr sprite_set_frame
    rts

; -----------------------------------------------------------------------------
; si_invaders_on_hit
; Un invasore e' stato colpito: suona l'esplosione, si aggiorna il conteggio
; e lo sciame accelera.
; -----------------------------------------------------------------------------
si_invaders_on_hit:
    lda #SID_SFX_EXPLOSION
    jsr sid_play_sfx

    dec SI_ALIVE
    beq .si_inv_wave_done

    ; Ogni invasore eliminato accelera lo sciame
    lda SI_SWARM_SPEED
    cmp #4
    bcc .si_inv_hit_done
    sec
    sbc #$01
    sta SI_SWARM_SPEED
.si_inv_hit_done:
    rts

.si_inv_wave_done:
    ; Ondata completata: il gioco passa allo stato "nuova ondata"
    lda #SI_STATE_NEXTWAVE
    sta SI_STATE
    rts

; -----------------------------------------------------------------------------
; si_invaders_march
; Suona la nota corrente della marcia a 4 note sulla seconda voce del SID.
; -----------------------------------------------------------------------------
si_invaders_march:
    ; Prepara la voce 1 (la seconda del chip)
    lda #$01
    ldx #SID_WAVE_SAW
    jsr sid_set_wave
    lda #$01
    ldx #si_march_ad
    ldy #si_march_sr
    jsr sid_set_adsr

    ; Frequenza della nota corrente
    ldx SI_MARCH_NOTE
    lda si_march_freq_lo,x
    sta SI_TMP_X
    lda si_march_freq_hi,x
    sta SI_TMP_Y

    ; Suona
    lda #$01
    ldx SI_TMP_X
    ldy SI_TMP_Y
    jsr sid_play_note

    ; Nota successiva (0 -> 1 -> 2 -> 3 -> 0)
    inc SI_MARCH_NOTE
    lda SI_MARCH_NOTE
    cmp #4
    bcc .si_march_done
    lda #$00
    sta SI_MARCH_NOTE
.si_march_done:
    rts

; -----------------------------------------------------------------------------
; si_bomb_update
; Gestisce la caduta delle bombe aliene: se non ce n'e' una attiva, ogni
; tanto ne genera una (il casuale arriva dall'engine).
; -----------------------------------------------------------------------------
si_bomb_update:
    lda SI_BOMB_ON
    bne .si_bomb_move

    ; Nessuna bomba attiva: si decide con il generatore casuale dell'engine
    jsr math_rand
    and #$1F
    bne .si_bomb_none

    ; Posizione di nascita della bomba (sotto lo sciame)
    lda SI_SWARM_X
    clc
    adc #SI_BOMB_DX
    sta SI_BOMB_X
    lda SI_SWARM_Y
    clc
    adc #SI_BOMB_DY
    sta SI_BOMB_Y

    lda #$01
    sta SI_BOMB_ON

    ; Sprite della bomba
    lda SI_SLOT_BOMB
    ldx SI_BOMB_X
    ldy SI_BOMB_Y
    jsr sprite_move
    lda SI_SLOT_BOMB
    jsr sprite_enable

.si_bomb_none:
    rts

.si_bomb_move:
    lda SI_BOMB_Y
    clc
    adc #SI_BOMB_SPEED
    cmp #SI_BOMB_BOTTOM_Y
    bcs .si_bomb_kill
    sta SI_BOMB_Y

    lda SI_SLOT_BOMB
    ldx SI_BOMB_X
    ldy SI_BOMB_Y
    jsr sprite_move
    rts

.si_bomb_kill:
    lda #$00
    sta SI_BOMB_ON
    lda SI_SLOT_BOMB
    jsr sprite_disable
    rts
