module TilesetExample exposing (main)

import Css
import Html.Styled exposing (toUnstyled)
import PixelEngine.Graphics as Graphics exposing (Background)
import PixelEngine.Graphics.Image exposing (fromTile, image, multipleImages)
import PixelEngine.Graphics.Tile as Tile
    exposing
        ( Tileset
        , tile
        )


main =
    let
        tileSize : Int
        tileSize =
            16

        windowWidth : Int
        windowWidth =
            16

        scale : Float
        scale =
            2

        width : Float
        width =
            (toFloat <| windowWidth * tileSize) * scale

        tileset : Tileset
        tileset =
            { source = "tileset.png", spriteWidth = tileSize, spriteHeight = tileSize }

        background : Background
        background =
            Graphics.colorBackground (Css.rgb 20 12 28)

        --Image { src = "background.png", width = 16 * scale, height = 16 * scale }
        goblin =
            tile ( 2, 8 ) |> Tile.animated 1

        letter_h =
            tile ( 1, 15 )

        letter_i =
            tile ( 2, 12 )

        heart =
            tile ( 4, 8 )
    in
    Graphics.render
        { width = width, transitionSpeedInSec = 0.2, scale = scale }
        [ Graphics.tiledArea
            { rows = 4
            , tileset = tileset
            , background = background
            }
            [ ( ( 6, 2 ), goblin )
            , ( ( 7, 2 ), letter_h )
            , ( ( 8, 2 ), letter_i )
            , ( ( 9, 2 ), heart )
            ]
        , Graphics.imageArea
            { height = scale * (toFloat <| tileSize * 12)
            , background = background
            }
            [ ( ( width / 2 - 80 * scale, 0 )
              , multipleImages
                    [ ( ( 0, 0 ), image "pixelengine-logo.png" )
                    ]
              )
            ]
        ]
        |> toUnstyled
