/// <reference types="vite/client" />

/**
 * I sorgenti Assembly del progetto vengono importati come testo grezzo
 * con la sintassi `?raw` di Vite (es. `import src from '../engine/text.asm?raw'`).
 */
declare module '*?raw' {
  const content: string;
  export default content;
}
