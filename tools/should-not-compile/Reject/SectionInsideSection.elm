-- Tries: nest a `Stack` section directly inside a `Grid` section's block
-- list.
-- Proves: sections cannot contain other sections. Every `Section`
-- constructor's children are `List (Block msg)` (or, for `Navbar`, leaves),
-- never a `Section`, so this is rejected the same way as any other section
-- appearing where a block is expected.


module Reject.SectionInsideSection exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Section msg
value =
    Grid defaultGridConfig [ Stack defaultStackConfig [] ]
