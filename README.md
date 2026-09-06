# elm-daisy

A typed composition layer over daisyUI for Elm 0.19.1. Views are composed only through a closed tree
(`Daisy.Tree`) and rendered by `Daisy.Render`; the compiler and test suite guarantee no contradictory
modifiers, no invalid nesting, one overlay layer, and a page content budget.

See `SPEC.md` for the specification and `CLAUDE.md` for conventions and commands.
Environment variables (none required) are documented in the dotenv example file.
