# look for a directory's _index resource and if present, serve it
select_actions= require('./select_actions')
module.exports= (indexResourceName)->
  invoke_directory_default= (req,res,next) ->
    try
      malifi = req.malifi
      next unless malifi.files['/']
      malifi.find_files dir, malifi.indexResourceName, (files)->
        if (files[''])
          select_actions(req,res,next)
        else
          next()
    catch e
      next(e)