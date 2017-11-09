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


type alias RoomForSelect =
    { name : String
    , selected : Bool
    }


type alias Model =
    { weekday : String
    , startTime : String
    , endTime : String
    , rooms : WebData (List RoomForSelect)
    , result : WebData Rooms.Model
    , history : WebData String
    }


modelEncoder : Model -> Encode.Value
modelEncoder model =
    Encode.object
        [ ( "weekday", Encode.string model.weekday )
        , ( "startTime", Encode.string model.startTime )
        , ( "endTime", Encode.string model.endTime )
        , ( "rooms"
          , tryGetAllRooms model.rooms
                |> List.filterMap
                    (\i ->
                        if i.selected then
                            Just (Encode.string i.name)
                        else
                            Nothing
                    )
                |> Encode.list
          )
        ]


init : ( Model, Cmd Msg )
init =
    ( { weekday = "monday"
      , startTime = "9:15"
      , endTime = "9:15"
      , rooms = RemoteData.NotAsked
      , result = RemoteData.NotAsked
      , history = RemoteData.NotAsked
      }
    , reqAllRooms
    )


tryGetAllRooms : WebData (List RoomForSelect) -> List RoomForSelect
tryGetAllRooms rooms =
    case rooms of
        RemoteData.Success rooms ->
            rooms

        _ ->
            []


type Msg
    = SelectWeekday String
    | SelectStartTime String
    | SelectEndTime String
    | Submit String
    | SubmitReqHistory String
    | UnselectRoom String
    | ReqAllRooms
    | OnAllRoomsResponse (WebData (List String))
    | OnCheckRoomsResponse (WebData Rooms.Model)
    | OnHistoryResponse (WebData String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectWeekday w ->
            ( { model | weekday = w }, Cmd.none )

        SelectStartTime s ->
            ( { model | startTime = s }, Cmd.none )

        SelectEndTime e ->
            ( { model | endTime = e }, Cmd.none )

        Submit accessToken ->
            ( { model | result = RemoteData.Loading }, reqCheckRooms model accessToken )

        SubmitReqHistory accessToken ->
            ( { model | history = RemoteData.Loading }, reqHistory model accessToken )

        ReqAllRooms ->
            ( { model | rooms = RemoteData.Loading }, reqAllRooms )

        UnselectRoom roomName ->
            ( { model | rooms = unselect roomName model.rooms }, Cmd.none )

        OnAllRoomsResponse response ->
            ( { model | rooms = RemoteData.map allRoomsToRoomsForSelect response }, Cmd.none )

        OnCheckRoomsResponse response ->
            ( { model | result = response }, Cmd.none )

        OnHistoryResponse history ->
            ( { model | history = history }, Cmd.none )


unselectARoom : String -> RoomForSelect -> RoomForSelect
unselectARoom roomName r =
    if r.name == roomName then
        { name = roomName, selected = False }
    else
        r


unselect : String -> WebData (List RoomForSelect) -> WebData (List RoomForSelect)
unselect roomName rooms =
    RemoteData.map (\rs -> List.map (\r -> unselectARoom roomName r) rs) rooms


times : List String
times =
    [ "9:15", "10:15", "11:15", "12:15", "13:15", "14:15", "15:15", "16:15" ]


weekdays : List String
weekdays =
    [ "monday", "tuesday", "wednesday", "thursday", "friday" ]


view : Model -> Html Msg
view model =
    div
        [ class "container"
        , style
            [ ( "margin-top", "30px" )
            , ( "text-align", "center" )
            ]
        ]
        [ div
            [ style
                [ ( "background-color", "#70ab8f" )
                , ( "border-style", "solid" )
                , ( "border-color", "grey" )
                , ( "text-align", "left" )
                ]
            ]
            [ label [] [ text "History" ]
            , p [] [ maybeHistory model.history ]
            ]
        , div
            [ style
                [ ( "background-color", "#7AAAE0" )
                , ( "margin", "30px" )
                ]
            ]
            [ label [] [ text "Weekday" ]
            , select
                [ style
                    [ ( "font-size", "105%" ) ]
                , onInput SelectWeekday
                ]
                (optionsList weekdays)
            , label [] [ text "Start time" ]
            , select
                [ style
                    [ ( "font-size", "105%" ) ]
                , onInput SelectStartTime
                ]
                (optionsList times)
            , label [] [ text "End time" ]
            , select
                [ style
                    [ ( "font-size", "105%" ) ]
                , onInput SelectEndTime
                ]
                (optionsList times)
            , br [] []
            , div
                [ style
                    [ ( "background-color", "#7AAAE0" )
                    , ( "margin", "30px" )
                    ]
                ]
                [ button
                    [ style
                        [ ( "font-size", "110%" ) ]
                    , onClick ReqAllRooms
                    ]
                    [ text "Refresh all rooms" ]
                , br [] []
                , br [] []
                , maybeAllRooms model.rooms
                ]
            , div
                [ style
                    [ ( "background-color", "#e5e5e5" )
                    , ( "border-style", "solid" )
                    , ( "border-color", "grey" )
                    , ( "text-align", "left" )
                    , ( "padding", "10px" )
                    , ( "margin", "60px" )
                    ]
                ]
                [ maybeResult model.result ]
            ]
        ]


optionsList : List String -> List (Html msg)
optionsList items =
    List.map (\i -> option [ value i ] [ text i ]) items


maybeAllRooms : WebData (List RoomForSelect) -> Html Msg
maybeAllRooms rooms =
    case rooms of
        RemoteData.NotAsked ->
            text "Some error occurred, please reload the page ..."

        RemoteData.Loading ->
            text "Loading rooms..."

        RemoteData.Success rooms ->
            div []
                (rooms
                    |> List.filterMap
                        (\r ->
                            (if r.selected then
                                Just (button [ style [ ( "font-size", "100%" ) ], onClick (UnselectRoom r.name) ] [ text r.name ])
                             else
                                Nothing
                            )
                        )
                )

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


maybeHistory : WebData String -> Html msg
maybeHistory response =
    case response of
        RemoteData.NotAsked ->
            text "History is not loaded"

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success history ->
            (if (String.length history) > 0 then
                ul [] <| List.map (\h -> li [] [ text h ]) <| String.split ";" history
             else
                text "No request has been made"
            )

        RemoteData.Failure error ->
            text (toString error)


allRoomsToRoomsForSelect : List String -> List RoomForSelect
allRoomsToRoomsForSelect strs =
    List.map (\str -> { name = str, selected = True }) strs


allRoomsDecoder : Decode.Decoder (List String)
allRoomsDecoder =
    Decode.field "rooms" <|
        Decode.list <|
            Decode.string


reqAllRooms : Cmd Msg
reqAllRooms =
    Http.get ("https://rooms-checker-go.herokuapp.com/api/public/rooms") allRoomsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map OnAllRoomsResponse


reqHistory : Model -> String -> Cmd Msg
reqHistory model accessToken =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://rooms-checker-go.herokuapp.com/api/limitedprivate/history"
        , body = Http.emptyBody
        , expect = Http.expectJson (Decode.field "history" <| Decode.string)
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map OnHistoryResponse


reqCheckRooms : Model -> String -> Cmd Msg
reqCheckRooms model accessToken =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = "https://rooms-checker-go.herokuapp.com/api/private/freetimes"
        , body = (Http.jsonBody (modelEncoder model))
        , expect = Http.expectJson Rooms.roomsDecoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map OnCheckRoomsResponse
