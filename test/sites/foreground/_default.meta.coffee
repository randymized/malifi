action_series= require('../../../lib/action_series')

# The actions herein do not necessarily demonstrate a best practice.
# Normally the text could simply be placed in a text files and served as
# statics.  They are here for the sake of testing, to readily test whether
# the first, middle and last of the actions in an array of actions will fire.

exports= module.exports= (prev)=>
  test_string: 'foreground'
  _actions: do(prev)->
    prev._actions.GET.test=
      action_series [
        # first action (yes, action handlers may be defined inline, as well
        # as in separate files).
        (req,res,next) ->
          try
            if req._.path.base == 'x'
              res.setHeader('Content-Type','text/plain')
              res.end('x test page')
            else
              next()
          catch e
            next(e)
        ,(req,res,next) ->
          # second action
          try
            if req._.path.base == 'y'
              res.setHeader('Content-Type','text/plain')
              res.end('y test page')
            else
              next()
          catch e
            next(e)
        ,(req,res,next) ->
          # third action
          try
            if req._.path.base == 'z'
              res.setHeader('Content-Type','text/plain')
              res.end('z test page')
            else
              next()
          catch e
            next(e)
      ]
    prev._actions

