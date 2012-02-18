# assume that the path is that of a module and load and run that module
module.exports= justAModuleAction= () ->
  when: (req)->
    true
  run: (req,res,next,malifi,meta) ->
    require(req.malifi.path.full)(req,res,next,malifi,meta)
