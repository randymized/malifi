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

    return for actor in @actions when runner(actor)

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]