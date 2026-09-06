module NoHtmlInDemoTest exposing (suite)

import NoHtmlInDemo exposing (rule)
import Review.Project as Project exposing (Project)
import Review.Test
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "NoHtmlInDemo"
        [ describe "reports (positive cases)"
            [ test "Demo.* module importing Html is reported" <|
                \() ->
                    """module Demo.Admin exposing (view)

import Html


view : Html.Html msg
view =
    Html.text "hi"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`import Html` is not allowed in demo/src"
                                , details =
                                    [ "Demo apps are built only through Daisy.Tree, rendered by Daisy.Render.page. The router (Main) is the sole exception and may `import Html` bare (for its view/Program type signatures and to call Daisy.Render.page) -- never Html.Attributes, another Html.* submodule, or Svg."
                                    ]
                                , under = "Html"
                                }
                                |> Review.Test.atExactly { start = { row = 3, column = 8 }, end = { row = 3, column = 12 } }
                            ]
            , test "Main importing Html.Attributes is reported (only bare Html is allowed)" <|
                \() ->
                    """module Main exposing (main)

import Html.Attributes


main : Html.Attributes.Attribute msg
main =
    Html.Attributes.class "nope"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`import Html.Attributes` is not allowed in demo/src"
                                , details =
                                    [ "Demo apps are built only through Daisy.Tree, rendered by Daisy.Render.page. The router (Main) is the sole exception and may `import Html` bare (for its view/Program type signatures and to call Daisy.Render.page) -- never Html.Attributes, another Html.* submodule, or Svg."
                                    ]
                                , under = "Html.Attributes"
                                }
                                |> Review.Test.atExactly { start = { row = 3, column = 8 }, end = { row = 3, column = 23 } }
                            ]
            , test "Demo.* module importing Svg is reported" <|
                \() ->
                    """module Demo.Analytics exposing (icon)

import Svg


icon : Svg.Svg msg
icon =
    Svg.svg [] []
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`import Svg` is not allowed in demo/src"
                                , details =
                                    [ "Demo apps are built only through Daisy.Tree, rendered by Daisy.Render.page. The router (Main) is the sole exception and may `import Html` bare (for its view/Program type signatures and to call Daisy.Render.page) -- never Html.Attributes, another Html.* submodule, or Svg."
                                    ]
                                , under = "Svg"
                                }
                                |> Review.Test.atExactly { start = { row = 3, column = 8 }, end = { row = 3, column = 11 } }
                            ]
            , test "Demo.* module importing Svg.Attributes is reported" <|
                \() ->
                    """module Demo.Settings exposing (icon)

import Svg.Attributes


icon : String
icon =
    ""
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`import Svg.Attributes` is not allowed in demo/src"
                                , details =
                                    [ "Demo apps are built only through Daisy.Tree, rendered by Daisy.Render.page. The router (Main) is the sole exception and may `import Html` bare (for its view/Program type signatures and to call Daisy.Render.page) -- never Html.Attributes, another Html.* submodule, or Svg."
                                    ]
                                , under = "Svg.Attributes"
                                }
                            ]
            ]
        , describe "does not report (negative cases)"
            [ test "Main may import bare Html (router needs Html msg / Daisy.Render.page)" <|
                \() ->
                    """module Main exposing (main)

import Html
import Daisy.Render


main : Html.Html msg
main =
    Daisy.Render.page
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "Daisy.Render (library code, reached via ../src) may import Html" <|
                \() ->
                    """module Daisy.Render exposing (page)

import Html


page : Html.Html msg
page =
    Html.text "hi"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "Daisy.Schema.Button (library code) may import Html" <|
                \() ->
                    """module Daisy.Schema.Button exposing (component)

import Html


component : String
component =
    "btn"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "the package's own tests/ may import Html (they render and query Html)" <|
                \() ->
                    Review.Test.runOnModulesWithProjectData projectWithTestModule
                        rule
                        [ """module Demo.Admin exposing (init)

import Browser


init : ()
init =
    ()
"""
                        ]
                        |> Review.Test.expectNoErrors
            , test "Demo.* module with no Html/Svg import is allowed" <|
                \() ->
                    """module Demo.Admin exposing (init)

import Browser


init : ()
init =
    ()
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            ]
        ]


{-| A module at a `tests/` path, which `Review.Test.run` cannot produce on its
own: it derives every path from the module name as `src/<Module>.elm`. Adding
it to the project directly is the only way to exercise the `tests/` exemption,
which is what keeps the root `elm-review` run (it reviews `tests/` next to
`src/`) from reporting the Tier A suite as demo code.
-}
projectWithTestModule : Project
projectWithTestModule =
    Project.new
        |> Project.addModule
            { path = "tests/CoverageTest.elm"
            , source = """module CoverageTest exposing (suite)

import Html
import Svg


suite : Html.Html msg
suite =
    Html.text "fixtures are rendered Html"
"""
            }
