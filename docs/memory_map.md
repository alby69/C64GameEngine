# Mappa della memoria — C64 Game Engine

```
$0000 - $00FF   Pagina Zero
                 $02-$1F   riservata all'ENGINE (temporanei e puntatori)
                 $20-$7F   riservata ai GIOCHI (variabili di gioco)
                 $80-$FF   libera

$0400 - $07E7   Screen RAM (40x25 caratteri, 1000 byte)
$07F8 - $07FF   Puntatori ai dati degli 8 sprite hardware

$0801 - $080C   Stub BASIC "10 SYS 2064"
$0810 - $0812   Trampolino JMP verso il gioco
$0813 - $17FF   Codice dell'ENGINE (la libreria, linkata per prima)
$1800 - $1FFF   Codice del GIOCO

$2000 - $22BF   Dati grafici degli sprite (blocchi da 64 byte, da $2000)

$3000 - $33FF   Espansione RAM del KERNAL (area sicura)
$0300 - $0304   TEXT_CURSOR, TEXT_CPTR, TEXT_COLOR
$0305 - $0305   SPR_ALLOC        (bitmap delle allocazioni sprite)
$0306 - $0315   SPR_XTABLE, SPR_MSB
$0316 - $031D   SPR_FRAME        (blocchi grafici per slot)
$031E - $0322   INPUT_JOY, INPUT_PREV, INPUT_KEY, INPUT_KBDROW, SID_STATE
$0323 - $032A   MATH_RESULT, MATH_RAND
$0326 - $0334   SID_WAVE, SID_AD, SID_SR, SID_FREQ_LO, SID_FREQ_HI
$0335 - $033A   SID_TIMER, SID_KIND, MATH_*, VIC_LINE

$D000 - $D02E   Registri VIC-II
$D400 - $D41C   Registri SID
$D800 - $DBE7   Color RAM
$DC00 - $DC0F   CIA 1 (joystick e matrice tastiera)
```

## Perché questa divisione

| Regola | Motivo |
|---|---|
| L'engine usa **solo** `$02-$1F` e `$0300-$$033A` | Un gioco può usare `$20-$7F` senza conflitti, e due giochi non si pestano i piedi |
| Il gioco **non** scrive mai nei registri hardware | L'unico modo per parlare con l'hardware è l'API dell'engine: il gioco resta portabile |
| I dati sprite stanno in `$2000` | Indirizzo standard del VIC-II: il blocco 0 = `$2000/64` = `$80` |
| Il codice sta sotto `$2000` | Così i dati grafici non vengono sovrascritti dal codice |

## Mappa dei registri usati dall'engine

| Indirizzo | Registro | Uso |
|---|---|---|
| `$D000`-`$D02E` | VIC-II | sprite, raster, colori |
| `$D400`-`$D41C` | SID | le 3 voci, volume, inviluppi |
| `$DC00` | CIA 1 porta A | joystick porta 2 + righe della tastiera |
| `$DC01` | CIA 1 porta B | colonne della tastiera + joystick porta 1 |
| `$DC0E` | CIA 1 CRA | direzione della porta A (input/output) |
| `$DC0F` | CIA 1 CRB | direzione della porta B |

## Uso della zero page dell'engine

| Indirizzo | Simbolo | Ruolo |
|---|---|---|
| `$02`-`$05` | `ZP_TMP`, `ZP_TMP2`, `ZP_TMP3`, `ZP_TMP4` | Temporanei generici |
| `$06` | `ZP_MASK` | Maschera di bit corrente |
| `$07` | `ZP_COUNT` | Contatore |
| `$08` | `ZP_DELAY` | Timer del debounce |
| `$09`-`$0A` | `ZP_TMP_X`, `ZP_TMP_Y` | Temporanei |
| `$0B`-`$0C` | `ZP_TMP_LO`, `ZP_TMP_HI` | Temporanei 8/16 bit |
| `$0D`-`$0E` | `ZP_OFFSET`, `ZP_OFFSET_HI` | Offset a 16 bit |
| `$0F`-`$10` | `ZP_PTR` | Puntatore indiretto 16 bit |
| `$11`-`$12` | `ZP_SRC` | Puntatore sorgente 16 bit |
| `$13`-`$14` | `ZP_DST` | Puntatore destinazione 16 bit |
| `$15`-`$19` | `ZP_KEY`, `ZP_MUL`, `ZP_MUL2`, `ZP_ROW`, `ZP_COL` | Utilità |
| `$1A`-`$1F` | `ZP_RESULT_LO/HI`, `ZP_RAND`, `ZP_ADSR`, `ZP_ARG`, `ZP_ARG2` | Utilità |

## Uso della zero page del gioco (Space Invaders)

| Indirizzo | Simbolo | Ruolo |
|---|---|---|
| `$20`-`$21` | `SI_STATE`, `SI_FRAME` | Stato della macchina a stati, contatore frame |
| `$22`-`$24` | `SI_PLAYER_X`, `SI_LIVES`, `SI_COOLDOWN` | Giocatore |
| `$25`-`$27` | `SI_BULLET_ON`, `SI_BULLET_X/Y` | Proiettile |
| `$28`-`$2A` | `SI_BOMB_ON`, `SI_BOMB_X/Y` | Bomba aliena |
| `$2B`-`$32` | `SI_SWARM_*`, `SI_ALIVE`, `SI_ANIM`, `SI_MARCH_NOTE` | Sciame |
| `$33`-`$36` | `SI_SCORE_LO/HI`, `SI_HI_LO/HI` | Punteggio BCD e record |
| `$37`-`$3C` | `SI_SLOT_PLAYER/BULLET/BOMB/SWARM1..3` | Slot sprite allocati |
| `$3D`-`$3F` | `SI_DIR`, `SI_TMP_X`, `SI_TMP_Y` | Temporanei del gioco |
