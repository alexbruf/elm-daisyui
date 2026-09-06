module Helpers.Classes exposing
    ( Element
    , allClassesIn
    , daisyClassesIn
    , dump
    , elementsIn
    , exclusivityProblems
    , expectNoProblems
    , hasElementWithDaisySet
    , partProblems
    , siblingPartProblems
    , siblingParts
    )

{-| Read the class attributes back out of rendered `Html`.

`Html msg` is opaque and `Test.Html.Query` cannot enumerate elements, so the
tests need another way to answer "which classes did the renderer actually
emit, and on which element". The one place elm-test exposes the whole rendered
tree is the failure message of a query: `Query.has` prints the full HTML,
attributes included, when it fails. [`dump`](#dump) forces exactly one such
failure with a class no renderer can emit, reads the message back through
`Test.Runner.getFailureReason`, and the rest of this module parses it.

The parse is deliberately narrow: only lines whose first non-space character is
`<` are treated as elements (so text content is never mistaken for markup), and
indentation gives the ancestor chain (elm-test indents each level by four
spaces). `Helpers.ClassesTest` pins both properties down against hand-written
`Html`, so a change in elm-test's printer fails loudly instead of silently
weakening every other test.

-}

import Daisy.Schema as Schema
import Daisy.Schema.Validator as SValidator
import Expect exposing (Expectation)
import Html exposing (Html)
import Set exposing (Set)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Test.Runner


{-| One element of a rendered tree.

`ancestors` is nearest-first and holds the class set of every enclosing
element.

-}
type alias Element =
    { index : Int
    , parent : Maybe Int
    , depth : Int
    , tag : String
    , classes : Set String
    , ancestors : List (Set String)
    }


{-| A class string that no daisyUI schema value and no render token equals, so
querying for it always fails and always prints the tree.
-}
sentinel : String
sentinel =
    "helpers-classes-sentinel"


{-| The rendered HTML of a node, as elm-test prints it.
-}
dump : Html msg -> String
dump html =
    let
        expectation =
            Query.fromHtml html |> Query.has [ Selector.class sentinel ]
    in
    case Test.Runner.getFailureReason expectation of
        Just reason ->
            reason.description

        Nothing ->
            ""


{-| Every element of a rendered node, in document order.
-}
elementsIn : Html msg -> List Element
elementsIn html =
    dump html
        |> String.lines
        |> List.filterMap parseLine
        |> withAncestors 0 []


{-| Every class the renderer put on any element.
-}
allClassesIn : Html msg -> Set String
allClassesIn html =
    elementsIn html
        |> List.foldl (\element acc -> Set.union element.classes acc) Set.empty


{-| Every daisyUI class the renderer put on any element.
-}
daisyClassesIn : Html msg -> Set String
daisyClassesIn html =
    Set.intersect (allClassesIn html) Schema.allClasses


{-| Every element carrying two classes of one exclusive group.
-}
exclusivityProblems : List Element -> List String
exclusivityProblems elements =
    let
        check element =
            List.filterMap
                (\group ->
                    let
                        both =
                            Set.intersect element.classes (Set.fromList group.classes)
                    in
                    if Set.size both > 1 then
                        Just
                            ("<"
                                ++ element.tag
                                ++ "> carries "
                                ++ String.join " and " (Set.toList both)
                                ++ ", both in the "
                                ++ group.component
                                ++ " "
                                ++ group.group
                                ++ " group"
                            )

                    else
                        Nothing
                )
                Schema.exclusiveGroups
    in
    List.concatMap check elements


{-| Parts daisyUI styles through a _sibling_ selector rather than by
containment, so they can never sit inside their component.

`validator-hint` is the only one: `validator.css` styles it as
`.validator ~ .validator-hint`, and `validator` itself goes on the form control,
which cannot have children. [`siblingPartProblems`](#siblingPartProblems)
checks the relation these parts really have to hold.

-}
siblingParts : List String
siblingParts =
    SValidator.parts


{-| Every element carrying a `part` class with no enclosing element carrying a
matching `component` class. Parts in [`siblingParts`](#siblingParts) are
checked by [`siblingPartProblems`](#siblingPartProblems) instead.
-}
partProblems : List Element -> List String
partProblems elements =
    let
        check element =
            Set.toList element.classes
                |> List.filter (\class -> not (List.member class siblingParts))
                |> List.filterMap
                    (\class ->
                        case componentsOwning class of
                            [] ->
                                Nothing

                            owners ->
                                if List.any (\owner -> List.any (Set.member owner) element.ancestors) owners then
                                    Nothing

                                else
                                    Just
                                        ("<"
                                            ++ element.tag
                                            ++ "> carries the part "
                                            ++ class
                                            ++ " with no enclosing "
                                            ++ String.join " or " owners
                                        )
                    )
    in
    List.concatMap check elements


{-| Every element carrying a sibling part with no preceding sibling carrying
the matching component class.
-}
siblingPartProblems : List Element -> List String
siblingPartProblems elements =
    let
        precedingSiblings element =
            List.filter
                (\other -> other.index < element.index && other.parent == element.parent)
                elements
                |> List.map .classes

        check element =
            Set.toList element.classes
                |> List.filter (\class -> List.member class siblingParts)
                |> List.filterMap
                    (\class ->
                        let
                            owners =
                                componentsOwning class
                        in
                        if
                            List.any
                                (\owner -> List.any (Set.member owner) (precedingSiblings element))
                                owners
                        then
                            Nothing

                        else
                            Just
                                ("<"
                                    ++ element.tag
                                    ++ "> carries "
                                    ++ class
                                    ++ " with no preceding sibling carrying "
                                    ++ String.join " or " owners
                                )
                    )
    in
    List.concatMap check elements


componentsOwning : String -> List String
componentsOwning class =
    Schema.parts
        |> List.filter (\entry -> entry.part == class)
        |> List.map .component


{-| True when some element of the render carries exactly this set of daisyUI
classes (Tailwind utilities are ignored).
-}
hasElementWithDaisySet : Set String -> Html msg -> Bool
hasElementWithDaisySet wanted html =
    elementsIn html
        |> List.any (\element -> Set.intersect element.classes Schema.allClasses == wanted)



-- PARSING -------------------------------------------------------------------


type alias Raw =
    { depth : Int
    , tag : String
    , classes : Set String
    }


parseLine : String -> Maybe Raw
parseLine line =
    let
        trimmed =
            String.trimLeft line

        indent =
            String.length line - String.length trimmed
    in
    if String.startsWith "<" trimmed && not (String.startsWith "</" trimmed) then
        Just
            { depth = indent // 4
            , tag = tagOf trimmed
            , classes = classesOf trimmed
            }

    else
        Nothing


tagOf : String -> String
tagOf trimmed =
    String.dropLeft 1 trimmed
        |> String.split ">"
        |> List.head
        |> Maybe.withDefault ""
        |> String.split " "
        |> List.head
        |> Maybe.withDefault ""


classesOf : String -> Set String
classesOf trimmed =
    case String.indexes " class=\"" trimmed of
        index :: _ ->
            let
                rest =
                    String.dropLeft (index + 8) trimmed
            in
            case String.indexes "\"" rest of
                end :: _ ->
                    String.words (String.left end rest)
                        |> List.filter (\word -> word /= "")
                        |> Set.fromList

                [] ->
                    Set.empty

        [] ->
            Set.empty


type alias Open =
    { index : Int, depth : Int, classes : Set String }


withAncestors : Int -> List Open -> List Raw -> List Element
withAncestors index stack raws =
    case raws of
        [] ->
            []

        raw :: rest ->
            let
                open =
                    List.filter (\entry -> entry.depth < raw.depth) stack
            in
            { index = index
            , parent = List.head open |> Maybe.map .index
            , depth = raw.depth
            , tag = raw.tag
            , classes = raw.classes
            , ancestors = List.map .classes open
            }
                :: withAncestors (index + 1)
                    ({ index = index, depth = raw.depth, classes = raw.classes } :: open)
                    rest


{-| Fail with every entry of a non-empty list of problems.
-}
expectNoProblems : List String -> Expectation
expectNoProblems problems =
    case problems of
        [] ->
            Expect.pass

        _ ->
            Expect.fail (String.join "\n" problems)
