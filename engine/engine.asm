; =============================================================================
; C64 GAME ENGINE - engine.asm
; =============================================================================
; Punto di ingresso unico della libreria.
;
; Un gioco include questo file e ottiene cosi' tutta l'engine:
;
;     !src "../../engine/engine.asm"
;
; REGOLE ASSOLUTE (impellabili)
; 1. Ogni file viene incluso UNA sola volta: ACME non ammette ridefinizioni di
;    simboli ne' label locali omonimi in file diversi.
; 2. I label locali (.nome) sono univoci in tutto il programma: ACME li
;    condivide fra tutti i file inclusi.
; 3. L'engine usa solo la zero page $02-$1F e la memoria $0300-$033F.
;    I giochi possono usare liberamente $20-$7F.
; 4. L'engine non conosce il gioco: nessun riferimento a regole, punteggi,
;    sprite o suoni specifici.
; =============================================================================

!src "c64hw.inc"
!src "vic_driver.asm"
!src "sid_driver.asm"
!src "sprite_mgr.asm"
!src "input.asm"
!src "text.asm"
!src "math.asm"
