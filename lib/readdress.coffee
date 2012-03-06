module.exports= (mainHandler,req,res,next,url,host) ->
  newreq= {}
  for key, val of req
    newreq[key] = val
  newreq.url= url
  if host
    for key, val of newreq.headers
      newreq.headers[key] = val
    newreq.headers.host= host
  (newreq.req_stack ?= []).push(req)
  mainHandler(newreq,res,next)
