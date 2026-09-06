module NoHtmlInDemo exposing (rule)

{-| Forbids `import Html`, `import Html.*`, `import Svg`, and `import Svg.*`
in demo modules (SPEC.md step 5 / CLAUDE.md "Tooling rules": "No
`Html`/`Html.Attributes`/`Svg` imports under `demo/src`"). Demo apps must be
expressed only through `Daisy.Tree`, rendered by `Daisy.Render`.

**Exemption: `Main` may `import Html` (bare, nothing else).**
`demo/src/Main.elm` is the router: it wires up `Browser.element`/
`Browser.application`, which requires `Html msg` in its `view` type
signature and `Program` types, and it calls `Daisy.Render.page` to produce
that `Html msg`. It has no other reason to touch `Html` — never
`Html.Attributes`, `Html.Events`, or any `Html.*` submodule, and never `Svg`.
Every other demo module (the `Demo.*` namespace: `Demo.Admin`,
`Demo.Analytics`, `Demo.Settings`, ...) must not import `Html` or `Svg` at
all; they only build `Daisy.Tree` values.

**Exemption is by file path, not just module name**, because the same
`review/` config is used from two places (see CLAUDE.md "Commands" — the
root `elm-review` for the package, and `elm-review --config ../review` run
from inside `demo/` for the demo app, whose `elm.json` also lists `../src`
as a source directory so it can see `Daisy.*`). Verified empirically: when
elm-review runs at the repo root, `Daisy.Render.elm` is reported at path
`src/Daisy/Render.elm`; when it runs from `demo/`, the same file (reached via
the `../src` source directory) is reported at `../src/Daisy/Render.elm`,
while demo's own files are reported at `src/Main.elm`, `src/Demo/Admin.elm`,
etc. So: a path starting with `../` or with `src/Daisy/` is library code and
is always exempt (it legitimately imports `Html` from `Daisy.Render`); any
other file is demo code and is subject to this rule.

**The package's own `tests/` are exempt too.** The root `elm-review` run
reviews `tests/` alongside `src/`, and the Tier A suite is about rendered
`Html`: it builds `Html` wrappers for `Test.Html.Query`, and the fixtures it
compares against are `Daisy.Render` output. Those modules are not demo code,
so `tests/...` (and `../tests/...`, when the demo run reaches them) is exempt.
`NoClassOutsideRender` still applies there, which is the rule that actually
keeps class strings out of the tests.

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Rule)


type alias Context =
    { filePath : String
    , moduleName : List String
    }


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoHtmlInDemo" contextCreator
        |> Rule.withImportVisitor importVisitor
        |> Rule.fromModuleRuleSchema


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\filePath moduleName () -> { filePath = filePath, moduleName = moduleName })
        |> Rule.withFilePath
        |> Rule.withModuleName


isLibraryFile : String -> Bool
isLibraryFile filePath =
    String.startsWith "../" filePath
        || String.startsWith "src/Daisy/" filePath
        || String.startsWith "tests/" filePath


importVisitor : Node Import -> Context -> ( List (Rule.Error {}), Context )
importVisitor node context =
    if isLibraryFile context.filePath then
        ( [], context )

    else
        let
            importedModuleNode : Node (List String)
            importedModuleNode =
                (Node.value node).moduleName

            importedModule : List String
            importedModule =
                Node.value importedModuleNode

            isMainRouter : Bool
            isMainRouter =
                context.moduleName == [ "Main" ]
        in
        case importedModule of
            "Html" :: [] ->
                if isMainRouter then
                    ( [], context )

                else
                    ( [ error "Html" importedModuleNode ], context )

            "Html" :: _ ->
                ( [ error (String.join "." importedModule) importedModuleNode ], context )

            "Svg" :: _ ->
                ( [ error (String.join "." importedModule) importedModuleNode ], context )

            _ ->
                ( [], context )


error : String -> Node (List String) -> Rule.Error {}
error moduleName node =
    Rule.error
        { message = "`import " ++ moduleName ++ "` is not allowed in demo/src"
        , details =
            [ "Demo apps are built only through Daisy.Tree, rendered by Daisy.Render.page. The router (Main) is the sole exception and may `import Html` bare (for its view/Program type signatures and to call Daisy.Render.page) -- never Html.Attributes, another Html.* submodule, or Svg."
            ]
        }
        (Node.range node)
