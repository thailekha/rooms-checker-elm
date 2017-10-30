const $ = require( '../../node_modules/jquery/dist/jquery.js' );           // <--- remove if jQuery not needed

// inject bundled Elm app into div#main
const Elm = require( '../elm/Main' );

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
    scope: 'openid profile write:freetimes', //profile is to patch the current elm model atm
    //https://auth0.com/docs/scopes/current
    responseType: 'token id_token' //really important, otherwise idToken key will be null
  });
}

function renewToken(elmApp, webAuth) {
  //this method is not in the docs, only in the quickstart tutorial
  webAuth.renewAuth({
    scope: 'write:freetimes',
    responseType: 'token' //override responseType, only need accessToken here
    // usePostMessage: true <-- DO NOT USE !!! this causes timeout !!!
  }, function(err, result) {
    if (err) {
      console.warn(err);
    } else {
      handleTokenRenewalResult(elmApp, result);
      console.warn('Successfully renewed auth!');
    }
  }
  );
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
        `Error: ${err.error}. Check the console for further details.`
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

function handleTokenRenewalResult(elmApp, authResult) {
  var result = { err: null, ok: null };
  var accessToken = authResult.accessToken;

  if (accessToken) {
    result.ok = accessToken;
    localStorage.setItem('access_token', accessToken);
  } else {
    //For Elm, refactor this !
    result.err = {
      name : "Error token renewal",
      code : "",
      description : "acessToken null",
      statusCode : -1
    };

    alert(result.err.description);
  }
  elmApp.ports.auth0TokenRenewalResult.send(result);
}

function init(pubKey) {
  var elmApp = Elm.Main.fullscreen(getStoredAuthData());

  var webAuth = initAuth();

  elmApp.ports.auth0showLock.subscribe(function(opts) {
    console.warn("JS got msg from Elm: show lock");
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

  elmApp.ports.auth0renewToken.subscribe(function(opts) {
    renewToken(elmApp, webAuth);
  });

  //auth0 will cause page reloading when auth result comes back
  parseAuthentication(elmApp, webAuth);
}

$.getJSON('https://thailekha.auth0.com/.well-known/jwks.json', function(jwks) {
  pubKey = KEYUTIL.getKey(jwks.keys[0]);
  init(pubKey);
});