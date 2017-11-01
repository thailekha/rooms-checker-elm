module Components.Rooms exposing (..)

import Html exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline as JDecode


type alias Room =
    { room : String
    , times : List String
    }


roomDecoder : Decode.Decoder Room
roomDecoder =
    JDecode.decode Room
        |> JDecode.required "room" Decode.string
        |> JDecode.required "times" (Decode.list Decode.string)


type alias Model =
    { rooms : List Room
    }


roomsDecoder : Decode.Decoder Model
roomsDecoder =
    JDecode.decode Model
        |> JDecode.required "rooms" (Decode.list roomDecoder)


view : Model -> Html msg
view model =
    div []
        (if (List.length model.rooms) > 0 then
            (List.map (\r -> viewRoom r) model.rooms)
         else
            [ text "No free room found!" ]
        )


viewRoom : Room -> Html msg
viewRoom room =
    div []
        [ label [] [ text room.room ]
        , ul [] (List.map (\t -> li [] [ text t ]) room.times)
        ]
