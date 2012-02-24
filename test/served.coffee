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
    get('/metaTestString','foreground:test', done)
  it 'metadata may be in a JSON file', (done) ->
    get('/sub/showmeta','b/show.test_string', done)
  it 'should be able to run a .js file', (done) ->
    get('/aJSFile','Got JS', done)
  it 'should 404 if a file is not present', (done) ->
    get('/notHere',404, done)
  it 'should err if the URL has an extension, but the extension is not allowed', (done) ->
    get('/any.xxx',404, done)
  it 'should err if any element of the URL starts with an underscore', (done) ->
    get('/x/_no',403, done)
  it 'should err if any element of the URL starts with an underscore', (done) ->
    get('/_no/way',403, done)
  it 'should err if any element of the URL starts with an underscore', (done) ->
    get('/_no',403, done)
  it 'should err if any element of the URL ends with an underscore', (done) ->
    get('/x/no_',403, done)
  it 'should err if any element of the URL ends with an underscore', (done) ->
    get('/no_/way',403, done)
  it 'should err if any element of the URL ends with an underscore', (done) ->
    get('/no_',403, done)
  it 'should err if any element of the URL starts with a dot', (done) ->
    get('/.no',403, done)
  it 'should err if any element of the URL starts with a dot', (done) ->
    get('/x/.no',403, done)
  it 'should err if any element of the URL starts with a dot', (done) ->
    get('/.no/whey',403, done)
  it 'should serve favicon.ico (which is in the base site)', (done) ->
    get('/favicon.ico',200, done)
  it 'should find a file in the background layer site', (done) ->
    get('/background.txt','In the background', done)
  it 'should find a file in the common layer site', (done) ->
    get('/common.txt','in common', done)
