_=require('underscore')
module.exports= reroute= (url,host)->
  return (req,res,next)->
    newreq= _.clone(req)
    newreq.from_req= req
    newreq.headers= _.clone(req.headers)
    newreq.url= url
    newreq.headers.host= host if host && _.isString(host)
    newreq.internal= true
    req.malifi.connect_handler(newreq,res,next)  # feed back in as if just received from Connect


