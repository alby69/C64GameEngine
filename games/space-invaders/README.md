# Space Invaders — gioco di esempio del C64 Game Engine

Versione **rifatta** del gioco del repository
[alby69/c64-space-invaders](https://github.com/alby69/c64-space-invaders),
portata sulle librerie dell'engine.

---

## Com'è organized

| File | Ruolo |
|---|---|
| `si_main.asm` | Stub BASIC, trampolino, game loop, macchina a stati, collisioni |
| `si_config.inc` | Costanti e zero page **del gioco** (niente hardware) |
| `si_player.asm` | Cannone, movimento, fuoco, proiettile, vite |
| `si_invaders.asm` | Sciame, animazione, marcia a 4 note, bombe |
| `si_hud.asm` | Etichette, punteggio BCD, vite, titolo, game over |
| `si_sprites.asm` | Dati grafici degli sprite (11 sprite da 64 byte in `$2000`) |

Tutto il resto — video, audio, sprite, input, testo, matematica — è
fornito dall'engine in `engine/`.

---

## Compilazione

```bash
# dentro Docker (nessuna installazione richiesta)
make docker-build

# oppure, con ACME nel PATH
make game GAME=space-invaders

# compilazione + test automatico
make test
```

Il risultato è `games/space-invaders/space_invaders.prg`.

Per giocare: aprire il `.prg` con VICE (`x64sc space_invaders.prg`) o
caricarlo su un emulatore/hardware reale.

---

## Comandi

| Comando | Azione |
|---|---|
| Joystick porta 2 / tasti `A` `D` | Muovere il cannone |
| Tasto Fuoco / `SPAZIO` | Sparare |

---

## Il refactoring, file per file

| Originale | Nuovo | Cosa è cambiato |
|---|---|---|
| `constants.inc` | `engine/c64hw.inc` + `si_config.inc` | Hardware puro separato dalle regole; zero page divisa ($02-$1F engine, $20-$3F gioco) |
| `vic.asm` | `engine/vic_driver.asm` | API generica: init, colori, clear screen, sincronizzazione raster configurabile |
| `sid.asm` | `engine/sid_driver.asm` | Le 3 voci diventano risorse: `set_wave`, `set_adsr`, `play_note`, `play_sfx` |
| `sprites.asm` (codice) | `engine/sprite_mgr.asm` | Gestione sprite generica: alloc, free, move, enable, colore, frame |
| `sprites.asm` (dati) | `si_sprites.asm` | Nel gioco restano **solo** le matrici di pixel |
| `player.asm` (input) | `engine/input.asm` | Joystick, tastiera (matrice CIA) e debounce nell'engine |
| `player.asm` (logica) | `si_player.asm` | Nel gioco restano solo le regole del cannone |
| `hud.asm` (rendering) | `engine/text.asm` | Renderer PETSCII generico con cursore |
| `hud.asm` (punteggio) | `si_hud.asm` | Stringhe, score BCD, vite, schermate |
| `main.asm` | `si_main.asm` | Game loop e macchina a stati; l'engine è linkata come libreria |
| — | `engine/math.asm` | Casualità deterministica (xorshift), usata per le bombe |
| — | `tools/c64test.py` | Emulatore 6502 + test automatici del gioco |

---

## Bug corretti rispetto all'originale

Il codice originale **non compilava** con ACME 0.96:

1. **Label locali duplicati** — `.clear_loop` era definito in `vic.asm`,
   `sid.asm` e `hud.asm`: ACME li condivide fra tutti i file inclusi e
   segnalava `Symbol already defined`. Ora ogni label ha un prefisso univoco.
2. **`constants.inc` incluso 5 volte** — le costanti venivano ridefinite a ogni
   inclusione. Ora `c64hw.inc` include una sola volta e le costanti del gioco
   stanno in `si_config.inc`.
3. **Stringhe in PETSCII** — `!scr "SCORE"` produce i codici PETSCII, non quelli
   schermo: il testo risultava illeggibile. Ora le stringhe sono scritte in
   minuscolo, che ACME converte nei codici schermo corretti.
4. **Overflow nel calcolo `riga * 40`** — il prodotto non entra in 8 bit per le
   righe > 7: l'HUD finiva fuori schermo. Ora il calcolo è a 16 bit.

---

## Verifica automatica

`tools/c64test.py` esegue il `.prg` in un emulatore 6502 minimale e verifica:

1. la schermata del titolo viene scritta correttamente nella Screen RAM;
2. la pressione del tasto Fuoco avvia la partita;
3. l'HUD mostra punteggio e vite;
4. lo sciame si muove;
5. il proiettile viene generato;
6. la collisione con un invasore aumenta il punteggio;
7. 600+ frame di gioco senza opcode illegali.

```bash
$ make test
== 1. titolo ==
   riga 5 : COMMODORE 64 SPACE INVADERS
   riga 12: PRESS FIRE OR SPACE TO START
== 2. avvio partita (FIRE premuto) ==
   stato di gioco: 1 (1 = in gioco)
...
== 8. nessun opcode illegale ==
   istruzioni eseguite: 1135276

RISULTATO: TUTTI I TEST SUPERATI
```
