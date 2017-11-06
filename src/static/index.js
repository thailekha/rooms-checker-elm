const $ = require( '../../node_modules/jquery/dist/jquery.js' );           // <--- remove if jQuery not needed

// inject bundled Elm app into div#main
const Elm = require( '../elm/Main' );

function logLocalStorage() {
  console.warn(localStorage);
}

function setLocalStorage(name, picture, idToken, accessToken, expiresAt) {
  localStorage.setItem('name', JSON.stringify(name));
  localStorage.setItem('picture', JSON.stringify(picture));
  localStorage.setItem('id_token', idToken);
  localStorage.setItem('access_token', accessToken);
  localStorage.setItem('expires_at', expiresAt);
}

function resetLocalStorage() {
  localStorage.removeItem('name');
  localStorage.removeItem('picture');
  localStorage.removeItem('id_token');
  localStorage.removeItem('access_token');
  localStorage.removeItem('expires_at');
}

function proceessTokenExpiry(expiresIn) {
  return new Date(expiresIn * 1000 + Date.now()).toISOString();
}

function getStoredAuthData() {
  logLocalStorage();
  var storedName = localStorage.getItem('name');
  var storedPicture = localStorage.getItem('picture');
  var storedIDToken = localStorage.getItem('id_token');
  var storedAccessToken = localStorage.getItem('access_token');
  var storedExpiresAt = localStorage.getItem('expires_at');

  return storedExpiresAt
    && storedName
    && storedPicture 
    && storedIDToken
    && storedAccessToken
    ? ({
        name: JSON.parse(storedName),
        picture: JSON.parse(storedPicture),
        token: storedAccessToken,
        expiresAt: storedExpiresAt + ""
      }) : null;
}

function initAuth() {
  return new auth0.WebAuth({
    domain: 'thailekha.auth0.com',
    clientID: '9891wr1mAT8JBBHk9REi4khrO24Dpow9',
    redirectUri: location.href,
    audience: 'http://localhost:3000',
    scope: 'openid profile read:history',
    responseType: 'token id_token'
  });
}

function renewToken(elmApp, webAuth) {
  webAuth.renewAuth({
    scope: 'read:history',
    responseType: 'token'
  }, function(err, result) {
    if (err) {
      console.warn(err);
    } else {
      handleTokenRenewalResult(elmApp, result);
      console.warn('Successfully renewed auth!');
    }
  });
}

function parseAuthentication(elmApp, webAuth, pubKey) {
  webAuth.parseHash(function(err, authResult) {
    if (authResult 
      && authResult.idToken 
      && authResult.accessToken 
      && authResult.idTokenPayload 
      && authResult.expiresIn) {
      window.location.hash = '';
      handleAuthResult(elmApp, authResult, pubKey);
    } else if (err) {
      console.log(err);
      alert(`Error: ${err.error}. Check the console for further details.`);
    }
  });
}

function handleAuthResult(elmApp, authResult, pubKey) {
  console.warn(authResult);
  var idToken = authResult.idToken;

  if (KJUR.jws.JWS.verifyJWT(idToken, pubKey, {alg: ["RS256"]})) {
    var name = authResult.idTokenPayload.name;
    var picture = authResult.idTokenPayload.picture;
    var accessToken = authResult.accessToken;
    var expiresAt = proceessTokenExpiry(authResult.expiresIn);

    elmApp.ports.auth0authResult.send({ 
      name: name,
      picture: picture,
      token: accessToken,
      expiresAt: expiresAt
    });
    setLocalStorage(name, picture, idToken, accessToken, expiresAt);
  }
}

function handleTokenRenewalResult(elmApp, tokenRenewalResult) {
  console.warn(tokenRenewalResult);
  var accessToken = tokenRenewalResult.accessToken;

  if (accessToken) {
    var expiresAt = proceessTokenExpiry(tokenRenewalResult.expiresIn);

    elmApp.ports.auth0TokenRenewalResult.send({
      token: accessToken, 
      expiresAt: expiresAt
    });
    localStorage.setItem('access_token', accessToken);
    localStorage.setItem('expires_at', expiresAt);
  }
}

function setupElmPorts(elmApp, webAuth) {
  elmApp.ports.auth0showLock.subscribe(function() {
    console.warn("JS got msg from Elm: show lock");
    webAuth.authorize();
  });

  elmApp.ports.auth0renewToken.subscribe(function() {
    console.warn("JS got msg from Elm: renew token");
    renewToken(elmApp, webAuth);
  });

  elmApp.ports.auth0logout.subscribe(function() {
    console.warn("JS got msg from Elm: logout");
    resetLocalStorage();
  });  
}

//webAuth.authorize({nonce: '1234'});
//auth0 will cause page reloading when auth result comes back

function init(pubKey) {
  var elmApp = Elm.Main.fullscreen(getStoredAuthData());
  var webAuth = initAuth();
  setupElmPorts(elmApp, webAuth);
  parseAuthentication(elmApp, webAuth, pubKey);
}

$.getJSON('https://thailekha.auth0.com/.well-known/jwks.json', function(jwks) {
  var pubKey = KEYUTIL.getKey(jwks.keys[0]);
  init(pubKey);
});