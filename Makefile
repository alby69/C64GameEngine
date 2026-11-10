# =============================================================================
# C64 GAME ENGINE - Makefile
# =============================================================================
# Compila i giochi in Assembly 6502 per il Commodore 64 e ne verifica il
# comportamento con l'emulatore di test incluso nel progetto.
#
#   make                compila il gioco predefinito
#   make game GAME=...  compila un altro gioco (cartella in games/)
#   make test           compila e lancia il test automatico
#   make docker-build   compila il gioco dentro Docker (nessun assembler richiesto)
#   make docker-test    compila e testa il gioco dentro Docker
#   make clean          rimuove i file generati
#
# Richiede l'assembler ACME nel PATH (make docker-build non richiede nulla).
# =============================================================================

GAME        ?= space-invaders
GAME_DIR    := games/$(GAME)
GAME_FILE   := $(subst -,_,$(GAME))
TARGET      := $(GAME_DIR)/$(GAME_FILE).prg
# I simboli stanno accanto al gioco: ogni gioco ha i suoi
SYMBOLS     := $(GAME_DIR)/$(GAME_FILE).symbols
# Convenzione: il file principale e' l'unico "*_main.asm" della cartella
MAIN        := $(notdir $(firstword $(wildcard $(GAME_DIR)/*_main.asm)))

ACME        ?= acme
PYTHON      ?= python3
COMPOSE     ?= docker compose

# Le directory di ricerca di ACME (-I): i moduli dell'engine e quelli del gioco
INCLUDES    := -I engine -I $(GAME_DIR)
ACME_FLAGS  := -f cbm

ENGINE_SRC  := $(wildcard engine/*.asm) $(wildcard engine/*.inc)
GAME_SRC    := $(wildcard $(GAME_DIR)/*.asm) $(wildcard $(GAME_DIR)/*.inc)

.PHONY: all game test docker-build docker-test clean list-games help

all: game

# -----------------------------------------------------------------------------
# Compilazione
# -----------------------------------------------------------------------------
game: $(TARGET)

$(TARGET): $(GAME_DIR)/$(MAIN) $(ENGINE_SRC) $(GAME_SRC)
	@echo "=========================================================="
	@echo " Compilazione di $(GAME) con ACME"
	@echo "=========================================================="
	$(ACME) $(ACME_FLAGS) -o $@ -l $(SYMBOLS) $(INCLUDES) $(GAME_DIR)/$(MAIN)
	@echo " Fatto: $@"

# -----------------------------------------------------------------------------
# Test automatico (emulatore 6502 minimale incluso nel progetto)
# -----------------------------------------------------------------------------
test: $(TARGET)
	@test -f $(SYMBOLS) || $(ACME) $(ACME_FLAGS) -o $(TARGET) -l $(SYMBOLS) $(INCLUDES) $(GAME_DIR)/$(MAIN)
	$(PYTHON) tools/c64test.py $(TARGET) $(SYMBOLS)

# -----------------------------------------------------------------------------
# Stessa cosa dentro Docker: non serve installare ACME sull'host
# -----------------------------------------------------------------------------
docker-build:
	$(COMPOSE) --profile build run --rm -e GAME=$(GAME) -e MAIN=$(MAIN) assembler

docker-test: docker-build
	$(COMPOSE) --profile build run --rm \
		--entrypoint sh c64gameengine-assembler -c \
		"apk add --no-cache python3 >/dev/null && python3 tools/c64test.py $(TARGET) $(SYMBOLS)"

# -----------------------------------------------------------------------------
# Utilita'
# -----------------------------------------------------------------------------
list-games:
	@ls -1 games

clean:
	rm -f games/*/*.prg games/*/*.symbols
	@echo "Pulizia completata."

help:
	@echo "C64 Game Engine - obiettivi disponibili:"
	@echo "  make                 compila games/space-invaders"
	@echo "  make game GAME=x     compila games/x"
	@echo "  make test            compila e verifica con l'emulatore di test"
	@echo "  make docker-build    compila dentro Docker (ACME incluso)"
	@echo "  make docker-test     compila e verifica dentro Docker"
	@echo "  make list-games      elenca i giochi disponibili"
	@echo "  make clean           rimuove i file generati"
