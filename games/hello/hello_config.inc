; =============================================================================
; HELLO - configurazione specifica del gioco
; =============================================================================
; Niente di questo file appartiene all'engine: un altro gioco avrebbe un
; proprio file di configurazione con le proprie regole.
; =============================================================================

; Stato del gioco
HELLO_STATE_RUN  = 0       ; In esecuzione
HELLO_STATE_STOP = 1       ; Terminato

; Posizione del testo a schermo
HELLO_ROW        = 10      ; Riga (0-24)
HELLO_COL        = 12      ; Colonna (0-39)

; Zero page del gioco (l'engine usa $02-$1F, qui si parte da $20)
HELLO_STATE      = $20     ; Stato corrente
HELLO_FRAMES     = $21     ; Contatore di frame
