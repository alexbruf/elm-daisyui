import { copyFileSync, existsSync } from 'node:fs'
import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import elmPlugin from 'vite-plugin-elm'

// demo/ is the Vite root. src/Daisy/* (the library) lives one level up at
// ../src and is imported by demo/src/Main.elm via elm.json's
// source-directories ["src", "../src"].

// Where the built demo is served from. `/` for `vite dev`, `vite preview` and
// the Playwright run; `/elm-daisyui/` for GitHub Pages, which serves a project
// site under the repository name. The workflow sets it:
//
//   VITE_BASE=/elm-daisyui/ bun run build
//
// Vite hands the value to the bundle as `import.meta.env.BASE_URL`, which
// demo/src/main.js passes to Elm as the `basePath` flag (see BasePath.elm).
// BASE_PATH is accepted as a synonym.
const base = process.env.VITE_BASE || process.env.BASE_PATH || '/'

// GitHub Pages has no SPA fallback: a request for /elm-daisyui/analytics is a
// 404 unless a file exists at that path. Pages serves 404.html for any miss,
// so a copy of index.html under that name turns every deep link into the same
// Elm app, which then routes on the URL it was loaded with.
function pagesSpaFallback() {
  return {
    name: 'pages-spa-fallback',
    apply: 'build',
    closeBundle() {
      const outDir = resolve(import.meta.dirname, 'dist')
      const index = resolve(outDir, 'index.html')
      if (existsSync(index)) {
        copyFileSync(index, resolve(outDir, '404.html'))
      }
    },
  }
}

export default defineConfig({
  base,
  plugins: [tailwindcss(), elmPlugin(), pagesSpaFallback()],
})
