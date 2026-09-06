import { test, expect } from "./fixtures";
import { open } from "./lib/daisy";

/**
 * SPEC.md step 6, Tier C, row "responsive": "At 375 the dashboard drawer is
 * closed and a toggle exists; at 1440 it is open; stat cards wrap without
 * overlap."
 *
 * `Shell.Dashboard` renders `drawer lg:drawer-open`, so the breakpoint is
 * Tailwind's `lg` (1024px): the 375 and 768 projects are the closed case and
 * 1440 is the open one. The spec reads the project's own viewport rather than
 * resizing, so every row of the matrix asserts the behaviour it should have.
 */
const LG = 1024;
const DASHBOARDS = [
  { name: "admin", path: "/" },
  { name: "analytics", path: "/analytics" },
];

for (const demo of DASHBOARDS) {
  test(`${demo.name}: the drawer matches the viewport`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const width = page.viewportSize()!.width;

    const side = page.locator(".drawer-side");
    const sidebar = side.locator("ul.menu");
    const toggle = page.locator("label.drawer-button");

    if (width < LG) {
      await expect(sidebar, "the sidebar is off-screen below lg").toBeHidden();
      await expect(toggle, "a drawer toggle is offered instead").toBeVisible();
      // The toggle really opens it.
      await toggle.click();
      await expect(sidebar).toBeVisible();
    } else {
      await expect(sidebar, "the sidebar is docked at lg and up").toBeVisible();
      await expect(toggle, "and its toggle is hidden").toBeHidden();
    }
  });

  test(`${demo.name}: stat cards wrap without overlapping`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const width = page.viewportSize()!.width;

    const rects = await page.locator(".stat").evaluateAll((els) =>
      els.map((el) => {
        const r = el.getBoundingClientRect();
        return { x: r.x, y: r.y, w: r.width, h: r.height, right: r.right };
      }),
    );
    expect(rects.length, "every dashboard has stat tiles").toBeGreaterThan(0);

    const overlaps: string[] = [];
    for (let i = 0; i < rects.length; i++) {
      for (let j = i + 1; j < rects.length; j++) {
        const a = rects[i];
        const b = rects[j];
        const w = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
        const h = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
        if (w > 1 && h > 1) overlaps.push(`stat ${i} x stat ${j}`);
      }
    }
    expect(overlaps).toEqual([]);
    expect(
      rects.filter((r) => r.right > width + 1),
      "no stat tile reaches past the viewport",
    ).toEqual([]);
  });
}
