port module Components.Auth0Controller
    exposing
        ( Msg(..)
        , Model
        , init
        , update
        , view
        , either
        , tryGetAccessToken
        , subscriptions
        )

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Components.Auth0 as Auth0
import Time exposing (Time, second)
import Date as Date
import Task
import Basics


type alias Model =
    { state : Auth0.AuthenticationState
    , expiresIn : String
    }


init : Maybe Auth0.LoggedInUser -> Model
init initialData =
    { state =
        case initialData of
            Just user ->
                Auth0.LoggedIn user

            Nothing ->
                Auth0.LoggedOut
    , expiresIn = "Already expired"
    }


type Msg
    = AuthenticationResult Auth0.LoggedInUser
    | ShowLogIn
    | LogOut
    | RenewToken
    | TokenRenewalResult Auth0.RenewedToken
    | Tick Time
    | ReportDate Date.Date



-- Ports


port auth0showLock : () -> Cmd msg


port auth0logout : () -> Cmd msg


port auth0renewToken : () -> Cmd msg


port auth0authResult : (Auth0.LoggedInUser -> msg) -> Sub msg


port auth0TokenRenewalResult : (Auth0.RenewedToken -> msg) -> Sub msg


subscriptions : a -> Sub Msg
subscriptions model =
    Sub.batch
        [ auth0authResult (\loggedInUser -> AuthenticationResult loggedInUser)
        , auth0TokenRenewalResult (\renewedToken -> TokenRenewalResult renewedToken)
        , Time.every second Tick
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthenticationResult user ->
            ( { model | state = Auth0.LoggedIn user }, Cmd.none )

        ShowLogIn ->
            ( model, auth0showLock () )

        LogOut ->
            ( { model | state = Auth0.LoggedOut }, auth0logout () )

        TokenRenewalResult token ->
            ( { model | state = Auth0.updateToken token model.state }, Cmd.none )

        RenewToken ->
            ( model, auth0renewToken () )

        Tick aSecondHasPassed ->
            ( model, Task.perform ReportDate Date.now )

        ReportDate dateNow ->
            (case model.state of
                Auth0.LoggedIn user ->
                    ( { model | expiresIn = calculateExpiresIn dateNow user.expiresAt }, Cmd.none )

                _ ->
                    ( model, Cmd.none )
            )


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "text-align", "center" )
            , ( "background-color", "#e9c9ff" )
            ]
        ]
        [ (case tryGetUser model of
            Nothing ->
                p [] [ text "Please log in" ]

            Just user ->
                div []
                    [ p [] [ img [ src user.picture ] [] ]
                    , p [] [ text ("Hello, " ++ user.name ++ "!") ]
                    , p [] [ text ("Token will expire in (milliseconds): " ++ model.expiresIn) ]
                    ]
          )
        , button
            [ class "btn btn-primary"
            , style
                [ ( "font-size", "110%" ) ]
            , onClick (either model LogOut ShowLogIn)
            ]
            [ text (either model "Logout" "Login")
            ]
        , either model
            (button
                [ style
                    [ ( "font-size", "110%" ) ]
                , onClick RenewToken
                ]
                [ text "Renew token" ]
            )
            (br [] [])
        ]


tryGetUser : Model -> Maybe Auth0.LoggedInUser
tryGetUser model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user

        Auth0.LoggedOut ->
            Nothing


tryGetAccessToken : Model -> Maybe String
tryGetAccessToken model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user.token

        Auth0.LoggedOut ->
            Nothing


either : Model -> a -> a -> a
either model x y =
    case model.state of
        Auth0.LoggedIn _ ->
            x

        Auth0.LoggedOut ->
            y


toMillisecondsSinceEpoch : Date.Date -> Float
toMillisecondsSinceEpoch date =
    date
        |> Date.toTime
        |> Time.inMilliseconds


calculateExpiresIn : Date.Date -> String -> String
calculateExpiresIn dateNow tokenExpiresAt =
    case (Date.fromString tokenExpiresAt) of
        Ok expiresAt ->
            let
                diff =
                    (toMillisecondsSinceEpoch expiresAt) - (toMillisecondsSinceEpoch dateNow)
            in
                if diff > 0 then
                    diff |> Basics.toString
                else
                    "expired"

        Err err ->
            Debug.log "error calculateExpiresIn" ("Could not parse expiresAt: " ++ err)
