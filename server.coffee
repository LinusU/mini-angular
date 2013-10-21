
assman = require 'assman'
express = require 'express'

assman.top __dirname + '/assets'

assman.register 'html', 'test', [ 'test.jade' ]
assman.register 'js', 'mini-angular', [ 'event-emitter.coffee', 'mini-angular.coffee' ]

app = express()
app.use assman.middleware

app.get '/', (req, res) ->
  res.redirect '/test.html'

app.listen 4600
