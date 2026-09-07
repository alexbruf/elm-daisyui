module Daisy.Color exposing
    ( Oklch
    , hexToOklch, oklchToHex
    , oklchToCss
    )

{-| The one colour space daisyUI themes are written in, and the conversion a
colour picker needs to reach it.

daisyUI 5 writes every theme colour as `oklch(62% 0.265 303.9)`. An HTML colour
input, on the other hand, only ever produces `#rrggbb`. A theme editor therefore
needs both directions of the sRGB <-> OKLCH conversion, and this module is that
conversion — pure arithmetic over `Float`s, no `Html`, no class, no daisyUI
knowledge beyond the way the value is printed.


# The value

@docs Oklch


# Conversion

@docs hexToOklch, oklchToHex


# Printing

@docs oklchToCss

-}

-- THE VALUE -----------------------------------------------------------------


{-| A colour in OKLCH.

  - `l` is **lightness in percent**, `0` to `100`. daisyUI writes lightness with
    a `%` sign (`oklch(62% 0.265 303.9)`) and its own theme sources carry values
    like `11.784%`, so keeping the number in the same unit it is printed in
    makes a theme read out of `vendor/daisyui` and printed back byte-identical.
    The alternative — the 0..1 form the OKLab literature uses — would have to be
    multiplied by 100 on the way out, which is where a `0.11784` turns into
    `11.783999999999999`.
  - `c` is chroma, `0` at grey and about `0.37` at the most saturated sRGB
    colour. It is **not** a percentage.
  - `h` is hue in degrees, `0` to `360`. It is meaningless when `c` is `0`;
    [`hexToOklch`](#hexToOklch) then reports `0`, as daisyUI's own greys do
    (`oklch(98% 0 0)`).

-}
type alias Oklch =
    { l : Float
    , c : Float
    , h : Float
    }



-- CONVERSION ----------------------------------------------------------------


{-| `#rrggbb` (or `rrggbb`) to OKLCH.

The pipeline is the standard one: parse the three bytes, divide by 255, undo
the sRGB transfer function to get linear light, apply Björn Ottosson's two
matrices to get OKLab, then read the `a`/`b` pair as polar coordinates.

    hexToOklch "#ffffff" |> Maybe.map (.l >> round) --> Just 100

    hexToOklch "#000000" |> Maybe.map (.l >> round) --> Just 0

`Nothing` for anything that is not six hexadecimal digits, with or without a
leading `#`. Three-digit shorthand is **not** accepted: an HTML colour input
never produces it, and guessing at `#fff` would make the function's inverse
ambiguous.

-}
hexToOklch : String -> Maybe Oklch
hexToOklch hex =
    parseHex hex
        |> Maybe.map
            (\( r, g, b ) ->
                let
                    ( lightness, aStar, bStar ) =
                        linearToOklab
                            ( srgbToLinear (toFloat r / 255)
                            , srgbToLinear (toFloat g / 255)
                            , srgbToLinear (toFloat b / 255)
                            )

                    chroma : Float
                    chroma =
                        sqrt ((aStar * aStar) + (bStar * bStar))
                in
                { l = roundTo 4 (lightness * 100)
                , c = roundTo 4 chroma
                , h =
                    if chroma < 1.0e-4 then
                        0

                    else
                        roundTo 2 (normaliseHue (atan2 bStar aStar * 180 / pi))
                }
            )


{-| OKLCH back to `#rrggbb`.

The inverse of [`hexToOklch`](#hexToOklch), with one unavoidable difference:
OKLCH is a much larger space than sRGB, so a colour can be asked for that no
screen byte triple represents. Rather than fail, each linear channel is clamped
into `0..1` before the transfer function — the same thing a browser does when it
paints an out-of-gamut `oklch()` — so the result is always a real colour and is
always six digits.

    oklchToHex { l = 100, c = 0, h = 0 } --> "#ffffff"

    oklchToHex { l = 0, c = 0, h = 0 } --> "#000000"

-}
oklchToHex : Oklch -> String
oklchToHex { l, c, h } =
    let
        radians : Float
        radians =
            h * pi / 180

        ( rLinear, gLinear, bLinear ) =
            oklabToLinear ( l / 100, c * cos radians, c * sin radians )
    in
    "#"
        ++ hexByte (linearToSrgb rLinear)
        ++ hexByte (linearToSrgb gLinear)
        ++ hexByte (linearToSrgb bLinear)



-- PRINTING ------------------------------------------------------------------


{-| The CSS daisyUI writes for a theme colour.

    oklchToCss { l = 62, c = 0.265, h = 303.9 } --> "oklch(62% 0.265 303.9)"

-}
oklchToCss : Oklch -> String
oklchToCss { l, c, h } =
    "oklch(" ++ String.fromFloat l ++ "% " ++ String.fromFloat c ++ " " ++ String.fromFloat h ++ ")"



-- SRGB TRANSFER FUNCTION ----------------------------------------------------


{-| sRGB (0..1, gamma encoded) to linear light. IEC 61966-2-1.
-}
srgbToLinear : Float -> Float
srgbToLinear channel =
    if channel <= 0.04045 then
        channel / 12.92

    else
        ((channel + 0.055) / 1.055) ^ 2.4


{-| Linear light back to a gamma-encoded sRGB channel, clamped to the gamut.
-}
linearToSrgb : Float -> Float
linearToSrgb channel =
    let
        clamped : Float
        clamped =
            clamp 0 1 channel
    in
    if clamped <= 0.0031308 then
        clamped * 12.92

    else
        (1.055 * (clamped ^ (1 / 2.4))) - 0.055



-- OKLAB MATRICES ------------------------------------------------------------
--
-- Björn Ottosson, "A perceptual color space for image processing" (2020). The
-- two 3x3 matrices below are his published constants, unchanged; the cube root
-- between them is what makes the space perceptually uniform.


linearToOklab : ( Float, Float, Float ) -> ( Float, Float, Float )
linearToOklab ( r, g, b ) =
    let
        long : Float
        long =
            cubeRoot ((0.4122214708 * r) + (0.5363325363 * g) + (0.0514459929 * b))

        medium : Float
        medium =
            cubeRoot ((0.2119034982 * r) + (0.6806995451 * g) + (0.1073969566 * b))

        short : Float
        short =
            cubeRoot ((0.0883024619 * r) + (0.2817188376 * g) + (0.6299787005 * b))
    in
    ( (0.2104542553 * long) + (0.793617785 * medium) - (0.0040720468 * short)
    , (1.9779984951 * long) - (2.428592205 * medium) + (0.4505937099 * short)
    , (0.0259040371 * long) + (0.7827717662 * medium) - (0.808675766 * short)
    )


oklabToLinear : ( Float, Float, Float ) -> ( Float, Float, Float )
oklabToLinear ( lightness, aStar, bStar ) =
    let
        long : Float
        long =
            (lightness + (0.3963377774 * aStar) + (0.2158037573 * bStar)) ^ 3

        medium : Float
        medium =
            (lightness - (0.1055613458 * aStar) - (0.0638541728 * bStar)) ^ 3

        short : Float
        short =
            (lightness - (0.0894841775 * aStar) - (1.291485548 * bStar)) ^ 3
    in
    ( (4.0767416621 * long) - (3.3077115913 * medium) + (0.2309699292 * short)
    , (-1.2684380046 * long) + (2.6097574011 * medium) - (0.3413193965 * short)
    , (-0.0041960863 * long) - (0.7034186147 * medium) + (1.707614701 * short)
    )


{-| `x ^ (1/3)` for negative `x` as well. Elm's `^` is `Math.pow`, which is
`NaN` for a negative base and a fractional exponent, and the OKLab forward
transform does feed it small negative numbers for out-of-gamut inputs.
-}
cubeRoot : Float -> Float
cubeRoot x =
    if x < 0 then
        -(-x ^ (1 / 3))

    else
        x ^ (1 / 3)



-- HEX -----------------------------------------------------------------------


parseHex : String -> Maybe ( Int, Int, Int )
parseHex raw =
    let
        digits : String
        digits =
            String.toLower
                (if String.startsWith "#" raw then
                    String.dropLeft 1 raw

                 else
                    raw
                )
    in
    if String.length digits /= 6 then
        Nothing

    else
        Maybe.map3 (\r g b -> ( r, g, b ))
            (hexPair (String.slice 0 2 digits))
            (hexPair (String.slice 2 4 digits))
            (hexPair (String.slice 4 6 digits))


hexPair : String -> Maybe Int
hexPair pair =
    case String.toList pair of
        [ high, low ] ->
            Maybe.map2 (\h l -> (h * 16) + l) (hexDigit high) (hexDigit low)

        _ ->
            Nothing


hexDigit : Char -> Maybe Int
hexDigit char =
    let
        code : Int
        code =
            Char.toCode char
    in
    if code >= 0x30 && code <= 0x39 then
        Just (code - 0x30)

    else if code >= 0x61 && code <= 0x66 then
        Just (code - 0x61 + 10)

    else
        Nothing


{-| One gamma-encoded channel (0..1) as two lowercase hexadecimal digits.
-}
hexByte : Float -> String
hexByte channel =
    let
        value : Int
        value =
            clamp 0 255 (round (channel * 255))
    in
    hexDigitChar (value // 16) ++ hexDigitChar (modBy 16 value)


hexDigitChar : Int -> String
hexDigitChar n =
    if n < 10 then
        String.fromChar (Char.fromCode (0x30 + n))

    else
        String.fromChar (Char.fromCode (0x61 + n - 10))



-- SMALL HELPERS -------------------------------------------------------------


{-| Round to `places` decimals. The conversion is a chain of transcendental
functions, so the last few bits of a `Float` are noise; keeping four decimals of
lightness and chroma and two of hue is finer than any screen can show and keeps
the printed CSS short.
-}
roundTo : Int -> Float -> Float
roundTo places value =
    let
        scale : Float
        scale =
            toFloat (10 ^ places)
    in
    toFloat (round (value * scale)) / scale


normaliseHue : Float -> Float
normaliseHue degrees =
    if degrees < 0 then
        degrees + 360

    else
        degrees
