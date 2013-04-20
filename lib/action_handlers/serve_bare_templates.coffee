_ = require('underscore')
http_accept = require('http-accept')

# Serve a template even though there is no javascript module to establish a context object.
# The template will be rendered with an empty context.
module.exports= ()->
  serve_bare_templates= (req,res,next) ->
    select= ()->
      try
        malifi = req.malifi
        files = malifi.files
        meta= malifi.meta
        mime_map= meta.template_map_
        mime_list= _.keys(mime_map)
        mime_list.unshift(meta.template_map_default_MIME_type_) if meta.template_map_default_MIME_type_
        mime_type= req.accept.types?.getBestMatch(mime_list)
        if mime_map[mime_type]
          for renderer in mime_map[mime_type]
            if files[renderer[0]]
              return req.malifi.render(mime_type)
        next()
      catch e
        next(e)

    if req.accept?.types?
      select()
    else
      # http-accept is not in the middleware stack: insert its results
      http_accept req,res,(err)->
        return next(err) if err
      select()
