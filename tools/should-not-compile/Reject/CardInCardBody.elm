-- Tries: put a `Block.Card` into another card's `body`, now that
-- `CardParts.body` is `List (CardChild msg)` and CardChild carries four block
-- shapes (chart, table, stat, form) besides `CardLeaf`.
-- Proves: widening the card body did not widen it to blocks in general. There
-- is no `CardCard` constructor, and the one constructor that takes a node --
-- `CardLeaf` -- takes a `Leaf msg`, so a `Block` cannot be smuggled through it.


module Reject.CardInCardBody exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Card defaultCardConfig
        { figure = Nothing
        , title = Just "Outer"
        , body = [ CardLeaf (Card defaultCardConfig emptyCardParts) ]
        , actions = []
        }
