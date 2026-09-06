-- Tries: put a `Modal` overlay inside a `Prose` block's leaf list.
-- Proves: overlays can only ever appear in `Page.overlays`. `Modal` is an
-- `Overlay` constructor, not a `Leaf`, so it cannot be nested inside any
-- block.


module Reject.ModalInsideBlock exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Prose [ Modal defaultModalConfig [] ]
