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
import Json.Decode as Decode
import Json.Encode as Encode


type alias Model =
    { weekday : String
    , startTime : String
    , endTime : String
    , selectedRooms : List String
    , rooms : WebData (List String)
    , result : WebData Rooms.Model
    }


modelEncoder : Model -> Encode.Value
modelEncoder model =
    Encode.object
        [ ( "weekday", Encode.string model.weekday )
        , ( "startTime", Encode.string model.startTime )
        , ( "endTime", Encode.string model.endTime )
        , ( "rooms", Encode.list (List.map (\i -> Encode.string i) model.selectedRooms) )
        ]


init : ( Model, Cmd Msg )
init =
    ( { weekday = "monday"
      , startTime = "9:15"
      , endTime = "9:15"
      , selectedRooms = []
      , rooms = RemoteData.NotAsked
      , result = RemoteData.NotAsked
      }
    , reqAllRooms
    )


type Msg
    = SelectWeekday String
    | SelectStartTime String
    | SelectEndTime String
    | SelectRoom String
    | Submit String
    | OnAllRoomsResponse (WebData (List String))
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

        SelectRoom r ->
            ( { model | selectedRooms = (::) r model.selectedRooms }, Cmd.none )

        Submit accessToken ->
            ( { model | result = RemoteData.Loading }, send model accessToken )

        OnAllRoomsResponse rooms ->
            ( { model | rooms = rooms }, Cmd.none )

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
        , maybeAllRooms model.rooms
        , br [] []
        , p [] [ maybeResult model.result ]
        ]


optionsList : List String -> List (Html msg)
optionsList items =
    List.map (\i -> option [ value i ] [ text i ]) items


checkboxesList : List String -> Html Msg
checkboxesList items =
    ul [] (List.map (\i -> li [] [ checkbox i ]) items)


checkbox : String -> Html Msg
checkbox name =
    label
        []
        [ input [ type_ "checkbox", onClick (SelectRoom name) ] []
        , text name
        ]


maybeAllRooms : WebData (List String) -> Html Msg
maybeAllRooms rooms =
    case rooms of
        RemoteData.NotAsked ->
            text "Get rooms first ..."

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success rooms ->
            checkboxesList rooms

        RemoteData.Failure error ->
            text (toString error)


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



--send : Model -> Cmd Msg
--send model =
--    Http.post ("http://localhost:3000/api/freetimes") (Http.jsonBody (modelEncoder model)) Rooms.roomsDecoder
--        |> RemoteData.sendRequest
--        |> Cmd.map OnResponse


allRoomsDecoder : Decode.Decoder (List String)
allRoomsDecoder =
    Decode.field "rooms" <|
        Decode.list <|
            Decode.string


reqAllRooms : Cmd Msg
reqAllRooms =
    Http.get ("http://localhost:3000/api/public/rooms") allRoomsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map OnAllRoomsResponse


send : Model -> String -> Cmd Msg
send model accessToken =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "http://localhost:3000/api/private/freetimes"
        , body = (Http.jsonBody (modelEncoder model))
        , expect = Http.expectJson Rooms.roomsDecoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map OnResponse
