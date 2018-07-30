module PixelEngine.Graphics.Image exposing (Image, fromTile, image, movable, withAttributes)

{-| This module contains functions for creating images.
These Images can then be used for the _imageArea_ function from the main module

@docs Image,image,movable,fromTile,withAttributes

-}

import Html.Styled exposing (Attribute)
import PixelEngine.Graphics.Abstract as Abstract
import PixelEngine.Graphics.Tile exposing (Tile, Tileset)


{-| A image is a very general object: as we will see later,
even tiles are essentially images.
The following functions are intended to be modular.

A example of a image could be:

```
image "img.png" |> movable "uniqueName"
```

-}
type alias Image msg =
    Abstract.ContentElement msg


{-| The basic image constructor.
the string contains the url to the image

```
image "https://orasund.github.io/pixelengine/pixelengine-logo.png"
```

-}
image : String -> Image msg
image source =
    { elementSource =
        Abstract.ImageSource source
    , customAttributes = []
    , uniqueId = Nothing
    }


{-| Makes a image transition between positions.
This is useful for images that will change their position during the game.

**Note:** The string should be unique, if not the transition might fail every now and then.

**Note:** The string will be a id Attribute in a html node, so be careful not to use names that might be already taken.

-}
movable : String -> Image msg -> Image msg
movable transitionId contentElement =
    { contentElement
        | uniqueId = Just transitionId
    }


{-| Tiles are essentially also images,
therefore this constructor transforms a tile and a tileset into an image.

```
fromTile (tile (0,0))
    (tileset {source:"https://orasund.github.io/pixelengine/pixelengine-logo.png",width:80,height:80})
==
image "https://orasund.github.io/pixelengine/pixelengine-logo.png"
```

**Note:** fromTile displays only the width and height of the image, that where given.
This means setting width and height to 0 would not display the image at all.

```
fromTile (tile (0,0) |> movable "uniqueId")
==
fromTile (tile (0,0)) |> movable "uniqueId"
```

**Note:** If you want to animate an image use this function instead

-}
fromTile : Tile msg -> Tileset -> Image msg
fromTile { info, uniqueId, customAttributes } tileset =
    let
        { top, left, steps } =
            info
    in
    { elementSource =
        Abstract.TileSource
            { left = left
            , top = top
            , steps = steps
            , tileset = tileset
            }
    , customAttributes = customAttributes
    , uniqueId = uniqueId
    }


{-| Adds custom attributes. use the [elm-css Attributes](http://package.elm-lang.org/packages/rtfeldman/elm-css/latest/Svg-Styled-Attributes).

The motivation for this function was so that one can create [onClick](http://package.elm-lang.org/packages/rtfeldman/elm-css/latest/Html-Styled-Events#onClick) events.

-}
withAttributes : List (Attribute msg) -> Image msg -> Image msg
withAttributes attributes image =
    { image
        | customAttributes = attributes
    }