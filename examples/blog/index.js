'use strict';

require('./index.html');

var Elm = require('./src/Main.elm').Elm;

var app = Elm.Main.init({
  node: document.getElementById('elm-code'),
  flags: {
    api: process.env.API_URL || 'http://localhost:4000'
  }
});

// API

var users =
[
  {
    id: 1,
    name: 'Mr. Test',
    password: 'test',
    email: 'test@test.com',
    login: 'test'
  }
];

xhook.before(function(request, callback) {

  if (request.url.endsWith('auth/login') && 'POST' === request.method) {
    setTimeout(function() {
      var params = JSON.parse(request.body);
      var filtered = users.filter(function(user) {
        return user.login === params.login && user.password === params.password;
      });
      if (filtered.length > 0) {
        var response = filtered[0];
        response.token = 'fake-jwt-token';
        callback({
          status: 200,
          data: JSON.stringify({ user: response }),
          headers: { 'Content-Type': 'application/json' }
        });
      } else {
        console.log('401 Unauthorized');
        callback({
          status: 401,
          data: JSON.stringify({ error: 'Unauthorized' }),
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }, 800);
  } else {

    callback();

  }

});