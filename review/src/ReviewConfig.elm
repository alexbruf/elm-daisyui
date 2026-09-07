module ReviewConfig exposing (config)

{-| elm-review configuration for elm-daisyui (SPEC.md step 5 / CLAUDE.md
"Tooling rules"). Three custom rules, each with its own module and rule
tests under review/src and review/tests:

  - NoClassOutsideRender: only src/Daisy/Render.elm may call
    Html.Attributes.class / classList / attribute "class" ...
  - NoHtmlInDemo: demo/src modules may not import Html/Html.\*/Svg/Svg.\*,
    except Main, which may bare-import Html only, and demo/src/Viz/, which
    holds the `Leaf.Embed` view functions and so writes Html/Svg by
    definition. NoClassOutsideRender and NoRawSchemaStrings still apply
    there, so an embed cannot reach a daisyUI class.
  - NoRawSchemaStrings: no string literal may exactly equal a daisyUI class
    from fixtures/schema.json, outside Daisy.Schema/Daisy.Schema.\*/Daisy.Render.

This config is used from two places (see CLAUDE.md "Commands"):

  - `elm-review` from the repo root, reviewing the package's `src/`.
  - `elm-review --config ../review`, run from inside `demo/`, reviewing
    `demo/src` plus the library's `../src` (demo/elm.json lists both as
    source-directories).

`review/`, `vendor/` and `demo/elm-stuff` are excluded from every rule since
none of them are code we own or lint (review/ is this project's own
tooling, vendor/daisyui is the read-only oracle, elm-stuff is build cache).
`tests/` (spelled `../tests/` as well, because the run from inside `demo/`
reports the package's test files through that relative path) is excluded from
NoRawSchemaStrings only: test fixtures
legitimately assert against literal daisyUI class strings as oracles (e.g.
`"card-body"` in PartsTest), which is exactly what that rule otherwise
forbids; the other two rules still apply inside tests/.

-}

import NoClassOutsideRender
import NoHtmlInDemo
import NoRawSchemaStrings
import Review.Rule as Rule exposing (Rule)


config : List Rule
config =
    [ NoClassOutsideRender.rule
    , NoHtmlInDemo.rule
    , NoRawSchemaStrings.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/", "../tests/" ]
    ]
        |> List.map
            (Rule.ignoreErrorsForDirectories
                [ "review/"
                , "vendor/"
                , "demo/elm-stuff/"
                , "elm-stuff/"
                ]
            )
