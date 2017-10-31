module Components.Authentication
    exposing
        ( Msg(..)
        , Model
        , init
        , update
        , handleAuthResult
        , handleTokenRenewalResult
        , tryGetAccessToken
        , isLoggedIn
        , view
        , either
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
    , lastError : Maybe Auth0.AuthenticationError
    , showLock : Auth0.Options -> Cmd Msg
    , logOut : () -> Cmd Msg
    , renewToken : () -> Cmd Msg
    , expiresIn : String
    }


init : (Auth0.Options -> Cmd Msg) -> (() -> Cmd Msg) -> (() -> Cmd Msg) -> Maybe Auth0.LoggedInUser -> Model
init showLock logOut renewToken initialData =
    { state =
        case initialData of
            Just user ->
                Auth0.LoggedIn user

            Nothing ->
                Auth0.LoggedOut
    , lastError = Nothing
    , showLock = showLock
    , logOut = logOut
    , renewToken = renewToken
    , expiresIn = "Already expired"
    }


type Msg
    = AuthenticationResult Auth0.AuthenticationResult
    | TokenRenewalResult Auth0.TokenRenewalResult
    | ShowLogIn
    | LogOut
    | RenewToken
    | Tick Time
    | ReportDate Date.Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthenticationResult result ->
            let
                ( newState, error ) =
                    case result of
                        Ok user ->
                            ( Auth0.LoggedIn user, Nothing )

                        Err err ->
                            ( model.state, Just err )
            in
                ( { model | state = newState, lastError = error }, Cmd.none )

        TokenRenewalResult result ->
            let
                ( newState, error ) =
                    case result of
                        Ok token ->
                            ( Auth0.updateToken token model.state, Nothing )

                        Err err ->
                            ( model.state, Just err )
            in
                ( { model | state = newState, lastError = error }, Cmd.none )

        ShowLogIn ->
            ( model, model.showLock Auth0.defaultOpts )

        LogOut ->
            ( { model | state = Auth0.LoggedOut }, model.logOut () )

        RenewToken ->
            ( model, model.renewToken () )

        Tick aSecondHasPassed ->
            ( model, Task.perform ReportDate Date.now )

        --trigger get date
        ReportDate dateNow ->
            (case model.state of
                Auth0.LoggedIn user ->
                    ( { model | expiresIn = calculateExpiresIn dateNow user.expiresAt }, Cmd.none )

                _ ->
                    ( model, Cmd.none )
            )


view : Model -> Html Msg
view model =
    div []
        [ (case tryGetUser model of
            Nothing ->
                p [] [ text "Please log in" ]

            Just user ->
                div []
                    [ p [] [ img [ src user.profile.picture ] [] ]
                    , p [] [ text ("Hello, " ++ user.profile.name ++ "!") ]
                    , p [] [ text ("Token will expire in " ++ model.expiresIn ++ " milliseconds") ]
                    ]
          )
        , button
            [ class "btn btn-primary"
            , onClick (either model LogOut ShowLogIn)
            ]
            [ text (either model "Logout" "Login")
            ]
        , either model (button [ onClick RenewToken ] [ text "Renew token" ]) (br [] [])
        ]


handleAuthResult : Auth0.RawAuthenticationResult -> Msg
handleAuthResult =
    Auth0.mapResult >> AuthenticationResult


handleTokenRenewalResult : Auth0.RawTokenRenewalResult -> Msg
handleTokenRenewalResult =
    Auth0.mapTokenRenewalResult >> TokenRenewalResult


tryGetUser : Model -> Maybe Auth0.LoggedInUser
tryGetUser model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user

        Auth0.LoggedOut ->
            Nothing


tryGetAccessToken : Model -> Maybe Auth0.Token
tryGetAccessToken model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user.token

        Auth0.LoggedOut ->
            Nothing


isLoggedIn : Model -> Bool
isLoggedIn model =
    case model.state of
        Auth0.LoggedIn _ ->
            True

        Auth0.LoggedOut ->
            False


either : Model -> a -> a -> a
either model x y =
    (if isLoggedIn model then
        x
     else
        y
    )


toMillisecondsSinceEpoch : Date.Date -> Float
toMillisecondsSinceEpoch date =
    date
        |> Date.toTime
        |> Time.inMilliseconds


calculateExpiresIn : Date.Date -> String -> String
calculateExpiresIn dateNow tokenExpiresAt =
    case (Date.fromString tokenExpiresAt) of
        Ok expiresAt ->
            ((toMillisecondsSinceEpoch expiresAt) - (toMillisecondsSinceEpoch dateNow))
                |> Basics.toString

        Err err ->
            Debug.log "error calculateExpiresIn" ("Could not parse expiresAt: " ++ err)
