// Not a test. Regenerates docs/screenshots/*: the four demos (full page,
// 1440), the light/dark/nord report set for the three SPEC demos, and the two
// side-by-side comparison sheets' right-hand halves.
//
//   cd e2e && node docshots.mjs http://localhost:<port>
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";

const base = process.argv[2] || "http://localhost:4173";
const out = path.resolve(import.meta.dirname, "..", "docs", "screenshots");
fs.mkdirSync(path.join(out, "report"), { recursive: true });

const browser = await chromium.launch({ channel: "chrome" });

async function shoot(route, theme, file, { fullPage = true, fold = false } = {}) {
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 1,
    reducedMotion: "reduce",
  });
  await page.addInitScript(() => {
    const style = document.createElement("style");
    style.textContent =
      "*,*::before,*::after{transition:none!important;animation:none!important;" +
      "scroll-behavior:auto!important;caret-color:transparent!important}";
    document.addEventListener("DOMContentLoaded", () => document.head.appendChild(style));
  });
  const sep = route.includes("?") ? "&" : "?";
  await page.goto(`${base}${route}${sep}theme=${theme}`, { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
  await page.screenshot({ path: file, fullPage: fold ? false : fullPage });
  await page.close();
  console.log("wrote", path.relative(process.cwd(), file));
}

const demos = [
  ["/", "admin"],
  ["/analytics", "analytics"],
  ["/settings", "settings"],
  ["/theme", "theme"],
];

for (const [route, name] of demos) {
  await shoot(route, "light", path.join(out, `demo-${name}.png`));
}
// The report set covers all four demos, the generator included: it is the page
// the "Generator close-up pass" changed most, and light/dark/nord is where a
// theme-dependent regression on it would show.
for (const [route, name] of demos) {
  for (const theme of ["light", "dark", "nord"]) {
    await shoot(route, theme, path.join(out, "report", `${name}-${theme}.png`));
  }
}
// The settings modal, open.
{
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 1,
    reducedMotion: "reduce",
  });
  // The same "kill every transition" stylesheet `shoot()` injects. daisyUI's
  // `.modal` opens with a 0.3s translate and a 0.2s opacity that its own CSS
  // does not guard behind `prefers-reduced-motion`, so without this the shot
  // catches the dialog mid-flight — sometimes at opacity 0.
  await page.addInitScript(() => {
    const style = document.createElement("style");
    style.textContent =
      "*,*::before,*::after{transition:none!important;animation:none!important;" +
      "scroll-behavior:auto!important;caret-color:transparent!important}";
    document.addEventListener("DOMContentLoaded", () => document.head.appendChild(style));
  });
  await page.goto(`${base}/settings?theme=light`, { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });
  await page.getByRole("button", { name: "Save changes" }).click();
  await page.locator("dialog.modal").waitFor({ state: "visible" });
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
  await page.screenshot({ path: path.join(out, "demo-settings-modal.png") });
  await page.close();
  console.log("wrote docs/screenshots/demo-settings-modal.png");
}
// The two comparison halves, at the fold (1440x900, no fullPage).
await shoot("/", "light", path.join(out, "fold-admin.png"), { fold: true });
await shoot("/theme", "light", path.join(out, "fold-theme.png"), { fold: true });

await browser.close();
