isModule = require('../utilities').isModule

# invoke the module at the given path if it is present
module.exports= justAModuleAction= (pass,req,res,next,malifi,meta) ->
  path = req.malifi.path.full
  isModule path, (found)->
    if found
      require(path)(req,res,next,malifi,meta)
    else
      pass()
