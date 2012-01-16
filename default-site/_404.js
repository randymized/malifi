_res.statusCode=404
_res.setHeader('Content-Type','text/plain');
if ('HEAD' == _req.method) return _res.end()
_res.end('Cannot '+_req.method+' '+_req.url);
