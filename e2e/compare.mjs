// Builds a side-by-side comparison sheet: a daisyUI reference page on the left,
// the matching demo on the right, both at 1440x900.
//
// Two are committed:
//   docs/screenshots/nexus-vs-admin.png       Nexus /dashboards/ecommerce vs `/`
//   docs/screenshots/generator-vs-theme.png   daisyUI's theme generator vs `/theme`
//
// Composited by rendering a tiny local page in the same Chrome the e2e suite
// uses and photographing it, so no image library is needed.
import { chromium } from "playwright";
import fs from "node:fs";

const [left, right, out, leftCaption, rightCaption] = process.argv.slice(2);
const b64 = (p) => `data:image/png;base64,${fs.readFileSync(p).toString("base64")}`;

const html = `<!doctype html><meta charset="utf-8"><style>
  :root { color-scheme: light }
  body { margin:0; background:#0f1115; font:500 15px/1.4 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; color:#e6e8eb }
  .wrap { display:flex; gap:24px; padding:24px }
  figure { margin:0; flex:0 0 1440px }
  figcaption { padding:0 0 10px 2px; letter-spacing:.01em }
  figcaption b { color:#fff }
  figcaption span { color:#98a2b3; font-weight:400 }
  img { display:block; width:1440px; height:900px; border-radius:8px; border:1px solid #222834 }
</style>
<div class="wrap">
  <figure>
    <figcaption><b>Reference</b> &nbsp;<span>${leftCaption || "daisyUI Nexus — /dashboards/ecommerce, 1440&times;900, light"}</span></figcaption>
    <img src="${b64(left)}">
  </figure>
  <figure>
    <figcaption><b>elm-daisyui</b> &nbsp;<span>${rightCaption || "Demo.Admin — built from Daisy.Tree only, 1440&times;900, light"}</span></figcaption>
    <img src="${b64(right)}">
  </figure>
</div>`;

const browser = await chromium.launch({ channel: "chrome" });
const page = await browser.newPage({
  viewport: { width: 2952, height: 976 },
  deviceScaleFactor: 1,
});
await page.setContent(html, { waitUntil: "load" });
await page.evaluate(() => document.fonts.ready.then(() => undefined));
await page.screenshot({ path: out });
await browser.close();
console.log("wrote", out);
