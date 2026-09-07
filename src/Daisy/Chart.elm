module Daisy.Chart exposing
    ( ChartConfig(..), allChartConfigs
    , BarStyle, defaultBarStyle, allBarStyles
    , LineStyle, defaultLineStyle, allLineStyles
    , ChartData, Series, series
    , ChartInteraction
    , SemanticColor(..), allSemanticColors, semanticColorToCss
    , trackColorToCss, bandColorToCss
    )

{-| A closed chart configuration.

`Daisy.Render` maps these values onto `terezka/elm-charts`. No elm-charts type
appears in this module's API, so chart authors cannot reach the underlying
library: the tree stays closed and every chart on a page is drawn the same way.

Colours are daisyUI semantic colours, emitted as CSS custom properties
(`var(--color-primary)`), so a chart follows whatever theme `Page.theme`
selected without the renderer knowing any concrete colour.


# Chart kind

@docs ChartConfig, allChartConfigs
@docs BarStyle, defaultBarStyle, allBarStyles
@docs LineStyle, defaultLineStyle, allLineStyles


# Data

@docs ChartData, Series, series


# Interaction

@docs ChartInteraction


# Colour

@docs SemanticColor, allSemanticColors, semanticColorToCss
@docs trackColorToCss, bandColorToCss

-}


{-| The kind of chart to draw.

`Line`, `Area` and `Donut` read one point per `xLabel` per series. `Bar` draws
the series of each bin side by side, or stacked when its
[`BarStyle`](#BarStyle) says so.

The two styled kinds carry a record rather than a constructor per combination:
`Bar { stacked = True, track = True, rounded = True }` is one value, and adding
a fourth switch later does not multiply the constructor list.

-}
type ChartConfig
    = Line LineStyle
    | Bar BarStyle
    | Donut
    | Area


{-| How a `Bar` chart is drawn.

  - `stacked` puts the series of one bin on top of each other instead of side
    by side.
  - `track` paints a full-height bar behind each bin in
    [`trackColorToCss`](#trackColorToCss), which is what makes a short column
    read as a proportion of the whole rather than as a lonely stub. It is the
    library's colour, not the caller's: see that function.
  - `rounded` rounds both caps of every bar.

-}
type alias BarStyle =
    { stacked : Bool
    , track : Bool
    , rounded : Bool
    }


{-| Side-by-side bars, no track, square caps — daisyUI's plainest bar chart.
-}
defaultBarStyle : BarStyle
defaultBarStyle =
    { stacked = False, track = False, rounded = False }


{-| Every [`BarStyle`](#BarStyle) value: all eight combinations of the three
switches. `allChartConfigs` is built from it, so a fuzzer or a coverage test
covers every branch of the renderer.
-}
allBarStyles : List BarStyle
allBarStyles =
    List.concatMap
        (\stacked ->
            List.concatMap
                (\track ->
                    List.map
                        (\rounded -> { stacked = stacked, track = track, rounded = rounded })
                        bools
                )
                bools
        )
        bools


{-| How a `Line` chart is drawn. `stepped` draws each segment as a horizontal
run and a vertical riser instead of a curve, which is the shape a discrete
series (orders per month, a plan tier) actually has.
-}
type alias LineStyle =
    { stepped : Bool }


{-| A curved line.
-}
defaultLineStyle : LineStyle
defaultLineStyle =
    { stepped = False }


{-| Both [`LineStyle`](#LineStyle) values.
-}
allLineStyles : List LineStyle
allLineStyles =
    List.map (\stepped -> { stepped = stepped }) bools


bools : List Bool
bools =
    [ False, True ]


{-| Every [`ChartConfig`](#ChartConfig) value: both line styles, all eight bar
styles, `Donut` and `Area`.
-}
allChartConfigs : List ChartConfig
allChartConfigs =
    List.map Line allLineStyles
        ++ List.map Bar allBarStyles
        ++ [ Donut, Area ]


{-| The data a chart draws.

`xLabels` labels the bins along the x axis; each `Series` should have one point
per label. Missing points are read as `0`, extra points are ignored.

A `Donut` ignores `xLabels`: each series becomes one ring segment, sized by the
sum of its points and coloured by its own colour.

-}
type alias ChartData =
    { series : List Series
    , xLabels : List String
    }


{-| One named, coloured line / bar set / ring.

`dashed` only affects the line of a `Line` or `Area` chart — it is the
convention every dashboard uses for a projection, and it is a property of the
series rather than of the chart because exactly one series in a chart is
usually the projection.

-}
type alias Series =
    { name : String
    , color : SemanticColor
    , points : List Float
    , dashed : Bool
    }


{-| A solid [`Series`](#Series).

    series "Revenue" Primary [ 1, 2, 3 ]

-}
series : String -> SemanticColor -> List Float -> Series
series name color points =
    { name = name, color = color, points = points, dashed = False }


{-| Hovering a chart, by x index.

`hovered` is the index into `ChartData.xLabels` the pointer is nearest, or
`Nothing`. `onHover` is fired with that index on pointer move and on click (so
a touch works too) and with `Nothing` when the pointer leaves.

It is an _index_, not an elm-charts item: the application therefore stores an
`Int` and the library keeps its `Chart.Item` plumbing to itself, exactly as it
keeps `Chart.Attributes`.

-}
type alias ChartInteraction msg =
    { hovered : Maybe Int
    , onHover : Maybe Int -> msg
    }


{-| The daisyUI semantic palette. These are the only colours a chart can use.
-}
type SemanticColor
    = Primary
    | Secondary
    | Accent
    | Info
    | Success
    | Warning
    | Error
    | Neutral


{-| Every [`SemanticColor`](#SemanticColor) value.
-}
allSemanticColors : List SemanticColor
allSemanticColors =
    [ Primary, Secondary, Accent, Info, Success, Warning, Error, Neutral ]


{-| The CSS colour value for a [`SemanticColor`](#SemanticColor).

    semanticColorToCss Primary --> "var(--color-primary)"

-}
semanticColorToCss : SemanticColor -> String
semanticColorToCss color =
    case color of
        Primary ->
            "var(--color-primary)"

        Secondary ->
            "var(--color-secondary)"

        Accent ->
            "var(--color-accent)"

        Info ->
            "var(--color-info)"

        Success ->
            "var(--color-success)"

        Warning ->
            "var(--color-warning)"

        Error ->
            "var(--color-error)"

        Neutral ->
            "var(--color-neutral)"


{-| The colour of a `BarStyle.track`: `var(--color-base-200)`.

It is a constant rather than a thirty-sixth `SemanticColor`, and that is the
whole decision. A track is a _surface_ — the unfilled part of a column — and a
surface is not something a series may choose:

  - `e2e/themes.spec.ts` reads every `stroke`/`fill` that names a `--color-*`
    variable back off the painted SVG and compares it with the theme's own
    value, so a base surface here is checked exactly like a semantic colour is
    (it is not an exemption); but
  - a _series_ painted `--color-base-200` would be invisible against the
    `--color-base-100` panel it is drawn on, and
    `e2e/contrast.spec.ts`'s classifier reads a base-over-base pair as
    daisyUI's own, so it would pass while showing nothing.

Keeping the track out of `SemanticColor` is therefore what stops "a line the
colour of the paper" from being expressible at all, while still letting the
track follow the theme.

-}
trackColorToCss : String
trackColorToCss =
    "var(--color-base-200)"


{-| The colour of the band behind the hovered column:
`var(--color-base-300)`, one step darker than [`trackColorToCss`](#trackColorToCss).

daisyUI's own dashboard templates highlight the hovered column with `base-200`,
but a chart that also carries a `base-200` track needs the two to be
distinguishable — so the band is the next surface down, which is the same
relationship (one step off the panel) against a track instead of against the
panel.

-}
bandColorToCss : String
bandColorToCss =
    "var(--color-base-300)"
