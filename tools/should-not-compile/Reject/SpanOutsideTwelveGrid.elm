-- Tries: put a `GridItem` -- a cell with a `col-span` -- into a `Columns`
-- grid, which is the equal-track one.
-- Proves: a span is only meaningful in the twelve-column grid, and that is a
-- type-level fact rather than a convention. `Section.Grid` takes a closed
-- `GridSection`: `Columns GridConfig (List (Block msg))` for equal tracks and
-- `Spans (List (GridItem msg))` for the twelve. A cell that says how many of
-- twelve it takes therefore cannot appear in a grid that has four.


module Reject.SpanOutsideTwelveGrid exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Section msg
value =
    Grid
        (Columns { columns = Cols4 }
            [ span Span7 (Prose [ Text "seven of four?" ]) ]
        )
