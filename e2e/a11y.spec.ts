import AxeBuilder from "@axe-core/playwright";
import { test, expect } from "./fixtures";
import { DEMOS, open } from "./lib/daisy";

/**
 * SPEC.md step 6, Tier C, row "a11y": "Zero serious or critical axe violations
 * per demo per theme." Moderate and minor findings are reported in the failure
 * message when there is one, but do not fail the run — the row is explicit
 * about the two impacts that matter.
 *
 * The Settings demo is scanned twice, once with its confirm modal open, since
 * a native `<dialog>` in the top layer is a different accessibility tree.
 *
 * The moderate/minor count is printed for every scan (`moderate=<n>`) so the
 * effect of a composition change on the findings the row does not fail on is
 * visible in the run output. It is reported, never asserted.
 */
function moderateLine(
  label: string,
  results: Awaited<ReturnType<AxeBuilder["analyze"]>>,
): string {
  const soft = results.violations.filter(
    (v) => v.impact === "moderate" || v.impact === "minor",
  );
  const ids = soft.map((v) => `${v.id}[${v.impact}]x${v.nodes.length}`);
  return `axe ${label}: moderate=${soft.filter((v) => v.impact === "moderate").length} minor=${soft.filter((v) => v.impact === "minor").length}${ids.length ? " " + ids.join(" ") : ""}`;
}

function serious(results: Awaited<ReturnType<AxeBuilder["analyze"]>>) {
  return results.violations
    .filter((v) => v.impact === "serious" || v.impact === "critical")
    .map(
      (v) =>
        `${v.id} [${v.impact}] x${v.nodes.length}: ${v.nodes
          .map((n) => n.target.join(" "))
          .join(" | ")}`,
    );
}

for (const demo of DEMOS) {
  test(`${demo.name}: no serious or critical axe violations`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const results = await new AxeBuilder({ page }).analyze();
    console.log(moderateLine(`${demo.name} ${theme}`, results));
    expect(serious(results)).toEqual([]);
  });
}

test("settings: no serious or critical axe violations with the modal open", async ({
  page,
  theme,
}) => {
  await open(page, "/settings", theme);
  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(page.locator("dialog.modal")).toBeVisible();
  const results = await new AxeBuilder({ page }).analyze();
  console.log(moderateLine(`settings-modal ${theme}`, results));
  expect(serious(results)).toEqual([]);
});
