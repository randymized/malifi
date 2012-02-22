hasAnExtension = require('../utilities').hasAnExtension

extensions= ['.js','.coffee']

# invoke the module at the given path if it is present
module.exports= justAModuleAction= (pass) ->
  try
    path = @path.full
    hasAnExtension path, extensions, (found)=>
      if found
        require(path).call(this)
      else
        pass()
  catch e
    @next(e)
