module ThemeTest exposing (suite)

{-| `Daisy.Tree`'s custom-theme half, and the generated `Daisy.Themes` table.

The claims:

1.  **`ThemeName` is closed.** The only way to build one for a new theme is
    `themeName`, and it refuses everything daisyUI's `data-theme` selector and
    `@plugin` block cannot carry — including all thirty-five reserved names.
2.  **The property list is exactly daisyUI's.** Twenty-nine declarations, in
    daisyUI's own order, spelled the way its theme sources spell them.
3.  **`Daisy.Themes` round-trips the oracle.** Every one of the thirty-five
    generated themes prints back the CSS
    `vendor/daisyui/packages/daisyui/src/themes/<name>.css` declares, which is
    what makes "start from a built-in" honest.
4.  **The JSON is daisyUI's generator's own shape**, so the `#theme=` link a
    caller builds from it opens the theme rather than a default.

-}

import Daisy.Themes as Themes
import Daisy.Tree as Tree
    exposing
        ( Border(..)
        , ColorScheme(..)
        , CustomTheme
        , Radius(..)
        , Size(..)
        , Theme(..)
        )
import Expect
import Set
import Test exposing (Test, describe, test)


{-| A theme with every value distinct from `light`'s, so a wrong field would
show up as a wrong string rather than as a coincidence.
-}
sample : CustomTheme
sample =
    { name = Maybe.withDefault (Tree.themeNameOf Light) (Tree.themeName "acme")
    , colorScheme = LightScheme
    , colors =
        { base100 = { l = 98, c = 0, h = 0 }
        , base200 = { l = 97, c = 0, h = 0 }
        , base300 = { l = 92, c = 0, h = 0 }
        , baseContent = { l = 20, c = 0, h = 0 }
        , primary = { l = 62, c = 0.265, h = 303.9 }
        , primaryContent = { l = 98, c = 0.031, h = 120.757 }
        , secondary = { l = 76, c = 0.188, h = 70.08 }
        , secondaryContent = { l = 98, c = 0.022, h = 95.277 }
        , accent = { l = 71, c = 0.203, h = 305.504 }
        , accentContent = { l = 98, c = 0.031, h = 120.757 }
        , neutral = { l = 20, c = 0, h = 0 }
        , neutralContent = { l = 98, c = 0, h = 0 }
        , info = { l = 58, c = 0.158, h = 241.966 }
        , infoContent = { l = 97, c = 0.013, h = 236.62 }
        , success = { l = 62, c = 0.194, h = 149.214 }
        , successContent = { l = 98, c = 0.018, h = 155.826 }
        , warning = { l = 64, c = 0.222, h = 41.116 }
        , warningContent = { l = 98, c = 0.016, h = 73.684 }
        , error = { l = 57, c = 0.245, h = 27.325 }
        , errorContent = { l = 97, c = 0.013, h = 17.38 }
        }
    , radius = { selector = RadiusXs, field = RadiusXs, box = RadiusSm }
    , size = { selector = SizeMd, field = SizeMd }
    , border = BorderThin
    , depth = False
    , noise = False
    }


{-| The twenty-nine property names daisyUI's own theme files declare, in the
order they declare them. Written out rather than derived, so this is an oracle
and not a restatement of the implementation.
-}
expectedProperties : List String
expectedProperties =
    [ "color-scheme"
    , "--color-base-100"
    , "--color-base-200"
    , "--color-base-300"
    , "--color-base-content"
    , "--color-primary"
    , "--color-primary-content"
    , "--color-secondary"
    , "--color-secondary-content"
    , "--color-accent"
    , "--color-accent-content"
    , "--color-neutral"
    , "--color-neutral-content"
    , "--color-info"
    , "--color-info-content"
    , "--color-success"
    , "--color-success-content"
    , "--color-warning"
    , "--color-warning-content"
    , "--color-error"
    , "--color-error-content"
    , "--radius-selector"
    , "--radius-field"
    , "--radius-box"
    , "--size-selector"
    , "--size-field"
    , "--border"
    , "--depth"
    , "--noise"
    ]


suite : Test
suite =
    describe "custom themes"
        [ describe "ThemeName"
            [ test "a well-formed name is accepted" <|
                \_ ->
                    Expect.equal (Just "acme") (Maybe.map Tree.themeNameToString (Tree.themeName "acme"))
            , test "digits and hyphens are accepted after the first letter" <|
                \_ ->
                    Expect.equal (Just "acme-2-dark")
                        (Maybe.map Tree.themeNameToString (Tree.themeName "acme-2-dark"))
            , test "an uppercase letter is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "Acme")
            , test "a leading digit is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "1acme")
            , test "a leading hyphen is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "-acme")
            , test "a space is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "acme corp")
            , test "an underscore is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "acme_corp")
            , test "the empty string is refused" <|
                \_ -> Expect.equal Nothing (Tree.themeName "")
            , test "all 35 built-in names are reserved" <|
                \_ ->
                    Tree.allThemes
                        |> List.filter (\theme -> Tree.themeName (Tree.themeToString theme) /= Nothing)
                        |> List.map Tree.themeToString
                        |> Expect.equalLists []
            , test "themeNameOf reaches a built-in's reserved name anyway" <|
                \_ ->
                    Expect.equal "caramellatte"
                        (Tree.themeNameToString (Tree.themeNameOf Caramellatte))
            ]
        , describe "themeToString"
            [ test "a Custom theme answers to its own name" <|
                \_ -> Expect.equal "acme" (Tree.themeToString (Custom sample))
            , test "the 35 built-in names are distinct" <|
                \_ ->
                    Expect.equal 35
                        (Set.size (Set.fromList (List.map Tree.themeToString Tree.allThemes)))
            , test "allThemes stays the 35 built-ins" <|
                \_ -> Expect.equal 35 (List.length Tree.allThemes)
            ]
        , describe "customThemeProperties"
            [ test "declares exactly daisyUI's twenty-nine properties, in order" <|
                \_ ->
                    Expect.equalLists expectedProperties
                        (List.map Tuple.first (Tree.customThemeProperties sample))
            , test "colours are written as daisyUI writes them" <|
                \_ ->
                    Tree.customThemeProperties sample
                        |> List.filter (\( property, _ ) -> property == "--color-primary")
                        |> Expect.equalLists [ ( "--color-primary", "oklch(62% 0.265 303.9)" ) ]
            , test "the two effect switches are 0 or 1, never true or false" <|
                \_ ->
                    Tree.customThemeProperties { sample | depth = True, noise = False }
                        |> List.filter (\( property, _ ) -> property == "--depth" || property == "--noise")
                        |> Expect.equalLists [ ( "--depth", "1" ), ( "--noise", "0" ) ]
            ]
        , describe "customThemeStyle"
            [ test "is the same declarations as one style attribute value" <|
                \_ ->
                    Expect.equal
                        (String.join ";"
                            (List.map (\( p, v ) -> p ++ ":" ++ v) (Tree.customThemeProperties sample))
                        )
                        (Tree.customThemeStyle sample)
            , test "carries no line break, so it is one attribute" <|
                \_ ->
                    Expect.equal 1 (List.length (String.lines (Tree.customThemeStyle sample)))
            ]
        , describe "customThemeToCss"
            [ test "is the @plugin block daisyUI's docs ask for" <|
                \_ ->
                    Expect.equal
                        (String.join "\n"
                            ([ "@plugin \"daisyui/theme\" {"
                             , "  name: \"acme\";"
                             , "  default: false;"
                             , "  prefersdark: false;"
                             , "  color-scheme: light;"
                             ]
                                ++ List.map
                                    (\( p, v ) -> "  " ++ p ++ ": " ++ v ++ ";")
                                    (List.drop 1 (Tree.customThemeProperties sample))
                                ++ [ "}" ]
                            )
                        )
                        (Tree.customThemeToCss sample)
            , test "is 34 lines: the header, the four keys, 29 declarations, the brace" <|
                \_ -> Expect.equal 34 (List.length (String.lines (Tree.customThemeToCss sample)))
            , test "contains no daisyUI class" <|
                \_ ->
                    Tree.customThemeToCss sample
                        |> String.contains "btn"
                        |> Expect.equal False
            ]
        , describe "customThemeToJson"
            [ test "is daisyUI's generator shape, byte for byte" <|
                \_ ->
                    Expect.equal
                        ("{\"name\":\"acme\",\"color-scheme\":\"light\""
                            ++ ",\"--color-base-100\":\"oklch(98% 0 0)\""
                            ++ ",\"--color-base-200\":\"oklch(97% 0 0)\""
                            ++ ",\"--color-base-300\":\"oklch(92% 0 0)\""
                            ++ ",\"--color-base-content\":\"oklch(20% 0 0)\""
                            ++ ",\"--color-primary\":\"oklch(62% 0.265 303.9)\""
                            ++ ",\"--color-primary-content\":\"oklch(98% 0.031 120.757)\""
                            ++ ",\"--color-secondary\":\"oklch(76% 0.188 70.08)\""
                            ++ ",\"--color-secondary-content\":\"oklch(98% 0.022 95.277)\""
                            ++ ",\"--color-accent\":\"oklch(71% 0.203 305.504)\""
                            ++ ",\"--color-accent-content\":\"oklch(98% 0.031 120.757)\""
                            ++ ",\"--color-neutral\":\"oklch(20% 0 0)\""
                            ++ ",\"--color-neutral-content\":\"oklch(98% 0 0)\""
                            ++ ",\"--color-info\":\"oklch(58% 0.158 241.966)\""
                            ++ ",\"--color-info-content\":\"oklch(97% 0.013 236.62)\""
                            ++ ",\"--color-success\":\"oklch(62% 0.194 149.214)\""
                            ++ ",\"--color-success-content\":\"oklch(98% 0.018 155.826)\""
                            ++ ",\"--color-warning\":\"oklch(64% 0.222 41.116)\""
                            ++ ",\"--color-warning-content\":\"oklch(98% 0.016 73.684)\""
                            ++ ",\"--color-error\":\"oklch(57% 0.245 27.325)\""
                            ++ ",\"--color-error-content\":\"oklch(97% 0.013 17.38)\""
                            ++ ",\"--radius-selector\":\"0.25rem\""
                            ++ ",\"--radius-field\":\"0.25rem\""
                            ++ ",\"--radius-box\":\"0.5rem\""
                            ++ ",\"--size-selector\":\"0.25rem\""
                            ++ ",\"--size-field\":\"0.25rem\""
                            ++ ",\"--border\":\"1px\""
                            ++ ",\"--depth\":\"0\""
                            ++ ",\"--noise\":\"0\""
                            ++ ",\"default\":false,\"prefersdark\":false}"
                        )
                        (Tree.customThemeToJson sample)
            ]
        , describe "Daisy.Themes"
            [ test "has one value per built-in theme" <|
                \_ -> Expect.equal 35 (List.length Themes.all)
            , test "builtinToCustom answers for every built-in" <|
                \_ ->
                    Tree.allThemes
                        |> List.filter (\theme -> Themes.builtinToCustom theme == Nothing)
                        |> List.map Tree.themeToString
                        |> Expect.equalLists []
            , test "builtinToCustom refuses a Custom theme" <|
                \_ -> Expect.equal Nothing (Themes.builtinToCustom (Custom sample))
            , test "each theme keeps its own reserved name" <|
                \_ ->
                    Tree.allThemes
                        |> List.filterMap
                            (\theme ->
                                Themes.builtinToCustom theme
                                    |> Maybe.map
                                        (\custom ->
                                            ( Tree.themeToString theme
                                            , Tree.themeNameToString custom.name
                                            )
                                        )
                            )
                        |> List.filter (\( expected, actual ) -> expected /= actual)
                        |> Expect.equalLists []
            , -- The oracle: daisyUI's `light.css` verbatim, as one string. If
              -- `tools/gen-themes.js` mis-parsed a value or `customThemeToCss`
              -- mis-printed one, these two stop matching.
              test "light prints back the declarations of light.css" <|
                \_ ->
                    Expect.equal lightCss
                        (String.join "\n"
                            (List.map
                                (\( p, v ) -> p ++ ": " ++ v ++ ";")
                                (Tree.customThemeProperties Themes.light)
                            )
                        )
            , test "every theme declares all 29 properties" <|
                \_ ->
                    Themes.all
                        |> List.map (Tree.customThemeProperties >> List.length)
                        |> List.filter ((/=) 29)
                        |> Expect.equalLists []
            , test "the 35 generated names are the 35 built-in names" <|
                \_ ->
                    Expect.equalLists
                        (List.map Tree.themeToString Tree.allThemes)
                        (List.map (.name >> Tree.themeNameToString) Themes.all)
            ]
        ]


{-| `vendor/daisyui/packages/daisyui/src/themes/light.css`, verbatim.
-}
lightCss : String
lightCss =
    String.join "\n"
        [ "color-scheme: light;"
        , "--color-base-100: oklch(100% 0 0);"
        , "--color-base-200: oklch(98% 0 0);"
        , "--color-base-300: oklch(95% 0 0);"
        , "--color-base-content: oklch(21% 0.006 285.885);"
        , "--color-primary: oklch(45% 0.24 277.023);"
        , "--color-primary-content: oklch(93% 0.034 272.788);"
        , "--color-secondary: oklch(65% 0.241 354.308);"
        , "--color-secondary-content: oklch(94% 0.028 342.258);"
        , "--color-accent: oklch(77% 0.152 181.912);"
        , "--color-accent-content: oklch(38% 0.063 188.416);"
        , "--color-neutral: oklch(14% 0.005 285.823);"
        , "--color-neutral-content: oklch(92% 0.004 286.32);"
        , "--color-info: oklch(74% 0.16 232.661);"
        , "--color-info-content: oklch(29% 0.066 243.157);"
        , "--color-success: oklch(76% 0.177 163.223);"
        , "--color-success-content: oklch(37% 0.077 168.94);"
        , "--color-warning: oklch(82% 0.189 84.429);"
        , "--color-warning-content: oklch(41% 0.112 45.904);"
        , "--color-error: oklch(71% 0.194 13.428);"
        , "--color-error-content: oklch(27% 0.105 12.094);"
        , "--radius-selector: 0.5rem;"
        , "--radius-field: 0.25rem;"
        , "--radius-box: 0.5rem;"
        , "--size-selector: 0.25rem;"
        , "--size-field: 0.25rem;"
        , "--border: 1px;"
        , "--depth: 1;"
        , "--noise: 0;"
        ]
