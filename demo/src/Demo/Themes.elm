module Demo.Themes exposing (acme, acmeName, named, rename, startingPoints)

{-| The demo's own theme, and the two lookups the router and the theme
generator need around it.

[`acme`](#acme) is a `Daisy.Tree.CustomTheme` — a theme daisyUI does not ship —
and it is the demo's default. It reaches the page through
`Daisy.Render.page`, which writes its twenty-nine declarations onto the page
root as inline CSS custom properties; there is no `@plugin "daisyui/theme"`
block for it anywhere in `demo/app.css`, and there does not need to be. See
`docs/tree-decisions.md`, "Custom themes and the generator page".

The values are the ones the daisyUI theme generator produced for this palette,
transcribed field for field: `oklch(62% 0.265 303.9)` becomes
`{ l = 62, c = 0.265, h = 303.9 }`.

@docs acme, acmeName, named, rename, startingPoints

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
        , ThemeName
        )


{-| The demo's default theme.
-}
acme : CustomTheme
acme =
    { name = acmeName
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


{-| `acme`, as a validated [`ThemeName`](Daisy-Tree#ThemeName).

`Daisy.Tree.themeName` returns a `Maybe`, because it refuses a malformed name
and every one of daisyUI's thirty-five reserved ones. `"acme"` is neither, so
the fallback below is unreachable — but the compiler does not know that, and the
alternative would be a `Maybe` threaded through every call site of a value that
is a constant. The fallback is deliberately the _same_ string wrapped through
the only other constructor available, so a mistake here would show up as
`data-theme="light"` and not as a page that silently renders untidy.

-}
acmeName : ThemeName
acmeName =
    Maybe.withDefault (Tree.themeNameOf Light) (Tree.themeName "acme")


{-| The theme a `?theme=<name>` query string selects: any of daisyUI's
thirty-five, or `acme`.

    named "nord" --> Just Nord

    named "acme" --> Just (Custom acme)

    named "nope" --> Nothing

-}
named : String -> Maybe Theme
named name =
    if name == Tree.themeNameToString acmeName then
        Just (Custom acme)

    else
        Tree.allThemes
            |> List.filter (\theme -> Tree.themeToString theme == name)
            |> List.head


{-| Any theme as an editable `CustomTheme` under the demo's own name.

This is what "start from `nord`" means on the generator page: take the
built-in's twenty-nine values and give them a name daisyUI has not reserved, so
the result is a theme of ours rather than a copy of daisyUI's rule. Renaming is
also what makes the generator page prove its point — `data-theme="acme"` matches
no stylesheet rule at all, so every colour on it can only have come from the
inline properties.

-}
rename : Theme -> CustomTheme
rename theme =
    let
        base : CustomTheme
        base =
            case theme of
                Custom custom ->
                    custom

                builtin ->
                    Maybe.withDefault acme (Themes.builtinToCustom builtin)
    in
    { base | name = acmeName }


{-| What the generator's "Start from" `Select` offers: `acme` first, then all
thirty-five built-ins in daisyUI's order.
-}
startingPoints : List Theme
startingPoints =
    Custom acme :: Tree.allThemes
