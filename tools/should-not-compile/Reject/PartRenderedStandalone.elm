-- Tries: use a `CardParts` record directly as a `Block` value, i.e. render
-- a card's parts standalone in a section without the `Card` wrapper.
-- Proves: a part record is not itself a node. `CardParts msg` and `Block
-- msg` are different types; the parts of a card can only ever reach the
-- page through the `Card` constructor that owns them.


module Reject.PartRenderedStandalone exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    emptyCardParts
