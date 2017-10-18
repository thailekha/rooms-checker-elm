const $ = require( '../../node_modules/jquery/dist/jquery.js' );           // <--- remove if jQuery not needed

// inject bundled Elm app into div#main
const Elm = require( '../elm/Main' );

function getStoredAuthData() {
  var storedProfile = localStorage.getItem('profile');
  var storedIDToken = localStorage.getItem('id_token');
  //var storedAccessToken = localStorage.getItem('access_token');
  return storedProfile && storedIDToken && storedAccessToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
  return storedProfile && storedIDToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
}

function initAuth() {
  return new auth0.WebAuth({
    domain: 'thailekha.auth0.com',
    clientID: 'fKww8G6jE08WDtMRg2nYRfMOCkXQqZp0',
    redirectUri: location.href,
    scope: 'openid profile',
    responseType: 'id_token'
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
  //var accessToken = authResult.accessToken;

  //OpenID - use id token to verify user
  if (KJUR.jws.JWS.verifyJWT(idToken, pubKey,{alg: ["RS256"]})) {
    var profile = authResult.idTokenPayload;

    //verify using idtoken but give elm access token
    result.ok = { profile: profile, token: idToken };

    //store everything in local stage though
    localStorage.setItem('profile', JSON.stringify(profile));
    localStorage.setItem('id_token', idToken);
    //localStorage.setItem('access_token', accessToken);
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


  // var options = {
  //   allowedConnections: ['google-oauth2', 'Username-Password-Authentication'],
  //   auth: {
  //     params: {
  //       //revise the email scope here
  //       scope: 'openid email profile', //profile is to patch the current elm model atm
  //       //https://auth0.com/docs/scopes/current
  //       //https://auth0.com/docs/libraries/lock/v10/sending-authentication-parameters

  //       audience: 'https://thailekha.auth0.com/userinfo'
  //     },
  //     responseType: 'token' //really important, otherwise idToken key will be null
  //   },
  //   oidcConformant: true,
  //   theme: {
  //     logo: 'http://cultofthepartyparrot.com/parrots/hd/parrot.gif',
  //     primaryColor: '#31324F'
  //   },
  //   languageDictionary: {
  //     title: 'Log me in'
  //   },
  // };
  // var lock = new Auth0Lock('fKww8G6jE08WDtMRg2nYRfMOCkXQqZp0', 'thailekha.auth0.com', options);
  // var storedProfile = localStorage.getItem('profile');
  // var storedIDToken = localStorage.getItem('id_token');
  // var storedAccessToken = localStorage.getItem('access_token');
  // var authData = storedProfile && storedIDToken && storedAccessToken ? { profile: JSON.parse(storedProfile), token: storedAccessToken } : null;
  // var elmApp = Elm.Main.fullscreen(authData);

  // Show Auth0 lock subscription
  // elmApp.ports.auth0showLock.subscribe(function(opts) {
  //   console.warn("JS got msg from Elm");
  //   lock.show();
  // });

  // Log out of Auth0 subscription
  // elmApp.ports.auth0logout.subscribe(function(opts) {
  //   console.warn("JS got msg from Elm");
  //   localStorage.removeItem('profile');
  //   localStorage.removeItem('id_token');
  //   localStorage.removeItem('access_token');
  // });

  // Listening for the authenticated event
  // lock.on("authenticated", function(authResult) {
  //   console.warn(authResult);
  //   var result = { err: null, ok: null };
  //   var idToken = authResult.idToken;
  //   var accessToken = authResult.accessToken;

  //   //OpenID - use id token to verify user
  //   if (KJUR.jws.JWS.verifyJWT(idToken, pubKey,{alg: ["RS256"]})) {
  //     var profile = authResult.idTokenPayload;

  //     //verify using idtoken but give elm access token
  //     result.ok = { profile: profile, token: idToken };

  //     //store everything in local stage though
  //     localStorage.setItem('profile', JSON.stringify(profile));
  //     localStorage.setItem('id_token', idToken);
  //     localStorage.setItem('access_token', accessToken);
  //   } else {
  //     //For Elm, refactor this !
  //     result.err = {
  //       name : "Error user authentation",
  //       code : "",
  //       description : "Invalid JWT signature",
  //       statusCode : -1
  //     };

  //     alert(result.err.description);
  //   }
  //   elmApp.ports.auth0authResult.send(result);
  // });
}

$.getJSON('https://thailekha.auth0.com/.well-known/jwks.json', function(jwks) {
  pubKey = KEYUTIL.getKey(jwks.keys[0]);
  init(pubKey);
});