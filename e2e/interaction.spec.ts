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
