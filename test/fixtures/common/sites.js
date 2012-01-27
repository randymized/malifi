var site= '../site'
var map= {
  localhost: site
 ,'127.0.0.1': site
}
extractHostFromHost= /([^:]+).*/

module.exports= function(req) {
  return map[req.headers.host.replace(extractHostFromHost,'$1')]
}
