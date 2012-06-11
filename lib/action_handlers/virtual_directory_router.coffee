# This is a preempting router that turns any directory into a virtual directory.
# All URL elements beyond the directory will be placed into an array stored at
# request.args and the request will then be rerouted to the URL in the redirect_to
# argument.  The URL to which requests are redirected may (and probably should be)
# a hidden resource.
exports = module.exports = action= (redirect_to)->
  virtual_directory_router= (req,res,next)->
    malifi= req._
    meta= malifi.meta
    req.args= malifi.url.parsed.pathname.substr(meta.path_.length).split('/')
    meta.reroute_(redirect_to)(req,res,next)