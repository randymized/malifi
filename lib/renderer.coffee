_= require('underscore')
fs= require('fs')

module.exports= renderer= (req,res,context,next)->
    malifi= req._
    map= malifi.meta.template_map_
    files= malifi.files
    specs= _.find map, (candidate)->
      files[candidate[0]]
    if specs
      [extension,mimetype,renderer]= specs
      compilation_done= (err,compiled)->
        if err
          next(err)
        else
          compiled.render context, (err,result)->
            if err
              next(err)
            else
              res.setHeader('Content-Type',mimetype)
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