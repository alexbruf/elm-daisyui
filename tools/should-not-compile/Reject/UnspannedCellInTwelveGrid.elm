-- Tries: put a bare `Block` into the twelve-column grid, i.e. a cell that does
-- not say how wide it is.
-- Proves: the other half of the same rule. Every child of a `Spans` grid must
-- be a `GridItem`, so "twelve tracks and a cell of unstated width" is
-- unrepresentable -- there is no default span to fall back on and no runtime
-- check to forget.


module Reject.UnspannedCellInTwelveGrid exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Section msg
value =
    Grid (Spans [ Prose [ Text "how wide?" ] ])
