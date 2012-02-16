var msg = 'production' == _env
  ? 'Internal Server Error'
  : _err.stack || _err.toString();

// output to stderr in a non-test env
if ('test' != _env) console.error(_err.stack || _err.toString());

// unable to respond
if (_res.headerSent) return _req.socket.destroy();


_res.statusCode=500
_res.setHeader('Content-Type','text/plain');
if ('HEAD' == req.method) return _res.end()
_res.end(_err? _err.msg: 'Internal server error');
