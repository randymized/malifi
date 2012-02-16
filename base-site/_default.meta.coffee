exports= module.exports=
  # If getOnly is true, only GET or HEAD requests will be handled, unless a
  # request-type specific handler is found.
  # For example, if a POST request is received for /foo/bar, the request will
  # be 404ed unless there is a *.post.js, *.post.coffee or other such post-
  # specific handler
  getOnly: true

  ,test_string: 'base'
