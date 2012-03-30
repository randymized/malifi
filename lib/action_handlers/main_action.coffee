forbidden = require('../forbidden')
nameIsInArray= require('../name_is_in_array')

exports = module.exports = action= (subaction)->
  main_action= handler= if subaction
    (req,res,next)->
      malifi= req.malifi
      meta= malifi.meta
      pathobj= malifi.path
      meta.unhandled_handler_?.log?(req)

      unless req.internal?  # internal requests and redirections may address resources that are hidden to the outside world
        if meta.forbiddenURLChars_?.test(malifi.url.decoded_path)
          return forbidden(res)

        urlExtension = pathobj.extension
        if urlExtension && meta.allowed_url_extensions_ && '/' != urlExtension
          unless nameIsInArray(urlExtension,meta.allowed_url_extensions_)
            return next()

      malifi.next_middleware_layer= next
      malifi.find_files pathobj.dirname, pathobj.basename, (files)->
        subaction(req,res,next)
  else
    (req,res,next)->
      next()


  # Attachments to the handler to allow identification and creating copies
  handler.__defineGetter__ 'args', ()->
    _.clone(extLookup)
  handler.filename= __filename
  handler.extend= (editor)->
    action(subaction.extend(editor))

  handler
