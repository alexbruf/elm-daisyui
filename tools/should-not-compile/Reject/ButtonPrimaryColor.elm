-- Tries: give a `Button` leaf the color `Primary`, reaching for
-- `Daisy.Schema.Button.Primary` because `Daisy.Tree.ButtonColor` -- the type
-- `ButtonConfig.color` actually expects -- has no `Primary` constructor.
-- Proves: a `Button` leaf can never render `btn-primary`. The page's only
-- primary call to action is `Page.cta`, which uses the schema color directly.


module Reject.ButtonPrimaryColor exposing (value)

import Daisy.Schema.Button as SButton
import Daisy.Tree as Tree exposing (..)


value : Leaf msg
value =
    Button { defaultButtonConfig | color = Just SButton.Primary } "Buy now"
