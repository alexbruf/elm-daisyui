-- Tries: place a raw `Html.Html msg` node where a `Leaf` is expected.
-- Proves: there is no `Raw Html` escape hatch anywhere in the tree. Elm's
-- `Html` type is not a `Leaf`, so a hand-built node can never be smuggled
-- into a page.


module Reject.RawHtmlAsLeaf exposing (value)

import Daisy.Tree as Tree exposing (..)
import Html


value : Block msg
value =
    Prose [ Html.text "raw" ]
