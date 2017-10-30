module Components.Authentication
    exposing
        ( Msg(..)
        , Model
        , init
        , update
        , handleAuthResult
        , handleTokenRenewalResult
        , tryGetUserProfile
        , tryGetAccessToken
        , isLoggedIn
        , view
        , either
        )

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Components.Auth0 as Auth0


type alias Model =
    { state : Auth0.AuthenticationState
    , lastError : Maybe Auth0.AuthenticationError
    , showLock : Auth0.Options -> Cmd Msg
    , logOut : () -> Cmd Msg
    , renewToken : () -> Cmd Msg
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
    }


type Msg
    = AuthenticationResult Auth0.AuthenticationResult
    | TokenRenewalResult Auth0.TokenRenewalResult
    | ShowLogIn
    | LogOut
    | RenewToken


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


view : Model -> Html Msg
view model =
    div []
        [ (case tryGetUserProfile model of
            Nothing ->
                p [] [ text "Please log in" ]

            Just user ->
                div []
                    [ p [] [ img [ src user.picture ] [] ]
                    , p [] [ text ("Hello, " ++ user.name ++ "!") ]
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


tryGetUserProfile : Model -> Maybe Auth0.UserProfile
tryGetUserProfile model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user.profile

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
