; =============================================================================
; C64 GAME ENGINE - sid_driver.asm
; =============================================================================
; Driver audio generico per il SID (MOS 6581 / 8580).
;
; Espone le tre voci del chip come risorse indipendenti: il gioco sceglie
; voce, frequenza, forma d'onda e inviluppo, il driver si occupa del dettaglio
; hardware (gate, timer, sweep).
;
; I registri delle tre voci sono distanti 7 byte l'uno dall'altro
; ($D400, $D407, $D40E): per questo l'offset del registro si calcola come
; voce * 7 e si usa l'indirizzamento indicizzato.
;
; API:
;   sid_init          azzera il chip e imposta il volume master
;   sid_mute          spegne immediatamente tutte le voci
;   sid_set_volume    A = volume master (0-15)
;   sid_set_wave      A = voce (0-2), X = maschera forma d'onda (SID_WAVE_*)
;   sid_set_adsr      A = voce (0-2), X = byte AD, Y = byte SR
;   sid_play_note     A = voce (0-2), X = frequenza bassa, Y = frequenza alta
;   sid_play_sfx      A = effetto predefinito (SID_SFX_*)
;   sid_stop_voice    A = voce (0-2): spegne solo quella voce
;   sid_tick          da chiamare una volta per frame: gestisce i timer
; =============================================================================

!src "c64hw.inc"

; Effetti sonori predefiniti (generici, non legati a nessun gioco)
SID_SFX_LASER     = 0       ; Raggio laser: sweep discendente
SID_SFX_EXPLOSION = 1       ; Esplosione: rumore bianco
SID_SFX_UFO       = 2       ; Sirena: onda quadra
SID_SFX_BLIP      = 3       ; Beep breve

; Offset del primo registro di ogni voce (voce * 7)
sid_voice_offset:
    !byte 0, 7, 14

; -----------------------------------------------------------------------------
; sid_init
; Azzera tutti i registri del SID, imposta il volume massimo e azzera i
; timer degli effetti.
; -----------------------------------------------------------------------------
sid_init:
    ldx #$1C                ; $D400 - $D41C: 29 registri
    lda #$00
.sid_clear_loop:
    sta $D400,x
    dex
    bpl .sid_clear_loop

    lda #$0F                ; Volume master 15, nessun filtro forzato
    sta SID_VOL_CTRL

    lda #$00
    sta SID_TIMER
    sta SID_KIND
    sta SID_STATE

    ; Azzera le tabelle delle tre voci
    ldx #$02
.sid_clear_tables:
    lda #$00
    sta SID_WAVE,x
    sta SID_AD,x
    sta SID_SR,x
    sta SID_FREQ_LO,x
    sta SID_FREQ_HI,x
    dex
    bpl .sid_clear_tables
    rts

; -----------------------------------------------------------------------------
; sid_mute - spegne tutte le voci
; -----------------------------------------------------------------------------
sid_mute:
    lda #$00
    sta SID_V1_CTRL
    sta SID_V2_CTRL
    sta SID_V3_CTRL
    sta SID_TIMER
    sta SID_KIND
    rts

; -----------------------------------------------------------------------------
; sid_set_volume - A = volume master (0-15)
; -----------------------------------------------------------------------------
sid_set_volume:
    and #$0F
    sta SID_VOL_CTRL
    rts

; -----------------------------------------------------------------------------
; sid_set_wave - A = voce (0-2), X = maschera forma d'onda (SID_WAVE_*)
; -----------------------------------------------------------------------------
sid_set_wave:
    cmp #$03
    bcs .sid_wave_done
    tay
    txa
    sta SID_WAVE,y
.sid_wave_done:
    rts

; -----------------------------------------------------------------------------
; sid_set_adsr - A = voce (0-2), X = byte ADSR "AD", Y = byte ADSR "SR"
; -----------------------------------------------------------------------------
sid_set_adsr:
    cmp #$03
    bcs .sid_adsr_done
    sta ZP_TMP2             ; voce
    sty ZP_TMP3             ; byte SR
    txa                     ; byte AD
    ldy ZP_TMP2
    sta SID_AD,y
    lda ZP_TMP3
    sta SID_SR,y
.sid_adsr_done:
    rts

; -----------------------------------------------------------------------------
; sid_play_note - A = voce (0-2), X = frequenza bassa, Y = frequenza alta
; Applica alla voce la forma d'onda e l'inviluppo precedentemente impostati
; e avvia il suono (gate on).
; -----------------------------------------------------------------------------
sid_play_note:
    cmp #$03
    bcs .sid_note_done

    sta ZP_TMP2             ; voce
    sty ZP_TMP3             ; frequenza alta
    stx ZP_TMP4             ; frequenza bassa

    ldx ZP_TMP2
    lda sid_voice_offset,x
    sta ZP_TMP              ; offset dei registri SID della voce

    ldy ZP_TMP2
    lda ZP_TMP4
    sta SID_FREQ_LO,y
    lda ZP_TMP3
    sta SID_FREQ_HI,y

    ldx ZP_TMP
    lda SID_FREQ_LO,y
    sta $D400,x
    lda SID_FREQ_HI,y
    sta $D401,x
    lda SID_AD,y
    sta $D405,x
    lda SID_SR,y
    sta $D406,x
    lda SID_WAVE,y
    ora #SID_WAVE_GATE
    sta $D404,x
.sid_note_done:
    rts

; -----------------------------------------------------------------------------
; sid_stop_voice - A = voce (0-2)
; -----------------------------------------------------------------------------
sid_stop_voice:
    cmp #$03
    bcs .sid_stop_done
    tay
    lda sid_voice_offset,y
    tax
    lda #$00
    sta $D404,x             ; Gate off
.sid_stop_done:
    rts

; -----------------------------------------------------------------------------
; sid_play_sfx - A = effetto predefinito (SID_SFX_*)
; Gli effetti sono "generici" e riutilizzabili da qualunque gioco.
; -----------------------------------------------------------------------------
sid_play_sfx:
    cmp #SID_SFX_BLIP
    bcc .sid_sfx_valid
    rts
.sid_sfx_valid:
    tax                     ; X = effetto
    lda #$00
    sta SID_KIND
    sta SID_TIMER

    cmp #SID_SFX_LASER
    beq .sid_sfx_laser
    cmp #SID_SFX_EXPLOSION
    beq .sid_sfx_explosion
    cmp #SID_SFX_UFO
    beq .sid_sfx_ufo

    ; --- SID_SFX_BLIP: beep breve sulla voce 1 ---
    lda #$01                ; voce 1
    ldy #$40                ; onda quadra
    jsr sid_set_wave
    lda #$01
    ldx #$00                ; AD: attacco 0, decay 0
    ldy #$08                ; SR: sustain 0, release 8
    jsr sid_set_adsr
    lda #$01                ; voce 1
    ldx #$00                ; frequenza bassa
    ldy #$08                ; frequenza alta
    jsr sid_play_note
    jmp .sid_sfx_done

.sid_sfx_laser:
    ; Raggio laser sulla voce 0: triangolare con sweep discendente
    lda #$00                ; voce 0
    ldy #SID_WAVE_TRI
    jsr sid_set_wave
    lda #$00
    ldx #$04                ; AD: attacco 0, decay 4
    ldy #$02                ; SR: sustain 0, release 2
    jsr sid_set_adsr
    lda #$00                ; voce 0
    ldx #$00                ; frequenza bassa
    ldy #$1E                ; frequenza alta
    jsr sid_play_note
    lda #SID_SFX_LASER
    sta SID_KIND
    lda #18                 ; durata dello sweep in frame
    sta SID_TIMER
    jmp .sid_sfx_done

.sid_sfx_explosion:
    ; Esplosione sulla voce 2: rumore bianco
    lda #$02                ; voce 2
    ldy #SID_WAVE_NOISE
    jsr sid_set_wave
    lda #$02
    ldx #$0A                ; AD: attacco 0, decay 10
    ldy #$04                ; SR: sustain 0, release 4
    jsr sid_set_adsr
    lda #$02                ; voce 2
    ldx #$20                ; frequenza bassa
    ldy #$08                ; frequenza alta
    jsr sid_play_note
    lda #SID_SFX_EXPLOSION
    sta SID_KIND
    lda #32                 ; durata del rumore in frame
    sta SID_TIMER
    jmp .sid_sfx_done

.sid_sfx_ufo:
    ; Sirena sulla voce 0: onda quadra
    lda #$00                ; voce 0
    ldy #SID_WAVE_PULSE
    jsr sid_set_wave
    lda #$00
    ldx #$22                ; AD: attacco 2, decay 2
    ldy #$88                ; SR: sustain 8, release 8
    jsr sid_set_adsr
    lda #$00                ; voce 0
    ldx #$00                ; frequenza bassa
    ldy #$20                ; frequenza alta
    jsr sid_play_note
    lda #SID_SFX_UFO
    sta SID_KIND

.sid_sfx_done:
    rts

; -----------------------------------------------------------------------------
; sid_tick
; Da chiamare una volta per frame: gestisce lo sweep del laser e lo spegnimento
; degli effetti al termine della loro durata.
; -----------------------------------------------------------------------------
sid_tick:
    lda SID_KIND
    beq .sid_tick_done
    cmp #SID_SFX_LASER
    beq .sid_tick_laser
    cmp #SID_SFX_EXPLOSION
    beq .sid_tick_explosion
    jmp .sid_tick_done

.sid_tick_laser:
    lda SID_TIMER
    beq .sid_tick_done
    dec SID_TIMER
    bne .sid_sweep
    ; Timer scaduto: spegni la voce 0
    lda #$00
    sta SID_V1_CTRL
    sta SID_KIND
    rts

.sid_sweep:
    ; Abbassa di 2 la frequenza della voce 0 ad ogni frame
    lda SID_FREQ_HI
    sec
    sbc #$02
    bcs .sid_sweep_store
    lda #$00
.sid_sweep_store:
    sta SID_FREQ_HI
    sta SID_V1_FREQ_HI
    rts

.sid_tick_explosion:
    lda SID_TIMER
    beq .sid_tick_done
    dec SID_TIMER
    bne .sid_tick_done
    lda #$00
    sta SID_V3_CTRL
    sta SID_KIND

.sid_tick_done:
    rts
