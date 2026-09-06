-- Tries: use `dropdown` as if it were a `Leaf` node constructor
-- (`DropdownLeaf`), the way a developer used to other component libraries
-- might expect a dropdown to be an addressable element.
-- Proves: `dropdown` is only ever a property on a leaf's config
-- (`ButtonConfig.dropdown`, `LinkConfig.dropdown`, ...), never a node of its
-- own. No such `Leaf` constructor exists, so this fails as an unresolved
-- name rather than a type mismatch.


module Reject.DropdownAsNode exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Leaf msg
value =
    DropdownLeaf defaultDropdownConfig
