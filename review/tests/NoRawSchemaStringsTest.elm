module NoRawSchemaStringsTest exposing (suite)

import NoRawSchemaStrings exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "NoRawSchemaStrings"
        [ describe "reports (positive cases)"
            [ test "a raw daisyUI class string outside Daisy.Schema/Daisy.Render is reported" <|
                \() ->
                    """module Some.View exposing (btnClass)

btnClass : String
btnClass =
    "btn"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "String literal \"btn\" is a raw daisyUI class name"
                                , details =
                                    [ "This exact string appears in fixtures/schema.json as a daisyUI class. Hand-writing a schema class as a string bypasses the typed Daisy.Tree / Daisy.Schema constructors that guarantee no contradictory modifiers or invalid nesting. Use the generated Daisy.Schema type and constructor instead; only Daisy.Render is allowed to turn those into class strings."
                                    ]
                                , under = "\"btn\""
                                }
                            ]
            , test "a Viz.* embed module is not exempt: a raw daisyUI class is still reported" <|
                \() ->
                    """module Viz.Funnel exposing (label)

label : String
label =
    "btn"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "String literal \"btn\" is a raw daisyUI class name"
                                , details =
                                    [ "This exact string appears in fixtures/schema.json as a daisyUI class. Hand-writing a schema class as a string bypasses the typed Daisy.Tree / Daisy.Schema constructors that guarantee no contradictory modifiers or invalid nesting. Use the generated Daisy.Schema type and constructor instead; only Daisy.Render is allowed to turn those into class strings."
                                    ]
                                , under = "\"btn\""
                                }
                            ]
            , test "a raw part class string (card-body) outside the exempt modules is reported" <|
                \() ->
                    """module Some.Tree exposing (cardBodyPart)

cardBodyPart : String
cardBodyPart =
    "card-body"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "String literal \"card-body\" is a raw daisyUI class name"
                                , details =
                                    [ "This exact string appears in fixtures/schema.json as a daisyUI class. Hand-writing a schema class as a string bypasses the typed Daisy.Tree / Daisy.Schema constructors that guarantee no contradictory modifiers or invalid nesting. Use the generated Daisy.Schema type and constructor instead; only Daisy.Render is allowed to turn those into class strings."
                                    ]
                                , under = "\"card-body\""
                                }
                            ]
            , test "a raw modifier class string (modal-open) in a plain Daisy.Tree-adjacent module is reported" <|
                \() ->
                    """module Daisy.Tree exposing (openModalClass)

openModalClass : String
openModalClass =
    "modal-open"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "String literal \"modal-open\" is a raw daisyUI class name"
                                , details =
                                    [ "This exact string appears in fixtures/schema.json as a daisyUI class. Hand-writing a schema class as a string bypasses the typed Daisy.Tree / Daisy.Schema constructors that guarantee no contradictory modifiers or invalid nesting. Use the generated Daisy.Schema type and constructor instead; only Daisy.Render is allowed to turn those into class strings."
                                    ]
                                , under = "\"modal-open\""
                                }
                            ]
            ]
        , describe "does not report (negative cases)"
            [ test "Daisy.Render may contain raw schema class strings" <|
                \() ->
                    """module Daisy.Render exposing (page)

import Html
import Html.Attributes


page : Html.Html msg
page =
    Html.div [ Html.Attributes.class "btn" ] []
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "Daisy.Schema (aggregate) may contain raw schema class strings" <|
                \() ->
                    """module Daisy.Schema exposing (allClasses)

import Set exposing (Set)


allClasses : Set String
allClasses =
    Set.fromList [ "btn", "card-body" ]
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "Daisy.Schema.Button (per-component module) may contain raw schema class strings" <|
                \() ->
                    """module Daisy.Schema.Button exposing (component)

component : String
component =
    "btn"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            , test "a string that is not a schema class is allowed anywhere" <|
                \() ->
                    """module Some.View exposing (greeting)

greeting : String
greeting =
    "hello world"
"""
                        |> Review.Test.run rule
                        |> Review.Test.expectNoErrors
            ]
        ]
