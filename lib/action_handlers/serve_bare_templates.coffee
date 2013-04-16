# Serve a template even though there is no javascript module to establish a context object.
# The template will be rendered with an empty context.
module.exports= ()->
  serve_bare_templates= (req,res,next) ->
    try
      accepts= req.headers.accept?.split(',')
      return next() unless accepts
      malifi = req.malifi
      files = malifi.files
      mime_map= malifi.meta.template_map_
      for mime_type in accepts
        mime_type= mime_type.split(';')[0]
        if mime_map[mime_type]
          for renderer in mime_map[mime_type]
            if files[renderer[0]]
              return req.malifi.render(mime_type)
      next()
    catch e
      next(e)