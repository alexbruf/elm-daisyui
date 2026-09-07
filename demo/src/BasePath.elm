module BasePath exposing (join, strip)

{-| Base-path arithmetic for the demo router.

The demo is served two ways:

  - locally (`vite dev`, `vite preview`, Playwright) from `/`,
  - on GitHub Pages from `/elm-daisyui/`.

Vite decides which by its `base` option, exposes it to the bundle as
`import.meta.env.BASE_URL`, and `demo/src/main.js` hands it to Elm as the
`basePath` flag. Everything the router does with a path goes through one of
these two functions, so the demo's own routes stay base-free (`"/"`,
`"/analytics"`, `"/settings"`) and the prefix is applied in exactly two
places: the `href`/`pushUrl` that leave Elm, and the `Url` that comes back in.

`BASE_URL` always has a trailing slash (`"/"` or `"/elm-daisyui/"`), but both
functions tolerate one that does not.

@docs join, strip

-}


{-| Prefix a route with the base path.

    join "/" "/analytics" --> "/analytics"

    join "/elm-daisyui/" "/analytics" --> "/elm-daisyui/analytics"

    join "/elm-daisyui/" "/" --> "/elm-daisyui/"

-}
join : String -> String -> String
join basePath route =
    prefix basePath ++ route


{-| Remove the base path from a URL's path, giving the demo's own route.
The inverse of [`join`](#join).

    strip "/elm-daisyui/" "/elm-daisyui/analytics" --> "/analytics"

    strip "/elm-daisyui/" "/elm-daisyui/" --> "/"

    strip "/" "/analytics" --> "/analytics"

-}
strip : String -> String -> String
strip basePath path =
    let
        p =
            prefix basePath
    in
    if p /= "" && String.startsWith p path then
        emptyToRoot (String.dropLeft (String.length p) path)

    else
        path


{-| The base path without its trailing slash, so it concatenates with a route
that starts with one. `"/"` becomes `""`.
-}
prefix : String -> String
prefix basePath =
    if String.endsWith "/" basePath then
        String.dropRight 1 basePath

    else
        basePath


emptyToRoot : String -> String
emptyToRoot path =
    if path == "" then
        "/"

    else
        path
