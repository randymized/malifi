staticHandler= require('../static_handler')

# if a .txt file is requested, return it
module.exports= textAction= (pass) ->
  if '.txt' == @malifi.path.extension
    staticHandler(@req,@res,@next)
  else
    pass()
