-- Tries: reuse `CardParts` (the record that produces the `card-body` part)
-- as a `StatItem` inside an unrelated `Stat` block -- the closest
-- type-level shape to "use card-body outside a card", since there is no
-- `Raw Html` escape hatch to write the class directly.
-- Proves: a part-bearing record belongs to its own component only.
-- `CardParts` and `StatItem` are different record types, so `card-body`
-- cannot be produced anywhere except inside a `Card`.


module Reject.CardBodyOutsideCard exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Stat defaultStatConfig [ emptyCardParts ]
