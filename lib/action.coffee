connect = require('connect')
utils = connect.utils

exports = module.exports = class Action
  constructor: (actions)->
    @actions= actions
  run: (req,res,next)->
    malifi= req.malifi
    meta= malifi.meta
    runner= (actor)->
      act= actor()
      if act.when(req,malifi,meta)
        act.run(req,res,next,malifi,meta)
        return true
      return false

    runner(noBackoutAction)   # URLs cannot drop out of the site's root dir
    return for actor in @actions when runner(actor)

# disallow using .. in URLs to drop out of a site's root directory
noBackoutAction= () ->
  when: (req,malifi)->
    0 < malifi.path.full.indexOf(malifi.pwd)
  run: (req,res,next) ->
    return utils.forbidden(res)

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]