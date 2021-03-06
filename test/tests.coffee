_= require('underscore')
path= require('path')
connect= require('connect')
assert = require('assert')
malifi = require('..')
http = require('http')
querystring = require('querystring')
port= 8889
host = 'localhost'

malifi_middleware= malifi(__dirname+'/sites/common',
  {
    'build_lineage_':true
  , 'hook_main_connect_handler_': (handler)->
      return (req,res,next)->
        req._inserted= 'inserted by main handler hook'
        return handler(req,res,next)
  }
)

app= connect.createServer()
app.use(malifi_middleware.favicon)
app.use(malifi_middleware)
app.listen(port)

getResponse= (res,expected,statusCode,done)->
  if _.isFunction(expected)
    done= expected
  buf= ''
  res.statusCode.should.equal(statusCode)
  res.setEncoding('utf8')
  res.on 'data', (chunk)->
    buf += chunk
  res.on 'end', ()->
    if _.isFunction(expected)
      expected(null,buf,res)
    else
      buf.should.equal(expected)
      done()
  res.on 'error', (exception) ->
    done(exception)

get= (url, expected, statusCode, done)->
  unless done?
    done= statusCode
    statusCode=200
  options =
    host: host
    port: port
    path: url
  req= http.get options, (res)->
    if typeof expected is 'number'
      res.on 'data', ()->
      res.on 'end', ()->
        res.statusCode.should.equal(expected)
        done()
    else
      getResponse(res,expected,statusCode,done)

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
  it 'foreground resource\'s metadata\'s lineage should show the order of inheritance', (done) ->
    get '/dumpMeta',(err,buf)->
      if err
        done(err)
      else
        lineage = JSON.parse(buf).lineage_
        ltest= (index,expected) ->
          lineage[index].substr(-1).should.equal('/')   #path.relative strips trailing '/'.  Test that they are acually there
          path.relative(__dirname,lineage[index]).should.equal(expected)
        ltest(0,'../base-site')
        ltest(1,'sites/common')
        ltest(2,'sites/background')
        ltest(3,'sites/foreground')
        lineage.length.should.equal(4);
        done()
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
  it 'should make the path of the rerouting resource available to the one rerouted to ', (done) ->
    get('/reroute?what=show_from','Came from /reroute', done)
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
  it 'accepts a POST', (done) ->
    postdata= querystring.stringify
      a: 'b'
      x: 'y'
    options =
      host: 'localhost'
      port: port
      path: '/post'
      method: 'POST'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': postdata.length

    req = http.request options, (res)->
      getResponse(res,'{"a":"b","x":"y"}',200,done)

    # write data to request body
    req.write postdata
    req.end();
  it "metadata may be included in the resource's main module", (done) ->
    get('/sub/addmeta','foreground+', done)
  it "metadata can be inherited vertically", (done) ->
    get '/inherit/a',(err,buf)->
      if err
        done(err)
      else
        meta= JSON.parse(buf)
        meta.test_string.should.equal 'foreground+!'
        lineage= meta.lineage_
        ltest= (index,expected) ->
          path.relative(__dirname,lineage[index]).should.equal(expected)
        ltest(0,'../base-site')
        ltest(1,'sites/common')
        ltest(2,'sites/background')
        ltest(3,'sites/foreground')
        ltest(4,'sites/background/inherit/a:')
        ltest(5,'sites/foreground/inherit/a')
        lineage.length.should.equal(6);
        done()
  it "meta.path_ should reflect where metadata was actually found.", (done) ->
    get('/sub/x/y/z/showpath','/sub/x/', done)
  it "Can use the regex router to parse variables in a URL.", (done) ->
    get('/date/12/21/2012','month:12,day:21,year:2012', done)
  it "The regex router ignores any query string.", (done) ->
    get('/date/12/21/2012?x=y','month:12,day:21,year:2012', done)
  it "The regex router punts if the URL does not match the regular expression.", (done) ->
    get('/date/12/21',404, done)
  it "The regex router punts if the URL does not match the regular expression.", (done) ->
    get('/date/12/x/2012',404, done)
  it "if the URL does not match the regular expression, but there is a specific resource, that resource is served.", (done) ->
    get('/date/today','yes, today\n', done)
  it "Can implement a virtual directory using the virtual_directory preempting router.", (done) ->
    get('/virtual/12/xx/2012','["12","xx","2012"]', done)
  it "Confirm that the resource that is redirected to from the virtual directory cannot be accessed directly, as it is hidden.", (done) ->
    get('/virtual_',403, done)
  it 'should set cache max_age when serving a static resource with meta.max_age_ set', (done) ->
    get '/perpetual/note',(err,buf,res)->
      if err
        done(err)
      else
        buf.should.equal("I am forever!\n")
        res.headers['cache-control'].should.equal('public, max-age=31536000')
        done()
  it 'should set cache max_age to the proper value according to meta.max_age_', (done) ->
    get '/daily/note',(err,buf,res)->
      if err
        done(err)
      else
        buf.should.equal("This might change daily!\n")
        res.headers['cache-control'].should.equal('public, max-age=86400')
        done()
  it 'allows interception of requests immediately after being received from Connect', (done) ->
    get '/dumpInserted','inserted by main handler hook', done
  it 'should render a template with the default underscore template function', (done) ->
    get '/use_template',(err,buf,res)->
      if err
        done(err)
      else
        buf.should.equal('<body>xyz</body>')
        res.headers['content-type'].should.equal('text/html')
        done()
  it 'should render a template using abbreviated mime type', (done) ->
    get '/use_template2',(err,buf,res)->
      if err
        done(err)
      else
        buf.should.equal('<body>xyz</body>')
        res.headers['content-type'].should.equal('text/html')
        done()
  it 'should render a bare template (one without a corresponding module)', (done) ->
    options =
      host: host
      port: port
      path: '/bare_template'
      headers:
        accept: 'text/html'      # for this to work, text/html must be explicitly accepted
    req= http.get options, (res)->
        getResponse(res,'Hello there!',200,done)
  it 'should render a bare template using the default context', (done) ->
    options =
      host: host
      port: port
      path: '/autotitled/to_be_titled'
      headers:
        accept: 'text/html'      # for this to work, text/html must be explicitly accepted
    req= http.get options, (res)->
        getResponse(res,'Hello to_be_titled!',200,done)
  it 'should report the site stack to _sites module', ->
    require(__dirname+'/sites/common/_sites').getPrevSite().should.equal('base-site')
