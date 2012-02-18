staticHandler= require('../static_handler')

# if a .txt file is requested, return it
module.exports= textAction= () ->
  when: (req)->
    '.txt' == req.malifi.path.extension
  run: (req,res,next) ->
    staticHandler(req,res,next)
