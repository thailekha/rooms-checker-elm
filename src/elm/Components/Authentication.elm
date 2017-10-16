module Components.Authentication
    exposing
        ( Msg(..)
        , Model
        , init
        , update
        , handleAuthResult
        , tryGetUserProfile
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
    }


init : (Auth0.Options -> Cmd Msg) -> (() -> Cmd Msg) -> Maybe Auth0.LoggedInUser -> Model
init showLock logOut initialData =
    { state =
        case initialData of
            Just user ->
                Auth0.LoggedIn user

            Nothing ->
                Auth0.LoggedOut
    , lastError = Nothing
    , showLock = showLock
    , logOut = logOut
    }


type Msg
    = AuthenticationResult Auth0.AuthenticationResult
    | ShowLogIn
    | LogOut


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

        ShowLogIn ->
            ( model, model.showLock Auth0.defaultOpts )

        LogOut ->
            ( { model | state = Auth0.LoggedOut }, model.logOut () )


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
        ]


handleAuthResult : Auth0.RawAuthenticationResult -> Msg
handleAuthResult =
    Auth0.mapResult >> AuthenticationResult


tryGetUserProfile : Model -> Maybe Auth0.UserProfile
tryGetUserProfile model =
    case model.state of
        Auth0.LoggedIn user ->
            Just user.profile

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
