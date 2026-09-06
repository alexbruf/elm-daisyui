# schema.json vs class.json diff

Generated-by-hand companion to `bun tools/gen-schema.js`.

`fixtures/schema.json` is the union of the ten documented `classnames:` groups in
`vendor/daisyui/packages/docs/src/routes/(routes)/components/*/+page.md`.
The comparison set is the union of every
`vendor/daisyui/packages/daisyui/components/*/class.json`, which the daisyUI build
produces by running `functions/extractClasses.js` over `src/components/*.css` only.

Every class below is a real, verified difference. `gen-schema.js` exits 1 if a class
appears in the diff and is not listed here.

Counts: 7 documented-but-not-in-`class.json`, 70 in-`class.json`-but-not-documented.

## In schema.json but not in any class.json (7)

Tailwind variants, not CSS classes. `packages/daisyui/index.js` registers them with
`addVariant`, so `extractClasses.js` never sees them in a stylesheet.

- `is-drawer-open:`: Tailwind variant added by `addVariant("is-drawer-open", ...)` in `packages/daisyui/index.js`; it is a selector prefix (`is-drawer-open:w-80`), never a standalone class.
- `is-drawer-close:`: Tailwind variant added by `addVariant("is-drawer-close", ...)` in `packages/daisyui/index.js`; same, it only ever prefixes another utility.

Defined in `src/utilities/`, not `src/components/`, so no `class.json` is generated for them.

- `join`: defined in `src/utilities/join.css`; `class.json` files are only emitted for `src/components/*.css`, and there is no `components/join`.
- `join-item`: defined in `src/utilities/join.css`, same reason.
- `join-horizontal`: defined in `src/utilities/join.css`, same reason.
- `join-vertical`: defined in `src/utilities/join.css`, same reason.

Emitted by a plugin, not by a stylesheet.

- `theme-controller`: written by `functions/themePlugin.js` / `generateThemeFiles.js` into theme selectors (`:root:has(input.theme-controller[value=light]:checked)`); it lives in no component CSS file.

## In class.json but not in schema.json (70)

Classes owned by another plugin or by plain markup, referenced only inside a daisyUI selector.

- `prose`: `button.css` line 7 selects `.prose :where(a.btn:not(.btn-link))`; `prose` is the Tailwind typography plugin class, not a button class.
- `disabled`: `menu.css` selects `li:not(.menu-title, .disabled)`; a bare state class on the host `<li>`, and the docs document `menu-disabled` for the daisyUI-owned equivalent.

Deprecated or undocumented daisyUI classes kept in the CSS.

- `fieldset-label`: `fieldset.css` carries the comment "deprecated in favor of label - but stays in source code to avoid breaking change"; the docs list `label` in the fieldset `component` group instead.
- `row-hover`: `table.css` styles `tr.row-hover` (and `&.row-hover` under `table-zebra`); an opt-in per-row hover class that the table docs frontmatter never lists.

Third-party calendar library classes styled by `calendar.css`. The calendar docs page
documents only the three library root classes (`cally`, `react-day-picker`, `vc`) as its
`component` group; every class below belongs to the vendored library's own DOM, not to
daisyUI. (Cally adds none of these because it is a web component styled through `::part()`.)

react-day-picker internals, styled under `.react-day-picker` (25):

- `rdp-nav`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-chevron`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-day`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-day_button`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-caption_label`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-button_next`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-button_previous`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-dropdowns`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-dropdown`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-dropdown_root`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-month_caption`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-months`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-month_grid`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-weekday`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-week_number`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-today`: react-day-picker state class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-outside`: react-day-picker state class (day outside the shown month), styled under `.react-day-picker`.
- `rdp-selected`: react-day-picker state class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-disabled`: react-day-picker state class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-hidden`: react-day-picker state class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-range_start`: react-day-picker range state class, styled under `.react-day-picker`.
- `rdp-range_middle`: react-day-picker range state class, styled under `.react-day-picker`.
- `rdp-range_end`: react-day-picker range state class, styled under `.react-day-picker`.
- `rdp-focusable`: react-day-picker state class, styled under `.react-day-picker` in `calendar.css`.
- `rdp-footer`: react-day-picker internal class, styled under `.react-day-picker` in `calendar.css`.

Pikaday internals and state classes, styled under `.pika-single` (23):

- `pika-single`: Pikaday root class; `calendar.css` styles the whole Pikaday DOM under it.
- `pika-lendar`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-title`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-label`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-prev`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-next`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-select`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-table`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-button`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-week`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `pika-row`: Pikaday internal class, styled under `.pika-single` in `calendar.css`.
- `is-hidden`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-bound`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-disabled`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-today`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-selected`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-inrange`: Pikaday range state class, styled under `.pika-single` in `calendar.css`.
- `is-startrange`: Pikaday range state class, styled under `.pika-single` in `calendar.css`.
- `is-endrange`: Pikaday range state class, styled under `.pika-single` in `calendar.css`.
- `is-outside-current-month`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `is-selection-disabled`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `has-event`: Pikaday state class, styled under `.pika-single` in `calendar.css`.
- `pick-whole-week`: Pikaday option class, styled as `.pika-row.pick-whole-week:hover .pika-button`.

Vanilla Calendar Pro internals, styled under `.vc` (18):

- `vc-arrow`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-header__content`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-month`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-year`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-months__month`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-years__year`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-week-numbers__title`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-week-number`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-week__day`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-date`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-date__btn`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-date__popup`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-date-range-tooltip`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-time`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-time__hour`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-time__minute`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-time__keeping`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
- `vc-time__range`: Vanilla Calendar Pro internal class, styled under `.vc` in `calendar.css`.
