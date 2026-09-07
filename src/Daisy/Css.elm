module Daisy.Css exposing (stylesheet, version)

{-| The one stylesheet this package ships.

`Daisy.Render` emits daisyUI classes and Tailwind utilities, both of which the
application's own CSS build already provides. Motion is the one thing neither
does: daisyUI animates its own components and nothing else, and there is no
Tailwind utility for "grow this bar from its baseline". So the four `daisy-*`
classes below come with their own rules, and this module is where those rules
live — as a string, so that a generator can write them to a real `.css` file
that the application imports (`tools/gen-daisy-css.js` ->
`demo/daisy-motion.css`), exactly the way `alexbruf/elm-cally` ships
`Cally.Css.stylesheet`.

Three things about the contents are deliberate:

  - **Everything is inside `@media (prefers-reduced-motion: no-preference)`.**
    Not `reduce`-guarded-off afterwards: the animations are only ever declared
    when the reader has not asked for less motion, so the reduced-motion state
    is the plain, undecorated one and there is nothing to override.

  - **The `daisy-` prefix.** These are the only class names in the package that
    are neither a daisyUI class nor a Tailwind utility, so they carry a
    namespace that neither library uses. They are listed in
    `Daisy.Render.tokens` like every other class the renderer may emit, and
    `tools/render-class-audit.js` and `tests/RenderPurityTest.elm` check them
    the same way.

  - **Two selectors reach into `terezka/elm-charts`.** `.elm-charts__bar-series`
    and `.elm-charts__interpolation-section` are the library's own class names
    on the group of bars and on the drawn line; `Daisy.Render` cannot put a
    class of its own on either, because both are produced inside `C.bars` /
    `C.series`. This is the same exemption `tests/RenderPurityTest.elm` states
    for the classes elm-charts writes (`chartLibraryPrefix`), read from the
    other side: the renderer marks the _container_ it owns, and the rule
    descends from there.


# The stylesheet

@docs stylesheet, version

-}


{-| The version of the rules below.

`tools/gen-daisy-css.js` copies it into the generated file's header, so the
committed `demo/daisy-motion.css` says which revision of this module produced
it and a stale copy is visible in a diff rather than silent.

-}
version : String
version =
    "2"


{-| The rules for the four `daisy-anim-*` classes `Daisy.Render` emits.

  - `daisy-anim-bars` on a chart whose bars should grow out of the baseline.
    The transform is on the _series group_, so a stack rises as one column, and
    `transform-box: fill-box` is what makes `transform-origin: bottom` mean the
    group's own bottom rather than the SVG viewport's.

  - `daisy-anim-line` on a chart whose line should draw itself in. A
    `stroke-dasharray` long enough to cover any path in an 800-unit viewBox,
    animated to zero offset; the filled half of an `Area` has no stroke to
    dash, so it fades instead.

    The dash pattern is inside the **keyframes**, and the animation has no
    fill mode, both for one reason: `Series.dashed` is a `stroke-dasharray`
    _presentation attribute_ on the same path, and any CSS declaration beats a
    presentation attribute. A static `stroke-dasharray: 2400` in this rule
    would therefore make a dashed projection line solid — permanently, with
    `animation-fill-mode: both`. Confining the pattern to the keyframes and
    letting the animation stop filling gives the path back to its own
    attribute the moment the draw-in ends.

  - `daisy-anim-tooltip` on the hover tooltip card, so it arrives rather than
    appears.

  - `daisy-anim-band` on the band behind the hovered column, whose fill is
    cross-faded when the hovered index changes.

-}
stylesheet : String
stylesheet =
    """
@media (prefers-reduced-motion: no-preference) {
  @keyframes daisy-bar-grow {
    from { transform: scaleY(0); }
    to   { transform: scaleY(1); }
  }

  @keyframes daisy-line-draw {
    from { stroke-dasharray: 2400; stroke-dashoffset: 2400; }
    to   { stroke-dasharray: 2400; stroke-dashoffset: 0; }
  }

  @keyframes daisy-fade-in {
    from { opacity: 0; }
    to   { opacity: 1; }
  }

  @keyframes daisy-tooltip-in {
    from { opacity: 0; transform: translateY(4px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  .daisy-anim-bars .elm-charts__bar-series {
    transform-box: fill-box;
    transform-origin: bottom;
    animation: daisy-bar-grow 0.55s cubic-bezier(0.22, 1, 0.36, 1) both;
  }

  .daisy-anim-line .elm-charts__interpolation-section {
    animation: daisy-line-draw 0.9s ease-out;
  }

  .daisy-anim-line .elm-charts__area-section {
    animation: daisy-fade-in 0.9s ease-out both;
  }

  .daisy-anim-tooltip {
    animation: daisy-tooltip-in 0.12s ease-out both;
  }

  .daisy-anim-band {
    transition: fill 0.15s ease-out, opacity 0.15s ease-out;
  }
}
"""
