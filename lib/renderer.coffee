_= require('underscore')
fs= require('fs')

module.exports= renderer= (req,res,mime_type,context,next)->
    malifi= req._
    meta= malifi.meta
    map= meta.template_map_
    files= malifi.files
    type_list= map[mime_type]
    unless type_list
      # perhaps an abbreviation was used for the mime type, e.g. 'html' for 'text/html'
      orig_mime_type= mime_type
      mime_type= meta.mime_type_abbreviations_[mime_type]
      type_list= map[mime_type]
    unless type_list
      return next(new Error("Unexpected mime type (#{orig_mime_type}) was requested."))

    specs= _.find type_list, (candidate)->
      files[candidate[0]]
    if specs
      [extension,renderer]= specs
      compilation_done= (err,compiled)->
        if err
          next(err)
        else
          compiled.render context, (err,result)->
            if err
              next(err)
            else
              res.setHeader('Content-Type',mime_type)
              res.end(result)
      if renderer.compile_file
        renderer.compile_file(req, res, files[extension], compilation_done)
      else
        fs.readFile files[extension], 'utf8', (err, template)->
          if (err)
            next(err)
          else
            renderer.compile_string(req, res, template, compilation_done)
    else
      next(new Error("No template was found"))