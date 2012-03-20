buffertools= require('buffertools')
reroute= require('./reroute')

# Partial_capture invokes a URL during the rendering of a different URL,
# allowing a page to be composed of components taken from other pages.
# Data sent to the response object is captured and accumulated and, when
# the partial has completed, the callback function is invoked with the result.
#
# The host argument is optional.
# The final argument should be a callback that is invoked when the partial
# calls res.end().

module.exports= partial= (url,host)->
  (req,res,next,done) ->
    newnext= (err)->
      next(err) if err?
      done(new Buffer(0))  #not found: empty partial

    headers= {}

    newres= new buffertools.WritableBufferStream()
    wr= newres.write
    newres.write= (buffer,encoding)->
      wr.call(newres,buffer,encoding)
    newres.end= (data,encoding)->  #end is really not the end.  Write any data and call the callback.
      newres.write(data,encoding) if data?
      done(newres.getBuffer())
    newres.writeContinue= ()->
      next(new Error('writeContinue in the context of a partial is not supported'))
    newres.statusCode= (statusCode)->
      unless statusCode == 200 || statusCode == 100
        next(new Error('Status code of '+statusCode+' was encountered in a partial.'))
    newres.writeHead= (statusCode,reasonPhrase,hdrs)->
      newres.statusCode= (statusCode)
      setHeader(name,value) for name, value of hdrs
    newres.setHeader= (name,value)->   #log, but otherwise ignore headers set by the partial
      headers[name]= value
    newres.getHeader= (name)->
      return headers[name]
    newres.removeHeader= (name)->
      delete headers[name]
    newres.addTrailers= ()->
      #ignore
    reroute(url,host)(req,newres,newnext)
