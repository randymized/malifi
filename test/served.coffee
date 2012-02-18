connect= require('connect')
assert = require('assert')
malifi = require('..')
http = require('http')
port= 8889
host = 'localhost'

app= connect.createServer()
app.use(malifi(__dirname+'/fixtures/common'))
app.listen(port)

get= (url, expected, test, done)->
  unless done?
    done= test
    test= null
  options =
    host: host,
    port: port,
    path: url
  req= http.get options, (res)->
    buf= ''
    if typeof expected is 'number'
      res.statusCode.should.equal(expected)
      done()
    else
      res.statusCode.should.equal(200)
      res.setEncoding('utf8')
      res.on 'data', (chunk)->
        buf += chunk
      res.on 'end', ()->
        buf.should.equal(expected)
        done()
      res.on 'error', (exception) ->
        done(exception)

describe 'malifi server', ->
  before (cb) ->
    process.nextTick cb
  after ->
    app.close

  it 'should find /a.txt', (done) ->
    get('/a.txt','this is a.txt', done)
  it 'should find /sub/b.txt', (done) ->
    get('/sub/b.txt','this is the content of sub/b.txt', done)
  it 'should pick up correct site metadata', (done) ->
    get('/metaTestString','common', done)
  it 'should be able to run a .js file', (done) ->
    get('/aJSFile','Got JS', done)
  it 'should 404 if a file is not present', (done) ->
    get('/notHere',404, done)
