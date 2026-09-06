-- Tries: give a button both `btn-sm` and `btn-lg` by writing `size` as a
-- list of sizes, the way a developer reaching for "two sizes at once" would
-- naturally generalize `Maybe Size` to `List Size`.
-- Proves: `ButtonConfig.size` is `Maybe SButton.Size`, a pick-at-most-one
-- slot. There is no way to attach two size classes to one button.


module Reject.TwoSizesOnButton exposing (value)

import Daisy.Schema.Button as SButton
import Daisy.Tree as Tree exposing (..)


value : Leaf msg
value =
    Button { defaultButtonConfig | size = [ SButton.Sm, SButton.Lg ] } "Click"
