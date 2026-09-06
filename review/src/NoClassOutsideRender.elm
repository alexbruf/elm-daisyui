module NoClassOutsideRender exposing (rule)

{-| Forbids `Html.Attributes.class`, `Html.Attributes.classList`, and
`Html.Attributes.attribute "class" ...` everywhere except `Daisy.Render`
(src/Daisy/Render.elm), which is the one module in the whole project allowed
to emit daisyUI class strings (see CLAUDE.md "Render conventions" /
SPEC.md step 5).

The exemption is keyed on module name (`Daisy.Render`), not file path: module
names are unambiguous and stable regardless of which directory `elm-review`
is invoked from (repo root for the package, or `demo/` via `--config
../review`), and it is what `Review.Test` gives us to work with anyway.

Detection resolves the real origin module of every `class` / `classList` /
`attribute` reference via `Review.ModuleNameLookupTable`, so it catches
qualified calls (`Html.Attributes.class`), aliased imports
(`import Html.Attributes as A`, then `A.class`), and names brought in via
`exposing (class)`.

-}

import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node)
import Review.ModuleNameLookupTable as LookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


type alias Context =
    { lookupTable : ModuleNameLookupTable
    , isExemptModule : Bool
    }


exemptModuleName : List String
exemptModuleName =
    [ "Daisy", "Render" ]


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoClassOutsideRender" contextCreator
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\lookupTable moduleName () ->
            { lookupTable = lookupTable
            , isExemptModule = moduleName == exemptModuleName
            }
        )
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node context =
    if context.isExemptModule then
        ( [], context )

    else
        case Node.value node of
            Application (fn :: firstArg :: _) ->
                case ( Node.value fn, Node.value firstArg ) of
                    ( FunctionOrValue _ "attribute", Expression.Literal "class" ) ->
                        if isHtmlAttributes context.lookupTable fn then
                            ( [ classAttributeError node ], context )

                        else
                            ( [], context )

                    _ ->
                        ( visitFunctionOrValue context node, context )

            FunctionOrValue _ _ ->
                ( visitFunctionOrValue context node, context )

            _ ->
                ( [], context )


visitFunctionOrValue : Context -> Node Expression -> List (Rule.Error {})
visitFunctionOrValue context node =
    case Node.value node of
        FunctionOrValue _ name ->
            if (name == "class" || name == "classList") && isHtmlAttributes context.lookupTable node then
                [ classCallError name node ]

            else
                []

        _ ->
            []


isHtmlAttributes : ModuleNameLookupTable -> Node Expression -> Bool
isHtmlAttributes lookupTable node =
    LookupTable.moduleNameFor lookupTable node == Just [ "Html", "Attributes" ]


classCallError : String -> Node Expression -> Rule.Error {}
classCallError name node =
    Rule.error
        { message = "`Html.Attributes." ++ name ++ "` is only allowed in Daisy.Render"
        , details =
            [ "daisyUI class strings must only be emitted from src/Daisy/Render.elm so that the rest of the codebase can only build views through Daisy.Tree. Express this through Daisy.Tree instead, and let Daisy.Render turn it into classes."
            ]
        }
        (Node.range node)


classAttributeError : Node Expression -> Rule.Error {}
classAttributeError node =
    Rule.error
        { message = "`Html.Attributes.attribute \"class\" ...` is only allowed in Daisy.Render"
        , details =
            [ "This is another way of setting the class attribute, and is restricted the same as Html.Attributes.class / classList: only src/Daisy/Render.elm may emit daisyUI class strings."
            ]
        }
        (Node.range node)
