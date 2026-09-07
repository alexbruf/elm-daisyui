-- The positive control. This is a minimal, valid `Page` built only through
-- `Daisy.Tree`, and it MUST compile. It exists so the runner can prove the
-- harness itself works: if this fixture ever fails to compile, something is
-- wrong with the temporary project setup (source-directories, dependencies),
-- not with the tree's type design, and every "rejected" result in the same
-- run becomes suspect.


module Accept.Control exposing (value)

import Daisy.Tree as Tree exposing (..)


value : Page ()
value =
    Page
        { header = Nothing
        , shell = Plain
        , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "Hello" ] ])
        , cta = cta "Save" ()
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }
