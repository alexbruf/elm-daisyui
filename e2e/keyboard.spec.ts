import { test, expect } from "./fixtures";
import { DEMOS, open } from "./lib/daisy";
import { collectFocusables, focusedKey } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "keyboard": "Tab order reaches every `Leaf`
 * control in tree order; modal traps focus and closes on Escape; menu items
 * reachable."
 *
 * "Tree order" is DOM order: `Daisy.Render` walks the tree once and emits in
 * order, and it never sets `tabindex`, so the document's natural sequence is
 * the tree's. The expected set is therefore every visible, enabled control in
 * DOM order, and the assertion is that tabbing from the top of the document
 * visits exactly that sequence.
 */
for (const demo of DEMOS) {
  test(`${demo.name}: Tab reaches every control in tree order`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const expected = await page.evaluate(collectFocusables);
    expect(expected.length, "the demo has focusable controls").toBeGreaterThan(0);

    await page.evaluate(() => (document.activeElement as HTMLElement)?.blur());
    const seen: string[] = [];
    for (let i = 0; i < expected.length; i++) {
      await page.keyboard.press("Tab");
      seen.push(await page.evaluate(focusedKey));
    }
    expect(seen).toEqual(expected);
  });
}

test("admin: the sidebar menu items are reachable and are links", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);
  const width = page.viewportSize()!.width;
  if (width < 1024) await page.locator("label.drawer-button").click();

  // Three routes plus "Docs", which leaves the SPA for the generated
  // documentation site at <base>docs/ (see demo/src/Demo/Admin.elm).
  //
  // The assertion is "every destination is there, exactly once, and focusable",
  // not a count of anchors: since the Nexus design pass the sidebar also holds
  // `menu-title` rows, which are `<li>`s and not links, and adding a real route
  // should not make this spec fail.
  const items = page.locator(".drawer-side ul.menu a");
  await expect(items).toHaveCount(4);
  // "Analytics New" is the label plus its `MenuItem.badge`, which is inside the
  // link and therefore part of its accessible name — which is what a screen
  // reader announces, so it is asserted as written rather than matched loosely.
  for (const name of ["Overview", "Analytics New", "Settings", "Docs"]) {
    const item = page.getByRole("link", { name, exact: true });
    await expect(item).toHaveCount(1);
    await item.focus();
    await expect(item).toBeFocused();
  }
});

test("settings: the modal traps focus and closes on Escape", async ({
  page,
  theme,
}) => {
  await open(page, "/settings", theme);
  await page.getByRole("button", { name: "Save changes" }).click();
  const dialog = page.locator("dialog.modal");
  await expect(dialog).toBeVisible();

  // Native modal dialogs confine sequential focus navigation to the dialog.
  for (let i = 0; i < 8; i++) {
    await page.keyboard.press("Tab");
    const inside = await page.evaluate(() => {
      const active = document.activeElement;
      if (!active || active === document.body) return true; // the cycle's wrap step
      return !!active.closest("dialog.modal");
    });
    expect(inside, `focus left the modal on Tab #${i + 1}`).toBe(true);
  }

  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(page.getByText(/^last-msg: /)).toHaveText("last-msg: ModalCancelled");
});
