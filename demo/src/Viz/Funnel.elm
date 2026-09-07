module Viz.Funnel exposing (Stage, stages, view)

{-| A conversion funnel, drawn with `gampleman/elm-visualization`.

This is a `Daisy.Tree.Leaf.Embed` view function: the one kind of module in
`demo/` that writes its own `Html`. `NoHtmlInDemo` exempts `demo/src/Viz/` for
exactly this, and nothing else about the rules is relaxed here —
`NoClassOutsideRender` still forbids a `class` attribute and
`NoRawSchemaStrings` still forbids a daisyUI class as a string, so every colour
below comes from the `ThemeContext` the renderer hands in, as a
`var(--color-*)` value on an SVG presentation attribute.

Why a funnel, and why this library: `Daisy.Tree.Block.Chart` is a closed set of
five chart kinds (line, bar, stacked bar, donut, area) over
`terezka/elm-charts`, and a funnel is none of them — it is a sequence of
trapezoids whose width encodes a count and whose slope encodes the drop-off
between two stages. `Shape.area` with a linear curve generates exactly that
band, and `Scale.linear` maps a count to a half-height, so the shape is
computed rather than hand-drawn.

It follows the theme live. The three bands are `Primary`, `Secondary` and
`Accent`; the plate behind them is `Base200`; every label is `BaseContent`.
None of those is a colour value — they are the CSS variables daisyUI's own
`[data-theme]` rules set, so switching the theme repaints the funnel with no
re-render and no message.

@docs Stage, stages, view

-}

import Daisy.Chart exposing (SemanticColor(..))
import Daisy.Tree exposing (Surface(..), ThemeContext)
import Html exposing (Html)
import Path
import Scale
import Shape
import Svg
import Svg.Attributes as SvgA


{-| One step of the funnel: what it is called and how many reached it.
-}
type alias Stage =
    { label : String
    , value : Float
    }


{-| The demo's four stages, widest first.
-}
stages : List Stage
stages =
    [ { label = "Visitors", value = 12480 }
    , { label = "Signups", value = 5120 }
    , { label = "Trials", value = 2050 }
    , { label = "Paid", value = 820 }
    ]


{-| The funnel, sized to fill whatever box `Daisy.Render` gives it.

The drawing is done in a fixed 640x240 user-space viewBox and scaled by
`preserveAspectRatio`, so the embed is resolution-independent and the renderer
stays the only thing that decides how tall the box is.

-}
view : ThemeContext -> Html msg
view ctx =
    Svg.svg
        [ SvgA.viewBox "0 0 640 240"
        , SvgA.width "100%"
        , SvgA.height "100%"
        , SvgA.preserveAspectRatio "xMidYMid meet"
        ]
        (plate ctx :: bands ctx ++ labels ctx)



-- GEOMETRY ------------------------------------------------------------------


{-| The drawing's own coordinate system. The plate is inset from the viewBox so
a band's edge never touches the clip of the embed box.
-}
padding : { top : Float, right : Float, bottom : Float, left : Float }
padding =
    { top = 16, right = 16, bottom = 44, left = 16 }


plateWidth : Float
plateWidth =
    640 - padding.left - padding.right


plateHeight : Float
plateHeight =
    240 - padding.top - padding.bottom


{-| The vertical centre the funnel is symmetric about.
-}
axis : Float
axis =
    padding.top + plateHeight / 2


{-| Count -> half-height, in user space.

`Scale.linear` from zero to the first stage's count, onto zero to half the
plate. Anchoring the domain at zero is what makes the taper honest: a band half
as wide is half the conversions, not "somewhat fewer".

-}
heightScale : Scale.ContinuousScale Float
heightScale =
    Scale.linear ( 0, plateHeight / 2 ) ( 0, firstValue )


firstValue : Float
firstValue =
    List.head stages |> Maybe.map .value |> Maybe.withDefault 1


{-| The x of stage `i`, evenly spaced across the plate.
-}
stageX : Int -> Float
stageX i =
    let
        steps : Float
        steps =
            toFloat (max 1 (List.length stages - 1))
    in
    padding.left + (toFloat i / steps) * plateWidth


halfHeightAt : Stage -> Float
halfHeightAt stage =
    Scale.convert heightScale stage.value



-- MARKS ---------------------------------------------------------------------


{-| The surface the funnel is drawn on: one step off the card it sits in, so
the empty part of the funnel's envelope is visible without being a colour of
its own.
-}
plate : ThemeContext -> Svg.Svg msg
plate ctx =
    Svg.rect
        [ SvgA.x (String.fromFloat padding.left)
        , SvgA.y (String.fromFloat padding.top)
        , SvgA.width (String.fromFloat plateWidth)
        , SvgA.height (String.fromFloat plateHeight)
        , SvgA.rx "8"
        , SvgA.fill (ctx.surface Base200)
        ]
        []


{-| One band per pair of adjacent stages, `Shape.area` over two x positions.

`Shape.area` takes `((x, y0), (x, y1))` pairs — a topline point and a baseline
point at each x — so two pairs and a linear curve produce the trapezoid between
one stage's half-height and the next's, mirrored about `axis`.

-}
bands : ThemeContext -> List (Svg.Svg msg)
bands ctx =
    List.map3
        (\i pair color ->
            Path.element (bandPath i pair)
                [ SvgA.fill (ctx.color color)
                , SvgA.stroke (ctx.surface Base100)
                , SvgA.strokeWidth "2"
                ]
        )
        (List.range 0 (List.length bandColors - 1))
        (pairs stages)
        bandColors


bandColors : List SemanticColor
bandColors =
    [ Primary, Secondary, Accent ]


bandPath : Int -> ( Stage, Stage ) -> Path.Path
bandPath i ( from, to ) =
    let
        left : Float
        left =
            halfHeightAt from

        right : Float
        right =
            halfHeightAt to
    in
    Shape.area Shape.linearCurve
        [ Just ( ( stageX i, axis - left ), ( stageX i, axis + left ) )
        , Just ( ( stageX (i + 1), axis - right ), ( stageX (i + 1), axis + right ) )
        ]


{-| The stage names and counts, on the baseline under the funnel.

Text is the one thing here that is not a shape, and it is `BaseContent` — the
colour daisyUI pairs with the card the embed sits on, so `e2e/contrast.spec.ts`
reads it as daisyUI's own pair rather than as a colour this module invented.

-}
labels : ThemeContext -> List (Svg.Svg msg)
labels ctx =
    List.indexedMap
        (\i stage ->
            Svg.g
                [ SvgA.fill (ctx.surface BaseContent) ]
                [ Svg.text_
                    [ SvgA.x (String.fromFloat (stageX i))
                    , SvgA.y (String.fromFloat (240 - padding.bottom + 20))
                    , SvgA.textAnchor (anchorAt i)
                    , SvgA.fontSize "13"
                    , SvgA.fontWeight "600"
                    ]
                    [ Svg.text stage.label ]
                , Svg.text_
                    [ SvgA.x (String.fromFloat (stageX i))
                    , SvgA.y (String.fromFloat (240 - padding.bottom + 36))
                    , SvgA.textAnchor (anchorAt i)
                    , SvgA.fontSize "11"
                    , SvgA.opacity "0.7"
                    ]
                    [ Svg.text (thousands stage.value) ]
                ]
        )
        stages


{-| The first and last labels are pulled inside the plate so a centred label
cannot be clipped by the embed box.
-}
anchorAt : Int -> String
anchorAt i =
    if i == 0 then
        "start"

    else if i == List.length stages - 1 then
        "end"

    else
        "middle"



-- HELPERS -------------------------------------------------------------------


pairs : List a -> List ( a, a )
pairs list =
    case list of
        a :: ((b :: _) as rest) ->
            ( a, b ) :: pairs rest

        _ ->
            []


thousands : Float -> String
thousands value =
    let
        digits : List Char
        digits =
            String.toList (String.fromInt (round value))

        grouped : List Char -> List Char
        grouped chars =
            if List.length chars <= 3 then
                chars

            else
                grouped (List.take (List.length chars - 3) chars)
                    ++ (',' :: List.drop (List.length chars - 3) chars)
    in
    String.fromList (grouped digits)
