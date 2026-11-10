; =============================================================================
; C64 GAME ENGINE - sprite_mgr.asm
; =============================================================================
; Gestore generico degli 8 sprite hardware del VIC-II.
;
; Il gioco non parla mai direttamente con i registri $D000-$D02E: usa solo
; questa API. Cosi' lo stesso motore puo' pilotare sprite di qualunque gioco.
;
; API:
;   sprite_init         prepara il VIC-II (hires 24x21) e libera tutti gli slot
;   sprite_alloc        A = slot libero (0-7) oppure $FF se sono tutti occupati
;   sprite_free         A = slot da liberare
;   sprite_move         A = slot, X = coordinata X (0-255), Y = coordinata Y
;   sprite_set_msb      A = slot, X = 9° bit della X (0 o 1) per X > 255
;   sprite_enable       A = slot: mostra lo sprite
;   sprite_disable      A = slot: nasconde lo sprite
;   sprite_set_color    A = slot, X = colore (0-15)
;   sprite_set_frame    A = slot, X = blocco grafico (indirizzo / 64)
;   sprite_hide_all     nasconde tutti gli sprite
;   sprite_get_x        A = slot: restituisce in X la coordinata X salvata
; =============================================================================

!src "c64hw.inc"

; Maschera di bit per ogni slot sprite
spr_slot_mask:
    !byte $01, $02, $04, $08, $10, $20, $40, $80

; -----------------------------------------------------------------------------
; sprite_init
; Spegne tutti gli sprite, azzera le tabelle interne e imposta la modalita'
; hires 24x21 senza espansioni.
; -----------------------------------------------------------------------------
sprite_init:
    lda #$00
    sta SPR_ALLOC
    sta VIC_SPR_ENA
    sta VIC_SPR_X_MSB

    ldx #$07
.spr_init_tables:
    lda #$00
    sta SPR_XTABLE,x
    sta SPR_MSB,x
    sta SPR_FRAME,x
    dex
    bpl .spr_init_tables

    ; Nessun puntatore dati valido: il gioco deve assegnare i propri frame
    ldx #$07
.spr_init_pointers:
    lda #$00
    sta $07F8,x
    dex
    bpl .spr_init_pointers

    ; Modalita' hires 24x21
    lda #$00
    sta VIC_SPR_MCOLOR
    sta VIC_SPR_EXP_X
    sta VIC_SPR_EXP_Y
    rts

; -----------------------------------------------------------------------------
; sprite_alloc - A = slot libero, oppure $FF se non ce ne sono
; Lo slot viene marcato come occupato e inizializzato (nascosto).
; -----------------------------------------------------------------------------
sprite_alloc:
    ldx #$00
.spr_alloc_scan:
    lda SPR_ALLOC
    and spr_slot_mask,x
    beq .spr_alloc_free
    inx
    cpx #$08
    bne .spr_alloc_scan
    lda #$FF                ; nessuno slot libero
    rts

.spr_alloc_free:
    txa
    tay
    lda spr_slot_mask,y
    ora SPR_ALLOC
    sta SPR_ALLOC

    ; Inizializza lo slot: nascosto, senza 9° bit, frame 0
    txa
    sta ZP_TMP
    tay
    lda #$00
    sta SPR_XTABLE,y
    sta SPR_MSB,y
    sta SPR_FRAME,y
    sta $07F8,y

    ; Lo slot parte nascosto
    lda ZP_TMP
    jsr sprite_disable

    ; Colore di default: bianco
    lda ZP_TMP
    ldx #COLOR_WHITE
    jsr sprite_set_color

    ; Restituisce lo slot trovato
    lda ZP_TMP
    rts

; -----------------------------------------------------------------------------
; sprite_free - A = slot da liberare
; -----------------------------------------------------------------------------
sprite_free:
    cmp #$08
    bcs .spr_free_done
    sta ZP_TMP
    tay
    lda spr_slot_mask,y
    sta ZP_MASK
    lda ZP_MASK
    eor #$FF
    sta ZP_MASK
    lda SPR_ALLOC
    and ZP_MASK
    sta SPR_ALLOC

    ldx ZP_TMP
    jsr sprite_disable
.spr_free_done:
    rts

; -----------------------------------------------------------------------------
; sprite_move - A = slot, X = coordinata X, Y = coordinata Y
; -----------------------------------------------------------------------------
sprite_move:
    cmp #$08
    bcs .spr_move_done
    sta ZP_TMP
    stx ZP_TMP_X
    sty ZP_TMP_Y

    ldx ZP_TMP
    lda ZP_TMP_X
    sta SPR_XTABLE,x
    sta $D000,x             ; VIC_SPR0_X + slot
    lda ZP_TMP_Y
    sta $D001,x             ; VIC_SPR0_Y + slot
.spr_move_done:
    rts

; -----------------------------------------------------------------------------
; sprite_set_msb - A = slot, X = 9° bit della X (0 o 1)
; Necessario per posizionare uno sprite oltre il pixel 255.
; -----------------------------------------------------------------------------
sprite_set_msb:
    cmp #$08
    bcs .spr_msb_done
    sta ZP_TMP
    tay
    lda spr_slot_mask,y
    sta ZP_MASK

    ; Cancella il bit di questo slot nel registro del VIC-II
    lda ZP_MASK
    eor #$FF
    sta ZP_TMP2
    lda VIC_SPR_X_MSB
    and ZP_TMP2
    sta VIC_SPR_X_MSB

    ; Se richiesto, reimposta il bit
    lda ZP_TMP_X
    beq .spr_msb_done
    lda VIC_SPR_X_MSB
    ora ZP_MASK
    sta VIC_SPR_X_MSB

    ldy ZP_TMP
    lda ZP_TMP_X
    sta SPR_MSB,y
.spr_msb_done:
    rts

; -----------------------------------------------------------------------------
; sprite_get_x - A = slot: X = coordinata X salvata
; -----------------------------------------------------------------------------
sprite_get_x:
    cmp #$08
    bcs .spr_get_x_done
    tay
    lda SPR_XTABLE,y
    tax
.spr_get_x_done:
    rts

; -----------------------------------------------------------------------------
; sprite_enable - A = slot
; -----------------------------------------------------------------------------
sprite_enable:
    cmp #$08
    bcs .spr_enable_done
    tay
    lda spr_slot_mask,y
    sta ZP_MASK
    lda VIC_SPR_ENA
    ora ZP_MASK
    sta VIC_SPR_ENA
.spr_enable_done:
    rts

; -----------------------------------------------------------------------------
; sprite_disable - A = slot
; -----------------------------------------------------------------------------
sprite_disable:
    cmp #$08
    bcs .spr_disable_done
    tay
    lda spr_slot_mask,y
    sta ZP_MASK
    lda ZP_MASK
    eor #$FF
    sta ZP_MASK
    lda VIC_SPR_ENA
    and ZP_MASK
    sta VIC_SPR_ENA
.spr_disable_done:
    rts

; -----------------------------------------------------------------------------
; sprite_hide_all - nasconde tutti gli sprite
; -----------------------------------------------------------------------------
sprite_hide_all:
    lda #$00
    sta VIC_SPR_ENA
    rts

; -----------------------------------------------------------------------------
; sprite_set_color - A = slot, X = colore (0-15)
; -----------------------------------------------------------------------------
sprite_set_color:
    cmp #$08
    bcs .spr_color_done
    sta ZP_TMP
    tay
    txa                     ; colore richiesto
    ldx ZP_TMP
    sta $D027,x             ; VIC_SPR0_COL + slot
.spr_color_done:
    rts

; -----------------------------------------------------------------------------
; sprite_set_frame - A = slot, X = blocco grafico (indirizzo dati / 64)
; Il blocco 0 corrisponde a $0000, il blocco 128 a $2000.
; -----------------------------------------------------------------------------
sprite_set_frame:
    cmp #$08
    bcs .spr_frame_done
    sta ZP_TMP
    tay
    txa                     ; blocco grafico richiesto
    sta SPR_FRAME,y
    ldx ZP_TMP
    sta $07F8,x             ; puntatore ai dati dello sprite
.spr_frame_done:
    rts
