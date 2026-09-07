-- Tries: nest a second Card inside the first Card's `body` (its only List
-- child slot, via CardParts.body : List (CardChild msg)).
-- Proves: cards cannot be nested. `Card` is a `Block` constructor and
-- `CardChild` has no `CardCard`, so it cannot occupy any part of `CardParts`
-- -- there is no slot in the tree where a card can hold another card.
-- See also Reject/CardInCardBody.elm, which tries the same thing through
-- `CardLeaf`.


module Reject.CardInCard exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Card defaultCardConfig
        { figure = Nothing
        , title = Just "Outer"
        , body = [ Card defaultCardConfig emptyCardParts ]
        , actions = []
        }
