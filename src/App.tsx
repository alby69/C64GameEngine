import { useState } from 'react';

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
          <h3 className="text-lg font-bold text-[#50fa7b] mb-4">📁 Struttura Proposta</h3>
          <div className="code-block p-4 text-xs">
            <pre className="text-[#50fa7b]">
{`c64-game-engine/
├── engine/                    # LIBRERIA RIUTILIZZABILE
│   ├── c64hw.inc             # Costanti hardware C64
│   ├── vic_driver.asm        # Driver video VIC-II
│   ├── sid_driver.asm        # Driver audio SID
│   ├── sprite_mgr.asm        # Gestione sprite generica
│   ├── input.asm             # Input handler (joystick/kbd)
│   ├── text.asm              # Text renderer PETSCII
│   └── math.asm              # Utility matematiche (opz.)
│
├── games/
│   └── space-invaders/       # GIOCO DI ESEMPIO
│       ├── si_main.asm       # Game loop specifico
│       ├── si_player.asm     # Logica giocatore
│       ├── si_invaders.asm   # Logica invasori
│       ├── si_hud.asm        # HUD specifico
│       ├── si_sprites.asm    # Dati sprite del gioco
│       └── si_config.inc     # Config. specifica gioco
│
├── tools/
│   ├── sprite_converter.py   # Convertitore immagini→sprite
│   └── music_tool.py         # Tool composizione SID
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
                <td className="py-2 px-3 font-mono">vic_init, vic_set_border, vic_set_bg, vic_wait_raster, vic_clear_screen</td>
                <td className="py-2 px-3">Controllo video e sincronizzazione</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">sid_driver.asm</td>
                <td className="py-2 px-3 font-mono">sid_init, sid_play_note, sid_play_sfx, sid_set_adsr, sid_mute, sid_tick</td>
                <td className="py-2 px-3">Sintesi audio e effetti sonori</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">sprite_mgr.asm</td>
                <td className="py-2 px-3 font-mono">sprite_init, sprite_alloc, sprite_free, sprite_move, sprite_enable, sprite_set_color, sprite_set_frame</td>
                <td className="py-2 px-3">Gestione completa sprite hardware</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">input.asm</td>
                <td className="py-2 px-3 font-mono">input_init, input_read_joy, input_read_kbd, input_is_pressed, input_set_debounce</td>
                <td className="py-2 px-3">Input da joystick e tastiera</td>
              </tr>
              <tr className="border-b border-[#1e1e3f]">
                <td className="py-2 px-3 text-[#50fa7b]">text.asm</td>
                <td className="py-2 px-3 font-mono">text_init, text_print, text_print_at, text_print_bcd, text_clear_area, text_set_color</td>
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
    'engine-c64hw': {
      name: 'engine/c64hw.inc',
      lang: 'assembly',
      code: `; ==============================================================================
; C64 GAME ENGINE - c64hw.inc
; ==============================================================================
; Costanti hardware PURE del Commodore 64.
; Questo file NON contiene variabili di gioco - solo registri hardware.
; ==============================================================================

; --- VIC-II REGISTRI ($D000 - $D02E) ---
; Posizioni Sprite (X, Y per sprite 0-7)
VIC_SPR0_X      = $D000
VIC_SPR0_Y      = $D001
; ... (tutti gli sprite 0-7)
VIC_SPR_X_MSB   = $D010     ; 9° bit X
VIC_CTRL_1      = $D011     ; Controllo 1
VIC_RASTER      = $D012     ; Linea raster corrente
VIC_SPR_ENA     = $D015     ; Abilitazione sprite
VIC_CTRL_2      = $D016     ; Controllo 2
VIC_SPR_EXP_Y   = $D017     ; Espansione Y
VIC_MEM_SETUP   = $D018     ; Setup memoria video
VIC_IRQ_STATUS  = $D019     ; IRQ status
VIC_SPR_MCOLOR  = $D01C     ; Multicolor mode
VIC_SPR_EXP_X   = $D01D     ; Espansione X

; Colori
VIC_BORDER_COL  = $D020
VIC_BG_COL0     = $D021
VIC_SPR0_COL    = $D027
; ... (sprite 1-7 colors)

; --- SID REGISTRI ($D400 - $D41C) ---
SID_V1_FREQ_LO  = $D400
SID_V1_FREQ_HI  = $D401
SID_V1_PW_LO    = $D402
SID_V1_PW_HI    = $D403
SID_V1_CTRL     = $D404
SID_V1_AD       = $D405
SID_V1_SR       = $D406
; ... (Voice 2, Voice 3)
SID_VOL_CTRL    = $D418

; Forme d'onda SID
SID_WAVE_GATE   = $01
SID_WAVE_TRI    = $10
SID_WAVE_SAW    = $20
SID_WAVE_PULSE  = $40
SID_WAVE_NOISE  = $80

; --- CIA 1 ($DC00 - $DC0F) ---
CIA1_PORT_A     = $DC00
CIA1_PORT_B     = $DC01
JOY_UP          = $01
JOY_DOWN        = $02
JOY_LEFT        = $04
JOY_RIGHT       = $08
JOY_FIRE        = $10

; --- INDIRIZZI MEMORIA ---
SCREEN_RAM      = $0400
COLOR_RAM       = $D800
SPRITE_PTR_BASE = $07F8
SPRITE_MEM_BASE = $2000

; --- COLORI C64 ---
COLOR_BLACK     = 0
COLOR_WHITE     = 1
COLOR_RED       = 2
COLOR_CYAN      = 3
COLOR_PURPLE    = 4
COLOR_GREEN     = 5
COLOR_BLUE      = 6
COLOR_YELLOW    = 7
COLOR_ORANGE    = 8
COLOR_BROWN     = 9
COLOR_LIGHTRED  = 10
COLOR_DARKGREY  = 11
COLOR_GREY      = 12
COLOR_LIGHTGREEN= 13
COLOR_LIGHTBLUE = 14
COLOR_LIGHTGREY = 15`,
    },
    'engine-sprite': {
      name: 'engine/sprite_mgr.asm',
      lang: 'assembly',
      code: `; ==============================================================================
; C64 GAME ENGINE - sprite_mgr.asm
; ==============================================================================
; Gestore generico degli sprite hardware VIC-II.
; API: init, alloc, free, move, enable, disable, set_color, set_frame
; ==============================================================================

; --- ZERO PAGE ENGINE (riservata) ---
SPR_ZP_TEMP     = $02       ; Temporaneo per calcoli
SPR_ZP_IDX      = $03       ; Indice sprite corrente

; --- VARIABILI ENGINE ---
spr_alloc_map   = $0340     ; 8 byte: bitmap allocazione sprite
spr_x_table     = $0350     ; 8 byte: X salvati
spr_y_table     = $0360     ; 8 byte: Y salvati

; ==============================================================================
; sprite_init - Inizializza il sistema sprite
; Input:  nessuno
; Output: tutti gli sprite disabilitati, alloc map azzerata
; ==============================================================================
sprite_init:
    lda #$00
    ldx #$07
.clear_loop:
    sta spr_alloc_map, x
    dex
    bpl .clear_loop
    
    lda #$00
    sta VIC_SPR_ENA         ; Tutti gli sprite OFF
    sta VIC_SPR_MCOLOR      ; No multicolor
    sta VIC_SPR_EXP_X       ; No espansione X
    sta VIC_SPR_EXP_Y       ; No espansione Y
    sta VIC_SPR_X_MSB       ; MSB X = 0
    rts

; ==============================================================================
; sprite_alloc - Alloca il primo sprite libero
; Input:  A = block numero (sprite data pointer)
; Output: X = indice sprite allocato (0-7), A = 0xFF se nessuno libero
; ==============================================================================
sprite_alloc:
    sta SPR_ZP_TEMP         ; Salva il block number
    ldx #$00
.find_free:
    lda spr_alloc_map, x
    beq .found_free
    inx
    cpx #$08
    bcc .find_free
    lda #$FF                ; Nessun sprite libero!
    rts

.found_free:
    ; Segna come allocato
    lda #$01
    sta spr_alloc_map, x
    
    ; Imposta il puntatore sprite
    lda SPR_ZP_TEMP
    sta SPRITE_PTR_BASE, x
    
    ; Abilita lo sprite
    lda VIC_SPR_ENA
    ora sprite_bit_table, x
    sta VIC_SPR_ENA
    
    txa                     ; Ritorna indice in A
    rts

; ==============================================================================
; sprite_free - Libera uno sprite
; Input:  X = indice sprite (0-7)
; ==============================================================================
sprite_free:
    lda #$00
    sta spr_alloc_map, x
    
    lda VIC_SPR_ENA
    and sprite_bit_inv, x   ; AND con bit inverso = spegni
    sta VIC_SPR_ENA
    rts

; ==============================================================================
; sprite_move - Muove uno sprite a coordinate X,Y
; Input:  X = indice sprite, A = X, Y_reg = Y
; ==============================================================================
sprite_move:
    stx SPR_ZP_IDX
    sta spr_x_table, x
    sty spr_y_table, x
    
    ; Calcola registro VIC per questo sprite
    ; VIC_SPRn_X = $D000 + (n * 2)
    ; VIC_SPRn_Y = $D001 + (n * 2)
    txa
    asl                     ; A = n * 2
    tax
    
    lda spr_x_table, x      ; (usa indice originale)
    ldx SPR_ZP_IDX
    ; ... scrittura registri VIC
    rts

; --- TABELLE DI SUPPORTO ---
sprite_bit_table:
    !byte $01, $02, $04, $08, $10, $20, $40, $80

sprite_bit_inv:
    !byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F`,
    },
    'engine-sid': {
      name: 'engine/sid_driver.asm',
      lang: 'assembly',
      code: `; ==============================================================================
; C64 GAME ENGINE - sid_driver.asm
; ==============================================================================
; Driver audio generico per chip SID (MOS 6581/8580).
; API: init, play_note, play_sfx, set_adsr, mute, tick
; ==============================================================================

; --- ZERO PAGE ENGINE ---
SID_ZP_VOICE    = $04       ; Voce corrente (0,1,2)
SID_ZP_ENV_TMR  = $05       ; Timer envelope

; --- TABELLA OFFSET VOCI SID ---
; Voce 0: $D400, Voce 1: $D407, Voce 2: $D40E
sid_voice_offset:
    !byte $00, $07, $0E

; ==============================================================================
; sid_init - Resetta il chip SID
; ==============================================================================
sid_init:
    ldx #$1C
    lda #$00
.clear_loop:
    sta $D400, x
    dex
    bpl .clear_loop
    
    lda #$0F                ; Volume massimo
    sta SID_VOL_CTRL
    rts

; ==============================================================================
; sid_play_note - Suona una nota su una voce
; Input:  A = voce (0-2), X = freq_lo, Y = freq_hi
;         (pre-configura waveform e ADSR prima)
; ==============================================================================
sid_play_note:
    sta SID_ZP_VOICE
    
    ; Calcola base address voce
    tax
    lda sid_voice_offset, x
    sta SID_ZP_ENV_TMR      ; riuso temporaneo
    
    ; ... scrittura registri frequenza
    rts

; ==============================================================================
; sid_play_sfx - Suona un effetto sonoro predefinito
; Input:  A = numero SFX (0-15)
; SFX predefiniti:
;   0 = Shoot (triangle sweep down)
;   1 = Explosion (noise burst)
;   2 = Power-up (triangle sweep up)
;   3 = Hit (pulse short)
;   4 = Jump (triangle sweep up fast)
;   5 = Coin (pulse double beep)
; ==============================================================================
sid_play_sfx:
    asl                     ; x2 per indice tabella
    tax
    lda sfx_table_lo, x
    sta SID_ZP_ENV_TMR
    lda sfx_table_hi, x
    pha                     ; Salva puntatore routine
    
    ; Jump alla routine SFX specifica
    rts                     ; (in realtà: jmp (pointer))

; ==============================================================================
; sid_tick - Aggiorna envelope e sweep (chiamare ogni frame)
; ==============================================================================
sid_tick:
    ; Aggiorna sweep voce 0 se attivo
    ; Aggiorna decay voce 1 se attivo
    ; Aggiorna noise voce 2 se attivo
    rts

; ==============================================================================
; sid_mute - Silenzia una voce
; Input: A = voce (0-2)
; ==============================================================================
sid_mute:
    ; Release immediato
    rts

; --- TABELLA SFX ---
sfx_table_lo:
    !byte <sfx_shoot, <sfx_explosion, <sfx_powerup
    !byte <sfx_hit, <sfx_jump, <sfx_coin
sfx_table_hi:
    !byte >sfx_shoot, >sfx_explosion, >sfx_powerup
    !byte >sfx_hit, >sfx_jump, >sfx_coin

; --- ROUTINE SFX ---
sfx_shoot:
    ; Voce 0: Triangle sweep down
    lda #$11                ; Triangle + Gate
    sta SID_V1_CTRL
    lda #$1E
    sta SID_V1_FREQ_HI
    lda #$04
    sta SID_V1_AD
    lda #$02
    sta SID_V1_SR
    rts

sfx_explosion:
    ; Voce 2: Noise burst
    lda #$81                ; Noise + Gate
    sta SID_V3_CTRL
    lda #$20
    sta SID_V3_FREQ_LO
    lda #$08
    sta SID_V3_FREQ_HI
    lda #$0A
    sta SID_V3_AD
    rts`,
    },
    'game-main': {
      name: 'games/space-invaders/si_main.asm',
      lang: 'assembly',
      code: `; ==============================================================================
; SPACE INVADERS - si_main.asm
; ==============================================================================
; Game loop specifico. Usa le API dell'engine per il gioco.
; ==============================================================================

; Include l'engine
!src "../../engine/c64hw.inc"

* = $0801
basic_header:
    !byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00

* = $0810
entry_point:
    sei
    cld
    
    ; === INIZIALIZZA ENGINE ===
    jsr vic_init            ; Engine: init video
    jsr sid_init            ; Engine: init audio
    jsr sprite_init         ; Engine: init sprite manager
    jsr input_init          ; Engine: init input handler
    jsr text_init           ; Engine: init text renderer
    
    ; === INIZIALIZZA GIOCO ===
    jsr si_game_init        ; Init specifico Space Invaders
    
    cli

; === GAME LOOP ===
main_loop:
    jsr vic_wait_raster     ; Engine: sync raster
    
    ; Leggi input (engine)
    jsr input_read_joy      ; Engine: leggi joystick
    
    ; Aggiorna logica gioco
    jsr si_player_update    ; Gioco: aggiorna giocatore
    jsr si_invaders_update  ; Gioco: aggiorna invasori
    jsr si_check_collisions ; Gioco: collisioni
    
    ; Aggiorna audio (engine)
    jsr sid_tick            ; Engine: aggiorna envelope
    
    jmp main_loop

; ==============================================================================
; si_game_init - Inizializzazione specifica del gioco
; Usa le API dell'engine per allocare sprite e configurare il gioco
; ==============================================================================
si_game_init:
    ; Alloca sprite per il giocatore
    lda #$80                ; Block $80 = sprite cannone
    ldx #$00
    jsr sprite_alloc        ; ENGINE CALL
    
    ; Posiziona il giocatore al centro
    lda #160                ; X center
    ldy #228                ; Y bottom
    jsr sprite_move         ; ENGINE CALL
    
    ; Imposta colore verde
    lda #$00
    ldx #COLOR_LIGHTGREEN
    jsr sprite_set_color    ; ENGINE CALL
    
    ; Alloca sprite per invasori (3 tipi)
    lda #$81
    jsr sprite_alloc
    lda #$83
    jsr sprite_alloc
    
    ; Mostra titolo usando text renderer
    ldx #>title_string
    lda #<title_string
    ldy #208                ; Posizione schermo
    jsr text_print_at       ; ENGINE CALL
    
    ; Init stato gioco specifico
    lda #$00
    sta si_game_state
    sta si_score_lo
    sta si_score_hi
    lda #3
    sta si_lives
    
    ; Configura SFX del gioco
    jsr si_init_sounds
    
    rts

title_string:
    !scr "COMMODORE 64 SPACE INVADERS", 0`,
    },
    'engine-input': {
      name: 'engine/input.asm',
      lang: 'assembly',
      code: `; ==============================================================================
; C64 GAME ENGINE - input.asm
; ==============================================================================
; Gestore input generico: joystick (CIA 1) e tastiera.
; API: init, read_joy, read_kbd, is_pressed, set_debounce
; ==============================================================================

; --- ZERO PAGE ENGINE ---
INPUT_ZP_JOY    = $06       ; Stato joystick corrente
INPUT_ZP_JOY_OLD= $07       ; Stato joystick frame precedente
INPUT_ZP_DEBOUNCE=$08       ; Contatore debounce

; --- VARIABILI ENGINE ---
input_debounce_val = $0370  ; Valore debounce (default: 3)
input_key_map      = $0380  ; Tabella mappatura tasti (configurabile)

; ==============================================================================
; input_init - Inizializza il sistema input
; ==============================================================================
input_init:
    lda #$03
    sta input_debounce_val  ; Debounce default = 3 frame
    
    lda #$00
    sta INPUT_ZP_JOY
    sta INPUT_ZP_JOY_OLD
    sta INPUT_ZP_DEBOUNCE
    
    ; Imposta CIA1 Port A come input
    lda #$00
    sta $DC02               ; Data Direction Register A = input
    
    ; Carica mappatura tastiera default
    ldx #$04
    lda #$01                ; Default: spazio = fuoco
    sta input_key_map + 0
    lda #$0D                ; Default: A = sinistra
    sta input_key_map + 1
    lda #$11                ; Default: D = destra
    sta input_key_map + 2
    lda #$41                ; Default: W = su
    sta input_key_map + 3
    rts

; ==============================================================================
; input_read_joy - Leggi stato joystick porta 2
; Output: A = stato joystick (bit attivi = 0)
;   Bit 0: Up, Bit 1: Down, Bit 2: Left, Bit 3: Right, Bit 4: Fire
; ==============================================================================
input_read_joy:
    ; Salva stato precedente
    lda INPUT_ZP_JOY
    sta INPUT_ZP_JOY_OLD
    
    ; Leggi porta joystick
    lda CIA1_PORT_A
    sta INPUT_ZP_JOY
    
    ; Applica debounce sul fuoco
    lda INPUT_ZP_JOY
    and #JOY_FIRE
    bne .no_fire
    
    ; Fuoco premuto - controlla debounce
    lda INPUT_ZP_DEBOUNCE
    bne .fire_debounced     ; Ancora in debounce
    
    lda input_debounce_val
    sta INPUT_ZP_DEBOUNCE
    rts                     ; A ha ancora JOY_FIRE = 0 (premuto)

.fire_debounced:
    dec INPUT_ZP_DEBOUNCE
    lda #$FF                ; Ritorna "non premuto" durante debounce
    rts

.no_fire:
    lda #$00
    sta INPUT_ZP_DEBOUNCE   ; Reset debounce se non premuto
    lda INPUT_ZP_JOY
    rts

; ==============================================================================
; input_is_pressed - Controlla se una direzione è premuta
; Input:  A = mask (JOY_UP, JOY_DOWN, JOY_LEFT, JOY_RIGHT, JOY_FIRE)
; Output: A = $00 se premuto, $FF se non premuto
; ==============================================================================
input_is_pressed:
    bit INPUT_ZP_JOY
    bne .not_pressed
    lda #$00
    rts
.not_pressed:
    lda #$FF
    rts

; ==============================================================================
; input_set_debounce - Configura il valore di debounce
; Input: A = valore (0 = nessun debounce, 1-255 = frame di attesa)
; ==============================================================================
input_set_debounce:
    sta input_debounce_val
    rts`,
    },
    'engine-text': {
      name: 'engine/text.asm',
      lang: 'assembly',
      code: `; ==============================================================================
; C64 GAME ENGINE - text.asm
; ==============================================================================
; Renderer testo generico per Screen RAM ($0400) e Color RAM ($D800).
; API: init, print, print_at, print_bcd, clear_area, set_color
; ==============================================================================

; --- ZERO PAGE ENGINE ---
TEXT_ZP_PTR     = $09       ; 2 byte: puntatore stringa
TEXT_ZP_POS     = $0B       ; Posizione corrente sullo schermo

; ==============================================================================
; text_init - Inizializza il renderer testo
; Pulisce lo schermo e imposta colori default
; ==============================================================================
text_init:
    ; Pulisci Screen RAM
    ldx #$00
    lda #$20                ; Spazio PETSCII
.clear_screen:
    sta SCREEN_RAM, x
    sta SCREEN_RAM + $100, x
    sta SCREEN_RAM + $200, x
    sta SCREEN_RAM + $300, x
    inx
    bne .clear_screen
    
    ; Colora Color RAM
    ldx #$00
    lda #COLOR_WHITE        ; Default: testo bianco
.clear_color:
    sta COLOR_RAM, x
    sta COLOR_RAM + $100, x
    sta COLOR_RAM + $200, x
    sta COLOR_RAM + $300, x
    inx
    bne .clear_color
    rts

; ==============================================================================
; text_print_at - Stampa una stringa in una posizione specifica
; Input:  A = offset basso stringa, X = offset alto, Y = pos. schermo
; ==============================================================================
text_print_at:
    sta TEXT_ZP_PTR
    stx TEXT_ZP_PTR + 1
    sty TEXT_ZP_POS
    
.print_loop:
    ldy #$00
    lda (TEXT_ZP_PTR), y
    beq .print_done         ; $00 = fine stringa
    
    ; Converti se necessario e scrivi
    sta SCREEN_RAM, y       ; (semplificato - serve calcolo posizione)
    
    ; Avanza puntatore stringa
    inc TEXT_ZP_PTR
    bne .print_loop
    inc TEXT_ZP_PTR + 1
    jmp .print_loop
    
.print_done:
    rts

; ==============================================================================
; text_print_bcd - Stampa un numero BCD a N cifre
; Input:  A = valore BCD basso, X = valore BCD alto, Y = pos. schermo
;         (2 byte BCD = 4 cifre decimali)
; ==============================================================================
text_print_bcd:
    pha                     ; Salva score_lo
    
    ; Stampa cifra migliaia (score_hi alta)
    txa
    lsr
    lsr
    lsr
    lsr
    ora #$30                ; Converti in PETSCII
    sta SCREEN_RAM, y
    iny
    
    ; Stampa cifra centinaia
    txa
    and #$0F
    ora #$30
    sta SCREEN_RAM, y
    iny
    
    ; Stampa cifra decine
    pla
    pha
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta SCREEN_RAM, y
    iny
    
    ; Stampa cifra unità
    pla
    and #$0F
    ora #$30
    sta SCREEN_RAM, y
    
    rts

; ==============================================================================
; text_clear_area - Pulisce un'area rettangolare dello schermo
; Input:  A = posizione inizio, X = larghezza, Y = altezza
; ==============================================================================
text_clear_area:
    ; ... implementazione
    rts

; ==============================================================================
; text_set_color - Imposta il colore del testo per un'area
; Input:  A = colore (0-15), X = pos. inizio, Y = lunghezza
; ==============================================================================
text_set_color:
    ; ... implementazione
    rts`,
    },
  };

  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h2 className="text-3xl font-bold text-[#8be9fd] mb-2">Codice Sorgente</h2>
        <p className="text-gray-400">Esempi di codice dei moduli refattorizzati</p>
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
