import { useState } from 'react';

// Sorgenti reali del progetto: vengono importati come testo grezzo
// (Vite `?raw`), cosi' la web app mostra SEMPRE il codice che viene
// effettivamente assemblato, senza copie scolpite nel sorgente.
import c64hw from '../engine/c64hw.inc?raw';
import vicDriver from '../engine/vic_driver.asm?raw';
import sidDriver from '../engine/sid_driver.asm?raw';
import spriteMgr from '../engine/sprite_mgr.asm?raw';
import inputAsm from '../engine/input.asm?raw';
import textAsm from '../engine/text.asm?raw';
import mathAsm from '../engine/math.asm?raw';
import engineAsm from '../engine/engine.asm?raw';
import siConfig from '../games/space-invaders/si_config.inc?raw';
import siMain from '../games/space-invaders/si_main.asm?raw';
import siPlayer from '../games/space-invaders/si_player.asm?raw';
import siInvaders from '../games/space-invaders/si_invaders.asm?raw';
import siHud from '../games/space-invaders/si_hud.asm?raw';

// Types
interface Module {
  name: string;
  original: string;
  refactored: string;
  category: 'engine' | 'game';
  description: string;
  reusable: boolean;
}

// Data
const MODULES: Module[] = [
  {
    name: 'Hardware Constants',
    original: 'constants.inc',
    refactored: 'c64hw.inc',
    category: 'engine',
    description: 'Registri hardware VIC-II, SID, CIA. Separati in costanti hardware pure e variabili di gioco.',
    reusable: true,
  },
  {
    name: 'Video Driver',
    original: 'vic.asm',
    refactored: 'vic_driver.asm',
    category: 'engine',
    description: 'Driver video VIC-II generico: init schermo, colori, sprite pointers, raster sync. Senza logica di gioco.',
    reusable: true,
  },
  {
    name: 'Audio Driver',
    original: 'sid.asm',
    refactored: 'sid_driver.asm',
    category: 'engine',
    description: 'Driver SID generico: init, play note, ADSR envelope, sweep. API astratta per effetti sonori.',
    reusable: true,
  },
  {
    name: 'Sprite Manager',
    original: 'sprites.asm (parte)',
    refactored: 'sprite_mgr.asm',
    category: 'engine',
    description: 'Gestione generica sprite: alloc, free, move, enable/disable, animation flip. Dati sprite separati.',
    reusable: true,
  },
  {
    name: 'Input Handler',
    original: 'player.asm (parte)',
    refactored: 'input.asm',
    category: 'engine',
    description: 'Lettura joystick/tastiera generica. Mappatura configurabile dei pulsanti. Debounce riutilizzabile.',
    reusable: true,
  },
  {
    name: 'Text Renderer',
    original: 'hud.asm (parte)',
    refactored: 'text.asm',
    category: 'engine',
    description: 'Rendering testo PETSCII generico: print string, print number BCD, clear screen area, set color.',
    reusable: true,
  },
  {
    name: 'Game Sprites',
    original: 'sprites.asm (dati)',
    refactored: 'si_sprites.asm',
    category: 'game',
    description: 'Dati bitmap specifici del gioco: cannone, invasori, UFO, proiettili, bombe.',
    reusable: false,
  },
  {
    name: 'Invaders Logic',
    original: 'invaders.asm',
    refactored: 'si_invaders.asm',
    category: 'game',
    description: 'Logica specifica: sciame, movimento zigzag, accelerazione, bombe aliene.',
    reusable: false,
  },
  {
    name: 'Player Logic',
    original: 'player.asm (logica)',
    refactored: 'si_player.asm',
    category: 'game',
    description: 'Logica specifica: movimento cannone, sparo laser, cooldown, bounds del giocatore.',
    reusable: false,
  },
  {
    name: 'Game Loop',
    original: 'main.asm',
    refactored: 'si_main.asm',
    category: 'game',
    description: 'Game loop specifico: stati titolo/gioco/gameover, collisioni, punteggio Space Invaders.',
    reusable: false,
  },
  {
    name: 'Game HUD',
    original: 'hud.asm (logica)',
    refactored: 'si_hud.asm',
    category: 'game',
    description: 'HUD specifico: score BCD, vite, schermata titolo e game over del gioco.',
    reusable: false,
  },
];

const PHILOSOPHY = [
  {
    principle: 'KISS',
    full: 'Keep It Simple, Stupid',
    unix: 'Do one thing and do it well',
    application: 'Ogni modulo assembly fa UNA sola cosa. Il driver VIC-II gestisce solo il video, il SID solo l\'audio.',
    icon: '🎯',
  },
  {
    principle: 'DRY',
    full: 'Don\'t Repeat Yourself',
    unix: 'Write a big program only when it is no longer possible to write a small one',
    application: 'Il codice di gestione sprite è scritto UNA volta nel sprite_mgr.asm. Ogni gioco lo riutilizza.',
    icon: '🔄',
  },
  {
    principle: 'Separation',
    full: 'Separation of Concerns',
    unix: 'Everything is a file / Pipes and filters',
    application: 'Engine (libreria) e Gioco (applicazione) sono separati. L\'engine non conosce il gioco specifico.',
    icon: '🧩',
  },
  {
    principle: 'Modularity',
    full: 'Modular Design',
    unix: 'Rule of Composition: Design programs to be connected to other programs',
    application: 'I moduli sono collegabili tramite !src. Ogni file è indipendente e testabile singolarmente.',
    icon: '📦',
  },
];

function App() {
  const [activeTab, setActiveTab] = useState<'overview' | 'architecture' | 'modules' | 'code' | 'philosophy'>('overview');

  return (
    <div className="min-h-screen scanline">
      {/* Header */}
      <header className="border-b border-[#3c347e] bg-[#0d0d1a]/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-[#3c347e] to-[#6c5eb2] rounded-lg flex items-center justify-center text-white font-bold text-lg">
              C64
            </div>
            <div>
              <h1 className="text-xl font-bold text-[#8be9fd]">C64 Game Engine</h1>
              <p className="text-xs text-gray-400">Libreria Assembly 6502 per Giochi • KISS + DRY</p>
            </div>
          </div>
          <nav className="hidden md:flex gap-1">
            {(['overview', 'philosophy', 'architecture', 'modules', 'code'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-t-lg text-sm font-medium transition-all ${
                  activeTab === tab
                    ? 'tab-active text-[#8be9fd]'
                    : 'text-gray-400 hover:text-white hover:bg-[#1e1e3f]'
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
              </button>
            ))}
          </nav>
        </div>
        {/* Mobile nav */}
        <div className="md:hidden flex overflow-x-auto px-4 pb-2 gap-1">
          {(['overview', 'philosophy', 'architecture', 'modules', 'code'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-3 py-1.5 rounded text-xs font-medium whitespace-nowrap transition-all ${
                activeTab === tab
                  ? 'bg-[#3c347e] text-[#8be9fd]'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        {activeTab === 'overview' && <OverviewSection />}
        {activeTab === 'philosophy' && <PhilosophySection />}
        {activeTab === 'architecture' && <ArchitectureSection />}
        {activeTab === 'modules' && <ModulesSection />}
        {activeTab === 'code' && <CodeSection />}
      </main>

      {/* Footer */}
      <footer className="border-t border-[#3c347e] bg-[#0d0d1a]/80 py-6 mt-12">
        <div className="max-w-7xl mx-auto px-4 text-center text-sm text-gray-500">
          <p>C64 Game Engine — Refactoring di <a href="https://github.com/alby69/c64-space-invaders" className="text-[#6c5eb2] hover:text-[#8be9fd]">c64-space-invaders</a></p>
          <p className="mt-1">Filosofia UNIX: KISS • DRY • Modularità • Separazione dei Concerni</p>
        </div>
      </footer>
    </div>
  );
}

function OverviewSection() {
  return (
    <div className="space-y-8">
      {/* Hero */}
      <div className="text-center py-12">
        <h2 className="text-4xl md:text-5xl font-bold mb-4">
          <span className="text-[#8be9fd]">C64 Game Engine</span>
        </h2>
        <p className="text-xl text-gray-300 max-w-3xl mx-auto mb-6">
          Una libreria di sviluppo in <span className="text-[#50fa7b]">Assembly 6502</span> per creare 
          giochi sul Commodore 64, seguendo i principi <span className="text-[#f1fa8c]">KISS</span> e{' '}
          <span className="text-[#f1fa8c]">DRY</span> della filosofia UNIX.
        </p>
        <p className="text-gray-400 max-w-2xl mx-auto">
          Il progetto originale <code className="text-[#bd93f9]">c64-space-invaders</code> è stato 
          refattorizzato separando l'<strong className="text-[#8be9fd]">engine riutilizzabile</strong> dalla{' '}
          <strong className="text-[#ffb86c]">logica di gioco specifica</strong>.
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard label="Moduli Engine" value="6" color="#50fa7b" />
        <StatCard label="Moduli Gioco" value="5" color="#ffb86c" />
        <StatCard label="Registri HW" value="40+" color="#8be9fd" />
        <StatCard label="Riusabilità" value="55%" color="#bd93f9" />
      </div>

      {/* Before/After */}
      <div className="grid md:grid-cols-2 gap-6">
        <div className="module-card p-6">
          <h3 className="text-lg font-bold text-[#ff5555] mb-4 flex items-center gap-2">
            <span>❌</span> Prima: Codice Accoppiato
          </h3>
          <ul className="space-y-2 text-sm text-gray-300">
            <li className="flex items-start gap-2">
              <span className="text-[#ff5555]">•</span>
              <span><code className="text-[#bd93f9]">constants.inc</code> mescola costanti HW e variabili di gioco</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#ff5555]">•</span>
              <span><code className="text-[#bd93f9]">player.asm</code> contiene sia input che logica di gioco</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#ff5555]">•</span>
              <span><code className="text-[#bd93f9]">sprites.asm</code> mescola dati e gestione sprite</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#ff5555]">•</span>
              <span><code className="text-[#bd93f9]">hud.asm</code> mescola rendering testo e logica punteggio</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#ff5555]">•</span>
              <span>Nessuna API astratta: ogni gioco deve reinventare tutto</span>
            </li>
          </ul>
        </div>

        <div className="module-card p-6">
          <h3 className="text-lg font-bold text-[#50fa7b] mb-4 flex items-center gap-2">
            <span>✅</span> Dopo: Engine + Gioco Separati
          </h3>
          <ul className="space-y-2 text-sm text-gray-300">
            <li className="flex items-start gap-2">
              <span className="text-[#50fa7b]">•</span>
              <span><code className="text-[#50fa7b]">c64hw.inc</code>: solo costanti hardware C64</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#50fa7b]">•</span>
              <span><code className="text-[#50fa7b]">input.asm</code>: solo lettura joystick/tastiera</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#50fa7b]">•</span>
              <span><code className="text-[#50fa7b]">sprite_mgr.asm</code>: API generica per sprite</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#50fa7b]">•</span>
              <span><code className="text-[#50fa7b]">text.asm</code>: rendering testo universale</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#50fa7b]">•</span>
              <span>API chiara: il gioco chiama funzioni dell'engine</span>
            </li>
          </ul>
        </div>
      </div>

      {/* Quick diagram */}
      <div className="module-card p-6">
        <h3 className="text-lg font-bold text-[#8be9fd] mb-4 text-center">Flusso del Refactoring</h3>
        <div className="flex flex-col md:flex-row items-center justify-center gap-4 text-sm">
          <div className="bg-[#1a1a2e] border border-[#ff5555]/30 rounded-lg p-4 text-center">
            <p className="text-[#ff5555] font-bold">c64-space-invaders</p>
            <p className="text-gray-400 text-xs mt-1">Codice monolitico</p>
          </div>
          <div className="text-2xl text-[#8be9fd]">→</div>
          <div className="bg-[#1a1a2e] border border-[#f1fa8c]/30 rounded-lg p-4 text-center">
            <p className="text-[#f1fa8c] font-bold">Analisi & Separazione</p>
            <p className="text-gray-400 text-xs mt-1">KISS + DRY</p>
          </div>
          <div className="text-2xl text-[#8be9fd]">→</div>
          <div className="flex flex-col gap-2">
            <div className="bg-[#1a1a2e] border border-[#50fa7b]/30 rounded-lg p-3 text-center">
              <p className="text-[#50fa7b] font-bold text-xs">C64 Game Engine</p>
              <p className="text-gray-400 text-xs">Riutilizzabile</p>
            </div>
            <div className="bg-[#1a1a2e] border border-[#ffb86c]/30 rounded-lg p-3 text-center">
              <p className="text-[#ffb86c] font-bold text-xs">Space Invaders Game</p>
              <p className="text-gray-400 text-xs">Logica specifica</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function PhilosophySection() {
  return (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-3xl font-bold text-[#8be9fd] mb-2">Filosofia UNIX applicata al C64</h2>
        <p className="text-gray-400 max-w-2xl mx-auto">
          I principi fondamentali di UNIX (KISS, DRY, Separazione dei Concerns, Modularità) 
          applicati allo sviluppo di giochi in Assembly 6502 per il Commodore 64.
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        {PHILOSOPHY.map((p) => (
          <div key={p.principle} className="module-card p-6">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-3xl">{p.icon}</span>
              <div>
                <h3 className="text-xl font-bold text-[#50fa7b]">{p.principle}</h3>
                <p className="text-xs text-gray-400 italic">{p.full}</p>
              </div>
            </div>
            <div className="bg-[#0d1117] rounded-lg p-3 mb-3 border-l-2 border-[#bd93f9]">
              <p className="text-xs text-[#bd93f9] italic">"{p.unix}"</p>
              <p className="text-xs text-gray-500 mt-1">— Filosofia UNIX</p>
            </div>
            <p className="text-sm text-gray-300">{p.application}</p>
          </div>
        ))}
      </div>

      {/* Unix Rules applied */}
      <div className="module-card p-6">
        <h3 className="text-xl font-bold text-[#f1fa8c] mb-4">📜 Regole UNIX di Rob Pike applicate</h3>
        <div className="grid md:grid-cols-2 gap-4">
          {[
            { rule: 'Rule of Modularity', desc: 'Scrivi moduli piccoli che fanno una cosa sola. sid_driver.asm fa solo audio, vic_driver.asm fa solo video.' },
            { rule: 'Rule of Clarity', desc: 'Il codice assembly è già difficile da leggere. Nomi chiari come sprite_alloc, vic_init aiutano.' },
            { rule: 'Rule of Composition', desc: 'Progetta moduli collegabili. Il gioco include l\'engine con !src e chiama le sue API.' },
            { rule: 'Rule of Separation', desc: 'Separa engine da gioco, dati da logica, hardware da astrazione.' },
            { rule: 'Rule of Simplicity', desc: 'Design semplice prima. Un driver video generico prima di ottimizzazioni specifiche.' },
            { rule: 'Rule of Parsimony', desc: 'Evita sprite grandi quando bastano piccoli. Risparmia RAM per il gioco.' },
          ].map((r) => (
            <div key={r.rule} className="bg-[#0d1117] rounded-lg p-3">
              <p className="text-sm font-bold text-[#8be9fd]">{r.rule}</p>
              <p className="text-xs text-gray-400 mt-1">{r.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ArchitectureSection() {
  return (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-3xl font-bold text-[#8be9fd] mb-2">Architettura del Progetto</h2>
        <p className="text-gray-400">Struttura a due livelli: Engine (libreria) + Game (applicazione)</p>
      </div>

      {/* Directory Tree */}
      <div className="grid md:grid-cols-2 gap-6">
        <div className="module-card p-6">
          <h3 className="text-lg font-bold text-[#50fa7b] mb-4">📁 Struttura Reale</h3>
          <div className="code-block p-4 text-xs">
            <pre className="text-[#50fa7b]">
{`c64-game-engine/
├── engine/                    # LIBRERIA RIUTILIZZABILE
│   ├── engine.asm            # Punto di ingresso: include i moduli
│   ├── c64hw.inc             # Costanti hardware C64 + zero page
│   ├── vic_driver.asm        # Driver video VIC-II
│   ├── sid_driver.asm        # Driver audio SID
│   ├── sprite_mgr.asm        # Gestione sprite generica
│   ├── input.asm             # Input handler (joystick/kbd)
│   ├── text.asm              # Text renderer PETSCII
│   └── math.asm              # Utility matematiche
│
├── games/
│   └── space-invaders/       # GIOCO DI ESEMPIO
│       ├── si_main.asm       # Game loop + macchina a stati
│       ├── si_player.asm     # Logica giocatore e proiettile
│       ├── si_invaders.asm   # Logica sciame e bombe
│       ├── si_hud.asm        # HUD specifico (score, vite)
│       ├── si_sprites.asm    # Dati sprite del gioco
│       └── si_config.inc     # Config. specifica gioco
│
├── tools/
│   └── c64test.py            # Emulatore 6502 + test automatici
│
├── docker/
│   ├── Dockerfile.acme        # Immagine con l'assembler ACME
│   └── nginx/default.conf    # Server statico di produzione
│
└── docs/
    ├── api_reference.md      # API della libreria
    ├── memory_map.md         # Mappa memoria
    └── getting_started.md    # Guida rapida`}
            </pre>
          </div>
        </div>

        <div className="module-card p-6">
          <h3 className="text-lg font-bold text-[#ffb86c] mb-4">📁 Struttura Originale</h3>
          <div className="code-block p-4 text-xs">
            <pre className="text-[#ffb86c]">
{`c64-space-invaders/
└── src/c64/source/
    ├── constants.inc    # ⚠️ HW + variabili gioco
    ├── main.asm         # ⚠️ Loop + collisioni + init
    ├── vic.asm          # ✅ Driver video
    ├── sid.asm          # ✅ Driver audio
    ├── sprites.asm      # ⚠️ Dati + gestione misti
    ├── player.asm       # ⚠️ Input + logica gioco
    ├── invaders.asm     # ✅ Logica gioco specifica
    ├── hud.asm          # ⚠️ Rendering + logica score
    ├── Makefile
    ├── build.bat
    └── build.sh`}
            </pre>
          </div>
          <div className="mt-4 space-y-2 text-xs">
            <p className="text-[#50fa7b]">✅ = Già ben separato</p>
            <p className="text-[#ff5555]">⚠️ = Necessita refactoring</p>
          </div>
        </div>
      </div>

      {/* Refactoring del gioco */}
      <div className="module-card p-6">
        <h3 className="text-lg font-bold text-[#ffb86c] mb-4">🎮 Refactoring di Space Invaders</h3>
        <p className="text-xs text-gray-400 mb-4">
          Il gioco del repository <code className="text-[#bd93f9]">alby69/c64-space-invaders</code> è stato
          migrato nel progetto riscritto: ogni file originale è stato spezzato fra l'engine (riutilizzabile)
          e il gioco (logica specifica). Nessun file è stato copiato: è stato riscritto.
        </p>
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-[#3c347e]">
                <th className="text-left py-2 px-3 text-[#8be9fd]">Originale</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Destinazione</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Cosa è cambiato</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">constants.inc</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/c64hw.inc</code><br /><code className="text-[#ffb86c] font-mono">si_config.inc</code></td>
                <td className="py-2 px-3">Hardware puro separato dalle regole del gioco; zero page divisa ($02-$1F engine, $20-$3F gioco)</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">vic.asm</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/vic_driver.asm</code></td>
                <td className="py-2 px-3">API generica: init, colori, clear screen, sincronizzazione raster configurabile</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">sid.asm</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/sid_driver.asm</code></td>
                <td className="py-2 px-3">Le 3 voci diventano risorse: set_wave, set_adsr, play_note, play_sfx</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">sprites.asm</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/sprite_mgr.asm</code><br /><code className="text-[#ffb86c] font-mono">si_sprites.asm</code></td>
                <td className="py-2 px-3">Il codice di gestione diventa API generica; nel gioco restano solo i dati grafici</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">player.asm</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/input.asm</code><br /><code className="text-[#ffb86c] font-mono">si_player.asm</code></td>
                <td className="py-2 px-3">Lettura joystick/tastiera e debounce nell'engine; nel gioco solo le regole del cannone</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">hud.asm</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/text.asm</code><br /><code className="text-[#ffb86c] font-mono">si_hud.asm</code></td>
                <td className="py-2 px-3">Il rendering PETSCII diventa modulo riutilizzabile; nel gioco restano stringhe e punteggio</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#ff5555] font-mono">main.asm</td>
                <td className="py-2 px-3"><code className="text-[#ffb86c] font-mono">si_main.asm</code></td>
                <td className="py-2 px-3">Entry point, macchina a stati e collisioni; l'engine è linkata come libreria</td>
              </tr>
              <tr>
                <td className="py-2 px-3 text-[#50fa7b] font-mono">—</td>
                <td className="py-2 px-3"><code className="text-[#50fa7b] font-mono">engine/math.asm</code><br /><code className="text-[#50fa7b] font-mono">tools/c64test.py</code></td>
                <td className="py-2 px-3">Nuovi: casualita' deterministica e test automatico con emulatore 6502</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="grid md:grid-cols-2 gap-4 mt-6">
          <div className="code-block p-4 text-xs">
            <p className="text-[#50fa7b] font-bold mb-2">Compilazione (ACME)</p>
            <pre className="text-gray-300">{`acme -f cbm -o games/space-invaders/space_invaders.prg \\
     -I engine -I games/space-invaders \\
     games/space-invaders/si_main.asm`}</pre>
          </div>
          <div className="code-block p-4 text-xs">
            <p className="text-[#ffb86c] font-bold mb-2">Compilazione e test (Docker)</p>
            <pre className="text-gray-300">{`make docker-build   # assembla dentro Docker
make docker-test    # + emulatore 6502 di test`}</pre>
          </div>
        </div>
      </div>

      {/* Memory Map */}
      <div className="module-card p-6">
        <h3 className="text-lg font-bold text-[#8be9fd] mb-4">🗺️ Mappa Memoria Proposta</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-[#3c347e]">
                <th className="text-left py-2 px-3 text-[#8be9fd]">Indirizzo</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Utilizzo Engine</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Utilizzo Gioco</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$02-$1F</td>
                <td className="py-2 px-3">Zero Page Engine (sprite, input, text)</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$20-$7F</td>
                <td className="py-2 px-3">—</td>
                <td className="py-2 px-3">Zero Page Gioco (stato, score, nemici)</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$0400-$07E7</td>
                <td className="py-2 px-3">Screen RAM (text.asm)</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$07F8-$07FF</td>
                <td className="py-2 px-3">Sprite Pointers (sprite_mgr.asm)</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$0801-$080F</td>
                <td className="py-2 px-3">BASIC Stub</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$0810-$1FFF</td>
                <td className="py-2 px-3">Codice Engine</td>
                <td className="py-2 px-3">Codice Gioco</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$2000-$3FFF</td>
                <td className="py-2 px-3">—</td>
                <td className="py-2 px-3">Dati Sprite del gioco</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$D000-$D02E</td>
                <td className="py-2 px-3">VIC-II Registers</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#bd93f9]">$D400-$D41C</td>
                <td className="py-2 px-3">SID Registers</td>
                <td className="py-2 px-3">—</td>
              </tr>
              <tr>
                <td className="py-2 px-3 text-[#bd93f9]">$DC00-$DC0F</td>
                <td className="py-2 px-3">CIA 1 (input.asm)</td>
                <td className="py-2 px-3">—</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function ModulesSection() {
  return (
    <div className="space-y-8">
      <div className="text-center mb-8">
        <h2 className="text-3xl font-bold text-[#8be9fd] mb-2">Moduli del Progetto</h2>
        <p className="text-gray-400">Dettaglio di ogni modulo: originale → refattorizzato</p>
      </div>

      {/* Engine Modules */}
      <div>
        <h3 className="text-xl font-bold text-[#50fa7b] mb-4 flex items-center gap-2">
          <span className="w-3 h-3 bg-[#50fa7b] rounded-full"></span>
          Engine Modules (Riutilizzabili)
        </h3>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {MODULES.filter(m => m.category === 'engine').map((m) => (
            <div key={m.name} className="module-card p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-bold text-[#50fa7b] text-sm">{m.name}</h4>
                <span className="text-xs bg-[#50fa7b]/10 text-[#50fa7b] px-2 py-0.5 rounded">ENGINE</span>
              </div>
              <div className="flex items-center gap-2 text-xs mb-2">
                <code className="text-[#ff5555] line-through">{m.original}</code>
                <span className="text-gray-500">→</span>
                <code className="text-[#50fa7b] font-bold">{m.refactored}</code>
              </div>
              <p className="text-xs text-gray-400">{m.description}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Game Modules */}
      <div>
        <h3 className="text-xl font-bold text-[#ffb86c] mb-4 flex items-center gap-2">
          <span className="w-3 h-3 bg-[#ffb86c] rounded-full"></span>
          Game Modules (Specifici Space Invaders)
        </h3>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {MODULES.filter(m => m.category === 'game').map((m) => (
            <div key={m.name} className="module-card p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-bold text-[#ffb86c] text-sm">{m.name}</h4>
                <span className="text-xs bg-[#ffb86c]/10 text-[#ffb86c] px-2 py-0.5 rounded">GAME</span>
              </div>
              <div className="flex items-center gap-2 text-xs mb-2">
                <code className="text-[#bd93f9]">{m.original}</code>
                <span className="text-gray-500">→</span>
                <code className="text-[#ffb86c] font-bold">{m.refactored}</code>
              </div>
              <p className="text-xs text-gray-400">{m.description}</p>
            </div>
          ))}
        </div>
      </div>

      {/* API Table */}
      <div className="module-card p-6">
        <h3 className="text-lg font-bold text-[#8be9fd] mb-4">📋 API della Libreria (Engine)</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-[#3c347e]">
                <th className="text-left py-2 px-3 text-[#8be9fd]">Modulo</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Funzioni Esportate</th>
                <th className="text-left py-2 px-3 text-[#8be9fd]">Descrizione</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">vic_driver.asm</td>
                <td className="py-2 px-3 font-mono">vic_init, vic_set_border, vic_set_bg, vic_clear_screen, vic_wait_raster, vic_set_raster_line, vic_get_raster</td>
                <td className="py-2 px-3">Controllo video e sincronizzazione</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">sid_driver.asm</td>
                <td className="py-2 px-3 font-mono">sid_init, sid_play_note, sid_play_sfx, sid_set_wave, sid_set_adsr, sid_stop_voice, sid_set_volume, sid_mute, sid_tick</td>
                <td className="py-2 px-3">Sintesi audio e effetti sonori</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">sprite_mgr.asm</td>
                <td className="py-2 px-3 font-mono">sprite_init, sprite_alloc, sprite_free, sprite_move, sprite_set_msb, sprite_enable, sprite_disable, sprite_set_color, sprite_set_frame, sprite_hide_all</td>
                <td className="py-2 px-3">Gestione completa sprite hardware</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">input.asm</td>
                <td className="py-2 px-3 font-mono">input_init, input_read_joy, input_read_kbd, input_is_pressed, input_key_pressed, input_debounce</td>
                <td className="py-2 px-3">Input da joystick e tastiera</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">text.asm</td>
                <td className="py-2 px-3 font-mono">text_init, text_gotoxy, text_print, text_print_at, text_putc, text_print_bcd, text_print_dec, text_print_digit, text_clear_area, text_set_color</td>
                <td className="py-2 px-3">Rendering testo e numeri</td>
              </tr>
              <tr>
                <td className="py-2 px-3 text-[#50fa7b]">math.asm</td>
                <td className="py-2 px-3 font-mono">math_mul8, math_div8, math_rand, math_abs, math_clamp</td>
                <td className="py-2 px-3">Operazioni matematiche 8/16 bit</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function CodeSection() {
  const [selectedFile, setSelectedFile] = useState('engine-c64hw');

  const codeFiles: Record<string, { name: string; lang: string; code: string }> = {
    'engine-c64hw': { name: 'engine/c64hw.inc', lang: 'assembly', code: c64hw },
    'engine-vic': { name: 'engine/vic_driver.asm', lang: 'assembly', code: vicDriver },
    'engine-sid': { name: 'engine/sid_driver.asm', lang: 'assembly', code: sidDriver },
    'engine-sprite': { name: 'engine/sprite_mgr.asm', lang: 'assembly', code: spriteMgr },
    'engine-input': { name: 'engine/input.asm', lang: 'assembly', code: inputAsm },
    'engine-text': { name: 'engine/text.asm', lang: 'assembly', code: textAsm },
    'engine-math': { name: 'engine/math.asm', lang: 'assembly', code: mathAsm },
    'engine-entry': { name: 'engine/engine.asm', lang: 'assembly', code: engineAsm },
    'game-config': { name: 'games/space-invaders/si_config.inc', lang: 'assembly', code: siConfig },
    'game-main': { name: 'games/space-invaders/si_main.asm', lang: 'assembly', code: siMain },
    'game-player': { name: 'games/space-invaders/si_player.asm', lang: 'assembly', code: siPlayer },
    'game-invaders': { name: 'games/space-invaders/si_invaders.asm', lang: 'assembly', code: siInvaders },
    'game-hud': { name: 'games/space-invaders/si_hud.asm', lang: 'assembly', code: siHud },
  };

  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-3xl font-bold text-[#8be9fd] mb-2">Codice Sorgente</h2>
        <p className="text-gray-400">Il codice reale della libreria e del gioco, letto direttamente dai sorgenti Assembly</p>
      </div>

      {/* File tabs */}
      <div className="flex flex-wrap gap-1">
        {Object.entries(codeFiles).map(([key, file]) => (
          <button
            key={key}
            onClick={() => setSelectedFile(key)}
            className={`px-3 py-1.5 rounded-t text-xs font-mono transition-all ${
              selectedFile === key
                ? 'bg-[#0d1117] text-[#8be9fd] border border-[#30363d] border-b-0'
                : 'text-gray-500 hover:text-gray-300 hover:bg-[#1e1e3f]'
            }`}
          >
            {file.name.split('/').pop()}
          </button>
        ))}
      </div>

      {/* Code display */}
      <div className="code-block p-4 relative">
        <div className="absolute top-2 right-3 text-xs text-gray-600">
          {codeFiles[selectedFile].name}
        </div>
        <pre className="text-xs leading-relaxed overflow-x-auto pt-4">
          <code className="text-gray-300">
            {codeFiles[selectedFile].code.split('\n').map((line, i) => (
              <div key={i} className="flex">
                <span className="text-gray-600 select-none w-8 text-right mr-4 flex-shrink-0">
                  {i + 1}
                </span>
                <span className={getLineColor(line)}>
                  {line || ' '}
                </span>
              </div>
            ))}
          </code>
        </pre>
      </div>

      {/* Explanation */}
      <div className="module-card p-4">
        <h4 className="text-sm font-bold text-[#f1fa8c] mb-2">💡 Note sul codice</h4>
        <p className="text-xs text-gray-400">
          {selectedFile.startsWith('engine') 
            ? 'Questo modulo fa parte dell\'ENGINE ed è completamente riutilizzabile. Non contiene logica di gioco specifica. Ogni nuovo gioco può includere questo file e usare le sue API.'
            : 'Questo modulo è specifico del gioco Space Invaders. Include l\'engine e usa le sue API per gestire sprite, audio, input e testo. La logica del gioco (invasori, punteggio, collisioni) è qui.'}
        </p>
      </div>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="module-card p-4 text-center">
      <div className="text-3xl font-bold" style={{ color }}>{value}</div>
      <div className="text-xs text-gray-400 mt-1">{label}</div>
    </div>
  );
}

function getLineColor(line: string): string {
  if (line.trimStart().startsWith(';')) return 'text-green-600';
  if (line.includes('= $') || line.includes('!byte') || line.includes('!scr')) return 'text-[#bd93f9]';
  if (line.trimStart().startsWith('lda') || line.trimStart().startsWith('sta') || 
      line.trimStart().startsWith('jsr') || line.trimStart().startsWith('rts') ||
      line.trimStart().startsWith('sei') || line.trimStart().startsWith('cli') ||
      line.trimStart().startsWith('ldx') || line.trimStart().startsWith('ldy') ||
      line.trimStart().startsWith('stx') || line.trimStart().startsWith('sty') ||
      line.trimStart().startsWith('jmp') || line.trimStart().startsWith('beq') ||
      line.trimStart().startsWith('bne') || line.trimStart().startsWith('bcc') ||
      line.trimStart().startsWith('bcs') || line.trimStart().startsWith('cpx') ||
      line.trimStart().startsWith('cpy') || line.trimStart().startsWith('cmp') ||
      line.trimStart().startsWith('sec') || line.trimStart().startsWith('clc') ||
      line.trimStart().startsWith('sed') || line.trimStart().startsWith('cld') ||
      line.trimStart().startsWith('inx') || line.trimStart().startsWith('iny') ||
      line.trimStart().startsWith('dex') || line.trimStart().startsWith('dey') ||
      line.trimStart().startsWith('tax') || line.trimStart().startsWith('tay') ||
      line.trimStart().startsWith('txa') || line.trimStart().startsWith('tya') ||
      line.trimStart().startsWith('pha') || line.trimStart().startsWith('pla') ||
      line.trimStart().startsWith('asl') || line.trimStart().startsWith('lsr') ||
      line.trimStart().startsWith('ora') || line.trimStart().startsWith('and') ||
      line.trimStart().startsWith('eor') || line.trimStart().startsWith('adc') ||
      line.trimStart().startsWith('sbc') || line.trimStart().startsWith('bit') ||
      line.trimStart().startsWith('nop') || line.trimStart().startsWith('inc') ||
      line.trimStart().startsWith('dec')) return 'text-[#8be9fd]';
  if (line.includes(':') && !line.trimStart().startsWith(';')) return 'text-[#ffb86c]';
  if (line.includes('* =') || line.includes('!src')) return 'text-[#ff79c6]';
  return 'text-gray-300';
}

export default App;
