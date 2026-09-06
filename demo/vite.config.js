import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import elmPlugin from 'vite-plugin-elm'

// demo/ is the Vite root. src/Daisy/* (the library) lives one level up at
// ../src and is imported by demo/src/Main.elm via elm.json's
// source-directories ["src", "../src"].
export default defineConfig({
  plugins: [tailwindcss(), elmPlugin()],
})
