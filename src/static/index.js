const $ = require( '../../node_modules/jquery/dist/jquery.js' );           // <--- remove if jQuery not needed

// inject bundled Elm app into div#main
var Elm = require( '../elm/Main' );

function init(pubKey) {
  var options = {
    allowedConnections: ['google-oauth2', 'Username-Password-Authentication'],
    auth: {
      audience: 'http://localhost:3000',
      params: {
        //revise the email scope here
        scope: 'openid profile' //profile is to patch the current elm model atm
        //https://auth0.com/docs/scopes/current
        //https://auth0.com/docs/libraries/lock/v10/sending-authentication-parameters
      },
      responseType: 'token id_token' //really important, otherwise idToken key will be null
    },
    oidcConformant: true
  };
  var lock = new Auth0Lock('fKww8G6jE08WDtMRg2nYRfMOCkXQqZp0', 'thailekha.auth0.com', options);
  var storedProfile = localStorage.getItem('profile');
  var storedIdToken = localStorage.getItem('id_token');
  var storedAccessToken = localStorage.getItem('access_token');
  var authData = storedProfile && storedIdToken && storedAccessToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
  var elmApp = Elm.Main.fullscreen(authData);

  // Show Auth0 lock subscription
  elmApp.ports.auth0showLock.subscribe(function(opts) {
    console.warn("JS got msg from Elm");
    lock.show();
  });

  // Log out of Auth0 subscription
  elmApp.ports.auth0logout.subscribe(function(opts) {
    console.warn("JS got msg from Elm");
    localStorage.removeItem('profile');
    localStorage.removeItem('id_token');
    localStorage.removeItem('access_token');
  });

  // Listening for the authenticated event
  lock.on("authenticated", function(authResult) {
    console.warn(authResult);
    var result = { err: null, ok: null };

    var idToken = authResult.idToken;
    var accessToken = authResult.accessToken;

    //OpenID
    if (KJUR.jws.JWS.verifyJWT(idToken, pubKey,{alg: ["RS256"]})) {
      var profile = authResult.idTokenPayload;
      result.ok = { profile: profile, token: accessToken };
      localStorage.setItem('profile', JSON.stringify(profile));
      localStorage.setItem('id_token', idToken);
      localStorage.setItem('access_token', accessToken);
    } else {
      //For Elm, refactor this !
      result.err = {
        name : "Error user authentation",
        code : "",
        description : "Invalid JWT signature",
        statusCode : -1
      };

      alert(result.err.description);
    }
    elmApp.ports.auth0authResult.send(result);
  });
}

$.getJSON('https://thailekha.auth0.com/.well-known/jwks.json', function(jwks) {
  pubKey = KEYUTIL.getKey(jwks.keys[0]);
  init(pubKey);
});