module CultSim.Main exposing (main)

import Browser exposing (Document, document)
import CultSim.Person as Person exposing (Action(..), Person)
import Dict exposing (Dict)
import Html
import Html.Attributes as Attributes
import Location exposing (Location, Vector)
import PixelEngine
import PixelEngine.Image as Image exposing (Image)
import PixelEngine.Options as Options
import PixelEngine.Tile as Tile
import Process
import Random
import Random.Extra as RandomExtra
import Task
import Time exposing (Posix)


type alias Model =
    { seed : Random.Seed
    , hunger : Float
    , faith : Int
    , people : Dict String Person
    , newPerson : ( String, Person )
    }


type Msg
    = Tick Posix
    | NewGame Int
    | Pray String


init : flags -> ( Maybe Model, Cmd Msg )
init _ =
    ( Nothing
    , Random.generate NewGame <| Random.int Random.minInt Random.maxInt
    )


tickTask : Float -> Cmd Msg
tickTask delay =
    Task.perform Tick
        (Process.sleep delay
            |> Task.andThen (\_ -> Time.now)
        )


newGame : Int -> ( Maybe Model, Cmd Msg )
newGame int =
    let
        ( ( newId, newPerson ), seed ) =
            Random.step Person.generate <| Random.initialSeed int
    in
    ( Just
        { seed = seed
        , hunger = 0
        , faith = 0
        , people = Dict.empty --Dict.singleton newId newPerson
        , newPerson = ( newId, newPerson )
        }
    , tickTask 0
    )


update : Msg -> Maybe Model -> ( Maybe Model, Cmd Msg )
update msg maybeModel =
    case maybeModel of
        Just oldModel ->
            case msg of
                Tick _ ->
                    let
                        model =
                            let
                                newPeople =
                                    oldModel.people |> Dict.filter (\_ person -> person.action /= Dying)
                            in
                            if oldModel.hunger >= 1 then
                                let
                                    ( maybeId, newSeed ) =
                                        Random.step (RandomExtra.sample <| Dict.keys newPeople) oldModel.seed
                                in
                                { oldModel
                                    | seed = newSeed
                                    , people =
                                        newPeople
                                            |> (case maybeId of
                                                    Just id ->
                                                        Dict.update id (Maybe.map (\person -> { person | action = Dying }))

                                                    Nothing ->
                                                        identity
                                               )
                                }

                            else
                                { oldModel
                                    | people = newPeople
                                }
                    in
                    ( Just
                        (model.people
                            |> Dict.foldl
                                (\id ({ action, praying_duration } as person) ({ people, seed } as m) ->
                                    case action of
                                        PendingPraying ->
                                            { m | people = people |> Dict.update id (Maybe.map <| always <| Person.pray person) }

                                        Praying int ->
                                            let
                                                { hunger, faith } =
                                                    m
                                            in
                                            if int == 0 then
                                                let
                                                    ( newPerson, newSeed ) =
                                                        Person.move person seed
                                                in
                                                { m
                                                    | people = people |> Dict.update id (Maybe.map <| always <| newPerson)
                                                    , seed = newSeed
                                                    , hunger = hunger - 0 - 0.1 * toFloat praying_duration
                                                    , faith = faith + 1
                                                }

                                            else
                                                { m
                                                    | people = people |> Dict.update id (Maybe.map <| always <| { person | action = Praying <| int - 1 })
                                                    , hunger = hunger - 0 - 0.1 * toFloat praying_duration
                                                    , faith = faith + 1
                                                }

                                        Walking ->
                                            let
                                                ( newPerson, newSeed ) =
                                                    Person.move person seed
                                            in
                                            { m
                                                | people = people |> Dict.update id (Maybe.map <| always <| newPerson)
                                                , seed = newSeed
                                            }

                                        Dying ->
                                            { m | hunger = 0 }

                                        None ->
                                            m
                                )
                                model
                            |> (\({ hunger, people } as m) ->
                                    { m | hunger = hunger + 0.25 * (toFloat <| Dict.size people) }
                               )
                            |> (\({ faith, people, seed, newPerson } as m) ->
                                    if faith >= 2 ^ Dict.size people then
                                        let
                                            ( addedNewPerson, ( person, newSeed ) ) =
                                                Random.step Person.generate seed
                                                    |> Tuple.mapSecond
                                                        (Person.move
                                                            (newPerson
                                                                |> Tuple.second
                                                            )
                                                        )
                                        in
                                        { m
                                            | faith = faith - 2 ^ Dict.size people
                                            , people = people |> Dict.insert (newPerson |> Tuple.first) person
                                            , newPerson = addedNewPerson
                                            , seed = newSeed
                                        }

                                    else
                                        m
                               )
                            |> (\({ hunger } as m) ->
                                    if hunger < 0 then
                                        { m | hunger = 0 }

                                    else if hunger > 1 then
                                        { m | hunger = 1 }

                                    else
                                        m
                               )
                            |> (\({ seed, people, newPerson } as m) ->
                                    if people |> Dict.isEmpty then
                                        let
                                            ( addedNewPerson, ( person, newSeed ) ) =
                                                Random.step Person.generate seed
                                                    |> Tuple.mapSecond
                                                        (Person.move
                                                            (newPerson
                                                                |> Tuple.second
                                                            )
                                                        )
                                        in
                                        { m
                                            | people = people |> Dict.insert (newPerson |> Tuple.first) person
                                            , seed = newSeed
                                            , newPerson = addedNewPerson
                                        }

                                    else
                                        m
                               )
                        )
                    , tickTask (1000 * 8)
                    )

                Pray id ->
                    let
                        { people } =
                            oldModel
                    in
                    ( Just
                        { oldModel
                            | people = people |> Dict.update id (Maybe.map Person.setPraying)
                        }
                    , Cmd.none
                    )

                NewGame int ->
                    newGame int

        Nothing ->
            case msg of
                NewGame int ->
                    newGame int

                _ ->
                    ( Nothing
                    , Cmd.none
                    )


subscriptions : Maybe Model -> Sub Msg
subscriptions _ =
    Sub.none


width : Float
width =
    256


height : Float
height =
    208


areas : Model -> List ( Location, Image Msg )
areas { people, hunger, newPerson } =
    let
        offset : Vector
        offset =
            { x = width / 2
            , y = height / 2
            }
    in
    List.concat
        [ people
            |> Dict.toList
            |> List.append [ newPerson ]
            |> List.map
                (\( id, { location, action, skin, praying_duration } ) ->
                    let
                        image =
                            Image.fromTile (Person.tile action)
                                (Tile.tileset
                                    { source = "bodys/" ++ String.fromInt body ++ ".png"
                                    , spriteWidth = 16
                                    , spriteHeight = 16
                                    }
                                )

                        { head, body } =
                            skin
                    in
                    ( location |> Location.add offset
                    , Image.multipleImages
                        (if action == Dying then
                            [ ( ( 0, 0 )
                              , Image.fromTile
                                    (Tile.fromPosition ( 0, 0 ) |> Tile.animated 8)
                                    (Tile.tileset
                                        { source = "burning.png", spriteWidth = 16, spriteHeight = 16 }
                                    )
                              )
                            ]

                         else if action == None then
                            [ ( ( 0, 0 ), Image.fromSrc "empty.png" ) ]

                         else
                            [ ( ( 0, 0 ), image )
                            , ( case action of
                                    Praying _ ->
                                        ( 0, 2 )

                                    _ ->
                                        ( 0, 0 )
                              , Image.fromSrc <| "heads/" ++ String.fromInt head ++ ".png"
                              )
                            ]
                                |> (case action of
                                        Praying int ->
                                            List.append
                                                [ ( ( 0, 17 )
                                                  , Image.fromTile
                                                        (Person.tile_bar
                                                            ((16 // (praying_duration + 1) * (int + 1)) - 1)
                                                            (16 // (praying_duration + 1) - 1)
                                                            |> Tile.animated 8
                                                        )
                                                        (Tile.tileset
                                                            { source = "blue_bar.png"
                                                            , spriteWidth = 16
                                                            , spriteHeight = 4
                                                            }
                                                        )
                                                  )
                                                ]

                                        _ ->
                                            identity
                                   )
                        )
                        |> Image.movable id
                        |> (case action of
                                Walking ->
                                    Image.clickable (Pray id)

                                _ ->
                                    identity
                           )
                    )
                )
        , if hunger < 1 then
            [ ( ( width / 2 - 32, height / 2 - 48 )
              , Image.fromSrc "temple.png"
              )
            ]

          else
            [ ( ( width / 2 - 32, height / 2 - 48 )
              , Image.fromSrc "devil_temple.png"
              )
            , ( ( width / 2 - 80, height / 2 - 90 )
              , Image.fromTextWithSpacing -4
                    "Cuthulhu asks"
                    { source = "Berlin16x16.png"
                    , spriteWidth = 16
                    , spriteHeight = 16
                    }
              )
            , ( ( width / 2 - 85, height / 2 - 70 )
              , Image.fromTextWithSpacing -5
                    "for a sacrifice..."
                    { source = "Berlin16x16.png"
                    , spriteWidth = 16
                    , spriteHeight = 16
                    }
              )
            ]
        ]


view : Maybe Model -> Document Msg
view maybeModel =
    let
        options =
            Options.default
                |> Options.withMovementSpeed 8
                |> Options.withScale 2
    in
    { title = "CultSim"
    , body =
        [ PixelEngine.toHtml
            { options = Just options, width = width }
            [ PixelEngine.imageArea
                { height = height
                , background =
                    --PixelEngine.colorBackground <| Color.rgb255 222 238 214
                    PixelEngine.imageBackground
                        { source = "background_scaled.png"
                        , width = width
                        , height = height
                        }
                }
                (case maybeModel of
                    Just model ->
                        areas model

                    Nothing ->
                        []
                )
            ]
        , Html.p [ Attributes.style "text-align" "center" ]
            [ Html.text "Click on people to let them pray. If your cult members stop praying, eventually Cuthulu will come out and ask for a sacrifice."
            , Html.text "The game is won, once you have 10 or more cult members."
            ]
        ]
    }


main : Program {} (Maybe Model) Msg
main =
    document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
