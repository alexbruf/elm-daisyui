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
