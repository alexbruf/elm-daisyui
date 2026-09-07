module ColorTest exposing (suite)

{-| `Daisy.Color`: the sRGB <-> OKLCH conversion a colour picker needs to edit a
daisyUI theme.

Three claims, in order of how much they are worth:

1.  **Known values.** Black, white, the sRGB primaries and daisyUI's own
    `light` theme primary land where the published OKLab constants say they do.
    A matrix transcribed with a digit wrong passes a round-trip test and fails
    this one.
2.  **Round trips.** `hexToOklch >> oklchToHex` is the identity on every
    `#rrggbb`, and `oklchToHex >> hexToOklch` returns to the same colour for
    every in-gamut OKLCH. Both are fuzzed.
3.  **Printing.** `oklchToCss` writes exactly what daisyUI's theme sources
    write, so a theme read out of `vendor/daisyui` and printed back is
    byte-identical.

-}

import Daisy.Color as Color exposing (Oklch)
import Daisy.Themes as Themes
import Expect exposing (FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer)
import Test exposing (Test, describe, fuzz, test)


{-| A hex byte, as two lowercase digits.
-}
byteFuzzer : Fuzzer Int
byteFuzzer =
    Fuzz.intRange 0 255


hexFuzzer : Fuzzer String
hexFuzzer =
    Fuzz.map3 (\r g b -> "#" ++ hex2 r ++ hex2 g ++ hex2 b) byteFuzzer byteFuzzer byteFuzzer


hex2 : Int -> String
hex2 value =
    String.right 2 ("0" ++ baseSixteen value)


baseSixteen : Int -> String
baseSixteen value =
    if value < 16 then
        String.slice value (value + 1) "0123456789abcdef"

    else
        baseSixteen (value // 16) ++ baseSixteen (modBy 16 value)


{-| An OKLCH that is inside the sRGB gamut at **every** hue.

The box matters, and it is not arbitrary. OKLCH is much larger than sRGB — 151
of daisyUI's own 700 theme colours are outside it — and `oklchToHex` clamps
rather than failing, so a round trip through a colour no screen can show does
not come back. `L` 45..75 with `C` 0.03..0.05 was swept at a quarter-degree of
hue against an independent implementation: nothing in it clips, the lightness
comes back within 0.18 of a percent and the chroma within 0.002.

Hue is the loose coordinate, and only because it is an _angle_: one byte of sRGB
at `C = 0.03` is up to 3.5 degrees of it, while the colour it names is the same
to the eye. The greys, where hue stops meaning anything at all, are pinned
exactly instead — by the known-value tests above (all `c = 0`) and by the hex
round trip, which is exact for every one of the 16.7 million sRGB colours.

-}
inGamutFuzzer : Fuzzer Oklch
inGamutFuzzer =
    Fuzz.map3 (\l c h -> { l = l, c = c, h = h })
        (Fuzz.floatRange 45 75)
        (Fuzz.floatRange 0.03 0.05)
        (Fuzz.floatRange 0 359)


close : Float -> Float -> Float -> Expect.Expectation
close tolerance expected actual =
    Expect.within (Absolute tolerance) expected actual


{-| Hue is an angle, so `0` and `359.63` are 0.37 degrees apart, not 359.63.
Comparing them as plain numbers is the kind of assertion that fails on a
correct implementation.
-}
closeAngle : Float -> Float -> Float -> Expect.Expectation
closeAngle tolerance expected actual =
    let
        raw : Float
        raw =
            abs (expected - actual)
    in
    Expect.atMost tolerance (min raw (360 - raw))


expectOklch : { l : Float, c : Float, h : Float } -> Float -> Maybe Oklch -> Expect.Expectation
expectOklch expected tolerance actual =
    case actual of
        Nothing ->
            Expect.fail "hexToOklch returned Nothing for a well-formed colour"

        Just got ->
            Expect.all
                [ \g -> close tolerance expected.l g.l
                , \g -> close tolerance expected.c g.c
                , \g -> closeAngle (max tolerance 0.5) expected.h g.h
                ]
                got


{-| The round-trip assertion, which needs a looser hue than the known-value
tests do.

`oklchToHex` quantises to three sRGB bytes. At a chroma of 0.05 one byte of the
`a`/`b` pair is about four degrees of hue — the colour is the same to within a
byte, but the _angle_ naming it has moved. Lightness and chroma are held to a
tenth of a step, which is where a real error in the matrices would show.

-}
expectRoundTrip : Oklch -> Maybe Oklch -> Expect.Expectation
expectRoundTrip expected actual =
    case actual of
        Nothing ->
            Expect.fail "hexToOklch returned Nothing for a colour oklchToHex produced"

        Just got ->
            Expect.all
                [ \g -> close 0.3 expected.l g.l
                , \g -> close 0.005 expected.c g.c
                , \g -> closeAngle 4 expected.h g.h
                ]
                got


suite : Test
suite =
    describe "Daisy.Color"
        [ describe "known values"
            [ test "#ffffff is white: full lightness, no chroma" <|
                \_ ->
                    expectOklch { l = 100, c = 0, h = 0 } 0.01 (Color.hexToOklch "#ffffff")
            , test "#000000 is black: no lightness, no chroma" <|
                \_ ->
                    expectOklch { l = 0, c = 0, h = 0 } 0.01 (Color.hexToOklch "#000000")
            , test "#808080 is a mid grey with no chroma" <|
                \_ ->
                    case Color.hexToOklch "#808080" of
                        Just { l, c } ->
                            Expect.all
                                [ \_ -> close 0.3 59.99 l
                                , \_ -> close 1.0e-3 0 c
                                ]
                                ()

                        Nothing ->
                            Expect.fail "hexToOklch #808080 returned Nothing"
            , -- Ottosson's own worked example: sRGB red is
              -- oklch(62.80% 0.2577 29.23). Chrome reports the same numbers for
              -- `color(srgb 1 0 0)` converted to oklch.
              test "#ff0000 is oklch(62.8% 0.2577 29.23)" <|
                \_ ->
                    expectOklch { l = 62.7955, c = 0.2577, h = 29.23 } 0.02 (Color.hexToOklch "#ff0000")
            , test "#00ff00 is oklch(86.64% 0.2948 142.5)" <|
                \_ ->
                    expectOklch { l = 86.644, c = 0.2948, h = 142.5 } 0.02 (Color.hexToOklch "#00ff00")
            , test "#0000ff is oklch(45.2% 0.3132 264.05)" <|
                \_ ->
                    expectOklch { l = 45.201, c = 0.3132, h = 264.05 } 0.02 (Color.hexToOklch "#0000ff")
            , -- daisyUI's `light` theme primary, `oklch(45% 0.24 277.023)`, put
              -- through both directions. The hex is what a colour input would
              -- show for it, and converting that hex back must land on the same
              -- colour to within a byte of rounding.
              test "daisyUI light's primary survives OKLCH -> hex -> OKLCH" <|
                \_ ->
                    let
                        primary : Oklch
                        primary =
                            Themes.light.colors.primary
                    in
                    expectRoundTrip primary (Color.hexToOklch (Color.oklchToHex primary))
            , -- Cross-checked against an independent JavaScript implementation
              -- of Ottosson's inverse transform, not against this module.
              test "daisyUI light's primary is #422ad5" <|
                \_ ->
                    Expect.equal "#422ad5" (Color.oklchToHex Themes.light.colors.primary)
            ]
        , describe "parsing"
            [ test "the leading # is optional" <|
                \_ ->
                    Expect.equal (Color.hexToOklch "#ff0000") (Color.hexToOklch "ff0000")
            , test "uppercase digits are accepted" <|
                \_ ->
                    Expect.equal (Color.hexToOklch "#ff00aa") (Color.hexToOklch "#FF00AA")
            , test "three-digit shorthand is refused" <|
                \_ -> Expect.equal Nothing (Color.hexToOklch "#fff")
            , test "a non-hex digit is refused" <|
                \_ -> Expect.equal Nothing (Color.hexToOklch "#gggggg")
            , test "the empty string is refused" <|
                \_ -> Expect.equal Nothing (Color.hexToOklch "")
            ]
        , describe "round trips"
            [ fuzz hexFuzzer "hex -> OKLCH -> hex is the identity" <|
                \hex ->
                    Expect.equal (Just hex) (Maybe.map Color.oklchToHex (Color.hexToOklch hex))
            , fuzz inGamutFuzzer "an in-gamut OKLCH survives hex and back" <|
                \oklch ->
                    expectRoundTrip oklch (Color.hexToOklch (Color.oklchToHex oklch))
            , -- OKLCH is far larger than sRGB, and daisyUI itself uses colours
              -- outside it (151 of the 700 in `Daisy.Themes`). `oklchToHex`
              -- clamps each linear channel rather than failing, which is what a
              -- browser does with the same colour.
              test "an out-of-gamut OKLCH still produces six digits" <|
                \_ ->
                    Expect.equal 7 (String.length (Color.oklchToHex { l = 70, c = 0.9, h = 120 }))
            , test "every built-in theme colour prints as six digits" <|
                \_ ->
                    Themes.all
                        |> List.concatMap (\theme -> [ theme.colors.primary, theme.colors.base100, theme.colors.error ])
                        |> List.map (Color.oklchToHex >> String.length)
                        |> List.filter ((/=) 7)
                        |> Expect.equalLists []
            ]
        , describe "printing"
            [ test "oklchToCss writes daisyUI's own spelling" <|
                \_ ->
                    Expect.equal "oklch(62% 0.265 303.9)"
                        (Color.oklchToCss { l = 62, c = 0.265, h = 303.9 })
            , test "a grey prints without trailing zeros" <|
                \_ ->
                    Expect.equal "oklch(98% 0 0)" (Color.oklchToCss { l = 98, c = 0, h = 0 })
            , test "a fractional lightness prints in full" <|
                \_ ->
                    Expect.equal "oklch(11.784% 0.015 254.027)"
                        (Color.oklchToCss { l = 11.784, c = 0.015, h = 254.027 })
            ]
        ]
