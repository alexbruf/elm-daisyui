-- Tries: give a page zero sections by passing an empty list where a
-- `Sections msg` is expected, the natural way a developer would reach for
-- "no sections".
-- Proves: `Sections` has no zero-arity constructor. `Page.sections` must be
-- one of `Sections1` .. `Sections5`, so an empty page is unrepresentable.


module Reject.ZeroSections exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Page ()
value =
    Page
        { header = Nothing
        , shell = Plain
        , sections = []
        , cta = cta "Save" ()
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }
