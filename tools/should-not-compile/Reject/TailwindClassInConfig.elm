-- Tries: pass a raw Tailwind/daisyUI class string ("alert-error") to a
-- config field that expects a typed schema value.
-- Proves: no `XConfig` record has a `String` class field anywhere. Every
-- exclusive-group field is a `Maybe <Group>` value from `Daisy.Schema.*`, so
-- a bare class name is a type error, never a valid value.


module Reject.TailwindClassInConfig exposing (value)

import Daisy.Tree as Tree exposing (..)


value : AlertConfig
value =
    { defaultAlertConfig | color = Just "alert-error" }
