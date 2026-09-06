-- Tries: put a `Drawer` overlay inside a `Stack` section's block list.
-- Proves: overlays never nest inside a section either. `Drawer` is an
-- `Overlay` constructor, not a `Block`, so a section's children can never
-- include one.


module Reject.DrawerInsideSection exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Section msg
value =
    Stack defaultStackConfig [ Drawer defaultDrawerConfig [] ]
