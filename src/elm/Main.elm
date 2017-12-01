module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Components.Auth0 as Auth0
import Components.Auth0Controller as Auth0Controller
import Components.RoomsController as RoomsController


main : Program (Maybe Auth0.LoggedInUser) Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { authModel : Auth0Controller.Model
    , roomsModel : RoomsController.Model
    }



-- Init


init : Maybe Auth0.LoggedInUser -> ( Model, Cmd Msg )
init initialUser =
    let
        ( roomsModel, cmd ) =
            RoomsController.init
    in
        ( { authModel = Auth0Controller.init initialUser
          , roomsModel = roomsModel
          }
        , Cmd.map RoomsControllerMsg cmd
        )



-- Messages


type Msg
    = Auth0ControllerMsg Auth0Controller.Msg
    | RoomsControllerMsg RoomsController.Msg



-- Subscriptions


subscriptions : a -> Sub Msg
subscriptions a =
    Sub.map Auth0ControllerMsg (Auth0Controller.subscriptions a)



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Auth0ControllerMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Auth0Controller.update subMsg model.authModel
            in
                ( { model | authModel = subModel }, Cmd.map Auth0ControllerMsg subCmd )

        RoomsControllerMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    RoomsController.update subMsg model.roomsModel
            in
                ( { model | roomsModel = subModel }, Cmd.map RoomsControllerMsg subCmd )



-- View


view : Model -> Html Msg
view model =
    div
        [ class "container"
        , style
            [ ( "width", "90%" )
            , ( "background-color", "#7AAAE0" )
            , ( "font-size", "160%" )
            ]
        ]
        [ (Html.map Auth0ControllerMsg (Auth0Controller.view model.authModel))
        , Auth0Controller.either model.authModel
            -- logged in (implicitly has accessToken)
            (div []
                [ historyButton model
                , liftRoomsControllerView (RoomsController.view model.roomsModel)
                , submitView model
                ]
            )
            -- not logged in
            (p [] [ text "OLD VERSION !!!" ])
        ]


liftRoomsControllerView : Html RoomsController.Msg -> Html Msg
liftRoomsControllerView roomsControllerHtml =
    Html.map RoomsControllerMsg roomsControllerHtml


submitView : Model -> Html Msg
submitView model =
    div
        [ style
            [ ( "background-color", "#7AAAE0" )
            , ( "text-align", "center" )
            ]
        ]
        [ (case Auth0Controller.tryGetAccessToken model.authModel of
            Just accessToken ->
                button
                    [ style
                        [ ( "font-size", "160%" ) ]
                    , onClick (RoomsController.Submit accessToken)
                    ]
                    [ text "Submit" ]
                    |> liftRoomsControllerView

            Nothing ->
                p [] [ text "Acess Token unavailable or expired" ]
          )
        ]


historyButton : Model -> Html Msg
historyButton model =
    case Auth0Controller.tryGetAccessToken model.authModel of
        Just accessToken ->
            button
                [ style
                    [ ( "font-size", "110%" ) ]
                , onClick (RoomsController.SubmitReqHistory accessToken)
                ]
                [ text "View history" ]
                |> liftRoomsControllerView

        Nothing ->
            p [] [ text "Acess Token unavailable or expired" ]
