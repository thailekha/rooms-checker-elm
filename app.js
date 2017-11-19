var express = require('express');
//.debug = true
var bodyParser = require('body-parser');
//require('dotenv').config();
var path = require('path');
var server = express();

server.set('port', (process.env.PORT || 5000));
server.use(bodyParser.json()); // support json encoded bodies
server.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies
server.use('/',express.static(path.join(__dirname, 'dist')));

server.listen(server.get('port'), function() {
  console.log('Node app is running at', server.get('port'));
});