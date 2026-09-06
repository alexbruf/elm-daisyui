module CoverageTest exposing (suite)

{-| Tier A, row 1: the set of daisyUI classes the renderer emits across every
`Daisy.Tree` constructor equals `Daisy.Schema.allClasses` minus
`Daisy.Render.unreachableClasses`.

The fixtures live in `Helpers.Fixtures`; the class set is read back out of the
rendered `Html` by `Helpers.Classes`.

-}

import Daisy.Render as Render
import Daisy.Schema as Schema
import Expect
import Helpers.Classes as Classes
import Helpers.Fixtures as Fixtures
import Set exposing (Set)
import Test exposing (Test, describe, test)


emitted : Set String
emitted =
    Fixtures.groups
        |> List.foldl (\( _, html ) acc -> Set.union (Classes.daisyClassesIn html) acc) Set.empty


expected : Set String
expected =
    Set.diff Schema.allClasses (Set.fromList Render.unreachableClasses)


suite : Test
suite =
    describe "class coverage"
        [ test "every daisyUI class except the unreachable ones is emitted by some tree" <|
            \_ ->
                let
                    missing =
                        Set.diff expected emitted
                in
                if Set.isEmpty missing then
                    Expect.pass

                else
                    Expect.fail
                        ("never emitted by any fixture ("
                            ++ String.fromInt (Set.size missing)
                            ++ "): "
                            ++ String.join ", " (Set.toList missing)
                        )
        , test "no unreachable class is emitted after all" <|
            \_ ->
                let
                    reached =
                        Set.intersect emitted (Set.fromList Render.unreachableClasses)
                in
                if Set.isEmpty reached then
                    Expect.pass

                else
                    Expect.fail
                        ("listed as unreachable but emitted: "
                            ++ String.join ", " (Set.toList reached)
                        )
        , test "the emitted set is exactly the expected set" <|
            \_ -> Expect.equal expected emitted
        , test "the fixture list is not accidentally empty" <|
            \_ -> Expect.greaterThan 300 (Set.size emitted)
        ]
