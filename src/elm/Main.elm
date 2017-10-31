port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Components.Auth0 as Auth0
import Components.Authentication as Authentication exposing (either)
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
    { authModel : Authentication.Model
    , roomsModel : RoomsController.Model
    }



-- Init


init : Maybe Auth0.LoggedInUser -> ( Model, Cmd Msg )
init initialUser =
    let
        ( roomsModel, cmd ) =
            RoomsController.init
    in
        ( { authModel = Authentication.init auth0showLock auth0logout auth0renewToken initialUser
          , roomsModel = roomsModel
          }
        , Cmd.map RoomsControllerMsg cmd
        )



-- Messages


type Msg
    = AuthenticationMsg Authentication.Msg
    | RoomsControllerMsg RoomsController.Msg -- in order to use RoomsController's view here



-- Ports


port auth0showLock : Auth0.Options -> Cmd msg


port auth0authResult : (Auth0.RawAuthenticationResult -> msg) -> Sub msg


port auth0logout : () -> Cmd msg


port auth0renewToken : () -> Cmd msg


port auth0TokenRenewalResult : (Auth0.RawTokenRenewalResult -> msg) -> Sub msg



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthenticationMsg authMsg ->
            let
                ( authModel, cmd ) =
                    Authentication.update authMsg model.authModel
            in
                ( { model | authModel = authModel }, Cmd.map AuthenticationMsg cmd )

        -- ( { model | authModel = first (Authentication.update authMsg model.authModel) }, Cmd.none )
        RoomsControllerMsg roomMsg ->
            let
                ( roomsModel, cmd ) =
                    RoomsController.update roomMsg model.roomsModel
            in
                ( { model | roomsModel = roomsModel }, Cmd.map RoomsControllerMsg cmd )



-- Subscriptions
-- lift msg from ports to Msg for Authentication module


subscriptions : a -> Sub Msg
subscriptions model =
    Sub.batch
        [ auth0authResult (Authentication.handleAuthResult >> AuthenticationMsg)
        , auth0TokenRenewalResult (Authentication.handleTokenRenewalResult >> AuthenticationMsg)
        , Sub.map AuthenticationMsg (Time.every second Authentication.Tick)

        --nested subscriptions breaks the compiler
        --, Sub.map AuthenticationMsg Authentication.subscriptions
        ]



-- View


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ (Html.map AuthenticationMsg (Authentication.view model.authModel))
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
    case Authentication.tryGetAccessToken model.authModel of
        Just accessToken ->
            (liftRCView (button [ onClick (RoomsController.Submit accessToken) ] [ text "Submit" ]))

        Nothing ->
            p [] [ text "Acess Token unavailable or expired" ]


historyButton : Model -> Html Msg
historyButton model =
    case Authentication.tryGetAccessToken model.authModel of
        Just accessToken ->
            (liftRCView (button [ onClick (RoomsController.SubmitReqHistory accessToken) ] [ text "View history" ]))

        Nothing ->
            p [] [ text "Acess Token unavailable or expired" ]
