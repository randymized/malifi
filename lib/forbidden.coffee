module.exports= (res)->
    body = 'Forbidden'
    res.setHeader('Content-Type', 'text/plain')
    res.setHeader('Content-Length', body.length)
    res.statusCode = 403
    res.end(body)

