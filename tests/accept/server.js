const server = require('../../api.js'),
	assert = require('assert'),
    http = require('http');

describe('server', function () {
  before(function () {
    server.listen();
  });

  after(function () {
    server.close();
  });
});

describe('/', function () {
  it('should return 200', function (done) {
    http.get('http://localhost:5000', function (res) {
      assert.equal(200, res.statusCode);
      done();
      process.exit(0);
    });
  });
});