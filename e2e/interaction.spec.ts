import { test, expect } from "./fixtures";
import { open } from "./lib/daisy";

/**
 * SPEC.md step 6, Tier C, row "interaction": "Toast appears and auto-dismisses;
 * modal confirm fires the expected `msg` (assert via a debug pane in the demo
 * showing last msg)."
 *
 * Every demo renders that pane as `last-msg: <Msg constructor name>`, so the
 * assertions read the message the Elm program actually handled rather than a
 * DOM side effect that happens to look right.
 */
const pane = /^last-msg: (\w+)$/;

test("admin: the toast appears after the CTA and dismisses itself", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);
  await expect(page.getByText(pane)).toHaveText("last-msg: none");
  await expect(page.locator(".toast")).toHaveCount(0);

  await page.getByRole("button", { name: "Export report" }).click();

  await expect(page.locator(".toast")).toBeVisible();
  await expect(page.locator(".toast")).toContainText("Report queued");
  await expect(page.getByText(pane)).toHaveText("last-msg: ExportClicked");

  // Demo.Main schedules `Process.sleep 3000` -> `ToastDismissed`.
  await expect(page.locator(".toast")).toHaveCount(0, { timeout: 10_000 });
  await expect(page.getByText(pane)).toHaveText("last-msg: ToastDismissed");
});

test("admin: the theme dropdown changes the page theme", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);
  const root = page.locator("[data-theme]").first();
  await expect(root).toHaveAttribute("data-theme", theme);

  // daisyUI's dropdown opens on `:focus-within`, so the panel is
  // `display:none` until its `role="button"` trigger is activated.
  const trigger = page.getByRole("button", { name: "Theme" });
  await expect(trigger).toBeVisible();
  await trigger.click();

  const nord = page.locator('input.theme-controller[value="nord"]');
  await expect(nord).toBeVisible();
  await nord.click();

  await expect(page.getByText(pane)).toHaveText("last-msg: ThemeChanged");
  await expect(root).toHaveAttribute("data-theme", "nord");
});

test("admin: the icon-only notifications button is named and fires its msg", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);

  // The button has no text: its `Bell` icon is `aria-hidden`, and the name
  // comes from `ButtonConfig.ariaLabel` (Daisy.Tree). Finding it by role and
  // name is the same lookup axe's `button-name` rule makes, so this fails if
  // the accessible name ever goes missing.
  const bell = page.getByRole("button", { name: "Notifications" });
  await expect(bell).toBeVisible();

  // The unread count is `ButtonConfig.indicator`: `Daisy.Render` wraps the
  // button in `.indicator` and puts `indicator-item` on the badge itself, so
  // the badge is the button's *sibling*, not its child.
  const wrapper = page.locator(".indicator").filter({ has: bell });
  await expect(wrapper.locator(".indicator-item")).toHaveText("3");

  await bell.click();
  await expect(page.getByText(pane)).toHaveText("last-msg: NotificationsOpened");
});

test("admin: the icon-only row action is named per order and fires OrderViewed", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);

  const view = page.getByRole("button", { name: "View order AC-10431" });
  await expect(view).toBeVisible();
  await view.click();
  await expect(page.getByText(pane)).toHaveText("last-msg: OrderViewed");
});

test("analytics: picking a range sets last-msg: DateRangeChanged", async ({
  page,
  theme,
}) => {
  await open(page, "/analytics", theme);
  await expect(page.getByText(pane)).toHaveText("last-msg: none");

  // `Leaf.Calendar` renders `alexbruf/elm-cally`, which puts a `part` token on
  // every element instead of a class. A range needs two clicks: the first
  // starts it (the picker's own `CalendarMsg`), the second sorts the pair and
  // fires `onChange`.
  const days = page.locator('.cally button[part~="day"]:not([disabled])');
  await expect(days.first()).toBeVisible();
  await days.nth(4).click();
  await days.nth(11).click();

  await expect(page.getByText(pane)).toHaveText("last-msg: DateRangeChanged");

  // The caption under the picker is a `Leaf.Text` in the same `card-body`, so
  // it shares its element with the card title and the calendar's own text.
  const card = page.locator(".card", { has: page.locator(".cally") });
  await expect(card).toContainText(
    /\d{4}-\d{2}-\d{2} to \d{4}-\d{2}-\d{2}/,
  );
});

test("settings: confirming the modal fires ModalConfirmed", async ({
  page,
  theme,
}) => {
  await open(page, "/settings", theme);
  const dialog = page.locator("dialog.modal");
  await expect(dialog).toBeHidden();

  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(dialog).toBeVisible();
  await expect(page.getByText(pane)).toHaveText("last-msg: SaveClicked");

  await page.getByRole("button", { name: "Apply changes" }).click();
  await expect(page.getByText(pane)).toHaveText("last-msg: ModalConfirmed");
  await expect(dialog).toBeHidden();
  await expect(dialog).not.toHaveAttribute("open", "");
});

test("settings: cancelling the modal fires ModalCancelled", async ({
  page,
  theme,
}) => {
  await open(page, "/settings", theme);
  await page.getByRole("button", { name: "Save changes" }).click();
  await page.getByRole("button", { name: "Cancel" }).click();
  await expect(page.getByText(pane)).toHaveText("last-msg: ModalCancelled");
  await expect(page.locator("dialog.modal")).toBeHidden();
});

test("admin: hovering the 2023 column opens its tooltip and highlights it", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);
  await expect(page.getByText(pane)).toHaveText("last-msg: none");

  // The revenue chart is `DChart.Bar { stacked, track, rounded }`, so every bin
  // holds a `base-200` track bar and the two stacked series above it.
  // `.elm-charts__bar` is elm-charts' own class on each drawn bar; the eighth
  // *stacked* bar of the real series is 2023, which is the bin these
  // assertions are about.
  const chart = page.locator(".card", { hasText: "Revenue Statistics" }).first();
  const bars = chart.locator(".elm-charts__bar");
  await expect(bars.first()).toBeVisible();

  // Nothing is hovered to begin with: no band, no tooltip.
  await expect(chart.locator(".daisy-anim-band")).toHaveCount(0);
  await expect(chart.locator(".daisy-anim-tooltip")).toHaveCount(0);

  // Eight bins in: the track element is drawn first (one bar per bin), so the
  // eighth `.elm-charts__bar` is 2023's track and its centre is inside 2023's
  // column whichever series the pointer lands nearest.
  await bars.nth(7).scrollIntoViewIfNeeded();
  const bin = await bars.nth(7).boundingBox();
  await page.mouse.move(bin!.x + bin!.width / 2, bin!.y + bin!.height / 2);

  // One tooltip, not one per `C.bars` element: the track draws its own bin at
  // every x, and the renderer filters the hover grouping to the caller's own
  // series so exactly one band and one card are drawn.
  const tooltip = chart.locator(".daisy-anim-tooltip");
  await expect(tooltip).toHaveCount(1);
  await expect(tooltip).toContainText("2023");
  await expect(tooltip).toContainText("Orders");
  await expect(tooltip).toContainText("Revenue");
  await expect(chart.locator(".daisy-anim-band")).toHaveCount(1);

  // Hovering is not something the application "did": `Main.paneName` ignores
  // `ChartHovered` exactly as it ignores `CalendarMsg`, so the debug pane is
  // still on the message before it.
  await expect(page.getByText(pane)).toHaveText("last-msg: none");

  // Leaving the chart clears it again.
  await page.mouse.move(4, 4);
  await expect(chart.locator(".daisy-anim-tooltip")).toHaveCount(0);
  await expect(chart.locator(".daisy-anim-band")).toHaveCount(0);
});

test("admin: the Day | Month | Year strip switches the revenue dataset", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);
  const chart = page.locator(".card", { hasText: "Revenue Statistics" }).first();

  // `Year`, the default: ten bins labelled 2016..2025.
  await expect(chart.getByRole("tab", { name: "Year" })).toHaveAttribute(
    "aria-selected",
    "true",
  );
  await expect(chart).toContainText("2016");
  await expect(chart).toContainText("over ten years");

  await chart.getByRole("tab", { name: "Month" }).click();

  // This one *is* stamped: it is a message the application acted on.
  await expect(page.getByText(pane)).toHaveText("last-msg: ChartRangeChanged");
  await expect(chart.getByRole("tab", { name: "Month" })).toHaveAttribute(
    "aria-selected",
    "true",
  );
  await expect(chart).toContainText("Jan");
  await expect(chart).not.toContainText("2016");
  await expect(chart).toContainText("$62.14K");
});

test("admin: hovering the acquisition line opens its tooltip and marks the series", async ({
  page,
  theme,
}) => {
  await open(page, "/", theme);

  // `DChart.Line { stepped = True }`, two series: the measured one and the
  // dashed projection. A line chart has no bin, so the hover is resolved by
  // `CI.sameX` and the highlight is a crosshair band with one dot per series
  // on it — `docs/tree-decisions.md`, "Fixes from live review".
  const chart = page
    .locator(".card", { hasText: "Customer Acquisition" })
    .first();
  const svg = chart.locator(".elm-charts__container-inner");
  await expect(svg).toBeVisible();

  await expect(chart.locator(".daisy-anim-tooltip")).toHaveCount(0);
  await expect(chart.locator(".daisy-anim-band")).toHaveCount(0);

  // The card is below the fold at 375 and 768, and `page.mouse` works in
  // viewport coordinates: without this the pointer would be moved off-screen.
  await svg.scrollIntoViewIfNeeded();
  const box = (await svg.boundingBox())!;
  await page.mouse.move(box.x + box.width * 0.55, box.y + box.height * 0.5);

  const tooltip = chart.locator(".daisy-anim-tooltip");
  await expect(tooltip).toHaveCount(1);
  await expect(tooltip).toContainText("Customer");
  await expect(tooltip).toContainText("Prediction");
  await expect(chart.locator(".daisy-anim-band")).toHaveCount(1);

  // Hovering is not something the application "did".
  await expect(page.getByText(pane)).toHaveText("last-msg: none");

  await page.mouse.move(4, 4);
  await expect(chart.locator(".daisy-anim-tooltip")).toHaveCount(0);
});

test("analytics: hovering a donut segment names it, values it and gives its share", async ({
  page,
  theme,
}) => {
  await open(page, "/analytics", theme);

  // `DChart.Donut` has no x, so its `ChartInteraction` index is a **segment**
  // — the nth series. `Daisy.Render.donutChart` hangs the handlers off each
  // stroked arc and draws the readout in the ring's hole.
  const chart = page.locator(".card", { hasText: "Sessions by device" }).first();
  const segments = chart.locator("svg circle");
  await expect(segments).toHaveCount(3);
  await expect(chart.locator(".daisy-anim-tooltip")).toHaveCount(0);

  // A ring segment is a *stroke*: its bounding box is the whole ring and its
  // centre is the empty hole, so the pointer has to be put on the painted arc.
  // The first segment starts at twelve o'clock and covers 54% of the ring, so
  // three o'clock — the right-hand middle of the box — is inside it.
  await segments.first().scrollIntoViewIfNeeded();
  const ring = (await segments.first().boundingBox())!;
  await page.mouse.move(ring.x + ring.width - 3, ring.y + ring.height / 2);

  const readout = chart.locator(".daisy-anim-tooltip");
  await expect(readout).toHaveCount(1);
  // Desktop is 54 of 54 + 38 + 8.
  await expect(readout).toContainText("Desktop");
  await expect(readout).toContainText("54");
  await expect(readout).toContainText("54%");

  await expect(page.getByText(pane)).toHaveText("last-msg: none");
});
