const $ = require( '../../node_modules/jquery/dist/jquery.js' );           // <--- remove if jQuery not needed

// inject bundled Elm app into div#main
const Elm = require( '../elm/Main' );

// console.warn(KJUR.jws.JWS.verifyJWT.toString());

function getStoredAuthData() {
  var storedProfile = localStorage.getItem('profile');
  var storedIDToken = localStorage.getItem('id_token');
  var storedAccessToken = localStorage.getItem('access_token');
  return storedProfile && storedIDToken && storedAccessToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
  return storedProfile && storedIDToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
}

function initAuth() {
  return new auth0.WebAuth({
    domain: 'thailekha.auth0.com',
    clientID: 'fKww8G6jE08WDtMRg2nYRfMOCkXQqZp0',
    redirectUri: location.href,
    audience: 'http://localhost:3000', //short accesToken issue was fixed by adding audience
    scope: 'openid profile',
    responseType: 'token id_token'
  });
}

function parseAuthentication(elmApp, auth) {
  // auth.parseHash({nonce: '1234'}, function(err, authResult) {
  auth.parseHash(function(err, authResult) {
    if (authResult && authResult.idToken) {
      window.location.hash = '';      
      handleAuthResult(elmApp, authResult);
    } else if (err) {
      console.log(err);
      alert(
        'Error: ' + err.error + '. Check the console for further details.'
      );
    }
  });
}

function handleAuthResult(elmApp, authResult) {
  console.warn(authResult);
  var result = { err: null, ok: null };
  var idToken = authResult.idToken;
  var accessToken = authResult.accessToken;

  //OpenID - use id token to verify user
  if (KJUR.jws.JWS.verifyJWT(idToken, pubKey,{alg: ["RS256"]})) {
    var profile = authResult.idTokenPayload;

    //verify using idtoken but give elm access token
    result.ok = { profile: profile, token: accessToken };

    //store everything in local stage though
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
}

function init(pubKey) {
  var elmApp = Elm.Main.fullscreen(getStoredAuthData());

  var webAuth = initAuth();

  parseAuthentication(elmApp, webAuth);

  elmApp.ports.auth0showLock.subscribe(function(opts) {
    console.warn("JS got msg from Elm");
    //webAuth.authorize({nonce: '1234'});
    webAuth.authorize();
  });

  // Log out of Auth0 subscription
  elmApp.ports.auth0logout.subscribe(function(opts) {
    console.warn("JS got msg from Elm");
    localStorage.removeItem('profile');
    localStorage.removeItem('id_token');
    localStorage.removeItem('access_token');
  });
}

$.getJSON('https://thailekha.auth0.com/.well-known/jwks.json', function(jwks) {
  pubKey = KEYUTIL.getKey(jwks.keys[0]);
  init(pubKey);
});