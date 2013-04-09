engine= require('underscore').template

module.exports= underscore_renderer=
  compile_string: (req,res,template_string,when_compiled)->
    try
      compiled= engine(template_string)
      when_compiled null,
        render: (context,done)->
          try
            done(null, compiled(context))
          catch err
            done(err)
    catch err
      when_compiled(err)
