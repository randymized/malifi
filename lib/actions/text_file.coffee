staticHandler= require('../static_handler')

# if a .txt file is requested, return it
module.exports= textAction= (pass) ->
  if '.txt' == @path.extension
    staticHandler.call(this)
  else
    pass()
