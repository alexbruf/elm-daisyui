-- Tries: put a `Toast` overlay inside a `Prose` block's leaf list.
-- Proves: like `Modal` and `Drawer`, `Toast` can only live in
-- `Page.overlays`; it is an `Overlay` constructor, never a `Leaf`.


module Reject.ToastInsideBlock exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Block msg
value =
    Prose [ Toast defaultToastConfig [] ]
