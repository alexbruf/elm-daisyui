module Daisy.Chart exposing
    ( ChartConfig(..), allChartConfigs
    , ChartData, Series
    , SemanticColor(..), allSemanticColors, semanticColorToCss
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


# Data

@docs ChartData, Series


# Colour

@docs SemanticColor, allSemanticColors, semanticColorToCss

-}


{-| The kind of chart to draw.

`Line`, `Area` and `Donut` read one point per `xLabel` per series. `Bar` draws
the series side by side in each bin, `StackedBar` stacks them.

-}
type ChartConfig
    = Line
    | Bar
    | StackedBar
    | Donut
    | Area


{-| Every [`ChartConfig`](#ChartConfig) value.
-}
allChartConfigs : List ChartConfig
allChartConfigs =
    [ Line, Bar, StackedBar, Donut, Area ]


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
-}
type alias Series =
    { name : String
    , color : SemanticColor
    , points : List Float
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
