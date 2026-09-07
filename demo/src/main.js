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

Elm.Main.init({ node, flags })

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
