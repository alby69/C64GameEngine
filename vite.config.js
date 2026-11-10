import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// Environment driven options (used by the Docker dev container).
// Locally everything falls back to the previous defaults.
const port = Number(process.env.VITE_PORT || 3000);
const hmrPort = Number(process.env.VITE_HMR_PORT || port);
const usePolling = process.env.VITE_USE_POLLING === "true";
const hmrHost = process.env.VITE_HMR_HOST || undefined;

const allowedHosts = (() => {
  const raw = process.env.VITE_ALLOWED_HOSTS;
  if (!raw) return undefined;
  if (raw === "true") return true;
  return raw
    .split(",")
    .map((host) => host.trim())
    .filter(Boolean);
})();

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    host: "0.0.0.0",
    port,
    strictPort: true,
    allowedHosts,
    watch: {
      // Required on Docker Desktop (Windows/macOS) to detect file changes
      usePolling,
    },
    hmr: {
      port: hmrPort,
      host: hmrHost,
    },
  },
});
