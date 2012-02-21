recent= []
limit= 10
enabled= false

uncaught= (err) ->
  console.error('Caught exception: ' + err + " Recent requests: "+JSON.stringify(recent))
  console.trace()
  process.exit(1)

module.exports= exports=
  log: ()->
    recent.unshift
      headers: @req.headers
      time: @req._startTime
      url: @req.url
    recent= recent[0...limit]
    exports.enable() unless enabled

  enable: ()->
    enabled= true
    process.on('uncaughtException', uncaught)

  diable: ()->
    process.removeListener('uncaughtException', uncaught)
    enabled= false
