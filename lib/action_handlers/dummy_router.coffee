# This is a dummy router.  It does nothing more than passing all requests through, unchanged, to
# Malifi's native filesystem based router.
exports = module.exports = action= (meta_key)->
  dummy_router= (req,res,next)->
    return next()