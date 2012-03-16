background= __dirname+'/../background'
example= __dirname+'/../example.com'
map=
  localhost: background
  '127.0.0.1': background
  'example.com': example
  'common.localhost': __dirname

exports= module.exports=
  lookup: ()->
      return map[@host.name]
  paths: [background,example]
