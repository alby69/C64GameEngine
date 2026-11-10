# API Reference — C64 Game Engine

L'engine è una libreria in Assembly 6502 per il Commodore 64.
Ogni modulo espone solo routine di basso livello: **il motore non sa nulla del gioco**.

```asm
; Includere la libreria (una sola volta, all'inizio del file principale)
!src "engine.asm"
```

> **Nota ACME**: ogni file può essere incluso **una sola volta** e i *label locali*
> (`.nome`) devono essere univoci in tutto il programma.

---

## c64hw.inc — Costanti hardware

Nessuna routine: solo indirizzi di registri, indici di memoria e colori.

| Simbolo | Valore | Descrizione |
|---|---|---|
| `VIC_SPR0_X` … `VIC_SPR7_Y` | `$D000`–`$D00F` | Coordinate degli 8 sprite |
| `VIC_SPR_X_MSB` | `$D010` | 9° bit delle coordinate X |
| `VIC_RASTER` | `$D012` | Linea di raster corrente |
| `VIC_SPR_ENA` | `$D015` | Abilitazione degli sprite |
| `VIC_SPR_COLL_S` / `_B` | `$D01E` / `$D01F` | Collisioni hardware |
| `VIC_BORDER_COL`, `VIC_BG_COL0..3` | `$D020`–`$D024` | Colori bordo e sfondo |
| `VIC_SPR0_COL` … `VIC_SPR7_COL` | `$D027`–`$D02E` | Colori individuali degli sprite |
| `SID_V1_*` … `SID_V3_*` | `$D400`–`$D414` | Registri delle 3 voci del SID |
| `SID_VOL_CTRL` | `$D418` | Volume master |
| `SID_WAVE_TRI/SAW/PULSE/NOISE/GATE` | `$10/$20/$40/$80/$01` | Forme d'onda |
| `CIA1_PORT_A` / `CIA1_PORT_B` | `$DC00` / `$DC01` | Porte della CIA 1 |
| `JOY_UP/DOWN/LEFT/RIGHT/FIRE` | `$01/$02/$04/$08/$10` | Maschere joystick (logica invertita) |
| `SCREEN_RAM` / `COLOR_RAM` | `$0400` / `$D800` | RAM schermo e colori |
| `SPRITE_PTR_BASE` | `$07F8` | Puntatori ai dati degli sprite |
| `COLOR_BLACK` … `COLOR_LIGHTGREY` | `0`–`15` | I 16 colori del C64 |

---

## vic_driver.asm — Video

| Routine | Input | Output / Effetto |
|---|---|---|
| `vic_init` | — | Configura VIC-II, disabilita interrupt, spegne sprite, pulisce lo schermo |
| `vic_set_border` | A = colore | Imposta il colore del bordo |
| `vic_set_bg` | A = colore | Imposta il colore dello sfondo |
| `vic_clear_screen` | — | Riempie Screen RAM di spazi e Color RAM di bianco |
| `vic_wait_raster` | — | Attende la linea raster configurata (sincronizzazione) |
| `vic_set_raster_line` | A = linea (0-255) | Cambia la linea di sincronizzazione |
| `vic_get_raster` | — | A = linea di raster corrente |

```asm
    jsr vic_init
    lda #COLOR_BLACK
    jsr vic_set_bg
    ; ... logica di gioco ...
    jsr vic_wait_raster      ; una volta per frame
```

---

## sid_driver.asm — Audio

Le tre voci del SID sono trattate come risorse indipendenti.
La frequenza si imposta in 16 bit (`X` = byte basso, `Y` = byte alto).

| Routine | Input | Output / Effetto |
|---|---|---|
| `sid_init` | — | Azzera il chip, volume massimo, timer puliti |
| `sid_mute` | — | Spegne subito tutte le voci |
| `sid_set_volume` | A = 0-15 | Volume master |
| `sid_set_wave` | A = voce, X = maschera `SID_WAVE_*` | Forma d'onda della voce |
| `sid_set_adsr` | A = voce, X = AD, Y = SR | Inviluppo della voce |
| `sid_play_note` | A = voce, X = freq lo, Y = freq hi | Suona la nota con wave/ADSR impostati |
| `sid_stop_voice` | A = voce | Spegne una sola voce |
| `sid_play_sfx` | A = `SID_SFX_*` | Effetto predefinito (laser, esplosione, UFO, beep) |
| `sid_tick` | — | Da chiamare una volta per frame: gestisce sweep e durata degli effetti |

```asm
    lda #$01                ; voce 1
    ldx #SID_WAVE_SAW
    jsr sid_set_wave
    lda #$01
    ldx #$06                ; AD
    ldy #$02                ; SR
    jsr sid_set_adsr
    lda #$01                ; voce 1
    ldx $70                 ; frequenza bassa
    ldy $04                 ; frequenza alta
    jsr sid_play_note
```

---

## sprite_mgr.asm — Sprite

| Routine | Input | Output / Effetto |
|---|---|---|
| `sprite_init` | — | Modalità hires 24x21, tutti gli sprite liberi e nascosti |
| `sprite_alloc` | — | A = slot libero (0-7) oppure `$FF` se sono pieni |
| `sprite_free` | A = slot | Libera lo slot |
| `sprite_move` | A = slot, X = x, Y = y | Posiziona lo sprite |
| `sprite_set_msb` | A = slot, X = 0/1 | 9° bit della X (per X > 255) |
| `sprite_get_x` | A = slot | X = coordinata X memorizzata |
| `sprite_enable` / `sprite_disable` | A = slot | Mostra / nasconde lo sprite |
| `sprite_set_color` | A = slot, X = colore | Colore dello sprite |
| `sprite_set_frame` | A = slot, X = blocco | Immagine: blocco = indirizzo dati / 64 |
| `sprite_hide_all` | — | Nasconde tutti gli sprite |

```asm
    jsr sprite_alloc         ; A = slot
    sta my_slot
    lda my_slot
    ldx #SI_BLOCK_PLAYER    ; blocco grafico
    jsr sprite_set_frame
    lda my_slot
    ldx #COLOR_LIGHTGREEN
    jsr sprite_set_color
    lda my_slot
    ldx #160                ; X
    ldy #228                ; Y
    jsr sprite_move
    lda my_slot
    jsr sprite_enable
```

---

## input.asm — Joystick e tastiera

| Routine | Input | Output |
|---|---|---|
| `input_init` | — | Configura la CIA 1 in ingresso |
| `input_read_joy` | A = porta (0 = porta 1, 1 = porta 2) | A = stato grezzo, salvato in `INPUT_JOY` |
| `input_read_kbd` | — | A = codice PETSCII del tasto premuto (0 = nessuno) |
| `input_is_pressed` | A = maschera | A = maschera dei tasti **premuti** (0 = nessuno) |
| `input_key_pressed` | A = codice tasto | A = 1 se quel tasto è premuto |
| `input_debounce` | A = maschera, X = ritardo | A = 1 solo al **nuovo** evento (edge detection) |

> I pin del joystick sono attivi a massa: nel valore grezzo il bit di un tasto
> premuto è **0**. `input_is_pressed` gestisce l'inversione: restituisce 1 per i
> tasti effettivamente premuti.

```asm
    lda #$01
    jsr input_read_joy
    lda #JOY_LEFT
    jsr input_is_pressed
    beq .not_left
```

---

## text.asm — Testo PETSCII

| Routine | Input | Output |
|---|---|---|
| `text_init` | — | Cursore a (0,0), colore bianco |
| `text_gotoxy` | A = riga (0-24), X = colonna (0-39) | Sposta il cursore |
| `text_print` | A = ptr alto, X = ptr basso | Stampa una stringa (terminata da 0) |
| `text_print_at` | A = ptr alto, X = ptr basso | Stampa a `ZP_ROW`/`ZP_COL` |
| `text_putc` | A = codice schermo | Scrive un carattere e avanza |
| `text_print_bcd` | A = byte basso, X = byte alto | Stampa 4 cifre BCD |
| `text_print_dec` | A = 0-255 | Stampa 3 cifre decimali |
| `text_print_digit` | A = 0-15 | Stampa una cifra |
| `text_clear_area` | A = riga, X = colonna, Y = lunghezza | Cancella Y caratteri |
| `text_set_color` | A = colore | Colore dei caratteri successivi |

Le stringhe sono scritte in **minuscolo** con `!scr`: ACME le converte nei
codici schermo (`$01`-`$1A`), che sullo schermo appaiono maiuscole.

```asm
si_str_title:
    !scr "commodore 64 space invaders", 0

    lda #5                  ; riga
    ldx #0                  ; colonna
    jsr text_gotoxy
    lda #>si_str_title
    ldx #<si_str_title
    jsr text_print
```

---

## math.asm — Utility

| Routine | Input | Output |
|---|---|---|
| `math_mul8` | A = multiplicando, X = moltiplicatore | `MATH_RESULT` (16 bit) |
| `math_div8` | A = dividendo, X = divisore | A = quoziente, resto in `MATH_REM_L` |
| `math_rand` | — | A = byte pseudo-casuale (xorshift a 8 bit) |
| `math_abs` | A = valore | A = valore assoluto |
| `math_clamp` | A = valore, X = min, Y = max | A = valore limitato |

---

## Regole d'uso dell'engine

1. **Il motore non conosce il gioco**: nessun riferimento a punteggi, sprite,
   suoni o regole specifiche.
2. **Zero page dell'engine**: `$02`-`$1F`. **Zero page del gioco**: `$20`-`$7F`.
3. **Variabili assolute dell'engine**: `$0300`-`$033A`.
4. Un gioco include `engine.asm` **una sola volta**.
5. Ogni routine dell'engine fa **una sola cosa** (KISS) e non chiama il gioco.
