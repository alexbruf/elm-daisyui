-- Tries: give one page record two `cta` fields, the direct way a developer
-- reaching for "two primary buttons" would attempt it at the `Page` level.
-- Proves: `Page` has exactly one `cta` slot. A record literal cannot carry
-- the same field twice, so "two CTAs on a page" has no representation.


module Reject.TwoCtas exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Page ()
value =
    Page
        { shell = Plain
        , sections = Sections1 (Stack defaultStackConfig [])
        , cta = cta "Buy" ()
        , cta = cta "Also buy" ()
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }
