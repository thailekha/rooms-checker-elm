module Components.Auth0
    exposing
        ( AuthenticationState(..)
        , LoggedInUser
        , RenewedToken
        , updateToken
        )


type alias LoggedInUser =
    { name : String
    , picture : String
    , token : String
    , expiresAt : String
    }


type AuthenticationState
    = LoggedOut
    | LoggedIn LoggedInUser


type alias RenewedToken =
    { token : String
    , expiresAt : String
    }


updateToken : RenewedToken -> AuthenticationState -> AuthenticationState
updateToken renewedToken state =
    case state of
        LoggedIn loggedInUser ->
            LoggedIn
                { loggedInUser
                    | token = renewedToken.token
                    , expiresAt = renewedToken.expiresAt
                }

        _ ->
            state
