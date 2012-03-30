utilities= require('./utilities')
forbidden = utilities.forbidden

exports = module.exports = action= (subaction)->
  main_action= handler= if subaction
    (req,res,next)->
      malifi= req.malifi
      meta= malifi.meta
      pathobj= malifi.path
      meta._unhandled_handler?.log?(req)

      unless req.internal?  # internal requests and redirections may address resources that are hidden to the outside world
        if meta._forbiddenURLChars?.test(malifi.url.decoded_path)
          return forbidden(res)

        urlExtension = pathobj.extension
        if urlExtension && meta._allowed_url_extensions && '/' != urlExtension
          unless utilities.nameIsInArray(urlExtension,meta._allowed_url_extensions)
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
