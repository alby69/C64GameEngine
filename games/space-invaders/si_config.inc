; =============================================================================
; SPACE INVADERS (C64 GAME ENGINE) - si_config.inc
; =============================================================================
; CONFIGURAZIONE SPECIFICA DEL GIOCO.
;
; Niente di questo file appartiene all'engine: un altro gioco avrebbe un
; proprio file di configurazione con le proprie regole (punteggio, velocita',
; formazione, layout dell'HUD). L'engine non sa cosa sia uno "sciame".
; =============================================================================

; -----------------------------------------------------------------------------
; Stati della macchina a stati finiti
; -----------------------------------------------------------------------------
SI_STATE_TITLE    = 0       ; Schermata del titolo
SI_STATE_PLAYING  = 1       ; Partita in corso
SI_STATE_GAMEOVER = 2       ; Partita persa
SI_STATE_NEXTWAVE = 3       ; Ondata completata: si riparte

; -----------------------------------------------------------------------------
; Giocatore
; -----------------------------------------------------------------------------
SI_PLAYER_START_X = 160     ; Posizione iniziale al centro dello schermo
SI_PLAYER_Y       = 228     ; Altezza fissa del cannone
SI_PLAYER_MIN_X   = 32      ; Bordo sinistro
SI_PLAYER_MAX_X   = 240     ; Bordo destro
SI_PLAYER_SPEED   = 2       ; Pixel per frame
SI_LIVES_START    = 3       ; Vite iniziali

; -----------------------------------------------------------------------------
; Proiettile del giocatore
; -----------------------------------------------------------------------------
SI_BULLET_SPEED   = 5       ; Pixel per frame verso l'alto
SI_BULLET_TOP_Y   = 42      ; Oltre questa quota il proiettile scompare
SI_BULLET_DX      = 8       ; Offset orizzontale rispetto al cannone
SI_BULLET_DY      = 6       ; Offset verticale rispetto al cannone
SI_FIRE_DELAY     = 8       ; Frame di attesa fra due colpi

; -----------------------------------------------------------------------------
; Sciame degli invasori
; -----------------------------------------------------------------------------
SI_SWARM_START_X  = 40
SI_SWARM_START_Y  = 70
SI_SWARM_MIN_X    = 32
SI_SWARM_MAX_X    = 230
SI_SWARM_STEP     = 4       ; Pixel per passo
SI_SWARM_DROP     = 8       ; Pixel di discesa a ogni inversione
SI_SWARM_COUNT    = 24      ; Alieni totali (3 righe da 8)
SI_SWARM_HEIGHT   = 64      ; Altezza della formazione (hitbox)
SI_SWARM_WIDTH    = 72      ; Larghezza della formazione (hitbox)
SI_SWARM_ROW2_DX  = 24      ; Scostamento X della seconda riga
SI_SWARM_ROW2_DY  = 22      ; Scostamento Y della seconda riga
SI_SWARM_ROW3_DX  = 48      ; Scostamento X della terza riga
SI_SWARM_ROW3_DY  = 44      ; Scostamento Y della terza riga
SI_SWARM_BOTTOM_Y = 190     ; Raggiunta questa quota gli alieni hanno vinto

; -----------------------------------------------------------------------------
; Bombe aliene
; -----------------------------------------------------------------------------
SI_BOMB_SPEED     = 2
SI_BOMB_BOTTOM_Y  = 245     ; Sotto questa quota la bomba esce dallo schermo
SI_BOMB_DX        = 24      ; Offset X rispetto allo sciame
SI_BOMB_DY        = 50      ; Offset Y rispetto allo sciame
SI_BOMB_HIT_TOP   = 220     ; Il giocatore e' centrato a 228
SI_BOMB_HIT_BOT   = 236
SI_BOMB_HALF      = 12      ; Meta' larghezza della hitbox del cannone
SI_BOMB_FULL      = 24      ; Larghezza completa della hitbox

; -----------------------------------------------------------------------------
; Punteggio (formato BCD)
; -----------------------------------------------------------------------------
SI_SCORE_HIT      = $20     ; 20 punti per un invasore colpito
SI_SCORE_ROW1     = $30     ; 30 punti per la prima riga
SI_SCORE_ROW2     = $20     ; 20 punti per la seconda riga
SI_SCORE_ROW3     = $10     ; 10 punti per la terza riga

; -----------------------------------------------------------------------------
; Blocchi grafici (indirizzo dei dati / 64)
; -----------------------------------------------------------------------------
SI_BLOCK_PLAYER    = $80
SI_BLOCK_INV1_A    = $81
SI_BLOCK_INV1_B    = $82
SI_BLOCK_INV2_A    = $83
SI_BLOCK_INV2_B    = $84
SI_BLOCK_INV3_A    = $85
SI_BLOCK_INV3_B    = $86
SI_BLOCK_UFO       = $87
SI_BLOCK_EXPLOSION = $88
SI_BLOCK_BULLET    = $89
SI_BLOCK_BOMB      = $8A

; -----------------------------------------------------------------------------
; Colori degli sprite
; -----------------------------------------------------------------------------
SI_COLOR_PLAYER = COLOR_LIGHTGREEN
SI_COLOR_INV1   = COLOR_CYAN
SI_COLOR_INV2   = COLOR_YELLOW
SI_COLOR_INV3   = COLOR_LIGHTRED
SI_COLOR_BULLET = COLOR_WHITE
SI_COLOR_BOMB   = COLOR_CYAN

; -----------------------------------------------------------------------------
; Layout dell'HUD (riga, colonna)
; -----------------------------------------------------------------------------
SI_HUD_ROW_SCORE = 1
SI_HUD_COL_SCORE = 2
SI_HUD_ROW_LIVES = 24
SI_HUD_COL_LIVES = 9
SI_HUD_ROW_TITLE = 5
SI_HUD_ROW_PRESS = 12
SI_HUD_ROW_OVER  = 12

; -----------------------------------------------------------------------------
; ZERO PAGE DEL GIOCO ($20 - $7F)
; L'engine usa solo $02-$1F: qui il gioco ha il monopolio del resto.
; -----------------------------------------------------------------------------
SI_STATE       = $20        ; Stato della macchina a stati finiti
SI_FRAME       = $21        ; Contatore di frame
SI_PLAYER_X    = $22        ; Posizione X del cannone
SI_LIVES       = $23        ; Vite rimaste
SI_COOLDOWN    = $24        ; Attesa fra due colpi
SI_BULLET_ON   = $25        ; 1 = proiettile attivo
SI_BULLET_X    = $26
SI_BULLET_Y    = $27
SI_BOMB_ON     = $28        ; 1 = bomba aliena attiva
SI_BOMB_X      = $29
SI_BOMB_Y      = $2A
SI_SWARM_X     = $2B        ; Riferimento X dello sciame
SI_SWARM_Y     = $2C        ; Riferimento Y dello sciame
SI_SWARM_DIR   = $2D        ; 1 = destra, 0 = sinistra
SI_SWARM_TIMER = $2E        ; Timer fra un passo e l'altro
SI_SWARM_SPEED = $2F        ; Velocita' corrente dello sciame
SI_ALIVE       = $30        ; Invasori ancora in vita
SI_ANIM        = $31        ; Frame di animazione 0/1
SI_MARCH_NOTE  = $32        ; Indice della nota della marcia
SI_SCORE_LO    = $33        ; Punteggio BCD, byte basso
SI_SCORE_HI    = $34        ; Punteggio BCD, byte alto
SI_HI_LO       = $35        ; Record, byte basso
SI_HI_HI       = $36        ; Record, byte alto
SI_SLOT_PLAYER = $37        ; Slot sprite del cannone
SI_SLOT_BULLET = $38        ; Slot sprite del proiettile
SI_SLOT_BOMB   = $39        ; Slot sprite della bomba
SI_SLOT_SWARM1 = $3A        ; Slot sprite degli invasori (riga 1)
SI_SLOT_SWARM2 = $3B        ; Slot sprite degli invasori (riga 2)
SI_SLOT_SWARM3 = $3C        ; Slot sprite degli invasori (riga 3)
SI_DIR         = $3D        ; Direzione di movimento richiesta
SI_TMP_X       = $3E        ; Temporaneo del gioco
SI_TMP_Y       = $3F        ; Temporaneo del gioco
