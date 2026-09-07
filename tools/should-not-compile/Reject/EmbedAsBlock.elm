-- Tries: place a `Leaf.Embed` where a `Block` is expected, and again where a
-- `Section` is expected.
-- Proves: `Leaf.Embed` is the escape hatch for *custom drawing*, not for
-- custom structure. It is a `Leaf`, so it can only ever sit where a leaf sits:
-- an embed cannot become a band of the page, cannot hold blocks, sections or
-- overlays, and cannot take the place of one. The renderer's fixed box is
-- therefore always between it and the rest of the page.


module Reject.EmbedAsBlock exposing (asBlock, asSection)

import Daisy.Tree as Tree exposing (..)
import Html


drawing : ThemeContext -> Html.Html msg
drawing _ =
    Html.text "custom"


asBlock : Section msg
asBlock =
    Stack defaultStackConfig
        [ Embed { height = EmbedMd, label = "Custom" } drawing ]


asSection : Sections msg
asSection =
    Sections1 (Embed { height = EmbedMd, label = "Custom" } drawing)
