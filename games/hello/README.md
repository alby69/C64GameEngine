# Hello — il gioco più piccolo possibile

Modello di partenza per un nuovo gioco: **30 righe di codice**, nessuno
sprite, solo l'engine video e testo.

```asm
* = $0801
basic_header:
    !byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

* = $0810
    jmp hello_entry

* = $0813
!src "engine.asm"        ; la libreria

* = $1800
!src "hello_config.inc"  ; costanti del gioco

* = $1810
hello_entry:
    sei
    cld
    jsr sid_init          ; motore audio
    jsr vic_init          ; motore video
    jsr text_init         ; cursore di testo

    lda #HELLO_ROW
    ldx #HELLO_COL
    jsr text_gotoxy
    lda #>hello_msg
    ldx #<hello_msg
    jsr text_print
    cli

hello_loop:
    jsr vic_wait_raster   ; un frame
    jmp hello_loop
```

## Compilazione

```bat
scripts\build-game.bat -game hello
```
```bash
./scripts/build-game.sh --game hello
make game GAME=hello
```

Output: `games/hello/hello.prg`

## Da qui a un gioco completo

1. Copia questa cartella: `games/mio-gioco/`
2. Rinomina `hello_main.asm` → `mio_gioco_main.asm` (deve restare l'unico `*_main.asm`)
3. Aggiungi i tuoi moduli (`mio_player.asm`, `mio_hud.asm`, ...)
4. Includili in fondo a `mio_gioco_main.asm` con `!src`
5. Compila: `scripts\build-game.bat -game mio-gioco`

Vedi `docs/getting_started.md` per la guida completa.
