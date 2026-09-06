import { test, expect } from "./fixtures";

// Proves the harness itself: the demo builds, `vite preview` serves it on
// the fixed port, Playwright drives system Chrome against it (channel:
// "chrome", no browser download), and the page mounts. Runs across the full
// viewport x theme project matrix (see playwright.config.ts). Real Tier C
// specs (overlap, overflow, layers, ...) are written separately per
// SPEC.md step 6 Tier C.
//
// NOTE on `#app`: index.html mounts Elm at `<div id="app">`, but the demo
// is a `Browser.application`, which takes over `<body>` and therefore
// removes that placeholder node from the live DOM. We check the *served*
// HTML for the `#app` mount point (proves index.html is wired correctly)
// and check the *live* page for rendered demo content (proves the JS
// bundle, Elm, and Chrome all actually ran).
//
// The live assertion targets the demo's debug pane, which every demo
// renders as a `Prose` block reading `last-msg: <Msg constructor name>`
// (`none` before the first message) — see demo/src/Main.elm. It is the one
// piece of text guaranteed to be present on all three routes.
test("home page mounts the app", async ({ page, request, theme }) => {
  const html = await (await request.get("/")).text();
  expect(html).toContain('<div id="app">');

  const consoleErrors: string[] = [];
  page.on("pageerror", (err) => consoleErrors.push(String(err)));

  await page.goto(`/?theme=${theme}`);
  await expect(page.getByText(/^last-msg: /)).toBeVisible();
  expect(consoleErrors).toEqual([]);
});
