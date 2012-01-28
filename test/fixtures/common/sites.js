var site= '../site'
var map= {
  localhost: site
 ,'127.0.0.1': site
}

module.exports= function(req) {
  return map[req.malifi.utils.hostname()]
}
