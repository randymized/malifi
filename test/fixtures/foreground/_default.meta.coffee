exports= module.exports= (prev)=>
  test_string: 'foreground'
  _actions: prev._actions.change (newAction)->
    # The actions herein do not necessarily demonstrate a best practice.
    # Normally the text could simply be placed in a text files and served as
    # statics.  They are here for the sake of testing, to readily test whether
    # the first, middle and last of the actions in a "silo" will fire.
    newAction.GET.test=
      [
        # first action (yes, action handlers may be defined inline, as well
        # as in separate files).
        (pass) ->
          try
            if @path.base == 'x'
              this.res.setHeader('Content-Type','text/plain')
              this.res.end('x test page')
            else
              pass()
          catch e
            @next(e)
        ,(pass) ->
          # second action
          try
            if @path.base == 'y'
              this.res.setHeader('Content-Type','text/plain')
              this.res.end('y test page')
            else
              pass()
          catch e
            @next(e)
        ,(pass) ->
          # third action
          try
            if @path.base == 'z'
              this.res.setHeader('Content-Type','text/plain')
              this.res.end('z test page')
            else
              pass()
          catch e
            @next(e)
      ]

