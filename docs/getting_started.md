# Guida rapida — creare un gioco con il C64 Game Engine

Questa guida mostra come scrivere un nuovo gioco per il Commodore 64
riutilizzando l'engine.

---

## 1. Struttura di un gioco

```
games/
└── mio-gioco/
    ├── mi_main.asm       # entry point + game loop + macchina a stati
    ├── mi_config.inc     # costanti e zero page del gioco
    ├── mi_*.asm          # moduli di logica (player, nemici, hud...)
    └── mi_sprites.asm    # dati grafici
```

Nessun file dell'engine viene copiato o modificato: si include.

---

## 2. Lo scheletro del gioco

```asm
; games/mio-gioco/mi_main.asm

* = $0801
basic_header:
    !byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

* = $0810
    jmp mi_entry

* = $0813
!src "engine.asm"           ; la libreria

* = $1800
!src "mi_config.inc"        ; costanti del gioco

* = $1810
mi_entry:
    sei
    cld
    jsr sid_init
    jsr vic_init
    jsr sprite_init
    jsr input_init
    jsr text_init
    jsr mi_init
    cli

mi_main_loop:
    jsr vic_wait_raster      ; un frame
    jsr mi_update
    jmp mi_main_loop

!src "mi_hud.asm"
!src "mi_sprites.asm"       ; i dati grafici vanno per ultimi
```

---

## 3. Le regole d'oro

### Ogni file incluso una sola volta
ACME non ammette ridefinizioni: includere `engine.asm` una volta sola,
all'inizio del file principale.

### I label locali sono globali
`.nome` è univoco in **tutto** il programma: usa prefissi per modulo
(`.vic_…`, `.si_…`, `.mi_…`). Nel codice originale di Space Invaders il
riutilizzo di `.clear_loop` in tre file faceva fallire la compilazione.

### Le costanti si definiscono prima dell'uso
ACME usa l'indirizzamento *zero page* solo se il simbolo è già definito
quando viene usato. Includi `engine.asm` e il file di costanti **prima**
del codice che li usa, se vuoi il codice più veloce.

### Il gioco non tocca l'hardware
Niente `sta VIC_SPR0_X` nel gioco: si usa `sprite_move`.
Niente `sta $DC00`: si usa `input_read_joy`.
Niente `sta SCREEN_RAM`: si usa `text_print`.
L'unica eccezione sono i dati (sprite, stringhe).

---

## 4. Compilazione

```bash
# con ACME installato
acme -f cbm -o games/mio-gioco/mio_gioco.prg \
     -I engine -I games/mio-gioco \
     games/mio-gioco/mi_main.asm

# dentro Docker (nessuna installazione richiesta)
make docker-build
# oppure
docker compose --profile build run --rm assembler
```

Il risultato è un file `.prg` pronto per VICE, CCS64, Micro64 o per vero
hardware (SD2IEC, Ultimate64, Kung Fu Flash).

---

## 5. Verifica automatica

Il progetto include un emulatore 6502 minimale (`tools/c64test.py`) che
esegue il gioco e ne controlla il comportamento:

```bash
make test          # compila e lancia i test
make docker-test   # stesso cosa dentro Docker
```

Il test può essere adattato al proprio gioco modificando `tools/c64test.py`:
controlla lo stato della macchina, l'HUD, il movimento e le collisioni.

---

## 6. Esempio: uno sprite che salta

```asm
mi_player_init:
    jsr sprite_alloc             ; A = slot libero
    sta MI_SLOT_PLAYER
    lda MI_SLOT_PLAYER
    ldx #MI_BLOCK_PLAYER        ; blocco grafico
    jsr sprite_set_frame
    lda MI_SLOT_PLAYER
    ldx #COLOR_LIGHTGREEN
    jsr sprite_set_color
    lda MI_SLOT_PLAYER
    ldx #160
    ldy #228
    jsr sprite_move
    lda MI_SLOT_PLAYER
    jsr sprite_enable
    rts

mi_player_update:
    lda #$01                    ; joystick porta 2
    jsr input_read_joy
    lda #JOY_LEFT
    jsr input_is_pressed
    beq .mi_no_left
    lda MI_PLAYER_X
    sec
    sbc #2
    cmp #32
    bcc .mi_no_left
    sta MI_PLAYER_X
.mi_no_left:
    lda MI_SLOT_PLAYER
    ldx MI_PLAYER_X
    ldy #228
    jsr sprite_move
    rts
```

---

## 7. Checklist del nuovo gioco

- [ ] `games/mio-gioco/mi_config.inc` con le costanti e la zero page del gioco
- [ ] i dati sprite in `$2000` con blocchi da 64 byte
- [ ] `mi_main.asm` con stub BASIC, trampolino, `!src "engine.asm"` e game loop
- [ ] una `jsr vic_wait_raster` per frame
- [ ] l'HUD disegnato con `text_gotoxy` + `text_print`
- [ ] l'input letto con `input_read_joy` / `input_read_kbd`
- [ ] nessun accesso diretto ai registri hardware
- [ ] compilato con `make game GAME=mio-gioco`
- [ ] test automatico in `tools/c64test.py`
