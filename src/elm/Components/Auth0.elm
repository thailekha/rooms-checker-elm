module Components.Auth0
    exposing
        ( AuthenticationState(..)
        , AuthenticationError
        , AuthenticationResult
        , RawAuthenticationResult
        , TokenRenewalResult
        , RawTokenRenewalResult
        , Options
        , defaultOpts
        , LoggedInUser
        , UserProfile
        , Token
        , mapResult
        , mapTokenRenewalResult
        , updateToken
        )


type alias LoggedInUser =
    { profile : UserProfile
    , token : Token
    , expiresAt : String
    }


type AuthenticationState
    = LoggedOut
    | LoggedIn LoggedInUser


type alias Options =
    {}


type alias UserProfile =
    { name : String
    , picture : String
    }


type alias Token =
    String


type alias RenewedToken =
    { token : String
    , expiresAt : String
    }


type alias AuthenticationError =
    { name : Maybe String
    , code : Maybe String
    , description : String
    , statusCode : Maybe Int
    }


type alias AuthenticationResult =
    Result AuthenticationError LoggedInUser


type alias TokenRenewalResult =
    Result AuthenticationError RenewedToken


type alias RawAuthenticationResult =
    { err : Maybe AuthenticationError
    , ok : Maybe LoggedInUser
    }


type alias RawTokenRenewalResult =
    { err : Maybe AuthenticationError
    , ok : Maybe RenewedToken
    }


mapResult : RawAuthenticationResult -> AuthenticationResult
mapResult result =
    case ( result.err, result.ok ) of
        ( Just msg, _ ) ->
            Err msg

        ( Nothing, Nothing ) ->
            Err { name = Nothing, code = Nothing, statusCode = Nothing, description = "No information was received from the authentication provider" }

        ( Nothing, Just user ) ->
            Ok user


mapTokenRenewalResult : RawTokenRenewalResult -> TokenRenewalResult
mapTokenRenewalResult result =
    case ( result.err, result.ok ) of
        ( Just msg, _ ) ->
            Err msg

        ( Nothing, Nothing ) ->
            Err { name = Nothing, code = Nothing, statusCode = Nothing, description = "No information was received from the authentication provider" }

        ( Nothing, Just renewedToken ) ->
            Ok renewedToken


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


defaultOpts : Options
defaultOpts =
    {}
