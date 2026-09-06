-- Tries: use `tooltip` as if it were a `Leaf` node constructor
-- (`TooltipLeaf`).
-- Proves: like `dropdown`, `tooltip` is only ever a property on a leaf's
-- config (e.g. `ButtonConfig.tooltip`), never a node. No such `Leaf`
-- constructor exists, so this fails as an unresolved name rather than a
-- type mismatch.


module Reject.TooltipAsNode exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Leaf msg
value =
    TooltipLeaf defaultTooltipConfig "hi"
