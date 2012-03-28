# if meta._directory_index_module is specified, invoke it to produce a directory index
_ = require('underscore')._
module.exports= (directory_index_module_name)->
  directory_index= (req,res,next) ->
    try
      directory_index_module = req.malifi.meta[directory_index_module_name]
      if _.isFunction(directory_index_module)
        directory_index_module(req,res,next)
      else
        next()
    catch e
      next(e)