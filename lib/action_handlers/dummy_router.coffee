# This is a dummy router.  It does nothing more than passing all requests through, unchanged, to
# Malifi's native filesystem based router.
exports = module.exports = action= (meta_key)->
  dummy_router= handler= (req,res,next)->
    return next()


  # Attachments to the handler to allow identification and creating copies
  handler.__defineGetter__ 'args', ()->
    {}
  handler.filename= __filename
  handler.extend= (editor)->
    action(subaction.extend(editor))

  handler
