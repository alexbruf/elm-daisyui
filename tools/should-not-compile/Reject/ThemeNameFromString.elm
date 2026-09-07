-- Tries: build a `Theme.Custom` whose `name` is a raw `String` ("acme")
-- rather than a `ThemeName` from the `Daisy.Tree.themeName` smart constructor.
-- Proves: a theme name cannot bypass validation. `ThemeName` is opaque -- the
-- module exposes the type but not its constructor -- so there is no literal a
-- caller can write in that field. The name is either one `themeName` accepted
-- (matching `[a-z][a-z0-9-]*` and not one of the 35 reserved built-ins) or one
-- `themeNameOf` read back off a built-in. `Just "acme"` is not a name; it is a
-- type error.


module Reject.ThemeNameFromString exposing (value)

import Daisy.Themes as Themes
import Daisy.Tree as Tree exposing (..)


value : Theme
value =
    let
        base : CustomTheme
        base =
            Themes.nord
    in
    Custom { base | name = "acme" }
