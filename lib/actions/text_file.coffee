staticHandler= require('../static_handler')

# if a .txt file is requested, return it
module.exports= textAction= (pass,req,res,next,malifi,meta) ->
  if '.txt' == req.malifi.path.extension
    staticHandler(req,res,next)
  else
    pass()
