// app.css lives at demo/app.css (repo root of the demo, one level up from
// here) so its `@source "./src"` directive covers this whole directory and
// `@source "../src/Daisy/..."` reaches the library at the repo root.
import '../app.css'
import { Elm } from './Main.elm'

const node = document.getElementById('app')

// Vite's `base` (see vite.config.js): `/` locally and under Playwright,
// `/elm-daisyui/` for the GitHub Pages build. The router strips it off the
// incoming URL and puts it back on every href and pushUrl — see
// demo/src/BasePath.elm.
const flags = { basePath: import.meta.env.BASE_URL }

const app = Elm.Main.init({ node, flags })

// --- ports (see demo/src/Ports.elm) -----------------------------------------
//
// Three ports, all of them browser APIs Elm cannot reach.

// 1. The clipboard. `writeText` needs a user gesture, which it has: Elm only
//    sends on a button's onClick.
app.ports.copyToClipboard.subscribe((text) => {
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).catch(() => {})
  }
})

// 2. The daisyUI theme-generator link.
//
// daisyUI encodes a theme into its own URL as
//
//     https://daisyui.com/theme-generator/#theme=<base64url(zlib-deflate(json))>
//
// — verified by inflating a hash the live generator produced (`bun -e` +
// node:zlib) and diffing the result against the JSON `Daisy.Tree` emits: same
// keys, same order, same values.
//
// `CompressionStream("deflate")` is the zlib wrapper (RFC 1950), which is what
// that hash is: every one of them starts `eJx`, i.e. the bytes 0x78 0x9c.
// (`"deflate-raw"` would be RFC 1951 and would not decode.) It is a stream, so
// this cannot be a synchronous function returning a value to Elm — hence the
// answer coming back on a second port.
const GENERATOR = 'https://daisyui.com/theme-generator/'

async function deflateToBase64Url(text) {
  const stream = new Blob([text])
    .stream()
    .pipeThrough(new CompressionStream('deflate'))
  const bytes = new Uint8Array(await new Response(stream).arrayBuffer())
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

app.ports.encodeTheme.subscribe(async (json) => {
  let url = GENERATOR
  try {
    url = `${GENERATOR}#theme=${await deflateToBase64Url(json)}`
  } catch {
    // No CompressionStream (or a blocked Blob): the bare generator URL is
    // still a working link, so the page never shows a broken one.
  }
  app.ports.themeEncoded.send(url)
})

// --- native <dialog> glue ---------------------------------------------------
//
// `Daisy.Render` emits a modal as daisyUI's recommended dialog markup
// (`<dialog class="modal">`), and adds the `open` attribute while the
// application's model says the modal is open. A `<dialog>` that merely
// carries `open` is a *non-modal* dialog: it does not go into the top layer,
// does not trap focus and does not close on Escape. Only `showModal()` does
// that, and it is a DOM method, so it cannot come from Elm's view.
//
// This observer is the whole of the glue and it is generic — it knows about
// `dialog.modal` and nothing about this app:
//
//   * an open `dialog.modal` that is not yet `:modal` is re-opened with
//     `showModal()` (the attribute is dropped first, because `showModal()`
//     throws `InvalidStateError` on an already-open dialog),
//   * a `:modal` dialog whose `open` attribute Elm has removed is `close()`d,
//     so it leaves the top layer and releases focus.
//
// Elm's virtual DOM diffs its own previous vnode, not the live attribute, so
// `showModal()` re-adding `open` does not fight the next render.
function syncDialogs() {
  for (const dialog of document.querySelectorAll('dialog.modal')) {
    const wantsOpen = dialog.hasAttribute('open')
    const isModal = dialog.matches(':modal')
    if (wantsOpen && !isModal) {
      dialog.removeAttribute('open')
      dialog.showModal()
    } else if (!wantsOpen && isModal) {
      // `close()` returns early when the element has no `open` attribute
      // (HTML standard, "close the dialog"), and Elm has just removed it —
      // so put it back for the length of the call. Without this the dialog
      // stays in the top layer and keeps the rest of the page inert.
      dialog.setAttribute('open', '')
      dialog.close()
    }
  }
}

new MutationObserver(syncDialogs).observe(document.documentElement, {
  subtree: true,
  childList: true,
  attributes: true,
  attributeFilter: ['open', 'class'],
})

syncDialogs()
