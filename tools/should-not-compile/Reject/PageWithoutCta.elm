-- Tries: build a `Page` record with no `cta` field at all.
-- Proves: `cta` is mandatory on every page, not merely conventional. Elm's
-- exhaustive record check reports the missing field as a type mismatch on
-- the whole record, since `Page`'s argument is a fixed, non-extensible
-- record type.


module Reject.PageWithoutCta exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Page ()
value =
    Page
        { shell = Plain
        , sections = Sections1 (Stack defaultStackConfig [])
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }
