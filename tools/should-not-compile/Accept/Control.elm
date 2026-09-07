-- The positive control. This is a minimal, valid `Page` built only through
-- `Daisy.Tree`, and it MUST compile. It exists so the runner can prove the
-- harness itself works: if this fixture ever fails to compile, something is
-- wrong with the temporary project setup (source-directories, dependencies),
-- not with the tree's type design, and every "rejected" result in the same
-- run becomes suspect.


module Accept.Control exposing (value)

import Daisy.Chart
import Daisy.Tree as Tree exposing (..)
import Html


value : Page ()
value =
    Page
        { header = Nothing
        , shell = Plain
        , sections =
            Sections1
                (Stack defaultStackConfig
                    [ Prose
                        [ Text "Hello"
                        , Embed { height = EmbedSm, label = "Custom" } drawing
                        ]
                    ]
                )
        , cta = cta "Save" ()
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }


{-| A `Leaf.Embed` in the one place it belongs: as a leaf. The control compiles,
so "an embed cannot be a block or a section" is a statement about the level, not
about `Embed` being unusable.
-}
drawing : ThemeContext -> Html.Html msg
drawing ctx =
    Html.text (ctx.color Daisy.Chart.Primary)
