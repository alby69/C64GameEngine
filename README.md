# C64GameEngine

**Libreria in Assembly 6502 per creare giochi per il Commodore 64**, con
refactoring completo di [c64-space-invaders](https://github.com/alby69/c64-space-invaders).

Il progetto contiene due cose:

- **`engine/`** — la libreria riutilizzabile (video, audio, sprite, input, testo, matematica)
- **`games/`** — i giochi che usano la libreria (`space-invaders` è il primo)

più una **web app React** che documenta l'architettura e mostra il codice
reale dei sorgenti, gestita completamente tramite **Docker**
(script di avvio e stop per Windows e Linux).

---

## Indice

- [L'engine](#lengine)
- [Space Invaders](#space-invaders)
- [Compilare e testare il gioco](#compilare-e-testare-il-gioco)
- [Stack tecnologico](#stack-tecnologico)
- [Avvio rapido con Docker](#avvio-rapido-con-docker)
- [Script di gestione](#script-di-gestione)
- [Configurazione](#configurazione)
- [Sviluppo locale senza Docker](#sviluppo-locale-senza-docker)
- [Struttura del progetto](#struttura-del-progetto)
- [Dettagli implementativi](#dettagli-implementativi)

---

## L'engine

Ogni modulo fa **una sola cosa** e non sa nulla del gioco che lo usa.

| Modulo | API | Note |
|---|---|---|
| `engine/c64hw.inc` | — | Costanti hardware pure (VIC-II, SID, CIA 1) |
| `engine/vic_driver.asm` | `vic_init`, `vic_set_border`, `vic_set_bg`, `vic_clear_screen`, `vic_wait_raster`, `vic_set_raster_line` | Driver video |
| `engine/sid_driver.asm` | `sid_init`, `sid_play_note`, `sid_play_sfx`, `sid_set_wave`, `sid_set_adsr`, `sid_stop_voice`, `sid_mute`, `sid_tick` | Driver audio (3 voci) |
| `engine/sprite_mgr.asm` | `sprite_init`, `sprite_alloc`, `sprite_free`, `sprite_move`, `sprite_set_msb`, `sprite_enable`, `sprite_disable`, `sprite_set_color`, `sprite_set_frame` | Gestione sprite hardware |
| `engine/input.asm` | `input_init`, `input_read_joy`, `input_read_kbd`, `input_is_pressed`, `input_key_pressed`, `input_debounce` | Joystick e tastiera |
| `engine/text.asm` | `text_init`, `text_gotoxy`, `text_print`, `text_print_at`, `text_putc`, `text_print_bcd`, `text_print_dec`, `text_clear_area`, `text_set_color` | Rendering PETSCII |
| `engine/math.asm` | `math_mul8`, `math_div8`, `math_rand`, `math_abs`, `math_clamp` | Utility 8/16 bit |

Documentazione: [`docs/api_reference.md`](docs/api_reference.md) ·
[`docs/memory_map.md`](docs/memory_map.md) ·
[`docs/getting_started.md`](docs/getting_started.md)

---

## Space Invaders

Il gioco del repository originale è stato **riscritto** (non copiato) sulle
librerie dell'engine:

| Originale | Nuovo |
|---|---|
| `constants.inc` | `engine/c64hw.inc` + `games/space-invaders/si_config.inc` |
| `vic.asm` | `engine/vic_driver.asm` |
| `sid.asm` | `engine/sid_driver.asm` |
| `sprites.asm` | `engine/sprite_mgr.asm` + `si_sprites.asm` (solo dati) |
| `player.asm` | `engine/input.asm` + `si_player.asm` |
| `hud.asm` | `engine/text.asm` + `si_hud.asm` |
| `main.asm` | `si_main.asm` |

Dettagli e bug corretti: [`games/space-invaders/README.md`](games/space-invaders/README.md)

---

## Provare il gioco

Il gioco è un normale **file `.prg` del Commodore 64**: caricandolo in un
emulatore si avvia con il comando BASIC `10 SYS 2064`.

| File | Descrizione |
|---|---|
| `games/space-invaders/space_invaders.prg` | Il gioco compilato (6850 byte, caricato a `$0801`) |

### 1. Con VICE (l'emulatore di riferimento)

Installa VICE:

```bash
# Debian / Ubuntu
sudo apt install vice
# Fedora
sudo dnf install vice
# Arch
sudo pacman -S vice
# macOS
brew install vice
```

Su Windows scarica l'installer da <https://vice-emu.org/download.html>.

Poi lancia il gioco con lo script, che compila se necessario e apre VICE:

```bat
:: Windows
scripts\run-game.bat
scripts\run-game.bat -game hello
```
```bash
# Linux / macOS
./scripts/run-game.sh
./scripts/run-game.sh --game hello
```

Oppure manualmente:

```bash
x64sc games/space-invaders/space_invaders.prg
```

### 2. Senza installare nulla

Il `.prg` si può aprire con qualsiasi emulatore C64:

- **RetroArch** (core `vice`) — installa il core e avvia il file
- **CCS64**, **Micro64**, **C64 Web** (browser)
- emulatori online come <https://c64online.com> (carica il `.prg`)

In pratica: apri l'emulatore e trascina dentro `space_invaders.prg`.

### 3. Su un Commodore 64 vero

Il `.prg` gira su SD2IEC, Ultimate64, Kung Fu Flash, TheC64, EmuC64:

```basic
LOAD "SPACE_INVADERS.PRG",8,1
RUN
```

### Comandi di gioco

| Comando | Azione |
|---|---|
| Joystick (porta 1 **o** porta 2) sinistra/destra | Muovere il cannone |
| Tasti `A` / `D` | Muovere il cannone (tastiera) |
| Tasto Fuoco (joystick) | Sparare |
| Barra spaziatrice | Sparare **e avviare la partita** |

> Alla schermata iniziale il gioco aspetta: premi **Fuoco** o **SPAZIO** per
> iniziare. In VICE ricorda di cliccare dentro la finestra dell'emulatore
> perché la tastiera va all'emulatore solo se ha il focus.

### Se il gioco non parte

1. **Ricompila il `.prg`**: il file generato non è nel repository (è in
   `.gitignore`), quindi dopo un `git pull` va rigenerato:

   ```bat
   scripts\build-game.bat
   ```

2. **In VICE**: se hai aperto il `.prg` a mano (drag & drop) senza autostart,
   digita `RUN` (oppure `SYS 2064`) al prompt del BASIC. Con lo script
   `scripts\run-game.bat` l'avvio è automatico.

3. **Tastiera**: clicca dentro la finestra di VICE, altrimenti i tasti non
   arrivano all'emulatore.

4. **Joystick**: in VICE il pulsante Fuoco va mappato su "Joystick 1" o
   "Joystick 2" (*Settings → Joystick*); il gioco li legge entrambi.

---

## Compilare e testare il gioco

### Il modo più semplice

Non serve installare nulla: l'assembler **ACME** gira dentro Docker.

```bat
:: Windows
scripts\build-game.bat              REM compila space-invaders
scripts\build-game.bat -game hello  REM compila un altro gioco
scripts\build-game.bat -test        REM compila + lancia i test automatici
```

```bash
# Linux / macOS
./scripts/build-game.sh
./scripts/build-game.sh --game hello
./scripts/build-game.sh --test
```

Il risultato è `games/<gioco>/<gioco>.prg`, pronto per VICE, CCS64,
Micro64 o per un C64 vero.

```bat
:: Con make (Linux/macOS, oppure dentro WSL)
make            REM compila space-invaders
make game GAME=hello
make test       REM compila + verifica
make docker-build
```

### Le quattro strade, dalla più semplice alla più esplicita

| Comando | Cosa fa |
|---|---|
| `scripts\build-game.bat` | Sceglie da solo: ACME se è nel PATH, altrimenti Docker |
| `make game GAME=<nome>` | Compila un gioco specifico con ACME |
| `docker compose --profile build run --rm assembler` | Compila sempre dentro Docker |
| `acme -f cbm -o out.prg -I engine -I games/x games/x/x_main.asm` | Comando ACME diretto |

### Convention

- Il gioco vive in `games/<nome>/`
- Il file principale è **l'unico `*_main.asm`** della cartella (rilevato automaticamente)
- Il `.prg` prende il nome del gioco con i trattini sostituiti da `_`
  (`space-invaders` → `space_invaders.prg`)

### Test automatico

`tools/c64test.py` è un emulatore 6502 incluso nel progetto che esegue il
`.prg` e ne verifica il comportamento (titolo, avvio partita, HUD, sparo,
collisioni, punteggio):

```bash
make test           # oppure scripts\build-game.bat -test
```

---

## Stack tecnologico

| Componente | Versione / Note |
|---|---|
| React | 18.2 (UI) |
| TypeScript | 5.7 (`tsc --noEmit` per il typecheck) |
| Vite | 6.3 (dev server + build) |
| Tailwind CSS | 4.1 (plugin `@tailwindcss/vite`) |
| Nginx | `nginx:alpine` (server statico in produzione) |
| Node.js | 22-alpine (stage di build e dev) |
| ACME | 0.96 (assembler 6502, immagine dedicata) |
| Docker Compose | v2 (profili `dev` e `build`) |

---

## Avvio rapido con Docker

### Prerequisiti

- **Docker Desktop** (Windows / macOS) oppure **Docker Engine + Compose plugin** (Linux)
- Verifica dell'installazione:

```bash
docker --version
docker compose version
```

### Windows (batch)

```bat
:: Avvia lo stack di produzione (nginx) -> http://localhost:3000
scripts\start.bat

:: Avvia lo stack di sviluppo con hot reload -> http://localhost:3001
scripts\start.bat -dev

:: Arresta tutto
scripts\stop.bat
```

Dal root del progetto si possono usare i wrapper `start.bat`, `stop.bat`,
`logs.bat` e `build-game.bat`.

### Windows (PowerShell)

```powershell
# Avvia lo stack di produzione (nginx) -> http://localhost:3000
powershell -ExecutionPolicy Bypass -File .\scripts\start.ps1

# Avvia lo stack di sviluppo con hot reload -> http://localhost:3001
powershell -ExecutionPolicy Bypass -File .\scripts\start.ps1 -Dev

# Arresta tutto
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1
```

In alternativa, dal root del progetto puoi usare i wrapper:
`.\start.ps1` / `.\start.ps1 -Dev` / `.\stop.ps1`.

### Linux / macOS (Bash)

```bash
# Avvia lo stack di produzione (nginx) -> http://localhost:3000
./scripts/start.sh

# Avvia lo stack di sviluppo con hot reload -> http://localhost:3001
./scripts/start.sh --dev

# Arresta tutto
./scripts/stop.sh
```

In alternativa, dal root del progetto: `./start.sh` / `./start.sh --dev` / `./stop.sh`.

> Se `bash` non è eseguibile: `chmod +x scripts/*.sh start.sh stop.sh`

---

## Script di gestione

| Azione | Windows (batch) | Windows (PowerShell) | Linux / macOS |
|---|---|---|---|
| Avvio produzione | `scripts\start.bat` | `scripts\start.ps1` | `scripts/start.sh` |
| Avvio sviluppo | `scripts\start.bat -dev` | `scripts\start.ps1 -Dev` | `scripts/start.sh --dev` |
| Avvio senza rebuild | `scripts\start.bat -nobuild` | `scripts\start.ps1 -NoBuild` | `scripts/start.sh --no-build` |
| Avvio in foreground (log) | `scripts\start.bat -foreground` | `scripts\start.ps1 -Foreground` | `scripts/start.sh --foreground` |
| Arresto completo | `scripts\stop.bat` | `scripts\stop.ps1` | `scripts/stop.sh` |
| Arresto solo dev | `scripts\stop.bat -dev` | `scripts\stop.ps1 -Dev` | `scripts/stop.sh --dev` |
| Arresto + immagini | `scripts\stop.bat -images` | `scripts\stop.ps1 -Images` | `scripts/stop.sh --images` |
| Arresto + volumi | `scripts\stop.bat -volumes` | `scripts\stop.ps1 -Volumes` | `scripts/stop.sh --volumes` |
| Log in tempo reale | `scripts\logs.bat [-dev]` | `scripts\logs.ps1 [-Dev]` | `scripts/logs.sh [--dev]` |
| Compila il gioco | `scripts\build-game.bat` | `scripts\build-game.ps1` | `scripts/build-game.sh` |
| Compila + test | `scripts\build-game.bat -test` | `scripts\build-game.ps1 -Test` | `scripts/build-game.sh --test` |
| Stato dei container | `docker compose ps` | `docker compose ps` | `docker compose ps` |

### Comandi Docker manuali equivalenti

```bash
# Produzione
docker compose up -d --build          # build + avvio
docker compose ps                      # stato
docker compose logs -f app             # log
docker compose down                    # arresto
docker compose down --rmi local        # arresto + rimozione immagini

# Sviluppo (profilo "dev")
docker compose --profile dev up -d --build dev
docker compose --profile dev logs -f dev
```

---

## Configurazione

Copia il file di esempio e adattalo:

```bash
cp .env.example .env      # Linux/macOS
copy .env.example .env    # Windows
```

| Variabile | Default | Descrizione |
|---|---|---|
| `APP_PORT` | `3000` | Porta esposta sulla host per lo stack di produzione |
| `DEV_PORT` | `3001` | Porta esposta sulla host per lo stack di sviluppo |
| `HMR_HOST` | `localhost` | Host usato dal browser per il websocket HMR |
| `ALLOWED_HOSTS` | `true` | Host autorizzati a raggiungere il dev server |
| `DEV_MOUNT` | `.` | Cartella montata nel container di sviluppo |
| `TZ` | `Europe/Rome` | Fuso orario dei container |

> **Nota:** per raggiungere il dev server da un altro dispositivo (telefono,
> altro PC) imposta `HMR_HOST` con l'IP della macchina (es. `192.168.1.20`) e
> `ALLOWED_HOSTS=true`.

---

## Sviluppo locale senza Docker

```bash
npm install
npm run dev        # dev server su http://localhost:3000
npm run build      # build di produzione in dist/
npm run typecheck  # controllo dei tipi
```

---

## Struttura del progetto

```
C64GameEngine/
├── engine/                   # LIBRERIA RIUTILIZZABILE (Assembly 6502)
│   ├── engine.asm            # punto di ingresso: include i moduli
│   ├── c64hw.inc             # costanti hardware C64 + zero page
│   ├── vic_driver.asm        # driver video VIC-II
│   ├── sid_driver.asm        # driver audio SID
│   ├── sprite_mgr.asm        # gestione sprite generica
│   ├── input.asm             # joystick e tastiera
│   ├── text.asm              # renderer PETSCII
│   └── math.asm              # utility matematiche
│
├── games/
│   ├── space-invaders/       # GIOCO DI ESEMPIO (completo)
│   │   ├── si_main.asm       # entry point, game loop, collisioni
│   │   ├── si_config.inc     # costanti e zero page del gioco
│   │   ├── si_player.asm     # logica cannone e proiettile
│   │   ├── si_invaders.asm   # logica sciame e bombe
│   │   ├── si_hud.asm        # HUD, punteggio, vite
│   │   └── si_sprites.asm    # dati grafici degli sprite
│   └── hello/                # GIOCO MINIMALE (modello di partenza)
│       ├── hello_main.asm    # 30 righe: video + testo dell'engine
│       └── hello_config.inc  # costanti del gioco
│
├── tools/
│   └── c64test.py            # emulatore 6502 + test automatici
│
├── docs/
│   ├── api_reference.md      # API della libreria
│   ├── memory_map.md         # mappa della memoria
│   └── getting_started.md    # come creare un nuovo gioco
│
├── docker-compose.yml        # stack produzione (app) + sviluppo (dev) + assembler (build)
├── Dockerfile                # build multi-stage: node build -> nginx
├── Dockerfile.dev            # dev server con hot reload
├── Makefile                  # compilazione e test del gioco
├── .dockerignore             # esclude node_modules, dist, .git, ...
├── .env.example              # configurazione di esempio
├── docker/
│   ├── Dockerfile.acme       # immagine con l'assembler ACME
│   └── nginx/default.conf    # nginx: SPA fallback, gzip, cache, healthcheck
├── scripts/
│   ├── common.sh / common.ps1   # helper condivisi
│   ├── start.sh / .ps1 / .bat   # avvio web app
│   ├── stop.sh  / .ps1 / .bat   # arresto web app
│   ├── logs.sh  / .ps1 / .bat   # log
│   └── build-game.sh / .ps1 / .bat  # compilazione del gioco
├── start.sh / .ps1 / .bat      # wrapper comodi dal root
├── stop.sh  / .ps1 / .bat
├── logs.sh  / .ps1 / .bat
├── build-game.sh / .ps1 / .bat
├── src/
│   ├── App.tsx               # interfaccia: mostra il codice reale dei sorgenti
│   ├── main.tsx              # bootstrap React
│   ├── vite-env.d.ts         # tipi per gli import `?raw`
│   └── index.css             # stili (Tailwind v4)
├── index.html
├── vite.config.js
└── package.json
```

---

## Dettagli implementativi

### Stack di produzione

Multi-stage build: la stage `builder` installa le dipendenze e compila il
frontend con `vite build`, la stage `runtime` copia solo `dist/` dentro
`nginx:alpine` (immagine finale molto leggera).

`docker/nginx/default.conf` gestisce:

- **SPA fallback** (`try_files ... /index.html`) per il routing lato client;
- **compressione gzip** su JS/CSS/JSON/SVG;
- **cache immutabile** (`1y, immutable`) per gli asset con hash, `no-cache` per `index.html`;
- **endpoint `/healthz`** usato dal `HEALTHCHECK` del container.

### Stack di sviluppo

- Servizio `dev` (profilo Compose `dev`) con Vite in ascolto su `0.0.0.0:3000`;
- Il codice sorgente è montato dentro il container → **hot reload immediato**;
- `node_modules` è un volume dedicato: mai condiviso con l'host (i binari
  Windows non girano in Linux);
- `usePolling` attivo: necessario su Docker Desktop (Windows/macOS) dove gli
  eventi di filesystem non vengono propagati al container;
- HMR configurato via variabili d'ambiente in `vite.config.js`
  (`VITE_HMR_HOST`, `VITE_HMR_PORT`, `VITE_ALLOWED_HOSTS`), con valori di
  default identici a quelli locali.

### Healthcheck e riavvio

Entrambi i servizi sono configurati con `restart: unless-stopped` e un
`HEALTHCHECK` dedicato; gli script di avvio attendono che il container
risulti `healthy` prima di restituire il controllo all'utente.

### Stack di compilazione (profilo `build`)

Il servizio `assembler` contiene **ACME 0.96**, il cross assembler usato dal
progetto, compilato dai sorgenti. Non serve installare nulla sull'host:

```bash
docker compose --profile build run --rm assembler
```

L'immagine è costruita da `docker/Dockerfile.acme`; il progetto viene
montato in `/work` e il `.prg` generato torna direttamente nella cartella
del gioco.

### La web app mostra il codice reale

`src/App.tsx` importa i sorgenti Assembly con la sintassi `?raw` di Vite:

```tsx
import textAsm from '../engine/text.asm?raw';
```

Così il codice mostrato nella scheda "Codice Sorgente" è **sempre** quello
che viene effettivamente assemblato: nessuna copia scolpita nel sorgente
dell'app, nessun disallineamento possibile.

### Test automatico del gioco

`tools/c64test.py` è un emulatore 6502 minimale (memoria 64 KB, registri
VIC-II/CIA, istruzioni complete) che esegue il `.prg` e ne verifica il
comportamento. Serve sia come test di regressione sia come strumento per
capire cosa fa il codice a runtime.
