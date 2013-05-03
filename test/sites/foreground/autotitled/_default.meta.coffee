module.exports =
  # bare templates will receive a context object that includes a title
  default_context_fn_: (req)->
    title: req.malifi.path.basename
