module NoClassOutsideRenderTest exposing (suite)

import NoClassOutsideRender exposing (rule)
import Review.Project as Project exposing (Project)
import Review.Test
import Review.Test.Dependencies
import Test exposing (Test, describe, test)


project : Project
project =
    Review.Test.Dependencies.projectWithElmCore
        |> Project.addDependency Review.Test.Dependencies.elmHtml


suite : Test
suite =
    describe "NoClassOutsideRender"
        [ describe "reports (positive cases)"
            [ test "qualified Html.Attributes.class outside Daisy.Render" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes


view : Html.Html msg
view =
    Html.div [ Html.Attributes.class "btn" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`Html.Attributes.class` is only allowed in Daisy.Render"
                                , details =
                                    [ "daisyUI class strings must only be emitted from src/Daisy/Render.elm so that the rest of the codebase can only build views through Daisy.Tree. Express this through Daisy.Tree instead, and let Daisy.Render turn it into classes."
                                    ]
                                , under = "Html.Attributes.class"
                                }
                            ]
            , test "classList exposed unqualified outside Daisy.Render" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes exposing (classList)


view : Html.Html msg
view =
    Html.div [ classList [ ( "btn", True ) ] ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`Html.Attributes.classList` is only allowed in Daisy.Render"
                                , details =
                                    [ "daisyUI class strings must only be emitted from src/Daisy/Render.elm so that the rest of the codebase can only build views through Daisy.Tree. Express this through Daisy.Tree instead, and let Daisy.Render turn it into classes."
                                    ]
                                , under = "classList"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 16 }, end = { row = 9, column = 25 } }
                            ]
            , test "aliased import: A.class outside Daisy.Render" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes as A


view : Html.Html msg
view =
    Html.div [ A.class "btn" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`Html.Attributes.class` is only allowed in Daisy.Render"
                                , details =
                                    [ "daisyUI class strings must only be emitted from src/Daisy/Render.elm so that the rest of the codebase can only build views through Daisy.Tree. Express this through Daisy.Tree instead, and let Daisy.Render turn it into classes."
                                    ]
                                , under = "A.class"
                                }
                            ]
            , test "Html.Attributes.attribute \"class\" ... outside Daisy.Render" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes


view : Html.Html msg
view =
    Html.div [ Html.Attributes.attribute "class" "btn" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "`Html.Attributes.attribute \"class\" ...` is only allowed in Daisy.Render"
                                , details =
                                    [ "This is another way of setting the class attribute, and is restricted the same as Html.Attributes.class / classList: only src/Daisy/Render.elm may emit daisyUI class strings."
                                    ]
                                , under = "Html.Attributes.attribute \"class\" \"btn\""
                                }
                            ]
            ]
        , describe "does not report (negative cases)"
            [ test "Daisy.Render itself may call Html.Attributes.class" <|
                \() ->
                    """module Daisy.Render exposing (page)

import Html
import Html.Attributes


page : Html.Html msg
page =
    Html.div [ Html.Attributes.class "btn" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectNoErrors
            , test "a locally defined function named class is not Html.Attributes.class" <|
                \() ->
                    """module Some.View exposing (view)

import Html


class : String -> String
class name =
    name


view : String
view =
    class "btn"
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectNoErrors
            , test "Html.Attributes.attribute with a non-class name is allowed" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes


view : Html.Html msg
view =
    Html.div [ Html.Attributes.attribute "id" "main" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectNoErrors
            , test "unrelated Html.Attributes functions like style are allowed" <|
                \() ->
                    """module Some.View exposing (view)

import Html
import Html.Attributes


view : Html.Html msg
view =
    Html.div [ Html.Attributes.style "color" "red" ] []
"""
                        |> Review.Test.runWithProjectData project rule
                        |> Review.Test.expectNoErrors
            ]
        ]
