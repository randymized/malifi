staticHandler= require('../static_handler')
utilities= require('../utilities')

# if a .txt file is requested, return it
module.exports= textAction= (pass) ->
  if !@meta._allowed_static_extensions? || utilities.nameIsInArray(@path.extension,@meta._allowed_static_extensions)
    staticHandler.call(this)
  else
    pass()
