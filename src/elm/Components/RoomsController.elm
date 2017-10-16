module Components.RoomsController
    exposing
        ( Msg(..)
        , Model
        , modelEncoder
        , init
        , update
        , view
        )

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import RemoteData exposing (WebData)
import Components.Rooms as Rooms
import Json.Encode as Encode


type alias Model =
    { weekday : String
    , startTime : String
    , endTime : String
    , result : WebData Rooms.Model
    }


modelEncoder : Model -> Encode.Value
modelEncoder model =
    Encode.object
        [ ( "weekday", Encode.string model.weekday )
        , ( "startTime", Encode.string model.startTime )
        , ( "endTime", Encode.string model.endTime )
        ]


init : Model
init =
    { weekday = "monday"
    , startTime = "9:15"
    , endTime = "9:15"
    , result = RemoteData.NotAsked
    }


type Msg
    = SelectWeekday String
    | SelectStartTime String
    | SelectEndTime String
    | Submit
    | OnResponse (WebData Rooms.Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectWeekday w ->
            ( { model | weekday = w }, Cmd.none )

        SelectStartTime s ->
            ( { model | startTime = s }, Cmd.none )

        SelectEndTime e ->
            ( { model | endTime = e }, Cmd.none )

        Submit ->
            ( { model | result = RemoteData.Loading }, send model )

        OnResponse response ->
            ( { model | result = response }, Cmd.none )


times : List String
times =
    [ "9:15", "10:15", "11:15", "12:15", "13:15", "14:15", "15:15", "16:15" ]


weekdays : List String
weekdays =
    [ "monday", "tuesday", "wednesday", "thursday", "friday" ]


view : Model -> Html Msg
view model =
    div [ class "container", style [ ( "margin-top", "30px" ), ( "text-align", "left" ) ] ]
        [ -- inline CSS (literal)
          label [] [ text "Weekday" ]
        , select [ onInput SelectWeekday ] (optionsList weekdays)
        , label [] [ text "Start time" ]
        , select [ onInput SelectStartTime ] (optionsList times)
        , label [] [ text "End time" ]
        , select [ onInput SelectEndTime ] (optionsList times)
        , br [] []
        , button [ onClick Submit ] [ text "Find" ]
        , br [] []
        , p [] [ maybeResult model.result ]
        ]


optionsList : List String -> List (Html msg)
optionsList items =
    List.map (\i -> option [ value i ] [ text i ]) items


maybeResult : WebData Rooms.Model -> Html msg
maybeResult response =
    case response of
        RemoteData.NotAsked ->
            text "Look up something ..."

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success rooms ->
            Rooms.view rooms

        RemoteData.Failure error ->
            text (toString error)


send : Model -> Cmd Msg
send model =
    Http.post ("http://localhost:3000/api/freetimes") (Http.jsonBody (modelEncoder model)) Rooms.roomsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map OnResponse
