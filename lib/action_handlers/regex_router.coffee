# This is a simple preempting router using a regular expression to parse the URL.
# The regular expression is relative to the farthest directory from root containing
# metadata, so any directory can be made a virtual directory by including
# a _default.meta.[js or coffee] in it specifying this as the preempting router.
# The regular expression will then parse URL elements beyond that directory.
# When a match is made, the request will be redirected to the URL specified in the
# redirect_to argument with the regular expression captures in req.args.  The URL may
# (and probably should be) to a hidden resource.
exports = module.exports = action= (regex,redirect_to)->
  regex_router= (req,res,next)->
    malifi= req._
    meta= malifi.meta
    a= regex.exec(malifi.url.parsed.pathname.substr(meta.path_.length))
    return next() unless a
    req.args= a.slice(1)
    meta.reroute_(redirect_to)(req,res,next)