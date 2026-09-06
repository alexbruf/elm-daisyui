-- Tries: put a Section (`Hero`) into a `Prose` block's leaf list.
-- Proves: a section can never nest inside a block. Every Block constructor's
-- children are `List (Leaf msg)`, `List (Row msg)`, etc. -- never a `Section`.


module Reject.SectionInBlock exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Prose [ Hero defaultHeroConfig [] ]
