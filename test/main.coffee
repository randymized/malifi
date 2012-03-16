connect= require('connect')
assert = require('assert')
malifi = require('..')
http = require('http')
port= 8889
host = 'localhost'

app= connect.createServer()
app.use(malifi(__dirname+'/sites/common'))
app.listen(port)

get= (url, expected, statusCode, done)->
  unless done?
    done= statusCode
    statusCode=200
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
      res.statusCode.should.equal(statusCode)
      res.setEncoding('utf8')
      res.on 'data', (chunk)->
        buf += chunk
      res.on 'end', ()->
        buf.should.equal(expected)
        done()
      res.on 'error', (exception) ->
        done(exception)

describe 'Malifi', ->
    it 'should provide its version', ->
      malifi.version.should.match(/^\d+\.\d+\.\d+$/)

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
  it 'should trigger the first of the action handlers in a silo', (done) ->
    get('/x.test','x test page', done)
  it 'should trigger the last of the action handlers in a silo', (done) ->
    get('/z.test','z test page', done)
  it 'should trigger an action handlers in the middle of a silo', (done) ->
    get('/y.test','y test page', done)
  it 'should not find /_hidden.txt', (done) ->
    get('/_hidden.txt',403, done)
  it 'should be able to internally redirect (reroute), serving the otherwise hidden _hidden.txt', (done) ->
    get('/showhidden','This is hidden from outside requests.', done)
  it 'should be able to capture a partial and insert it into some text or a page', (done) ->
    get('/partial','start...This is hidden from outside requests....end', done)
  it 'should be able to redirect to another site, pick up the site\'s metadata, and show the right 404 message', (done) ->
    get('/reroute','Cannot GET //example.com/nothing', 404, done)
  it 'should be able to redirect to another site, and show a page from it, pulling the page\'s name from the query string', (done) ->
    get('/reroute?what=something','Isn\'t this something?\n', done)
  it 'should produce a listing of the content of a directory, if enabled.', (done) ->
    get('/exposed','aPDF.pdf\nmore.txt\nsome.txt\n', done)
  it 'should (based on default actions) redirect if url is of a directory but is without a trailing slash.', (done) ->
    get('/sub',301, done)
  it "should (based on default actions) serve a directory's _index resouce.", (done) ->
    get('/sub/','This is the _index.\n', done)
  it 'deals with _sites module returning its own directory: going no further', (done) ->
    get('/from_common','This should be hidden: it\'s in the common layer.', done)
  it 'errs if hostname is unknown to _sites file', (done) ->
    get('/unknown_site',500, done)
