###
 * A large portion of the code in this file is adapted from:
 * Connect - staticProvider
 * Copyright(c) 2010 Sencha Inc.
 * Copyright(c) 2011 TJ Holowaychuk
 * MIT Licensed
 *
 * The overall file is 
 * Copyright(c) 2012 Randy McLaughlin
 * MIT Licensed
 *
###

fs = require('fs')
connect = require('connect')
utils = connect.utils
mime = require('mime')

exports= module.exports= staticHandler= (mimeWrapper)->
  path= @path.full
  mimeWrapper path, (err, type) =>
    if (err)
      return if 'ENOENT' == err.code then @next() else @next(err)
    else
      fs.stat path, (err, stat) =>
        # header fields
        unless @res.getHeader('Date')
          @res.setHeader('Date', new Date().toUTCString())
        #todo: unless @res.getHeader('Cache-Control') @res.setHeader('Cache-Control', 'public, max-age=' + (maxAge / 1000))
        unless @res.getHeader('Last-Modified')
          @res.setHeader('Last-Modified', stat.mtime.toUTCString())
        unless @res.getHeader('ETag')
          @res.setHeader('ETag', utils.etag(stat))
        unless @res.getHeader('content-type')
          charset = mime.charsets.lookup(type)
          @res.setHeader('Content-Type', type + (if charset then " charset=#{charset}" else ''))
        @res.setHeader('Accept-Ranges', 'bytes')

        # conditional GET support
        if utils.conditionalGET(@req)
          unless utils.modified(@req, @res)
            @req.emit('static')
            return utils.notModified(@res)

        opts = {}
        chunkSize = stat.size

        if ranges = @req.headers.range
          if ranges = utils.parseRange(stat.size, ranges)
            #valid
            # (connect)TODO: stream options
            # (connect)TODO: multiple support
            opts.start = ranges[0].start
            opts.end = ranges[0].end
            chunkSize = opts.end - opts.start + 1
            @res.statusCode = 206
            @res.setHeader('Content-Range', "bytes #{opts.start}-#{opts.end}/#{stat.size}")

        @res.setHeader('Content-Length', chunkSize)

        # transfer
        if 'HEAD' == @req.method
          return @res.end()

        # stream
        stream = fs.createReadStream(path, opts)
        @req.emit('static', stream)
        stream.pipe(@res)
