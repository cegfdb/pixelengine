module PixelEngine.Graphics.Transition exposing
    ( from
    , Transition, custom
    )

{-| Adding a transitions between screens.

The information for the transition will be written in the `Option` class from
[PixelEngine.Graphics](/PixelEngine-Graphics).

To get started, copy the following example:

    options
        |> Transition.from
            ListOfArea
            (Transition.customTransition
                "death_transition"
                [ ( 0, "opacity:1;filter:grayscale(0%) blur(0px);" )
                , ( 1, "opacity:1;filter:grayscale(70%) blur(0px);" )
                , ( 3, "opacity:0;filter:grayscale(70%) blur(5px);" )
            ])


## Main Function

@docs from


## Area

@docs Transition, custom

-}

import PixelEngine.Graphics exposing (Area, Options)
import PixelEngine.Graphics.Abstract as Abstract



{-| A transition between screens
-}
type alias Transition =
    Abstract.Transition


{-| The default constructor for a `Transition`.

For the future I have planed to make transitions modular, similar to a `Msg` or a `Sub`.

    Transition.customTransition
        "death_transition"
        [ ( 0, "opacity:1;filter:grayscale(0%) blur(0px);" )
        , ( 1, "opacity:1;filter:grayscale(70%) blur(0px);" )
        , ( 3, "opacity:0;filter:grayscale(70%) blur(5px);" )
        ]

The first value is the duration of the effect, the second is the CSS-command at that point in time.
So the example will compile to something like this:

    dealth_transition:
    0% {opacity:1;filter:grayscale(0%) blur(0px);}
    25% {opacity:1;filter:grayscale(70%) blur(0px);}
    100% {opacity:0;filter:grayscale(70%) blur(5px);}

**Note:**

A screen will be automatically hidden after a transition,
so the example would also work without the opacity-parameter.
-}
custom : String -> List ( Float, String ) -> Transition
custom name transitionList =
    Abstract.Transition { name = name, transitionList = transitionList }


{-| adds the `Transition` to the `Options`.
The first argument is the List or Areas taken **before** the transition is applied.
(e.g. the last state)
-}
from : List (Area msg) -> Transition -> Options msg -> Options msg
from listOfArea transition (Abstract.Options options) =
    Abstract.Options
        { options
            | transitionFrom = listOfArea
            , transition = transition
        }
