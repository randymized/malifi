_=require('underscore')
module.exports= reroute= (url,host)->
  return (req,res,next)->
    newreq= _.clone(req)
    newreq.headers= _.clone(req.headers)
    newreq.url= url
    newreq.headers.host= host if host && _.isString(host)
    newreq.internal= true
    req.malifi.main_handler(newreq,res,next)


