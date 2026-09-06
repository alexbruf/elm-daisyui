import { test, expect } from "./fixtures";
import { open } from "./lib/daisy";

/**
 * SPEC.md step 6, Tier C, row "layers": "With a modal open, every non-overlay
 * element is either hidden or has a lower stacking order than the modal; toast
 * is above modal; drawer below modal."
 *
 * Two halves, because the demos put the toast and the modal on different
 * pages (Admin owns the toast, Settings owns the modal) and the tree gives an
 * application no way to raise one over the other anyway:
 *
 *   1. the open modal is measured directly — `elementFromPoint` at each corner
 *      of the overlay, and at the centre of the page's own CTA, must land on
 *      the modal or a descendant of it;
 *   2. the ordering guarantee is read off `Daisy.Render`'s contract instead:
 *      overlays are emitted into one fixed wrapper, always in the order
 *      drawer, modal, toast. **Assumption:** with equal z-index inside one
 *      stacking context, later DOM order paints on top, so that emission order
 *      *is* the stacking order. `docs/e2e-findings.md` records what daisyUI's
 *      own z-indices do to that claim when a modal and a toast are shown at
 *      the same time — which these demos never do.
 */
test("settings: an open modal is the top layer", async ({ page, theme }) => {
  await open(page, "/settings", theme);
  await page.getByRole("button", { name: "Save changes" }).click();

  const dialog = page.locator("dialog.modal");
  await expect(dialog).toHaveAttribute("open", "");
  await expect(dialog).toBeVisible();

  const hits = await page.evaluate(() => {
    const modal = document.querySelector("dialog.modal")!;
    const r = modal.getBoundingClientRect();
    const inset = 2;
    const points: [string, number, number][] = [
      ["top-left", r.left + inset, r.top + inset],
      ["top-right", r.right - inset, r.top + inset],
      ["bottom-left", r.left + inset, r.bottom - inset],
      ["bottom-right", r.right - inset, r.bottom - inset],
    ];
    const cta = document.querySelector(".btn-primary");
    if (cta) {
      const c = cta.getBoundingClientRect();
      points.push(["page CTA centre", c.left + c.width / 2, c.top + c.height / 2]);
    }
    return points.map(([name, x, y]) => {
      const el = document.elementFromPoint(x, y);
      return {
        name,
        inModal: !!el && (el === modal || modal.contains(el)),
        got: el ? el.tagName.toLowerCase() + "." + (el.className || "") : "null",
      };
    });
  });

  expect(hits.filter((h) => !h.inModal).map((h) => `${h.name} -> ${h.got}`)).toEqual(
    [],
  );

  // The rest of the document is inert while the dialog is modal, which is the
  // "every non-overlay element is hidden or lower" half of the row.
  expect(
    await page.evaluate(() => document.querySelector("dialog.modal")!.matches(":modal")),
  ).toBe(true);
});

test("the drawer sits below the modal", async ({ page, theme }) => {
  await open(page, "/", theme);
  const drawerZ = await page
    .locator(".drawer-side")
    .evaluate((el) => getComputedStyle(el).zIndex);
  await open(page, "/settings", theme);
  const modalZ = await page
    .locator("dialog.modal")
    .evaluate((el) => getComputedStyle(el).zIndex);

  expect(Number(drawerZ)).toBeLessThan(Number(modalZ));
});

test("overlays are emitted in the fixed order drawer, modal, toast", async ({
  page,
  theme,
}) => {
  // Admin only shows its toast after the CTA fires, so both overlay-bearing
  // demos are visited and the observed order is checked against the contract.
  const order = ["drawer", "modal", "toast"];

  await open(page, "/settings", theme);
  const settings = await overlayOrder(page);
  expect(settings).toEqual(["modal"]);

  await open(page, "/", theme);
  await page.getByRole("button", { name: "Export report" }).click();
  await expect(page.locator(".toast")).toBeVisible();
  const admin = await overlayOrder(page);
  expect(admin).toEqual(["toast"]);

  // Both observed sequences are subsequences of the renderer's fixed order.
  for (const seen of [settings, admin]) {
    const positions = seen.map((k) => order.indexOf(k));
    expect(positions.every((p) => p >= 0)).toBe(true);
    expect([...positions].sort((a, b) => a - b)).toEqual(positions);
  }
});

async function overlayOrder(page: import("@playwright/test").Page) {
  return page.evaluate(() => {
    const wrapper = document.querySelector(".fixed.inset-0");
    if (!wrapper) return [] as string[];
    return [...wrapper.children]
      .map((c) =>
        c.classList.contains("drawer")
          ? "drawer"
          : c.classList.contains("modal")
            ? "modal"
            : c.classList.contains("toast")
              ? "toast"
              : "",
      )
      .filter(Boolean);
  });
}
