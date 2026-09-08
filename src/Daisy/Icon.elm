module Daisy.Icon exposing (Icon(..), allIcons, name)

{-| The closed icon set.

`Icon` is pure data: a name for one of twenty-five drawings. It carries no path
data, no markup and no class — `Daisy.Render` owns the `<svg>` and
`Daisy.Render.Icons` (internal) owns the path data, exactly as `Daisy.Chart`
carries chart shapes without touching `terezka/elm-charts`.

Like `Daisy.Tree.Leaf.Heading` and `Daisy.Tree.Leaf.Image`, an icon is **not** a
daisyUI component and emits **no** daisyUI class. daisyUI's own examples draw
inline SVG wherever a dashboard needs a glyph — in a `menu` item, a `stat-figure`,
a `btn` — and the set exists so a demo can do the same without an escape hatch.

Use it through `Daisy.Tree`:

  - `Leaf.Icon` for a standalone glyph,
  - `MenuItem.icon` for a sidebar entry,
  - `StatItem.figure` (which takes any `Leaf`) for a tile,
  - `ButtonConfig.icon` / `Cta.icon` for a leading glyph on a button.

Import it qualified. Several constructor names below (`Calendar`, `Menu`,
`Check`) also name a `Daisy.Tree` constructor, so `exposing (..)` on both
modules at once would be ambiguous:

    import Daisy.Icon as Icon

    Leaf.Icon Tree.defaultIconConfig Icon.Home


# The set

@docs Icon, allIcons, name


# Attribution

The drawings are [heroicons](https://heroicons.com) 2.2.0 **outline**, 24×24,
by Tailwind Labs, used under the MIT licence:

> MIT License
>
> Copyright (c) Tailwind Labs, Inc.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

heroicons is a **build-time** source only: the `d` attributes were copied into
`Daisy.Render.Icons` once and the package has no npm dependency at runtime.

-}


{-| One of the twenty-five drawings the package ships.

The set is closed on purpose. An open `Icon String` would be a string-typed
escape hatch into the renderer's markup, which is the one thing this package
does not have.

-}
type Icon
    = Home
    | ChartBar
    | Cog
    | Users
    | ShoppingCart
    | CurrencyDollar
    | Bell
    | Search
    | Menu
    | ChevronDown
    | ChevronRight
    | Plus
    | Check
    | X
    | ArrowTrendingUp
    | ArrowTrendingDown
    | Calendar
    | Document
    | Download
    | Eye
    | Pencil
    | Trash
    | User
    | Moon
    | Sun
    | Swatch
    | Sparkles
    | CodeBracket
    | ShieldCheck
    | EllipsisHorizontal
    | Play
    | Backward
    | Forward
    | SpeakerWave
    | ArrowsRightLeft
    | ArrowPath
    | Squares2x2
    | ListBullet
    | LockClosed


{-| Every [`Icon`](#Icon), in declaration order. Fixtures and coverage tests
walk this rather than repeating the list.
-}
allIcons : List Icon
allIcons =
    [ Home
    , ChartBar
    , Cog
    , Users
    , ShoppingCart
    , CurrencyDollar
    , Bell
    , Search
    , Menu
    , ChevronDown
    , ChevronRight
    , Plus
    , Check
    , X
    , ArrowTrendingUp
    , ArrowTrendingDown
    , Calendar
    , Document
    , Download
    , Eye
    , Pencil
    , Trash
    , User
    , Moon
    , Sun
    , Swatch
    , Sparkles
    , CodeBracket
    , ShieldCheck
    , EllipsisHorizontal
    , Play
    , Backward
    , Forward
    , SpeakerWave
    , ArrowsRightLeft
    , ArrowPath
    , Squares2x2
    , ListBullet
    , LockClosed
    ]


{-| The heroicons outline name the drawing comes from, e.g. `Search` is
`"magnifying-glass"`.

It identifies the source file the path data was copied from, so a drawing can
be checked against upstream, and it is a reasonable last-resort label for a
decorative icon. It is **not** rendered anywhere: an icon's accessible name
comes from `Daisy.Tree.IconConfig.label`, and an unlabelled icon is
`aria-hidden`.

-}
name : Icon -> String
name icon =
    case icon of
        Home ->
            "home"

        ChartBar ->
            "chart-bar"

        Cog ->
            "cog-6-tooth"

        Users ->
            "users"

        ShoppingCart ->
            "shopping-cart"

        CurrencyDollar ->
            "currency-dollar"

        Bell ->
            "bell"

        Search ->
            "magnifying-glass"

        Menu ->
            "bars-3"

        ChevronDown ->
            "chevron-down"

        ChevronRight ->
            "chevron-right"

        Plus ->
            "plus"

        Check ->
            "check"

        X ->
            "x-mark"

        ArrowTrendingUp ->
            "arrow-trending-up"

        ArrowTrendingDown ->
            "arrow-trending-down"

        Calendar ->
            "calendar"

        Document ->
            "document"

        Download ->
            "arrow-down-tray"

        Eye ->
            "eye"

        Pencil ->
            "pencil"

        Trash ->
            "trash"

        User ->
            "user"

        Moon ->
            "moon"

        Sun ->
            "sun"

        Swatch ->
            "swatch"

        Sparkles ->
            "sparkles"

        CodeBracket ->
            "code-bracket"

        ShieldCheck ->
            "shield-check"

        EllipsisHorizontal ->
            "ellipsis-horizontal"

        Play ->
            "play"

        Backward ->
            "backward"

        Forward ->
            "forward"

        SpeakerWave ->
            "speaker-wave"

        ArrowsRightLeft ->
            "arrows-right-left"

        ArrowPath ->
            "arrow-path"

        Squares2x2 ->
            "squares-2x2"

        ListBullet ->
            "list-bullet"

        LockClosed ->
            "lock-closed"
