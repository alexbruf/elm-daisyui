-- Tries: use a `Block` (`Prose`) as a form field's control, where a `Leaf`
-- is expected.
-- Proves: a `Field`'s `control` is typed `Leaf msg`, so a block can never
-- stand in for a leaf -- nesting only ever narrows (Page > Section > Block >
-- Leaf), never widens back up.


module Reject.BlockInsideLeaf exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Field msg
value =
    field "Info" (Prose [])
