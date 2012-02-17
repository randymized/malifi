fs = require('fs')
path = require('path')
connect = require('connect')
utils = connect.utils
staticHandler= require('./static_handler')
utilities= require('./utilities')

exports = module.exports = class Action
  constructor: (actions)->
    @actions= actions
  do: (req,res,next)->
    malifi= req.malifi
    meta= malifi.meta
    runner= (actor)->
      act= actor()
      if act.when(req,malifi,meta)
        act.do(req,res,next,malifi,meta)
        return true
      return false

    return for actor in @actions when runner(actor)

noBackoutAction= () ->
  when: (req,malifi)->
    0 < malifi.path.full.indexOf(malifi.pwd)
  do: (req,res,next) ->
    return utils.forbidden(res)

# ignore non-GET requests?
getOnlyAction= () ->
  when: (req,malifi,meta)->
    req.malifi.meta.getOnly? && 'GET' != req.method && 'HEAD' != req.method
  do: (req,res,next) ->
    @next()

textAction= () ->
  when: (req)->
    '.txt' == req.malifi.path.extension
  do: (req,res,next) ->
    staticHandler(req,res,next)

justAModuleAction= () ->
  when: (req)->
    true
  do: (req,res,next) ->
    require(req.malifi.path.full)(req,res,next)

exports.defaultActions= [
    noBackoutAction
  , getOnlyAction
  , textAction
  , justAModuleAction
]


exports.actions= [
  noBackoutAction
]