-- Tries: place a raw `Html.Html msg` node where a `Leaf` is expected.
-- Proves: there is no `Raw Html` constructor anywhere in the tree. Elm's
-- `Html` type is not a `Leaf`, so a hand-built node can never be smuggled
-- into a page. Custom `Html` has exactly one door, `Leaf.Embed`, and it is a
-- door with a frame: the node has to be produced by a
-- `ThemeContext -> Html msg` carried in an `Embed` beside its config, and the
-- renderer draws it inside a fixed, clipped, labelled box. A bare `Html` value
-- like this one still has nowhere to go. See Reject/EmbedAsBlock.elm for the
-- other half: an embed cannot climb the tree either.


module Reject.RawHtmlAsLeaf exposing (value)

import Daisy.Tree as Tree exposing (..)
import Html


value : Block msg
value =
    Prose [ Html.text "raw" ]
