import { defineConfig } from 'vite'

// The configuration of Vite for the development server and the build of the frontend (feat-9-walking-skeleton,
// Phase 300). The tests use vitest.config.ts. The JSX is the automatic runtime of React (the option `jsx` of
// tsconfig.json, which the esbuild of Vite reads), so the module needs no plugin for React.
//
// The development server sends the two operations of the contract to the backend, so the page uses relative URLs
// (the same origin, no CORS). The address of the backend is the environment variable SPECMGRDEMO_BACKEND_URL (the
// default is http://localhost:8080, the port of the Spring Boot service).
const backend = process.env.SPECMGRDEMO_BACKEND_URL ?? 'http://localhost:8080'

export default defineConfig({
  server: {
    proxy: {
      '/status': backend,
      '/info': backend,
    },
  },
})
