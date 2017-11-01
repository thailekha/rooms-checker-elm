port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Components.Auth0 as Auth0
import Components.Auth0Controller as Auth0Controller exposing (either)
import Components.RoomsController as RoomsController
import Time exposing (Time, second)


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
        ( { authModel = Auth0Controller.init auth0showLock auth0logout auth0renewToken initialUser
          , roomsModel = roomsModel
          }
        , Cmd.map RoomsControllerMsg cmd
        )



-- Messages


type Msg
    = Auth0ControllerMsg Auth0Controller.Msg
    | RoomsControllerMsg RoomsController.Msg



-- Ports


port auth0showLock : () -> Cmd msg


port auth0authResult : (Auth0.LoggedInUser -> msg) -> Sub msg


port auth0logout : () -> Cmd msg


port auth0renewToken : () -> Cmd msg


port auth0TokenRenewalResult : (Auth0.RenewedToken -> msg) -> Sub msg



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Auth0ControllerMsg authMsg ->
            let
                ( authModel, cmd ) =
                    Auth0Controller.update authMsg model.authModel
            in
                ( { model | authModel = authModel }, Cmd.map Auth0ControllerMsg cmd )

        RoomsControllerMsg roomMsg ->
            let
                ( roomsModel, cmd ) =
                    RoomsController.update roomMsg model.roomsModel
            in
                ( { model | roomsModel = roomsModel }, Cmd.map RoomsControllerMsg cmd )



-- Subscriptions


subscriptions : a -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map Auth0ControllerMsg (auth0authResult Auth0Controller.handleAuth0Result)
        , Sub.map Auth0ControllerMsg (auth0TokenRenewalResult Auth0Controller.handleTokenRenewalResult)
        , Sub.map Auth0ControllerMsg (Time.every second Auth0Controller.Tick)
        ]



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
        , either model.authModel
            -- logged in (implicitly has accessToken)
            (div []
                [ historyButton model
                , liftRCView (RoomsController.view model.roomsModel)
                , submitView model
                ]
            )
            -- not logged in
            (p [] [ text "Please login to use this app" ])
        ]


liftRCView : Html RoomsController.Msg -> Html Msg
liftRCView roomsControllerHtml =
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
                    |> liftRCView

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
                |> liftRCView

        Nothing ->
            p [] [ text "Acess Token unavailable or expired" ]
