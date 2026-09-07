port module Ports exposing (copyToClipboard, encodeTheme, themeEncoded)

{-| The demo's whole JavaScript surface: three ports, all of them for browser
APIs Elm has no access to.

`demo/src/main.js` implements them. Nothing here touches `Html`, so the
`NoHtmlInDemo` review rule applies to this module unchanged.

  - [`copyToClipboard`](#copyToClipboard) — `navigator.clipboard.writeText`.
  - [`encodeTheme`](#encodeTheme) / [`themeEncoded`](#themeEncoded) — the
    round trip that turns a theme's JSON into the `#theme=` hash daisyUI's own
    generator reads. The hash is
    `base64url(zlib-deflate(json))`, and the deflate is
    `CompressionStream("deflate")`, which is a stream API: it cannot be a
    synchronous function, so the answer comes back through a second port rather
    than as a return value.

@docs copyToClipboard, encodeTheme, themeEncoded

-}


{-| Put a string on the system clipboard.

`navigator.clipboard.writeText` needs a user gesture, so this is only ever sent
from a button's `onClick`; there is no acknowledgement port because there is
nothing useful to do with a failure that the browser has not already told the
user about.

-}
port copyToClipboard : String -> Cmd msg


{-| Ask for the daisyUI theme-generator URL of a theme.

The payload is the theme's JSON exactly as
`Daisy.Tree.customThemeToJson` produced it. The answer arrives on
[`themeEncoded`](#themeEncoded) as the full
`https://daisyui.com/theme-generator/#theme=<hash>` URL, so the shape of the
link is decided in one place — the glue that does the compression — rather than
half here and half there.

-}
port encodeTheme : String -> Cmd msg


{-| The URL [`encodeTheme`](#encodeTheme) asked for.

One message per request, in order. An encoding failure sends the plain
`https://daisyui.com/theme-generator/` instead of an error, because a link that
opens the generator without the theme is still a working link.

-}
port themeEncoded : (String -> msg) -> Sub msg
