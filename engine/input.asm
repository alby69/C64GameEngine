; =============================================================================
; C64 GAME ENGINE - input.asm
; =============================================================================
; Modulo di input generico: joystick (CIA 1) e tastiera (matrice CIA 1).
;
; Il gioco non conosce i registri della CIA: chiama solo questa API e
; riceve sempre lo stesso tipo di risposta (stato dei tasti logici).
;
; API:
;   input_init           configura la CIA 1 per l'input
;   input_read_joy       A = porta (0 = porta 1, 1 = porta 2) -> A = stato grezzo
;   input_read_kbd       A = codice PETSCII del tasto premuto (0 = nessuno)
;   input_is_pressed     A = maschera -> A = maschera AND stato (0 = rilasciato)
;   input_debounce       A = maschera, X = ritardo -> A = 1 al NUOVO evento
;   input_key_pressed    A = codice tasto -> A = 1 se quel tasto e' premuto
;
; NOTA SUI BIT DEL JOYSTICK
; I pin dei microinterruttori vanno a massa: il bit e' 0 quando il tasto e'
; premuto (logica invertita). Le maschere JOY_* riflettono questa convenzione.
; =============================================================================

!src "c64hw.inc"

; Maschera usata per pilotare una riga della matrice (bit della riga a 0)
inp_kbd_rowmask:
    !byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

; Codici PETSCII dei tasti, indicizzati come (riga * 8 + colonna).
; La tabella segue la matrice standard del Commodore 64 ed e' il punto giusto
; da modificare se serve una mappatura diversa.
inp_kbd_map:
    !byte $31, $32, $33, $34, $35, $36, $37, $38   ; riga 0: 1 2 3 4 5 6 7 8
    !byte $51, $57, $45, $52, $54, $59, $55, $49   ; riga 1: Q W E R T Y U I
    !byte $41, $53, $44, $46, $47, $48, $4A, $4B   ; riga 2: A S D F G H J K
    !byte $5A, $58, $43, $56, $42, $4E, $4D, $2C   ; riga 3: Z X C V B N M ,
    !byte $11, $0A, $20, $0D, $09, $05, $18, $1C   ; riga 4: CR SHIFT SPC SHIFT CR F1 F3 F5
    !byte $12, $05, $09, $2D, $2F, $2B, $A3, $17   ; riga 5: CR F7 F9 - / + GBP *
    !byte $30, $31, $32, $33, $34, $35, $36, $37   ; riga 6: 0 1 2 3 4 5 6 7
    !byte $38, $39, $30, $2B, $2D, $A3, $13, $7F   ; riga 7: 8 9 0 + - GBP INST DEL

; -----------------------------------------------------------------------------
; input_init
; La CIA 1 viene messa in ingresso: e' la condizione per leggere i joystick.
; -----------------------------------------------------------------------------
input_init:
    lda #$00
    sta CIA1_CRA            ; porta A in ingresso, timer fermi
    sta CIA1_CRB            ; porta B in ingresso, timer fermi
    sta INPUT_JOY
    sta INPUT_PREV
    sta INPUT_KEY
    sta ZP_DELAY
    lda #%00011111
    sta INPUT_JOY1          ; nessun pulsante del joystick in porta 1

    ; ---------------------------------------------------------------------------
    ; IMPORTANTE: si disattiva l'interrupt della CIA 1.
    ; Se il KERNAL resta in ascolto, la sua routine di interrupt scansiona la
    ; tastiera ogni frame e scrive sulla porta A: i suoi accessi si
    ; scontrerebbero con la scansione del gioco (e con la lettura del
    ; joystick). Da qui in poi la tastiera e' gestita solo dal gioco.
    ; ---------------------------------------------------------------------------
    lda #$00
    sta CIA1_ICR
    rts

; -----------------------------------------------------------------------------
; input_read_joy - A = porta (0 = porta 1, 1 = porta 2)
; Restituisce in A lo stato grezzo dei tasti (logica invertita: 0 = premuto)
; e lo memorizza in INPUT_JOY.
;
; I registri di direzione dei pin ($DC02, $DC03) vengono impostati
; esplicitamente: e' la direzione dei pin a decidere se la lettura restituisce
; il joystick oppure l'ultimo valore scritto sulla porta (che accade quando la
; tastiera e' stata interrogata poco prima).
; -----------------------------------------------------------------------------
input_read_joy:
    cmp #$01
    bcs .inp_joy_port2

    ; Porta 1: i tasti sono sulla porta B ($DC01)
    lda CIA1_CRB
    and #%11111011          ; bit 2 = 0 -> si usa il registro di direzione
    sta CIA1_CRB
    lda #$FF
    sta CIA1_DDR_B           ; tutti i pin in ingresso (1 = ingresso)
    lda CIA1_PORT_B
    sta INPUT_JOY
    rts

.inp_joy_port2:
    ; Porta 2: i tasti sono sulla porta A ($DC00)
    lda CIA1_CRA
    and #%11111011          ; bit 2 = 0 -> si usa il registro di direzione
    sta CIA1_CRA
    lda #$FF
    sta CIA1_DDR_A           ; tutti i pin in ingresso (1 = ingresso)
    lda CIA1_PORT_A
    sta INPUT_JOY
    rts

; -----------------------------------------------------------------------------
; input_read_joy_any
; Combina le due porte del joystick in un unico stato, cosi' il gioco
; funziona con il joystick in porta 1 oppure in porta 2.
;
; ATTENZIONE (comportamento reale del C64): la porta 1 del joystick condivide
; le linee con le COLONNE della tastiera. Premere un tasto (o un pulsante
; del joystick in porta 1) fa leggere come premute entrambe le cose.
; Per questo:
;   - se e' premuto un tasto della tastiera, la porta 1 non e' affidabile e
;     si usa solo la porta 2;
;   - il bit di fuoco viene comunque combinato fra le due porte.
; -----------------------------------------------------------------------------
input_read_joy_any:
    lda #$01                ; porta 2: linee dedicate
    jsr input_read_joy
    sta ZP_TMP

    lda #$00                ; porta 1: linee condivise con la tastiera
    jsr input_read_joy
    sta INPUT_JOY1

    ; Se e' premuto un tasto, la porta 1 racconterebbe falsi comandi
    lda INPUT_KEY
    bne .input_joy_any_port2

    ; Direzioni: AND dei due stati (0 = premuto su almeno una porta)
    lda ZP_TMP
    and INPUT_JOY1
    sta ZP_TMP2

    ; Fuoco: AND dei due bit di fuoco
    lda ZP_TMP
    and #%00010000
    sta ZP_TMP3
    lda INPUT_JOY1
    and #%00010000
    and ZP_TMP3
    sta ZP_TMP3

    ; Stato finale
    lda ZP_TMP2
    and #%11101111
    ora ZP_TMP3
    sta INPUT_JOY
    rts

.input_joy_any_port2:
    lda ZP_TMP
    sta INPUT_JOY
    rts

; -----------------------------------------------------------------------------
; input_is_pressed - A = maschera dei tasti
; Restituisce in A la maschera dei tasti richiesti che risultano PREMUTI
; (0 = nessuno premuto).
;
; ATTENZIONE: i pin dei joystick sono attivi a massa, quindi nel valore grezzo
; il bit di un tasto premuto e' 0. Questa routine inverte la logica e
; restituisce 1 per i tasti effettivamente premuti: il gioco non deve
; preoccuparsi del cablaggio elettrico.
; -----------------------------------------------------------------------------
input_is_pressed:
    sta ZP_MASK
    lda INPUT_JOY
    and ZP_MASK
    eor ZP_MASK              ; i bit "a zero" ( premuti) diventano 1
    rts

; -----------------------------------------------------------------------------
; input_key_pressed - A = codice PETSCII
; Restituisce A = 1 se il tasto indicato e' premuto in questo frame.
; -----------------------------------------------------------------------------
input_key_pressed:
    cmp INPUT_KEY
    beq .inp_key_yes
    lda #$00
    rts
.inp_key_yes:
    lda #$01
    rts

; -----------------------------------------------------------------------------
; input_read_kbd
; Scansiona la matrice della tastiera e restituisce in A il codice PETSCII del
; tasto premuto (0 se nessuno). Aggiorna anche INPUT_KEY.
;
; La matrice funziona cosi': la porta A (righe) viene pilotata in uscita,
; la porta B (colonne) resta in ingresso. Selezionando una riga a massa e
; leggendo le colonne, una colonna a massa significa "tasto premuto".
;
; ATTENZIONE (comportamento reale del C64): le linee della porta 1 del
; joystick sono le stesse delle colonne della tastiera. Un pulsante del
; joystick in porta 1 tiene una colonna a massa in TUTTE le righe, mentre un
; tasto vero si vede in una sola riga. Per ogni colonna si conta quindi quante
; righe la riportano: una sola = tasto reale, piu' di una = pulsante del
; joystick, e la colonna viene ignorata.
; -----------------------------------------------------------------------------
input_read_kbd:
    ; La porta A diventa output per pilotare le righe
    lda CIA1_CRA
    ora #%00000100
    sta CIA1_CRA
    lda #$00
    sta CIA1_DDR_A           ; tutti i pin della porta A in uscita (0 = uscita)

    ; La porta B resta in ingresso (colonne)
    lda CIA1_CRB
    and #%11111011
    sta CIA1_CRB
    lda #$FF
    sta CIA1_DDR_B           ; tutti i pin della porta B in ingresso

    ; Azzera i contatori e le righe delle colonne
    ldx #$07
.inp_kbd_clear:
    lda #$00
    sta KBD_COUNT,x
    sta KBD_ROW,x
    dex
    bpl .inp_kbd_clear

    ldx #$00
.inp_kbd_row:
    lda inp_kbd_rowmask,x
    sta CIA1_PORT_A

    lda CIA1_PORT_B
    eor #$FF                ; i tasti premuti si leggono come 0

    ldy #$00
.inp_kbd_bit:
    lsr
    bcc .inp_kbd_next

    ; Colonna Y rilevata nella riga X
    ; (INC non ha il modo ,y: si usa l'aritmetica)
    lda KBD_COUNT,y
    clc
    adc #$01
    sta KBD_COUNT,y
    cmp #$01
    bne .inp_kbd_twice
    txa                     ; STX non ha il modo ,y: si passa per A
    sta KBD_ROW,y           ; prima volta: si ricorda la riga
    jmp .inp_kbd_next

.inp_kbd_twice:
    cmp #$02
    bne .inp_kbd_next
    ; Seconda volta: e' il pulsante del joystick in porta 1
    lda #$00
    sta KBD_ROW,y

.inp_kbd_next:
    iny
    cpy #$08
    bne .inp_kbd_bit
    inx
    cpx #$08
    bne .inp_kbd_row

    ; Cerca l'unica colonna vista una sola volta: quello e' il tasto reale
    lda #$00
    sta INPUT_KEY
    ldy #$00
.inp_kbd_find:
    lda KBD_COUNT,y
    cmp #$01
    bne .inp_kbd_next_key
    sty ZP_TMP2             ; colonna
    lda KBD_ROW,y
    asl
    asl
    asl                     ; riga * 8
    clc
    adc ZP_TMP2
    tay
    lda inp_kbd_map,y
    sta INPUT_KEY
    jmp .inp_kbd_done

.inp_kbd_next_key:
    iny
    cpy #$08
    bne .inp_kbd_find

.inp_kbd_done:
    ; Ripristina lo stato: nessuna riga selezionata e porta A in ingresso,
    ; cosi' il joystick in porta 2 resta leggibile.
    lda #$FF
    sta CIA1_PORT_A
    lda CIA1_CRA
    and #%11111011
    sta CIA1_CRA
    lda #$FF
    sta CIA1_DDR_A           ; la porta A torna in ingresso (joystick)

    lda INPUT_KEY
    rts

; -----------------------------------------------------------------------------
; input_debounce - A = maschera dei tasti, X = ritardo in frame
; Restituisce A = 1 solo al PRIMO frame in cui il tasto viene premuto
; (edge detection con ritardo): permette di gestire il "colpo" e l'auto
; ripetizione senza ripetizioni indesiderate.
; -----------------------------------------------------------------------------
input_debounce:
    sta ZP_MASK
    stx ZP_DELAY

    ; Il tasto e' premuto?
    lda ZP_MASK
    and INPUT_JOY
    bne .inp_deb_pressed

    ; Rilasciato: azzera il timer e dimentica la pressione precedente
    lda #$00
    sta ZP_COUNT
    lda INPUT_PREV
    and ZP_MASK
    beq .inp_deb_no
    ; cancella il bit dalla maschera "precedente"
    lda ZP_MASK
    eor #$FF
    sta ZP_TMP
    lda INPUT_PREV
    and ZP_TMP
    sta INPUT_PREV
.inp_deb_no:
    lda #$00
    rts

.inp_deb_pressed:
    ; Il timer di debounce e' ancora carico: nessun nuovo evento
    lda ZP_COUNT
    beq .inp_deb_timer
    dec ZP_COUNT
    lda #$00
    rts

.inp_deb_timer:
    ; Ricarica il timer
    lda ZP_DELAY
    sta ZP_COUNT

    ; Se il tasto era gia' premuto, non e' un nuovo evento
    lda INPUT_PREV
    and ZP_MASK
    bne .inp_deb_same

    ; Nuovo evento: memorizza la pressione
    lda INPUT_PREV
    ora ZP_MASK
    sta INPUT_PREV
    lda #$01
    rts

.inp_deb_same:
    lda #$00
    rts
